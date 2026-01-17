//
//  MockNotesAPI.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//

import Foundation


final class MockNotesAPI: NotesAPI {
    func fetchNotes(count: Int) async throws -> [NoteDTO] {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000)

        return (0..<count).map { i in
            NoteDTO(
                id: "mockV2-\(i)",
                title: "MockV2 Note \(i)",
                content: "MockV2 content \(i)",
                createdAt: Date().addingTimeInterval(TimeInterval(-i))
            )
        }
    }
}
