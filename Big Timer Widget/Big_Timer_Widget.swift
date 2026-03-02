//
//  Big_Timer_Widget.swift
//  Big Timer Widget
//
//  Created by Donghyun Lee on 1/17/26.
//

import WidgetKit
import SwiftUI

// MARK: - Data Types

struct DayRecord: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: [WidgetWorkoutSession]
    
    var hasWorkout: Bool { !sessions.isEmpty }
    var totalDuration: Int { sessions.reduce(0) { $0 + $1.duration } }
    var allRoutines: [String] { Array(Set(sessions.flatMap { $0.routines })).sorted() }
}

struct WidgetWorkoutSession: Codable {
    let id: UUID
    let date: Date
    let duration: Int
    let routines: [String]
    let atePowder: Bool
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(date: Date(), days: Self.placeholderDays())
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutHistoryEntry) -> Void) {
        let entry = WorkoutHistoryEntry(date: Date(), days: loadLast7Days())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutHistoryEntry>) -> Void) {
        let entry = WorkoutHistoryEntry(date: Date(), days: loadLast7Days())
        // Refresh at next midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
    
    private func loadLast7Days() -> [DayRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = loadSessions()
        
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let daySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
            return DayRecord(date: date, sessions: daySessions)
        }
    }
    
    private func loadSessions() -> [WidgetWorkoutSession] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "workoutSessions"),
              let sessions = try? JSONDecoder().decode([WidgetWorkoutSession].self, from: data) else {
            return []
        }
        return sessions
    }
    
    static func placeholderDays() -> [DayRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayRecord(date: date, sessions: [])
        }
    }
}

// MARK: - Entry

struct WorkoutHistoryEntry: TimelineEntry {
    let date: Date
    let days: [DayRecord]
}

// MARK: - Views

struct Big_Timer_WidgetEntryView: View {
    var entry: WorkoutHistoryEntry
    @Environment(\.widgetFamily) var family
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    
    var workoutCount: Int {
        entry.days.filter { $0.hasWorkout }.count
    }

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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("7 DAYS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(workoutCount)/7")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                ForEach(entry.days) { day in
                    VStack(spacing: 4) {
                        Text(dayFormatter.string(from: day.date).prefix(1))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            Circle()
                                .fill(day.hasWorkout ? Color.primary : Color.primary.opacity(0.1))
                                .frame(width: 28, height: 28)
                            
                            Text(dateFormatter.string(from: day.date))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(day.hasWorkout ? Color(UIColor.systemBackground) : .primary.opacity(0.3))
                        }
                        
                        if day.hasWorkout {
                            Text(formatShortDuration(day.totalDuration))
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("")
                                .font(.system(size: 7, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Medium Widget
    
    var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LAST 7 DAYS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                ForEach(entry.days) { day in
                    VStack(spacing: 4) {
                        Text(dayFormatter.string(from: day.date).prefix(1))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(day.hasWorkout ? Color.primary : Color.primary.opacity(0.08))
                                .frame(height: 40)
                            
                            VStack(spacing: 2) {
                                Text(dateFormatter.string(from: day.date))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(day.hasWorkout ? Color(UIColor.systemBackground) : .primary.opacity(0.3))
                                
                                if day.hasWorkout {
                                    Text(formatShortDuration(day.totalDuration))
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundStyle(day.hasWorkout ? Color(UIColor.systemBackground).opacity(0.7) : .clear)
                                }
                            }
                        }
                        
                        if day.hasWorkout && !day.allRoutines.isEmpty {
                            Text(day.allRoutines.map { String($0.prefix(1)) }.joined())
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("")
                                .font(.system(size: 8, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatShortDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 {
            return "\(h)h\(m)m"
        }
        return "\(m)m"
    }
}

// MARK: - Widget

struct Big_Timer_Widget: Widget {
    let kind: String = "Big_Timer_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Big_Timer_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Workout History")
        .description("Shows your exercise records for the past 7 days.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Big_Timer_Widget()
} timeline: {
    WorkoutHistoryEntry(date: .now, days: Provider.placeholderDays())
}

#Preview(as: .systemMedium) {
    Big_Timer_Widget()
} timeline: {
    WorkoutHistoryEntry(date: .now, days: Provider.placeholderDays())
}
