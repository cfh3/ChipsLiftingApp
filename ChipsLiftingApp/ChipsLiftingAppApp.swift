//
//  ChipsLiftingAppApp.swift
//  ChipsLiftingApp
//
//  Created by chip on 2/18/26.
//

import SwiftUI
import CoreData

@main
struct ChipsLiftingAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
