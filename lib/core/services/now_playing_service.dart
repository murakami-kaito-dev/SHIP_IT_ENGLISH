import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ロック画面／コントロールセンター（iOSの「ミュージック」欄）の再生情報表示と、
/// そこからのリモート操作（再生/停止・次/前）を仲介するサービス。
///
/// - Dart → ネイティブ：`update`（曲名・サブ・再生中フラグ）/ `clear`。
/// - ネイティブ → Dart：`play`/`pause`/`togglePlay`/`next`/`previous`。
/// ネイティブ実装は ios/Runner/AppDelegate.swift（MPNowPlayingInfoCenter /
/// MPRemoteCommandCenter）。ネットワークは使わない。
class NowPlayingService {
  NowPlayingService._();
  static final NowPlayingService instance = NowPlayingService._();

  static const _channel = MethodChannel('shipit/now_playing');
  bool _initialized = false;

  // ネイティブから来たコマンドを受けるハンドラ（耳学コントローラーが差し込む）。
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onTogglePlay;
  VoidCallback? onNext;
  VoidCallback? onPrevious;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          onPlay?.call();
          break;
        case 'pause':
          onPause?.call();
          break;
        case 'togglePlay':
          onTogglePlay?.call();
          break;
        case 'next':
          onNext?.call();
          break;
        case 'previous':
          onPrevious?.call();
          break;
      }
      return null;
    });
  }

  Future<void> update({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('update', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      debugPrint('[NowPlayingService] update failed: $e');
    }
  }

  Future<void> clear() async {
    onPlay = onPause = onTogglePlay = onNext = onPrevious = null;
    try {
      await _channel.invokeMethod('clear');
    } catch (e) {
      debugPrint('[NowPlayingService] clear failed: $e');
    }
  }
}
