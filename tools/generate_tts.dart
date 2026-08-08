// 発音音声（Amazon Polly Neural）を開発時に一括生成するツール。
//
// ■ 方針（実行時はAPIを叩かない・完全オフライン再生）
//   cards.json の英語テキスト（phrase / example）を Amazon Polly で mp3 化し、
//   assets/audio/en-US/<sha1(text)>.mp3 として保存する。実行時はこのファイルを
//   just/audioplayers で再生し、無ければ端末TTSにフォールバックする。
//
// ■ 前提: AWS CLI をインストールし `aws configure` 済みであること
//   （手順は docs/tts_audio_generation.md）。本ツールは `aws polly
//   synthesize-speech` を呼ぶだけで、AWSキーはツールに直接渡さない。
//
// ■ 使い方
//   dart run tools/generate_tts.dart                 # ドライラン相当（要 --generate）
//   dart run tools/generate_tts.dart --generate      # 未生成分だけ生成（差分生成）
//   dart run tools/generate_tts.dart --generate --limit 20   # PoC: 先頭20件だけ
//   dart run tools/generate_tts.dart --generate --force      # 既存も作り直す
//   オプション: --voice Joanna  --region us-east-1
//
// ■ 差分生成: すでに <sha1>.mp3 が存在するテキストは生成しない（--force で無効化）。
//   生成後、assets/audio/en-US/ の実ファイルから manifest.json を作り直す。

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _audioDir = 'assets/audio/en-US';
const _manifestPath = 'assets/audio/manifest.json';
const _cardsPath = 'assets/data/cards.json';

String _normalize(String s) => s.trim();
String _key(String text) => sha1.convert(utf8.encode(_normalize(text))).toString();

bool _hasFlag(List<String> a, String f) => a.contains(f);
String? _opt(List<String> a, String name) {
  final i = a.indexOf(name);
  return (i >= 0 && i + 1 < a.length) ? a[i + 1] : null;
}

Future<void> main(List<String> args) async {
  final generate = _hasFlag(args, '--generate');
  final force = _hasFlag(args, '--force');
  final limit = int.tryParse(_opt(args, '--limit') ?? '');
  final voice = _opt(args, '--voice') ?? 'Joanna'; // US 女性 (Neural)
  final region = _opt(args, '--region') ?? Platform.environment['AWS_REGION'];

  // 1) cards.json から英語テキスト（phrase / example）を集めて重複排除
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

  // 2) 生成が必要なもの（未生成 or --force）を抽出
  Directory(_audioDir).createSync(recursive: true);
  final pending = <String>[];
  for (final t in unique) {
    final path = '$_audioDir/${_key(t)}.mp3';
    if (force || !File(path).existsSync()) pending.add(t);
  }
  final target = limit != null ? pending.take(limit).toList() : pending;

  stdout.writeln('■ Amazon Polly TTS 生成');
  stdout.writeln('  voice=$voice engine=neural locale=en-US'
      '${region != null ? ' region=$region' : ''}');
  stdout.writeln('  ユニークテキスト: ${unique.length}');
  stdout.writeln('  生成済み        : ${unique.length - pending.length}');
  stdout.writeln('  未生成          : ${pending.length}'
      '${force ? '（--force で全件対象）' : ''}');
  stdout.writeln('  今回の対象      : ${target.length}'
      '${limit != null ? '（--limit $limit）' : ''}');

  if (!generate) {
    stdout.writeln('\n（ドライラン）実際に生成するには --generate を付けてください。');
    _writeManifest(voice); // 既存ファイルからマニフェストは整えておく
    return;
  }

  // 3) 生成
  var ok = 0, fail = 0;
  for (var i = 0; i < target.length; i++) {
    final t = target[i];
    if (t.length > 2900) {
      stderr.writeln('  ! スキップ（長すぎ ${t.length}字）: ${t.substring(0, 40)}…');
      fail++;
      continue;
    }
    final out = '$_audioDir/${_key(t)}.mp3';
    final pollyArgs = [
      'polly', 'synthesize-speech',
      '--engine', 'neural',
      '--voice-id', voice,
      '--language-code', 'en-US',
      '--output-format', 'mp3',
      if (region != null) ...['--region', region],
      '--text', t,
      out,
    ];
    final r = await Process.run('aws', pollyArgs);
    if (r.exitCode == 0 && File(out).existsSync()) {
      ok++;
      if ((i + 1) % 50 == 0 || i + 1 == target.length) {
        stdout.writeln('  … ${i + 1}/${target.length} 完了');
      }
    } else {
      fail++;
      // 失敗ファイルが中途半端に残らないように
      final f = File(out);
      if (f.existsSync()) f.deleteSync();
      stderr.writeln('  ! 失敗: ${t.substring(0, t.length.clamp(0, 40))}\n'
          '    ${r.stderr.toString().trim().split('\n').first}');
    }
  }

  final total = _writeManifest(voice);
  stdout.writeln('\n完了: 生成 $ok / 失敗 $fail / マニフェスト総数 $total');
  if (fail > 0) {
    stdout.writeln('※ 失敗分は次回 --generate で再挑戦されます（差分生成）。');
    exitCode = 1;
  }
}

/// assets/audio/en-US/ の実mp3ファイルから manifest.json を作り直す。
int _writeManifest(String voice) {
  final dir = Directory(_audioDir);
  final keys = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.mp3'))
      .map((f) => f.uri.pathSegments.last.replaceAll('.mp3', ''))
      .toList()
    ..sort();
  final manifest = {
    'audioVersion': 1,
    'engine': 'neural',
    'provider': 'amazon-polly',
    'locale': 'en-US',
    'voice': voice,
    'keys': keys,
  };
  File(_manifestPath)
      .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  return keys.length;
}
