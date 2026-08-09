import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 事前生成した発音音声（OpenAI TTS）をオフライン再生する。
///
/// ロケール別に同梱された `assets/audio/<locale>/<sha1(text)>.m4a` を、読み上げたい
/// テキストのハッシュから引いて再生する。マニフェスト（利用可能なキー一覧）は
/// 起動時に一度だけ読み込む。該当クリップが無ければ [playIfAvailable] は false を
/// 返し、呼び出し側（[TtsService]）が端末TTSにフォールバックする。
///
/// - en-US（英語・jaモードの学習対象）: manifest = assets/audio/manifest.json
/// - ja-JP（日本語・enモードの学習対象）: manifest = assets/audio/ja-JP/manifest.json
///
/// 生成側（tools/generate_tts.dart）と**同じ正規化・同じsha1**でキーを作る。
class AudioClipService {
  static final AudioClipService _instance = AudioClipService._();
  factory AudioClipService() => _instance;
  AudioClipService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'pronunciation');

  /// 発音音声は「サイレントスイッチONでも聞こえる」のが仕様（学習の核）。
  /// SFX(SoundService)が直前にセッションを ambient に変えていても、
  /// 再生の直前にこの playback コンテキストへ設定し直して消音を上書きする。
  ///
  /// ⚠️ iOSの `defaultToSpeaker` は `playAndRecord` 専用オプション。`playback` と
  /// 併用すると `Error -50`（不正パラメータ）でセッション設定が失敗し、再生されない。
  /// `playback` は元々スピーカー出力かつサイレントスイッチを無視するので不要。
  static final AudioContext _playbackContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.assistanceAccessibility,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  /// 再生完了（または外部stop）まで待つための待機ハンドル。
  Completer<void>? _activeWait;

  /// ロケール → 利用可能なキー集合
  final Map<String, Set<String>> _keysByLocale = {};
  bool _loaded = false;

  // ロケールごとの manifest 位置（audioplayers の AssetSource は `assets/` を自動前置）
  static const _manifests = {
    'en-US': 'assets/audio/manifest.json',
    'ja-JP': 'assets/audio/ja-JP/manifest.json',
  };

  String _key(String text) =>
      sha1.convert(utf8.encode(text.trim())).toString();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    // iOS: サイレントスイッチONでも鳴らす（TtsServiceのセッション設定と揃える）
    try {
      await AudioPlayer.global.setAudioContext(_playbackContext);
    } catch (e) {
      debugPrint('[AudioClipService] audio context failed: $e');
    }
    // 各ロケールのマニフェスト読み込み（無ければそのロケールは端末TTSにフォールバック）
    for (final entry in _manifests.entries) {
      try {
        final raw = await rootBundle.loadString(entry.value);
        final map = json.decode(raw) as Map<String, dynamic>;
        _keysByLocale[entry.key] = Set<String>.from(
            (map['keys'] as List<dynamic>? ?? const [])
                .map((e) => e.toString()));
      } catch (e) {
        _keysByLocale[entry.key] = <String>{};
        debugPrint('[AudioClipService] manifest(${entry.key}) load failed: $e');
      }
    }
  }

  /// 指定ロケールに同梱クリップがあれば再生して true。無ければ何もせず false。
  /// [locale] は 'en-US'（英語）/ 'ja-JP'（日本語）。
  Future<bool> playIfAvailable(String text, String locale) async {
    if (text.trim().isEmpty) return false;
    await _ensureLoaded();
    final key = _key(text);
    if (!(_keysByLocale[locale]?.contains(key) ?? false)) return false;
    try {
      // 直前にSFXが ambient にしていても、発音は消音でも鳴らすため playback に戻す
      await AudioPlayer.global.setAudioContext(_playbackContext);
      await _player.stop();
      await _player.play(AssetSource('audio/$locale/$key.m4a'));
      return true;
    } catch (e) {
      debugPrint('[AudioClipService] play failed: $e');
      return false;
    }
  }

  /// 耳学（リスニング）用：同梱クリップがあれば**再生完了まで待って** true を返す。
  /// 無ければ false（呼び出し側が端末TTSにフォールバック）。
  /// [rate] は再生速度倍率（1.0=標準）。外部から stop() されると途中でも返る。
  Future<bool> playAndWait(String text, String locale, {double rate = 1.0}) async {
    if (text.trim().isEmpty) return false;
    await _ensureLoaded();
    final key = _key(text);
    if (!(_keysByLocale[locale]?.contains(key) ?? false)) return false;
    StreamSubscription<void>? sub;
    try {
      // セッション設定の失敗（-50等）で再生自体を止めないよう内側で握りつぶす
      try {
        await AudioPlayer.global.setAudioContext(_playbackContext);
      } catch (e) {
        debugPrint('[AudioClipService] setAudioContext skipped: $e');
      }
      await _player.stop();
      // 自然終了(onPlayerComplete)で解ける。外部stop()でも [stop] が解く。
      final wait = _activeWait = Completer<void>();
      sub = _player.onPlayerComplete.listen((_) {
        if (!wait.isCompleted) wait.complete();
      });
      await _player.play(AssetSource('audio/$locale/$key.m4a'), volume: 1.0);
      // 再生開始後に速度指定（開始前だと無視される端末がある）。
      // 前クリップが1.5倍のまま等の持ち越しを避けるため、1.0でも必ず設定する。
      await _player.setPlaybackRate(rate);
      await wait.future;
      return true;
    } catch (e) {
      debugPrint('[AudioClipService] playAndWait failed: $e');
      return true; // クリップは存在した＝端末TTSへは落とさない
    } finally {
      await sub?.cancel();
    }
  }

  /// 再生中のクリップの速度を**即時**変更する（耳学の速度スライダー用）。
  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player.setPlaybackRate(rate);
    } catch (_) {}
  }

  Future<void> stop() async {
    // 待機中の playAndWait を解いて次へ進めるようにする
    final wait = _activeWait;
    if (wait != null && !wait.isCompleted) wait.complete();
    try {
      await _player.stop();
    } catch (_) {}
  }
}
