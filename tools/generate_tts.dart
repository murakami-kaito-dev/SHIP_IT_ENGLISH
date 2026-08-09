// 発音音声（OpenAI TTS）を開発時に一括生成するツール（多言語対応）。
//
// ■ 方針（実行時はAPIを叩かない・完全オフライン再生）
//   cards.json のテキストを OpenAI TTS で音声化し、assets/audio/<locale>/<sha1(text)>.m4a
//   として保存。実行時は audioplayers で再生し、無ければ端末TTSにフォールバック。
//   OpenAIからWAV取得→macOS標準 afconvert で AAC(.m4a) 圧縮（ffmpeg不要）。
//
// ■ ロケール（--locale）
//   en-US（既定）：英語の phrase / example を生成 → assets/audio/en-US/・manifest=assets/audio/manifest.json
//   ja-JP        ：日本語の translation / example_translation を生成 → assets/audio/ja-JP/・manifest=assets/audio/ja-JP/manifest.json
//
// ■ 認証: OPENAI_API_KEY（環境変数、無ければ dart_defines.json）。実行時には使わない。
//
// ■ 使い方
//   dart run tools/generate_tts.dart --locale ja-JP                  # ドライラン（件数）
//   dart run tools/generate_tts.dart --locale ja-JP --poc            # 声の聴き比べ
//   dart run tools/generate_tts.dart --locale ja-JP --generate       # 本生成（差分）
//   オプション: --voice nova  --model gpt-4o-mini-tts  --bitrate 48000  --delay 200  --limit N  --force

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _cardsPath = 'assets/data/cards.json';
const _pocDir = 'tools/tts_poc';
const _endpoint = 'https://api.openai.com/v1/audio/speech';
const _defaultModel = 'gpt-4o-mini-tts';
const _defaultVoice = 'nova';
const _pocVoices = ['nova', 'shimmer', 'coral', 'sage'];

/// ロケールごとの設定（対象フィールド・保存先・読み上げ指示・PoC文）。
class _Locale {
  final String dir;
  final String manifestPath;
  final List<String> fields; // cards.json の対象キー
  final String instructions; // gpt-4o系の話し方指示
  final List<String> pocSamples;
  const _Locale(this.dir, this.manifestPath, this.fields, this.instructions, this.pocSamples);
}

