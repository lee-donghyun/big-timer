//
//  NotificationManager.swift
//  Big Timer
//
//  Created by Donghyun Lee on 2/20/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifierPrefix = "gymReminder"
    private let maxNotificationsPerWindow = 3
    
    private let motivationalMessages = [
        "Time to hit the gym! 💪",
        "Your muscles are waiting for you!",
        "No excuses today. Let's go! 🏋️",
        "Future you will thank present you. Gym time!",
        "The only bad workout is the one that didn't happen.",
        "Get up and get moving! 🔥",
        "Your body can handle almost anything. It's your mind you have to convince.",
        "Gym o'clock! Let's crush it! 💪",
        "Consistency beats perfection. Go now!",
        "You're one workout away from a better mood.",
        "Don't think about it. Just go! 🏃",
        "The gym misses you. Time to visit!",
    ]
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleGymNotifications(hasWorkedOutToday: @escaping () -> Bool) {
        // Remove existing gym notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: getPendingNotificationIdentifiers())
        
        // Don't schedule if already worked out today
        if hasWorkedOutToday() {
            print("Already worked out today, skipping notifications")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        // Get the time windows for today
        guard let timeWindow = getTimeWindow(for: weekday) else {
            print("No gym window for today (weekday: \(weekday))")
            return
        }
        
        // Schedule up to 3 notifications with random times within the window
        let notificationTimes = generateRandomTimes(
            within: timeWindow,
            count: maxNotificationsPerWindow,
            date: now
        )
        
        for (index, time) in notificationTimes.enumerated() {
            scheduleNotification(at: time, identifier: "\(notificationIdentifierPrefix)_\(index)")
        }
        
        print("Scheduled \(notificationTimes.count) gym notifications for today")
    }
    
    private func getTimeWindow(for weekday: Int) -> (start: Int, end: Int)? {
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        switch weekday {
        case 2, 3, 4, 5, 6: // Monday - Friday: 8-11 PM (20:00-23:00)
            return (start: 20, end: 23)
        case 7: // Saturday: 9 AM - 12 PM (9:00-12:00)
            return (start: 9, end: 12)
        case 1: // Sunday: 2-6 PM (14:00-18:00)
            return (start: 14, end: 18)
        default:
            return nil
        }
    }
    
    private func generateRandomTimes(within window: (start: Int, end: Int), count: Int, date: Date) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var times: [Date] = []
        
        let windowDurationMinutes = (window.end - window.start) * 60
        let segmentDuration = windowDurationMinutes / count
        
        for i in 0..<count {
            // Divide window into segments and pick random time in each
            let segmentStart = window.start * 60 + i * segmentDuration
            let segmentEnd = segmentStart + segmentDuration
            
            // Add randomness: pick random minute within segment
            let randomMinute = Int.random(in: segmentStart..<segmentEnd)
            let hour = randomMinute / 60
            let minute = randomMinute % 60
            
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = minute
            components.second = 0
            
            if let notificationDate = calendar.date(from: components),
               notificationDate > now {
                times.append(notificationDate)
            }
        }
        
        return times
    }
    
    private func scheduleNotification(at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Gym Time!"
        content.body = motivationalMessages.randomElement() ?? "Time to work out!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                print("Scheduled notification '\(identifier)' for \(formatter.string(from: date))")
            }
        }
    }
    
    private func getPendingNotificationIdentifiers() -> [String] {
        return (0..<maxNotificationsPerWindow).map { "\(notificationIdentifierPrefix)_\($0)" }
    }
    
    func cancelAllGymNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: getPendingNotificationIdentifiers())
        print("Cancelled all gym notifications")
    }
}
