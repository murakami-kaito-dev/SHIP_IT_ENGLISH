// 発音音声（OpenAI TTS）を開発時に一括生成するツール。
//
// ■ 方針（実行時はAPIを叩かない・完全オフライン再生）
//   cards.json の英語テキスト（phrase / example）を OpenAI TTS で mp3 化し、
//   assets/audio/en-US/<sha1(text)>.mp3 として保存する。実行時はこのファイルを
//   audioplayers で再生し、無ければ端末TTSにフォールバックする。
//   OpenAI は mp3 を直接返すので変換（ffmpeg/afconvert）不要。
//
// ■ 認証: OPENAI_API_KEY（環境変数、無ければ dart_defines.json）。
//   キーはツールに直接渡さず既存設定から読む。実行時には一切使わない。
//
// ■ 使い方
//   dart run tools/generate_tts.dart                        # ドライラン（件数だけ）
//   dart run tools/generate_tts.dart --poc                  # 声の聴き比べ用サンプルを tools/tts_poc/ に生成
//   dart run tools/generate_tts.dart --generate             # 未生成分だけ本生成（差分生成）
//   dart run tools/generate_tts.dart --generate --limit 20  # 先頭20件だけ
//   dart run tools/generate_tts.dart --generate --force     # 既存も作り直す
//   オプション: --voice nova  --model gpt-4o-mini-tts  --delay 200

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _audioDir = 'assets/audio/en-US';
const _manifestPath = 'assets/audio/manifest.json';
const _cardsPath = 'assets/data/cards.json';
const _pocDir = 'tools/tts_poc';
const _endpoint = 'https://api.openai.com/v1/audio/speech';
const _defaultModel = 'gpt-4o-mini-tts';
const _defaultVoice = 'nova'; // US女性寄り
// US発音・クリアさをそろえるための指示（gpt-4o系のみ有効）
const _instructions =
    'Speak clearly in a natural American English accent at a calm, natural pace.';

// 聴き比べ用の候補ボイス（女性寄り）とサンプル文
const _pocVoices = ['nova', 'shimmer', 'coral', 'sage'];
const _pocSamples = [
  "Let's take this offline.",
  "LGTM with a nit — can you rename this variable to be more descriptive?",
  "I'll pick this up in the next sprint.",
  "Can you walk me through the trade-offs here?",
];

String _normalize(String s) => s.trim();
String _key(String t) => sha1.convert(utf8.encode(_normalize(t))).toString();
bool _flag(List<String> a, String f) => a.contains(f);
String? _opt(List<String> a, String n) {
  final i = a.indexOf(n);
  return (i >= 0 && i + 1 < a.length) ? a[i + 1] : null;
}

String _apiKey() {
  final env = Platform.environment['OPENAI_API_KEY'];
  if (env != null && env.isNotEmpty) return env;
  final f = File('dart_defines.json');
  if (f.existsSync()) {
    final k = (json.decode(f.readAsStringSync())
        as Map<String, dynamic>)['OPENAI_API_KEY'] as String?;
    if (k != null && k.isNotEmpty) return k;
  }
  stderr.writeln('OPENAI_API_KEY が見つかりません（環境変数 or dart_defines.json）');
  exit(2);
}

Future<void> main(List<String> args) async {
  final model = _opt(args, '--model') ?? _defaultModel;
  final voice = _opt(args, '--voice') ?? _defaultVoice;
  final bitrate = _opt(args, '--bitrate') ?? '48000'; // AAC 48kbps mono（音声に十分）
  final delayMs = int.tryParse(_opt(args, '--delay') ?? '') ?? 200;
  final limit = int.tryParse(_opt(args, '--limit') ?? '');
  final force = _flag(args, '--force');
  final generate = _flag(args, '--generate');
  final poc = _flag(args, '--poc');
  final key = _apiKey();

  if (poc) {
    await _runPoc(key, model);
    return;
  }

  final cards = (json.decode(File(_cardsPath).readAsStringSync())
      as Map<String, dynamic>)['cards'] as List<dynamic>;
  final texts = <String>{};
  for (final c in cards.cast<Map<String, dynamic>>()) {
    for (final f in ['phrase', 'example']) {
      final t = (c[f] as String?)?.trim() ?? '';
      if (t.isNotEmpty) texts.add(t);
    }
  }
  final unique = texts.toList();

  Directory(_audioDir).createSync(recursive: true);
  final pending = <String>[
    for (final t in unique)
      if (force || !File('$_audioDir/${_key(t)}.m4a').existsSync()) t
  ];
  final target = limit != null ? pending.take(limit).toList() : pending;

  stdout.writeln('■ OpenAI TTS 生成');
  stdout.writeln('  model=$model voice=$voice');
  stdout.writeln('  ユニークテキスト: ${unique.length} / 生成済み: '
      '${unique.length - pending.length} / 未生成: ${pending.length}');
  stdout.writeln('  今回の対象: ${target.length}'
      '${limit != null ? '（--limit $limit）' : ''}');

  if (!generate) {
    stdout.writeln('\n（ドライラン）本生成は --generate、声の確認は --poc を付けてください。');
    _writeManifest(voice, model);
    return;
  }

  var ok = 0, fail = 0;
  for (var i = 0; i < target.length; i++) {
    final t = target[i];
    final out = '$_audioDir/${_key(t)}.m4a';
    // 品質のためロスレスWAVで取得し、AAC(.m4a)に単一エンコードして軽量化。
    final wav = await _openaiSynth(
        key: key, model: model, voice: voice, text: t, format: 'wav');
    if (wav != null && await _wavToM4a(wav, out, bitrate)) {
      ok++;
      if ((i + 1) % 50 == 0 || i + 1 == target.length) {
        stdout.writeln('  … ${i + 1}/${target.length} 完了');
      }
      if (ok % 100 == 0) _writeManifest(voice, model);
    } else {
      fail++;
    }
    if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
  }

  final total = _writeManifest(voice, model);
  stdout.writeln('\n完了: 生成 $ok / 失敗 $fail / マニフェスト総数 $total');
  if (fail > 0) {
    stdout.writeln('※ 失敗分は次回 --generate で再挑戦されます（差分生成）。');
    exitCode = 1;
  }
}

