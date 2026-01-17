//
//  NotesAPI.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//

import Foundation

import Foundation

struct NoteDTO: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
}

protocol NotesAPI {
    func fetchNotes(count: Int) async throws -> [NoteDTO]
}
