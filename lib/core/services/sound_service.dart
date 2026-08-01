import 'package:flutter/services.dart';

/// 効果音（SFX）とハプティクス（振動）を一元管理する再生フック。
///
/// SKILL(animation-effects) の「タップ/正解/レベルアップ時に必ず再生フックを
/// 呼ぶ」を満たすための窓口。現状は**オフライン前提・音声アセット無し**のため、
/// 端末内蔵のシステム音（[SystemSound]）とハプティクスのみを鳴らす。
///
/// 本格的なSFXを入れる場合は、この各メソッド内の `_sfx(...)` を audioplayers 等の
/// 実再生に差し替えるだけでよい（アプリのネットワーク非通信・データ収集なしの
/// 方針に合わせ、必ずローカルの mp3/wav アセットを同梱すること）。
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _muted = false;
  set muted(bool v) => _muted = v;

  // 差し替えポイント: ここを実SFX再生に置き換える。
  void _sfx() {
    if (_muted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// ボタン/カードのタップ。
  void tap() {
    HapticFeedback.selectionClick();
  }

  /// 1回で正解。軽快なフィードバック。
  void correct() {
    HapticFeedback.lightImpact();
    _sfx();
  }

  /// コンボ更新（数が上がるほど強めの手応え）。
  void combo(int count) {
    if (count >= 5) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _sfx();
  }

  /// FEVER突入。
  void fever() {
    HapticFeedback.heavyImpact();
    _sfx();
  }

  /// レベルアップ。
  void levelUp() {
    HapticFeedback.heavyImpact();
    _sfx();
  }

  /// セッション完了のセレブレーション。
  void celebrate() {
    HapticFeedback.mediumImpact();
    _sfx();
  }

  /// 不正解（＝復習へ）。暗い音は出さず、軽い合図だけ（負の感情を軽減）。
  void retry() {
    HapticFeedback.selectionClick();
  }
}
