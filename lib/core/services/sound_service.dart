import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 効果音（SFX）とハプティクス（振動）を一元管理する再生フック。
///
/// 事前生成した短い効果音（`assets/audio/sfx/*.m4a`・オフライン同梱・非通信）を
/// audioplayers で再生する。正解・コンボ・FEVER・レベルアップなど、学習が
/// うまくいっている感覚を後押しする音を鳴らす。ハプティクスも併用。
/// SKILL(animation-effects) の「必ず再生フックを呼ぶ」を満たす窓口。
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'sfx')
    ..setReleaseMode(ReleaseMode.stop);
  bool _muted = false;
  set muted(bool v) => _muted = v;

  /// SFX 用のオーディオコンテキスト。
  /// **iOS は `ambient`＝マナーモード（サイレントスイッチON）では鳴らさない**。
  /// 発音音声（AudioClipService）は `playback` で消音でも鳴るが、あちらは
  /// 再生直前にグローバルコンテキストを設定し直すので互いに干渉しない。
  static final AudioContext _sfxContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  /// SFX を再生（[rate] で再生速度＝ピッチを変える。コンボの上昇感に使う）。
  Future<void> _sfx(String name, {double volume = 1.0, double rate = 1.0}) async {
    if (_muted) return;
    try {
      // 再生の直前にマナーモード尊重（ambient）のセッションへ設定し直す。
      // 直前に発音音声が playback にしていても、ここで ambient に戻す。
      await AudioPlayer.global.setAudioContext(_sfxContext);
      await _player.stop();
      await _player.setPlaybackRate(rate);
      await _player.play(AssetSource('audio/sfx/$name.m4a'), volume: volume);
    } catch (e) {
      debugPrint('[SoundService] sfx($name) failed: $e');
    }
  }

  /// ボタン/カードのタップ（音は出さず触覚のみ＝毎タップでうるさくしない）。
  void tap() {
    HapticFeedback.selectionClick();
  }

  /// 1回で正解。軽快なフィードバック。
  void correct() {
    HapticFeedback.lightImpact();
    _sfx('correct');
  }

  /// コンボ更新（数が上がるほど手応え＆ピッチ上昇で「積み上がる」感覚を出す）。
  void combo(int count) {
    HapticFeedback.mediumImpact();
    // コンボが伸びるほど再生速度＝ピッチを上げる（上限まで）
    final rate = (1.0 + (count - 2) * 0.06).clamp(1.0, 1.6);
    _sfx('combo', rate: rate);
  }

  /// FEVER突入。きらめくアルペジオ。
  void fever() {
    HapticFeedback.heavyImpact();
    _sfx('fever', volume: 1.0);
  }

  /// レベルアップ。華やかなファンファーレ。
  void levelUp() {
    HapticFeedback.heavyImpact();
    _sfx('levelup');
  }

  /// セッション完了のセレブレーション（ファンファーレを流用）。
  void celebrate() {
    HapticFeedback.mediumImpact();
    _sfx('levelup', volume: 0.9);
  }

  /// 不正解（＝復習へ）。**沈まない柔らかい中立音**＋軽い触覚。
  /// 下降音やブザーは使わず、負の感情を出さない設計。
  void retry() {
    HapticFeedback.selectionClick();
    _sfx('soft', volume: 0.7);
  }
}
