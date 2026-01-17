//
//  MainView.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var sessionManager: WorkoutSessionManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                Group {
                    if selectedTab == 0 {
                        ContentView(sessionManager: sessionManager)
                    } else {
                        HistoryView(sessionManager: sessionManager)
                    }
                }
                
                // Custom Tab Bar
                HStack(spacing: 0) {
                    TabButton(
                        icon: "timer",
                        label: "Timer",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        icon: "calendar",
                        label: "History",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                }
                .frame(height: 60)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white),
                    alignment: .top
                )
            }
        }
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        }
    }
}

#Preview {
    MainView(sessionManager: WorkoutSessionManager())
}
