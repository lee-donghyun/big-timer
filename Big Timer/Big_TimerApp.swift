//
//  Big_TimerApp.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import SwiftUI
import ActivityKit
import UserNotifications

@main
struct Big_TimerApp: App {
    @StateObject private var sessionManager = WorkoutSessionManager()
    @StateObject private var weightManager = WeightEntryManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView(sessionManager: sessionManager, weightManager: weightManager)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                NotificationManager.shared.scheduleGymNotifications {
                    self.sessionManager.hasSessionToday()
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
