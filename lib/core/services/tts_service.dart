import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ship_it_english/core/i18n/app_strings.dart';
import 'package:ship_it_english/core/services/audio_clip_service.dart';

/// カードのフレーズ・例文を読み上げる。
/// - 事前生成した高品質音声（Amazon Polly Neural）が同梱されていればそれを再生
/// - 無ければ端末内蔵の音声合成（flutter_tts）にフォールバック
/// いずれもネットワークは使用しない（オフライン・プライバシー申告に影響なし）。
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// iOS のオーディオセッション設定。
  /// これを行わないと、端末の**サイレントスイッチがONのとき音が鳴らない**
  /// （デフォルトの ambient カテゴリはサイレントスイッチに従うため）。
  /// playback + defaultToSpeaker を指定して、消音状態でも読み上げが聞こえるようにする。
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// 学習対象言語のテキストを読み上げる。
  /// - jaモード（日本人向け）: 英語フレーズを読む → en-US
  /// - enモード（英語話者向け）: 日本語フレーズを読む → ja-JP
  Future<void> speakTarget(String text, LanguageMode mode) async {
    if (text.trim().isEmpty) return;

    // jaモードの読み上げ対象は英語。事前生成した高品質音声があればそれを再生し、
    // 端末TTSは鳴らさない（二重再生を防ぐため先に端末TTSを止める）。
    if (mode == LanguageMode.ja) {
      await _tts.stop();
      final played = await AudioClipService().playIfAvailable(text);
      if (played) return;
    }

    try {
      await _ensureInitialized();

      final lang = mode == LanguageMode.ja ? 'en-US' : 'ja-JP';

      await _tts.stop();
      // 対象言語の音声が端末に無い場合は既定音声にフォールバックさせる
      final available = await _tts.isLanguageAvailable(lang);
      if (available == true) {
        await _tts.setLanguage(lang);
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await AudioClipService().stop();
      await _tts.stop();
    } catch (e) {
      debugPrint('[TtsService] stop failed: $e');
    }
  }
}
