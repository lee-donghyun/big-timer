//
//  Big_TimerApp.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import SwiftUI
import ActivityKit

@main
struct Big_TimerApp: App {
    @StateObject private var sessionManager = WorkoutSessionManager()
    
    var body: some Scene {
        WindowGroup {
            MainView(sessionManager: sessionManager)
        }
    }
}