const _locales = {
  'en-US': _Locale(
    'assets/audio/en-US',
    'assets/audio/manifest.json',
    ['phrase', 'example'],
    'Speak clearly in a natural American English accent at a calm, natural pace.',
    [
      "Let's take this offline.",
      "LGTM with a nit — can you rename this variable to be more descriptive?",
      "I'll pick this up in the next sprint.",
      "Can you walk me through the trade-offs here?",
    ],
  ),
  'ja-JP': _Locale(
    'assets/audio/ja-JP',
    'assets/audio/ja-JP/manifest.json',
    ['translation', 'example_translation'],
    '自然で聞き取りやすい標準的な日本語で、落ち着いた速さではっきり話してください。',
    [
      'この話は別途話しましょう。',
      'おおむねOKだけど、この変数名をもっとわかりやすく変えてほしい。',
      'これは次のスプリントで対応します。',
      'ここでのトレードオフを説明してもらえますか？',
    ],
  ),
};

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
  final localeId = _opt(args, '--locale') ?? 'en-US';
  final loc = _locales[localeId];
  if (loc == null) {
    stderr.writeln('未対応の --locale: $localeId（en-US / ja-JP）');
    exit(2);
  }
  final model = _opt(args, '--model') ?? _defaultModel;
  final voice = _opt(args, '--voice') ?? _defaultVoice;
  final bitrate = _opt(args, '--bitrate') ?? '48000';
  final delayMs = int.tryParse(_opt(args, '--delay') ?? '') ?? 200;
  final limit = int.tryParse(_opt(args, '--limit') ?? '');
  final force = _flag(args, '--force');
  final generate = _flag(args, '--generate');
  final poc = _flag(args, '--poc');
  final key = _apiKey();

  if (poc) {
    await _runPoc(key, model, loc, localeId);
    return;
  }

  final cards = (json.decode(File(_cardsPath).readAsStringSync())
      as Map<String, dynamic>)['cards'] as List<dynamic>;
  final texts = <String>{};
  for (final c in cards.cast<Map<String, dynamic>>()) {
    for (final f in loc.fields) {
      final t = (c[f] as String?)?.trim() ?? '';
      if (t.isNotEmpty) texts.add(t);
    }
  }
  final unique = texts.toList();

  Directory(loc.dir).createSync(recursive: true);
  final pending = <String>[
    for (final t in unique)
      if (force || !File('${loc.dir}/${_key(t)}.m4a').existsSync()) t
  ];
  final target = limit != null ? pending.take(limit).toList() : pending;

  stdout.writeln('■ OpenAI TTS 生成  locale=$localeId  model=$model voice=$voice');
  stdout.writeln('  ユニークテキスト: ${unique.length} / 生成済み: '
      '${unique.length - pending.length} / 未生成: ${pending.length}');
  stdout.writeln('  今回の対象: ${target.length}${limit != null ? '（--limit $limit）' : ''}');

  if (!generate) {
    stdout.writeln('\n（ドライラン）本生成は --generate、声の確認は --poc を付けてください。');
    _writeManifest(loc, localeId, voice, model);
    return;
  }

  var ok = 0, fail = 0;
  for (var i = 0; i < target.length; i++) {
    final t = target[i];
    final out = '${loc.dir}/${_key(t)}.m4a';
    final wav = await _openaiSynth(
        key: key, model: model, voice: voice, text: t, instructions: loc.instructions, format: 'wav');
    if (wav != null && await _wavToM4a(wav, out, bitrate)) {
      ok++;
      if ((i + 1) % 50 == 0 || i + 1 == target.length) {
        stdout.writeln('  … ${i + 1}/${target.length} 完了');
      }
      if (ok % 100 == 0) _writeManifest(loc, localeId, voice, model);
    } else {
      fail++;
    }
    if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
  }

  final total = _writeManifest(loc, localeId, voice, model);
  stdout.writeln('\n完了: 生成 $ok / 失敗 $fail / マニフェスト総数 $total');
  if (fail > 0) {
    stdout.writeln('※ 失敗分は次回 --generate で再挑戦されます（差分生成）。');
    exitCode = 1;
  }
}

/// 声の聴き比べ用: 数文 × 候補ボイスを tools/tts_poc/ に読みやすい名前で生成。
Future<void> _runPoc(String key, String model, _Locale loc, String localeId) async {
  Directory(_pocDir).createSync(recursive: true);
  stdout.writeln('■ PoC（声の聴き比べ・$localeId）→ $_pocDir/');
  for (final v in _pocVoices) {
    for (var i = 0; i < loc.pocSamples.length; i++) {
      final wav = await _openaiSynth(
          key: key, model: model, voice: v, text: loc.pocSamples[i], instructions: loc.instructions, format: 'wav');
      final okk = wav != null && await _wavToM4a(wav, '$_pocDir/${localeId}_${v}__${i + 1}.m4a', '48000');
      stdout.writeln('  ${okk ? '✓' : '✗'} $v  "${loc.pocSamples[i]}"');
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
  stdout.writeln('\n完了。$_pocDir/ の .m4a を再生して声を選んでください。');
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

/// OpenAI TTS を呼び、WAV/mp3 バイト列を返す。429/5xx・通信例外は指数バックオフで再試行。
Future<Uint8List?> _openaiSynth({
  required String key,
  required String model,
  required String voice,
  required String text,
  required String instructions,
  String format = 'mp3',
}) async {
  final body = jsonEncode({
    'model': model,
    'voice': voice,
    'input': text,
    'response_format': format,
    if (model.contains('gpt-4o')) 'instructions': instructions,
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

/// ロケールの実 m4a から manifest.json を作り直す。
int _writeManifest(_Locale loc, String localeId, String voice, String model) {
  final keys = Directory(loc.dir)
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
    'locale': localeId,
    'voice': voice,
    'format': 'm4a',
    'keys': keys,
  };
  File(loc.manifestPath)
      .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  return keys.length;
}
