//
//  WorkoutSession.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import Foundation
import Combine

struct WorkoutSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: Int // seconds
    let routines: [String]
    let atePowder: Bool
    
    init(id: UUID = UUID(), date: Date = Date(), duration: Int, routines: [String], atePowder: Bool = false) {
        self.id = id
        self.date = date
        self.duration = duration
        self.routines = routines
        self.atePowder = atePowder
    }
}

class WorkoutSessionManager: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    
    private let sessionsKey = "workoutSessions"
    
    init() {
        loadSessions()
    }
    
    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        saveSessions()
    }
    
    func updateSession(_ session: WorkoutSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }
    
    func togglePowder(for session: WorkoutSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let updatedSession = WorkoutSession(
                id: session.id,
                date: session.date,
                duration: session.duration,
                routines: session.routines,
                atePowder: !session.atePowder
            )
            sessions[index] = updatedSession
            saveSessions()
        }
    }
    
    func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    func updateSessionDetails(id: UUID, duration: Int, routines: [String]) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            let updatedSession = WorkoutSession(
                id: sessions[index].id,
                date: sessions[index].date,
                duration: duration,
                routines: routines,
                atePowder: sessions[index].atePowder
            )
            sessions[index] = updatedSession
            saveSessions()
        }
    }
    
    func getSessions(for date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
    
    func getDatesWithSessions() -> Set<Date> {
        let calendar = Calendar.current
        return Set(sessions.map { calendar.startOfDay(for: $0.date) })
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            sessions = decoded
        }
    }
}
