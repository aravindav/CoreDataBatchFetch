//
//  ContentViewModel.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 17/01/26.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class NotesViewModel: ObservableObject {
    @Published private(set) var notes: [NoteDTO] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: NotesRepositoryProtocol

    init(repository: NotesRepositoryProtocol) {
        self.repository = repository
    }

    func load() {
        do {
            notes = try repository.fetchAll()
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
        }
    }

    func sync(count: Int) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await repository.sync(count: count)
                load()
            } catch {
                errorMessage = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    func addNote(title: String, content: String) {
          do {
              try repository.create(title: title, content: content)
              notes = try repository.fetchAll()
          } catch {
              /* set errorMessage */
              print("addNote error ")
          }
      }

      func saveEdit(id: String, title: String, content: String) {
          do {
              try repository.update(id: id, title: title, content: content)
              notes = try repository.fetchAll()
          } catch { /* set errorMessage */
              print("saveEdit error ")

          }
      }

      func deleteNotes(ids: [String]) {
          do {
              try repository.delete(ids: ids)
              notes = try repository.fetchAll()
          } catch {
              print("deleteNotes error ")

              /* set errorMessage */
          }
      }
}


