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
    private let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataBatchFetch")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Unresolved error: \(error)") }
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            let api: NotesAPI = MockNotesAPI()
            let repository: NotesRepositoryProtocol = NotesRepository(api: api, container: container)
            let viewModel = NotesViewModel(repository: repository)
            ContentView(viewModel: viewModel)
        }
    }
}

