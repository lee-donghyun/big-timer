//
//  Big_Timer_WidgetBundle.swift
//  Big Timer Widget
//
//  Created by Donghyun Lee on 1/17/26.
//

import WidgetKit
import SwiftUI

@main
struct Big_Timer_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Big_Timer_Widget()
        Big_Timer_WidgetControl()
        Big_Timer_WidgetLiveActivity()
    }
}
