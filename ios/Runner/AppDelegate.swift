import Flutter
import UIKit
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nowPlayingChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 耳学（リスニング）のロック画面/コントロールセンター表示・操作。
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "shipit/now_playing",
        binaryMessenger: controller.binaryMessenger)
      nowPlayingChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "update":
          if let args = call.arguments as? [String: Any] {
            self?.updateNowPlaying(args)
          }
          result(nil)
        case "clear":
          self?.clearNowPlaying()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      setupRemoteCommands(channel)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// ロック画面/コントロールセンターの再生情報を更新する。
  private func updateNowPlaying(_ args: [String: Any]) {
    let title = args["title"] as? String ?? ""
    let artist = args["artist"] as? String ?? ""
    let isPlaying = args["isPlaying"] as? Bool ?? false

    // 秒数メタデータは持たないので進捗バーは出さない（再生/停止・曲送りのみ）
    let info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: artist,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info

    if #available(iOS 13.0, *) {
      MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
  }

  private func clearNowPlaying() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    if #available(iOS 13.0, *) {
      MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
  }

  /// リモートコマンド（ロック画面/イヤホン等）→ Dart 側へ通知。
  private func setupRemoteCommands(_ channel: FlutterMethodChannel) {
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.isEnabled = true
    center.playCommand.addTarget { _ in
      channel.invokeMethod("play", arguments: nil)
      return .success
    }
    center.pauseCommand.isEnabled = true
    center.pauseCommand.addTarget { _ in
      channel.invokeMethod("pause", arguments: nil)
      return .success
    }
    center.togglePlayPauseCommand.isEnabled = true
    center.togglePlayPauseCommand.addTarget { _ in
      channel.invokeMethod("togglePlay", arguments: nil)
      return .success
    }
    center.nextTrackCommand.isEnabled = true
    center.nextTrackCommand.addTarget { _ in
      channel.invokeMethod("next", arguments: nil)
      return .success
    }
    center.previousTrackCommand.isEnabled = true
    center.previousTrackCommand.addTarget { _ in
      channel.invokeMethod("previous", arguments: nil)
      return .success
    }
  }
}
