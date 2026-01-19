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



// Abstraction for the repository
protocol NotesRepositoryProtocol: AnyObject {
    func sync(count: Int) async throws
    func fetchAll() throws -> [NoteDTO]
    func fetch(byID id: String) throws -> NoteDTO?
    
    func create(title: String, content: String) throws
    func update(id: String, title: String, content: String) throws
    func delete(ids: [String]) throws
}
