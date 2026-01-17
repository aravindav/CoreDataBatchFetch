//
//  NotesRepository.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//

import Foundation

import CoreData

final class NotesRepository {
    private let api: NotesAPI
    private let container: NSPersistentContainer

    init(api: NotesAPI, container: NSPersistentContainer) {
        self.api = api
        self.container = container
    }

    func sync(count: Int) async throws {
        let dtos = try await api.fetchNotes(count: count)

        let bg = container.newBackgroundContext()
        bg.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await bg.perform {
            for dto in dtos {
                // Find existing by remoteID (upsert)
                let req: NSFetchRequest<Note> = Note.fetchRequest()
                req.fetchLimit = 1
                req.predicate = NSPredicate(format: "remoteID == %@", dto.id)

                let existing = try bg.fetch(req).first
                let note = existing ?? Note(context: bg)

                note.remoteID = dto.id
                note.title = dto.title
                note.content = dto.content
                note.createdAt = dto.createdAt
            }

            if bg.hasChanges {
                try bg.save()
            }
        }
    }
}
