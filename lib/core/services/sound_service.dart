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
  bool _ctxReady = false;
  set muted(bool v) => _muted = v;

  Future<void> _ensureContext() async {
    if (_ctxReady) return;
    _ctxReady = true;
    try {
      // サイレントスイッチでも鳴らす／他の音（発音）と混ぜる
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
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[SoundService] audio context failed: $e');
    }
  }

  /// SFX を再生（[rate] で再生速度＝ピッチを変える。コンボの上昇感に使う）。
  Future<void> _sfx(String name, {double volume = 1.0, double rate = 1.0}) async {
    if (_muted) return;
    await _ensureContext();
    try {
      await _player.stop();
      await _player.setPlaybackRate(rate);
      await _player.play(AssetSource('audio/sfx/$name.m4a'), volume: volume);
    } catch (e) {
      debugPrint('[SoundService] sfx($name) failed: $e');
      // 失敗時は端末のシステム音でフォールバック
      SystemSound.play(SystemSoundType.click);
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

  /// 不正解（＝復習へ）。暗い音は出さず、軽い触覚だけ（負の感情を軽減）。
  void retry() {
    HapticFeedback.selectionClick();
  }
}
