import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 事前生成した発音音声（Amazon Polly Neural）をオフライン再生する。
///
/// ビルドに同梱された `assets/audio/en-US/<sha1(text)>.mp3` を、読み上げたい
/// テキストのハッシュから引いて再生する。マニフェスト（利用可能なキー一覧）は
/// 起動時に一度だけ読み込む。該当クリップが無ければ [playIfAvailable] は false を
/// 返し、呼び出し側（[TtsService]）が端末TTSにフォールバックする。
///
/// 生成側（tools/generate_tts.dart）と**同じ正規化・同じsha1**でキーを作るため、
/// 対応関係が常に一致する。
class AudioClipService {
  static final AudioClipService _instance = AudioClipService._();
  factory AudioClipService() => _instance;
  AudioClipService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'pronunciation');
  Set<String> _keys = <String>{};
  bool _loaded = false;

  static const _manifestAsset = 'assets/audio/manifest.json';
  // audioplayers の AssetSource は `assets/` を自動で前置するため、その先を渡す。
  static const _clipDir = 'audio/en-US';

  String _key(String text) =>
      sha1.convert(utf8.encode(text.trim())).toString();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    // iOS: サイレントスイッチONでも鳴らす（TtsServiceのセッション設定と揃える）
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.assistanceAccessibility,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AudioClipService] audio context failed: $e');
    }
    // マニフェスト読み込み（無ければ全て端末TTSにフォールバック）
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      final map = json.decode(raw) as Map<String, dynamic>;
      _keys = Set<String>.from((map['keys'] as List<dynamic>? ?? const [])
          .map((e) => e.toString()));
    } catch (e) {
      _keys = <String>{};
      debugPrint('[AudioClipService] manifest load failed: $e');
    }
  }

  /// 同梱クリップがあれば再生して true。無ければ何もせず false。
  Future<bool> playIfAvailable(String text) async {
    if (text.trim().isEmpty) return false;
    await _ensureLoaded();
    final key = _key(text);
    if (!_keys.contains(key)) return false;
    try {
      await _player.stop();
      await _player.play(AssetSource('$_clipDir/$key.mp3'));
      return true;
    } catch (e) {
      debugPrint('[AudioClipService] play failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
