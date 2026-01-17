//
//  TimerActivityAttributes.swift
//  Big Timer
//
//  Created by Donghyun Lee on 1/17/26.
//

import ActivityKit
import SwiftUI

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var seconds: Int
        var routines: [String]
    }
}
