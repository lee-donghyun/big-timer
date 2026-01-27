//
//  HistoryView.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var sessionManager: WorkoutSessionManager
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showAddSheet = false
    
    let calendar = Calendar.current
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("HISTORY")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                
                // Calendar
                VStack(spacing: 12) {
                    // Month/Year header
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Days of week
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(getDaysInMonth(), id: \.self) { date in
                            if let date = date {
                                DayCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    sessions: sessionManager.getSessions(for: date)
                                )
                                .onTapGesture {
                                    selectedDate = date
                                }
                            } else {
                                Color.clear
                                    .frame(height: 60)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Session list for selected date
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedDateString)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Spacer()
                        
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    let sessions = sessionManager.getSessions(for: selectedDate)
                    
                    if sessions.isEmpty {
                        Text("No workouts")
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(sessions) { session in
                                    SessionCard(session: session, sessionManager: sessionManager)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSessionSheet(date: selectedDate, sessionManager: sessionManager, isPresented: $showAddSheet)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate).uppercased()
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let sessions: [WorkoutSession]
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var allRoutines: [String] {
        Array(Set(sessions.flatMap { $0.routines })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.white : Color.clear)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 0 : (sessions.isEmpty ? 0 : 1))
                )
                .clipShape(Circle())
            
            if !allRoutines.isEmpty {
                HStack(spacing: 2) {
                    ForEach(allRoutines.prefix(2), id: \.self) { routine in
                        Text(String(routine.prefix(1)))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(width: 12, height: 12)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

struct SessionCard: View {
    let session: WorkoutSession
    @ObservedObject var sessionManager: WorkoutSessionManager
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: session.date)
    }
    
    private var durationString: String {
        let hours = session.duration / 3600
        let minutes = (session.duration % 3600) / 60
        let secs = session.duration % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    var body: some View {
        Button(action: {
            sessionManager.togglePowder(for: session)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(timeString)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    if session.atePowder {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text(durationString)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                if !session.routines.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(session.routines, id: \.self) { routine in
                            Text(routine)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Text("Edit")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("Delete")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(session.atePowder ? Color.white.opacity(0.05) : Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditSheet) {
            EditSessionSheet(session: session, sessionManager: sessionManager, isPresented: $showEditSheet)
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                sessionManager.deleteSession(session)
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct AddSessionSheet: View {
    let date: Date
    @ObservedObject var sessionManager: WorkoutSessionManager
    @Binding var isPresented: Bool
    
    @State private var selectedTime = Date()
    @State private var durationHours = "0"
    @State private var durationMinutes = "0"
    @State private var durationSeconds = "0"
    @State private var selectedRoutines: Set<String> = []
    @State private var atePowder = false
    @FocusState private var isInputActive: Bool
    
    let routineOptions = ["Back", "Legs", "Chest", "Shoulder", "Biceps", "Triceps"]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("ADD WORKOUT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIME")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DURATION")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hours")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationHours)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minutes")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationMinutes)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seconds")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationSeconds)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("ROUTINES")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(routineOptions, id: \.self) { routine in
                            Button(action: {
                                if selectedRoutines.contains(routine) {
                                    selectedRoutines.remove(routine)
                                } else {
                                    selectedRoutines.insert(routine)
                                }
                            }) {
                                Text(routine)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(selectedRoutines.contains(routine) ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(selectedRoutines.contains(routine) ? Color.white : Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    if atePowder {
                        atePowder = false
                    } else {
                        atePowder = true
                    }
                }) {
                    HStack {
                        Image(systemName: atePowder ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text("Ate Powder")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    addSession()
                }) {
                    Text("Add Workout")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private func addSession() {
        let hours = Int(durationHours) ?? 0
        let minutes = Int(durationMinutes) ?? 0
        let seconds = Int(durationSeconds) ?? 0
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        
        guard totalSeconds > 0 else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        if let finalDate = calendar.date(from: combinedComponents) {
            let newSession = WorkoutSession(
                date: finalDate,
                duration: totalSeconds,
                routines: Array(selectedRoutines).sorted(),
                atePowder: atePowder
            )
            sessionManager.addSession(newSession)
            isPresented = false
        }
    }
}

struct EditSessionSheet: View {
    let session: WorkoutSession
    @ObservedObject var sessionManager: WorkoutSessionManager
    @Binding var isPresented: Bool
    
    @State private var durationHours: String
    @State private var durationMinutes: String
    @State private var durationSeconds: String
    @State private var selectedRoutines: Set<String>
    @FocusState private var isInputActive: Bool
    
    let routineOptions = ["Back", "Legs", "Chest", "Shoulder", "Biceps", "Triceps"]
    
    init(session: WorkoutSession, sessionManager: WorkoutSessionManager, isPresented: Binding<Bool>) {
        self.session = session
        self.sessionManager = sessionManager
        self._isPresented = isPresented
        
        let hours = session.duration / 3600
        let minutes = (session.duration % 3600) / 60
        let seconds = session.duration % 60
        self._durationHours = State(initialValue: "\(hours)")
        self._durationMinutes = State(initialValue: "\(minutes)")
        self._durationSeconds = State(initialValue: "\(seconds)")
        self._selectedRoutines = State(initialValue: Set(session.routines))
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("EDIT WORKOUT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DURATION")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hours")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationHours)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minutes")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationMinutes)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seconds")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("", text: $durationSeconds)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .focused($isInputActive)
                                .padding(12)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("ROUTINES")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(routineOptions, id: \.self) { routine in
                            Button(action: {
                                if selectedRoutines.contains(routine) {
                                    selectedRoutines.remove(routine)
                                } else {
                                    selectedRoutines.insert(routine)
                                }
                            }) {
                                Text(routine)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(selectedRoutines.contains(routine) ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(selectedRoutines.contains(routine) ? Color.white : Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    saveChanges()
                }) {
                    Text("Save")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private func saveChanges() {
        let hours = Int(durationHours) ?? 0
        let minutes = Int(durationMinutes) ?? 0
        let seconds = Int(durationSeconds) ?? 0
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        
        sessionManager.updateSessionDetails(
            id: session.id,
            duration: totalSeconds,
            routines: Array(selectedRoutines).sorted()
        )
        
        isPresented = false
    }
}

#Preview {
    HistoryView(sessionManager: WorkoutSessionManager())
}