/// 声の聴き比べ用: 数文 × 候補ボイスを tools/tts_poc/ に読みやすい名前で生成。
Future<void> _runPoc(String key, String model) async {
  Directory(_pocDir).createSync(recursive: true);
  stdout.writeln('■ PoC（声の聴き比べ）→ $_pocDir/');
  for (final v in _pocVoices) {
    for (var i = 0; i < _pocSamples.length; i++) {
      final bytes = await _openaiSynth(key: key, model: model, voice: v, text: _pocSamples[i]);
      if (bytes != null) File('$_pocDir/${v}__${i + 1}.mp3').writeAsBytesSync(bytes);
      stdout.writeln('  ${bytes != null ? '✓' : '✗'} $v  "${_pocSamples[i]}"');
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
  stdout.writeln('\n完了。$_pocDir/ の .mp3 を再生して声を選んでください（例: nova__1.mp3）。');
}

/// OpenAI TTS を呼び、mp3 バイト列を返す。429/5xx は指数バックオフで最大5回リトライ。
Future<Uint8List?> _openaiSynth({
  required String key,
  required String model,
  required String voice,
  required String text,
  String format = 'mp3',
}) async {
  final body = jsonEncode({
    'model': model,
    'voice': voice,
    'input': text,
    'response_format': format,
    if (model.contains('gpt-4o')) 'instructions': _instructions,
  });
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final req = await client.postUrl(Uri.parse(_endpoint));
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(body));
        final resp = await req.close();

        if (resp.statusCode == 200) {
          final b = BytesBuilder();
          await for (final chunk in resp) {
            b.add(chunk);
          }
          return b.toBytes();
        }

        final errText = await resp.transform(utf8.decoder).join();
        if (resp.statusCode == 429 || resp.statusCode >= 500) {
          final wait = Duration(milliseconds: 800 * (1 << attempt));
          stderr.writeln('  … ${resp.statusCode} リトライ待機 ${wait.inMilliseconds}ms');
          await Future.delayed(wait);
          continue;
        }
        stderr.writeln('  ! HTTP ${resp.statusCode}: ${errText.substring(0, errText.length.clamp(0, 200))}');
        return null;
      } catch (e) {
        // 通信例外（接続切れ・タイムアウト等）もバックオフして再試行（落とさない）
        final wait = Duration(milliseconds: 800 * (1 << attempt));
        stderr.writeln('  … 通信エラー($e) リトライ ${wait.inMilliseconds}ms');
        await Future.delayed(wait);
      }
    }
    stderr.writeln('  ! リトライ上限');
    return null;
  } finally {
    client.close();
  }
}

/// OpenAI の WAV バイト列を macOS標準 afconvert で AAC(.m4a) に単一エンコード。
Future<bool> _wavToM4a(Uint8List wav, String outM4a, String bitrate) async {
  final tmp = File('$outM4a.tmp.wav')..writeAsBytesSync(wav);
  final r = await Process.run(
      'afconvert', ['-f', 'm4af', '-d', 'aac', '-b', bitrate, tmp.path, outM4a]);
  if (tmp.existsSync()) tmp.deleteSync();
  if (r.exitCode != 0 || !File(outM4a).existsSync()) {
    stderr.writeln('  ! afconvert 失敗: ${r.stderr.toString().trim().split('\n').first}');
    return false;
  }
  return true;
}

/// assets/audio/en-US/ の実 m4a から manifest.json を作り直す。
int _writeManifest(String voice, String model) {
  final keys = Directory(_audioDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.m4a'))
      .map((f) => f.uri.pathSegments.last.replaceAll('.m4a', ''))
      .toList()
    ..sort();
  final manifest = {
    'audioVersion': 1,
    'provider': 'openai',
    'model': model,
    'locale': 'en-US',
    'voice': voice,
    'format': 'm4a',
    'keys': keys,
  };
  File(_manifestPath)
      .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  return keys.length;
}
