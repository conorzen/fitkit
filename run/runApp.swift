//
//  runApp.swift
//  run
//
//  Created by Conor Reid Admin on 08/02/2025.
//

import SwiftUI

@main
struct runApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
