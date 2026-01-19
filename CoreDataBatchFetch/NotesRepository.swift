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

extension NotesRepository: NotesRepositoryProtocol {
    func create(title: String, content: String) throws {
          let context = container.viewContext
          let note = Note(context: context)
          note.remoteID = UUID().uuidString // or another ID scheme
          note.title = title
          note.content = content
          note.createdAt = Date()
          try context.save()
      }
    
    
    func update(id: String, title: String, content: String) throws {
          let context = container.viewContext
          let req: NSFetchRequest<Note> = Note.fetchRequest()
          req.fetchLimit = 1
          req.predicate = NSPredicate(format: "remoteID == %@", id)
          guard let note = try context.fetch(req).first else { return }
          note.title = title
          note.content = content
          try context.save()
      }
  
    
    func delete(ids: [String]) throws {
          let context = container.viewContext
          let req: NSFetchRequest<Note> = Note.fetchRequest()
          req.predicate = NSPredicate(format: "remoteID IN %@", ids)
          let results = try context.fetch(req)
          results.forEach { context.delete($0) }
          try context.save()
      }
    
    func fetchAll() throws -> [NoteDTO] {
        let context = container.viewContext
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)]
        let notes = try context.fetch(request)
        return notes.compactMap { note in
            guard let id = note.remoteID,
                  let title = note.title,
                  let content = note.content,
                  let createdAt = note.createdAt else { return nil }
            return NoteDTO(id: id, title: title, content: content, createdAt: createdAt)
        }
    }

    func fetch(byID id: String) throws -> NoteDTO? {
        let context = container.viewContext
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "remoteID == %@", id)
        guard let note = try context.fetch(request).first,
              let title = note.title,
              let content = note.content,
              let createdAt = note.createdAt else {
            return nil
        }
        return NoteDTO(id: id, title: title, content: content, createdAt: createdAt)
    }
}
