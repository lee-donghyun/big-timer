//
//  ContentView.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    @ObservedObject var sessionManager: WorkoutSessionManager
    @State private var seconds: Int = 0
    @State private var timer: Timer?
    @State private var isRunning: Bool = false
    @State private var activity: Activity<TimerActivityAttributes>?
    @State private var startTime: Date?
    @State private var selectedRoutines: Set<String> = []
    @State private var lastUpdatedSecond: Int = -1
    
    let routineOptions = ["Back", "Legs", "Chest", "Shoulder", "Biceps", "Triceps"]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TIMER")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    HStack(spacing: 4) {
                        let hours = seconds / 3600
                        let minutes = (seconds % 3600) / 60
                        let secs = seconds % 60
                        
                        DialDigit(value: hours / 10)
                        DialDigit(value: hours % 10)
                        Text(":")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                        
                        DialDigit(value: minutes / 10)
                        DialDigit(value: minutes % 10)
                        Text(":")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                        
                        DialDigit(value: secs / 10)
                        DialDigit(value: secs % 10)
                    }
                    
                    // Fixed space for tags to prevent layout shift
                    FlowLayout(spacing: 6) {
                        if !selectedRoutines.isEmpty {
                            ForEach(Array(selectedRoutines).sorted(), id: \.self) { routine in
                                Text(routine)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 30, alignment: .leading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT ROUTINE")
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
                                
                                // Save to UserDefaults
                                UserDefaults.standard.set(Array(selectedRoutines), forKey: "selectedRoutines")
                                
                                if isRunning {
                                    updateLiveActivity()
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
                
                if !isRunning && seconds == 0 {
                    Button(action: {
                        startTimer()
                    }) {
                        Text("Start")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 24)
                } else if isRunning {
                    Button(action: {
                        stopTimer()
                    }) {
                        Text("Stop")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 24)
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            startTimer()
                        }) {
                            Text("Continue")
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button(action: {
                            resetTimer()
                        }) {
                            Text("Reset")
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button(action: {
                            submitTimer()
                        }) {
                            Text("Submit")
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            // Restore timer if it was running
            if let savedStartTime = UserDefaults.standard.object(forKey: "timerStartTime") as? Date {
                startTime = savedStartTime
                isRunning = true
                startTimer()
            }
            
            // Restore selected routines
            if let savedRoutines = UserDefaults.standard.array(forKey: "selectedRoutines") as? [String] {
                selectedRoutines = Set(savedRoutines)
            }
        }
        .onDisappear {
            // Don't stop the timer, just save the state
            // Timer should continue running in background
            
            // Save selected routines
            UserDefaults.standard.set(Array(selectedRoutines), forKey: "selectedRoutines")
        }
    }
    
    private func startTimer() {
        if startTime == nil {
            // First time start - set start time to now minus already elapsed seconds
            startTime = Date().addingTimeInterval(-Double(seconds))
            UserDefaults.standard.set(startTime, forKey: "timerStartTime")
        }
        
        isRunning = true
        startLiveActivity()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let start = startTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                seconds = elapsed
                
                // Only update Live Activity when second changes
                if elapsed != lastUpdatedSecond {
                    lastUpdatedSecond = elapsed
                    updateLiveActivity()
                }
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        startTime = nil  // Clear startTime so it can be recalculated on continue
        UserDefaults.standard.removeObject(forKey: "timerStartTime")
        endLiveActivity()
    }
    
    private func resetTimer() {
        stopTimer()
        startTime = nil
        UserDefaults.standard.removeObject(forKey: "timerStartTime")
        seconds = 0
        lastUpdatedSecond = -1
        selectedRoutines.removeAll()
        UserDefaults.standard.removeObject(forKey: "selectedRoutines")
    }
    
    private func submitTimer() {
        // Record the workout session
        let session = WorkoutSession(
            duration: seconds,
            routines: Array(selectedRoutines).sorted()
        )
        sessionManager.addSession(session)
        
        // Reset after submission
        resetTimer()
        selectedRoutines.removeAll()
        
        // Clear saved routines
        UserDefaults.standard.removeObject(forKey: "selectedRoutines")
        
        print("Submitted workout session")
    }
    
    private func startLiveActivity() {
        let attributes = TimerActivityAttributes()
        let contentState = TimerActivityAttributes.ContentState(
            seconds: seconds,
            routines: Array(selectedRoutines).sorted()
        )
        
        do {
            activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = activity else { return }
        
        Task {
            let contentState = TimerActivityAttributes.ContentState(
                seconds: seconds,
                routines: Array(selectedRoutines).sorted()
            )
            
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: nil
                )
            )
        }
    }
    
    private func endLiveActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
}

struct DialDigit: View {
    let value: Int
    
    var body: some View {
        Text("\(value)")
            .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
            .foregroundColor(.white)
            .frame(minWidth: 48)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView(sessionManager: WorkoutSessionManager())
}
