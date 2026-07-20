//
//  StackChanDriverApp.swift
//  StackChanDriver
//
//  Created by Yuichi Nakamura on 2026/07/20.
//

import SwiftUI

@main
struct StackChanDriverApp: App {
    @StateObject private var bleManager: StackChanBLEManager
    @StateObject private var monitoringManager: DrivingMonitoringManager

    init() {
        let bleManager = StackChanBLEManager()
        _bleManager = StateObject(wrappedValue: bleManager)
        _monitoringManager = StateObject(
            wrappedValue: DrivingMonitoringManager(bleManager: bleManager)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                bleManager: bleManager,
                monitoringManager: monitoringManager
            )
        }
    }
}
