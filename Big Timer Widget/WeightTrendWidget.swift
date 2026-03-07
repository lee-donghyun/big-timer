//
//  WeightTrendWidget.swift
//  Big Timer Widget
//
//  Created by Donghyun Lee on 3/4/26.
//

import WidgetKit
import SwiftUI
import Charts

// MARK: - Data

struct WidgetWeightEntry: Codable {
    let id: UUID
    let date: Date
    let weight: Double
}

// MARK: - Provider

struct WeightTrendProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeightTrendTimelineEntry {
        WeightTrendTimelineEntry(date: Date(), weights: Self.placeholderWeights())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeightTrendTimelineEntry) -> Void) {
        let entry = WeightTrendTimelineEntry(date: Date(), weights: loadWeights())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeightTrendTimelineEntry>) -> Void) {
        let entry = WeightTrendTimelineEntry(date: Date(), weights: loadWeights())
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
    
    private func loadWeights() -> [WidgetWeightEntry] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "weightEntries"),
              let entries = try? JSONDecoder().decode([WidgetWeightEntry].self, from: data) else {
            return []
        }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: Date()))!
        return entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }
    
    static func placeholderWeights() -> [WidgetWeightEntry] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            return WidgetWeightEntry(id: UUID(), date: date, weight: 70.0 + Double.random(in: -1...1))
        }
    }
}

// MARK: - Entry

struct WeightTrendTimelineEntry: TimelineEntry {
    let date: Date
    let weights: [WidgetWeightEntry]
}

// MARK: - Views

struct WeightTrendWidgetEntryView: View {
    var entry: WeightTrendTimelineEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }
    
    // MARK: - Small Widget
    
    var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("WEIGHT")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            if let latest = entry.weights.last {
                Text(String(format: "%.1f", latest.weight))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                
                Text("kg")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                if entry.weights.count >= 2 {
                    let prev = entry.weights[entry.weights.count - 2]
                    let diff = latest.weight - prev.weight
                    HStack(spacing: 2) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(String(format: "%+.1f", diff))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(diff >= 0 ? .red : .green)
                }
            } else {
                Text("--")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                Text("No data")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if entry.weights.count >= 2 {
                Chart(entry.weights, id: \.id) { w in
                    LineMark(
                        x: .value("Date", w.date, unit: .day),
                        y: .value("Weight", w.weight)
                    )
                    .foregroundStyle(.primary)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 30)
            }
        }
    }
    
    // MARK: - Medium Widget
    
    var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("WEIGHT TREND")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let latest = entry.weights.last {
                    Text(String(format: "%.1f kg", latest.weight))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            
            if entry.weights.count >= 2,
               let minW = entry.weights.map(\.weight).min(),
               let maxW = entry.weights.map(\.weight).max() {
                let padding = max((maxW - minW) * 0.2, 0.5)
                
                Chart(entry.weights, id: \.id) { w in
                    LineMark(
                        x: .value("Date", w.date, unit: .day),
                        y: .value("Weight", w.weight)
                    )
                    .foregroundStyle(.primary)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", w.date, unit: .day),
                        y: .value("Weight", w.weight)
                    )
                    .foregroundStyle(.primary)
                    .symbolSize(12)
                }
                .chartYScale(domain: (minW - padding)...(maxW + padding))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(entry.weights.count / 5, 1))) { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.secondary)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("Not enough data to show trend")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
    }
}

// MARK: - Widget

struct WeightTrendWidget: Widget {
    let kind: String = "WeightTrendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeightTrendProvider()) { entry in
            WeightTrendWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weight Trend")
        .description("Shows your weight trend over the past 30 days.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WeightTrendWidget()
} timeline: {
    WeightTrendTimelineEntry(date: .now, weights: WeightTrendProvider.placeholderWeights())
}

#Preview(as: .systemMedium) {
    WeightTrendWidget()
} timeline: {
    WeightTrendTimelineEntry(date: .now, weights: WeightTrendProvider.placeholderWeights())
}
