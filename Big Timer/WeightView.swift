//
//  WeightView.swift
//  Big Timer
//
//  Created by Donghyun Lee on 3/4/26.
//

import SwiftUI
import Charts

struct WeightView: View {
    @ObservedObject var weightManager: WeightEntryManager
    @State private var weightInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("WEIGHT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                        .padding(.top, 60)
                    
                    // Input Section
                    inputSection
                    
                    // Chart Section
                    if !weightManager.entries(last: 30).isEmpty {
                        chartSection
                    }
                    
                    // Recent Entries
                    if !weightManager.entries.isEmpty {
                        recentEntriesSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            if let today = weightManager.todayEntry() {
                weightInput = String(format: "%.1f", today.weight)
            }
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S WEIGHT")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    TextField("0.0", text: $weightInput)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                    
                    Text("kg")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Button(action: saveWeight) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(weightInput.isEmpty ? .white.opacity(0.2) : .white)
                }
                .disabled(weightInput.isEmpty)
            }
            
            if let today = weightManager.todayEntry(),
               let previous = previousEntry(before: today.date) {
                let diff = today.weight - previous.weight
                HStack(spacing: 4) {
                    Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    Text(String(format: "%+.1f kg from last", diff))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(diff >= 0 ? .red.opacity(0.8) : .green.opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TREND (30 DAYS)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            let data = weightManager.entries(last: 30)
            
            if let minW = data.map(\.weight).min(),
               let maxW = data.map(\.weight).max() {
                let padding = max((maxW - minW) * 0.2, 0.5)
                
                Chart(data) { entry in
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(.white)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(20)
                }
                .chartYScale(domain: (minW - padding)...(maxW + padding))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            ForEach(weightManager.entries.suffix(10).reversed()) { entry in
                HStack {
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private func saveWeight() {
        guard let weight = Double(weightInput), weight > 0 else { return }
        let entry = WeightEntry(weight: weight)
        weightManager.addEntry(entry)
        isInputFocused = false
    }
    
    private func previousEntry(before date: Date) -> WeightEntry? {
        let calendar = Calendar.current
        return weightManager.entries
            .filter { !calendar.isDate($0.date, inSameDayAs: date) && $0.date < date }
            .last
    }
}

#Preview {
    WeightView(weightManager: WeightEntryManager())
}
