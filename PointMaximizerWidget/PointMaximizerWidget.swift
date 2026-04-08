import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PointMaximizerEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider

struct PointMaximizerProvider: TimelineProvider {

    func placeholder(in context: Context) -> PointMaximizerEntry {
        PointMaximizerEntry(date: .now, widgetData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PointMaximizerEntry) -> Void) {
        let data = context.isPreview ? .placeholder : SharedDataManager.shared.loadWidgetData()
        completion(PointMaximizerEntry(date: .now, widgetData: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PointMaximizerEntry>) -> Void) {
        let data  = SharedDataManager.shared.loadWidgetData()
        let entry = PointMaximizerEntry(date: .now, widgetData: data)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Widget Definition

struct PointMaximizerWidget: Widget {
    let kind = "PointMaximizerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PointMaximizerProvider()) { entry in
            PointMaximizerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Best Card")
        .description("Shows your highest-earning card for your current location.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium,
        ])
    }
}

// MARK: - Widget Bundle

@main
struct PointMaximizerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PointMaximizerWidget()
    }
}
