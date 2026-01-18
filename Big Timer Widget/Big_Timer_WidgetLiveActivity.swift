//
//  Big_Timer_WidgetLiveActivity.swift
//  Big Timer Widget
//
//  Created by Donghyun Lee on 1/17/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Big_Timer_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .trailing, spacing: 8) {
                Text(context.state.startDate, style: .timer)
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                if !context.state.routines.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        ForEach(context.state.routines, id: \.self) { routine in
                            Text(routine)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.black)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .trailing, spacing: 12) {
                        Text(context.state.startDate, style: .timer)
                            .font(.system(size: 24, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        if !context.state.routines.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                ForEach(context.state.routines, id: \.self) { routine in
                                    Text(routine)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            } minimal: {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .keylineTint(Color.white)
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    func formatTimeCompact(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
