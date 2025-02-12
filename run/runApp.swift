//
//  runApp.swift
//  run
//
//  Created by Conor Reid Admin on 08/02/2025.
//

import SwiftUI
import FacebookCore

@main
struct RunApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthManager()
    @StateObject private var trainingPlanService = TrainingPlanService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
                .environmentObject(trainingPlanService)
        }
    }
}
