//
//  WeightEntry.swift
//  Big Timer
//
//  Created by Donghyun Lee on 3/4/26.
//

import Foundation
import Combine

struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double // kg
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}

class WeightEntryManager: ObservableObject {
    @Published var entries: [WeightEntry] = []
    
    private let entriesKey = "weightEntries"
    private let sharedDefaults = UserDefaults(suiteName: "group.lee-donghyun.Big-Timer")
    
    init() {
        loadEntries()
    }
    
    func addEntry(_ entry: WeightEntry) {
        // Replace if same day already exists
        let calendar = Calendar.current
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        saveEntries()
    }
    
    func deleteEntry(_ entry: WeightEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func latestEntry() -> WeightEntry? {
        entries.last
    }
    
    func entries(last days: Int) -> [WeightEntry] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date()))!
        return entries.filter { $0.date >= cutoff }
    }
    
    func todayEntry() -> WeightEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
            sharedDefaults?.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            entries = decoded.sorted { $0.date < $1.date }
            sharedDefaults?.set(data, forKey: entriesKey)
        }
    }
}
