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
    final lang = mode == LanguageMode.ja ? 'en-US' : 'ja-JP';
    await speakLocale(text, lang);
  }

  /// **ロケールを明示して**読み上げる（英語=en-US / 日本語=ja-JP）。
  /// カード詳細で英語・日本語それぞれの行を鳴らすときに使う。
  Future<void> speakLocale(String text, String locale) async {
    if (text.trim().isEmpty) return;

    // 事前生成した高品質音声があればそれを再生（端末TTSは鳴らさない。
    // 二重再生を防ぐため先に端末TTSを止める）。
    await _tts.stop();
    final played = await AudioClipService().playIfAvailable(text, locale);
    if (played) return;

    try {
      await _ensureInitialized();
      await _tts.stop();
      // 対象言語の音声が端末に無い場合は既定音声にフォールバックさせる
      final available = await _tts.isLanguageAvailable(locale);
      if (available == true) {
        await _tts.setLanguage(locale);
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speak failed: $e');
    }
  }

  /// 耳学（リスニング）用：指定ロケールで読み上げ、**再生完了まで待つ**。
  /// [rate] は再生速度倍率（1.0=標準）。外部から [stop] されると途中でも返る。
  Future<void> speakAndWait(String text, String locale,
      {double rate = 1.0}) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    final played =
        await AudioClipService().playAndWait(text, locale, rate: rate);
    if (played) return;

    // 端末TTSフォールバック（完了を待つ）
    try {
      await _ensureInitialized();
      await _tts.awaitSpeakCompletion(true);
      final available = await _tts.isLanguageAvailable(locale);
      if (available == true) {
        await _tts.setLanguage(locale);
      }
      // 端末TTSの速度は 0〜1 スケール。基準0.45に倍率をかけて調整。
      await _tts.setSpeechRate((0.45 * rate).clamp(0.1, 1.0));
      await _tts.speak(text);
      await _tts.setSpeechRate(0.45); // 既定に戻す
    } catch (e) {
      debugPrint('[TtsService] speakAndWait failed: $e');
    }
  }

  /// 再生中の同梱クリップの速度を即時変更する（耳学の速度スライダー用）。
  /// 端末TTSは発話中の速度変更に非対応（次の発話から反映）。
  Future<void> setPlaybackRate(double rate) async {
    await AudioClipService().setPlaybackRate(rate);
  }

  /// 現在鳴っているクリップ内をシーク（音源単位のシークバー用）。
  Future<void> seek(Duration position) async {
    await AudioClipService().seek(position);
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
