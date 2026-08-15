import WidgetKit
import SwiftUI
import UIKit

// アプリ本体（home_widget 経由）が App Group の UserDefaults に書いた
// 学習状態を読み出して表示するだけのウィジェット。通信は一切しない。
private let appGroupId = "group.jp.co.shipitenglish.app"

struct StudyEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let today: Int
    let goal: Int
    let score: Double
}

struct StudyProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyEntry {
        StudyEntry(date: Date(), streak: 7, today: 12, goal: 20, score: 23.4)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyEntry>) -> Void) {
        // アプリ側が更新を push する（HomeWidget.updateWidget）。
        // 保険として30分ごとに再読込する。
        let timeline = Timeline(
            entries: [load()],
            policy: .after(Date().addingTimeInterval(30 * 60))
        )
        completion(timeline)
    }

    private func load() -> StudyEntry {
        let d = UserDefaults(suiteName: appGroupId)
        return StudyEntry(
            date: Date(),
            streak: d?.integer(forKey: "hw_streak") ?? 0,
            today: d?.integer(forKey: "hw_today") ?? 0,
            goal: max(1, d?.integer(forKey: "hw_goal") ?? 20),
            score: d?.double(forKey: "hw_score") ?? 0
        )
    }
}

struct ShipItWidgetEntryView: View {
    var entry: StudyEntry

    private var indigo: Color { Color(red: 0.357, green: 0.329, blue: 0.902) } // #5B54E6

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ストリーク（主役）
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("🔥")
                    .font(.system(size: 22))
                Text("\(entry.streak)")
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(indigo)
                Text("d")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            // 今日の学習（達成でチェック）
            HStack(spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(entry.today)/\(entry.goal)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(entry.today >= entry.goal ? .green : .primary)
                if entry.today >= entry.goal {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
            ProgressView(value: min(1.0, Double(entry.today) / Double(entry.goal)))
                .tint(indigo)
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
            // カバレッジ（実力スコア）
            HStack(spacing: 4) {
                Text("COVERAGE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", entry.score))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(indigo)
            }
        }
        .widgetBackground()
    }
}

extension View {
    // iOS 17+ は containerBackground が必須。iOS 16 は従来どおり padding のみ。
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        } else {
            self.padding(12)
        }
    }
}

struct ShipItWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ShipItWidget", provider: StudyProvider()) { entry in
            ShipItWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ShipIt English")
        .description("Streak & today's progress")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct ShipItWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShipItWidget()
    }
}
