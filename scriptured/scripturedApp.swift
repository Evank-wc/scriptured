//
//  scripturedApp.swift
//  scriptured
//
//  Created by Wen Cheng on 31/5/2026.
//

import SwiftData
import SwiftUI

@main
struct scripturedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            ReadingSession.self,
            UserStats.self,
            RewardTransaction.self,
            StreakState.self,
            InventoryItem.self,
            ActiveBoost.self,
            UserReadingPlan.self,
            UserReadingPlanDayProgress.self
        ])
    }
}
