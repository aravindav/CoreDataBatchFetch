//
//  CoreDataBatchFetchApp.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//

import SwiftUI
import CoreData

@main
struct CoreDataBatchFetchApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
