//
//  ContentView.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//


import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Sorting state toggled by toolbar button
    @State private var sortAscending = false

    @State private var newTitle = ""
    @State private var newContent = ""

    @State private var noteToEdit: Note?
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var searchText = ""
    
    private let pageSize = 50
    
    @State private var limit: Int = 50
    @State private var isLoadingMore = false
    
    private let repo = NotesRepository(
        api: MockNotesAPI(),
        container: PersistenceController.shared.container
    )

    
    var body: some View {
        NavigationStack {
            VStack {
                // List driven by a child view whose FetchRequest depends on sortAscending
                NotesList(searchText: searchText, sortAscending: sortAscending, paginationLimit: limit, onEdit: startEditingNote, onDelete: deleteNotes){
                    loadMore()
                }

                VStack {
                    TextField("Title", text: $newTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Content", text: $newContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: addNote) {
                        Text("Add Note")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 5)
                }
                .padding()
            }
            .navigationTitle("Note List")
            .searchable(text: $searchText , placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sortAscending.toggle()
                    } label: {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                                 Button("Sync 10k") {
                                     Task {
                                         do { try await repo.sync(count: 500) }
                                         catch { print("Sync failed:", error) }
                                     }
                                 }
                             }
            }
        }
        .sheet(item: $noteToEdit) { note in
            VStack {
                Text("Edit Note")
                    .font(.title)
                    .padding(.top)

                TextField("Title", text: $editTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Content", text: $editContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                HStack {
                    Button("Cancel") {
                        noteToEdit = nil
                    }
                    .foregroundStyle(.red)
                    .padding()

                    Spacer()

                    Button("Save") {
                        saveEdit(note)
                        noteToEdit = nil
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    private func loadMore() {
        
        guard !isLoadingMore else {return }
        
        isLoadingMore = true
        
        print("Loading more ....")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            limit += pageSize
            isLoadingMore = false
        }
    }

    // MARK: - CRUD

    private func addNote() {
        let newNote = Note(context: viewContext)
        newNote.title = newTitle
        newNote.content = newContent
        newNote.createdAt = Date()

        do {
            try viewContext.save()
            newTitle = ""
            newContent = ""
        } catch {
            print("Error occured: \(error)")
        }
    }

    private func saveEdit(_ note: Note) {
        note.title = editTitle
        note.content = editContent

        do {
            try viewContext.save()
        } catch {
            print("Error saving the edit : \(error)")
        }
    }

    private func deleteNotes(_ notes: FetchedResults<Note>, offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                viewContext.delete(notes[index])
            }

            do {
                try viewContext.save()
            } catch {
                print("Failed to delete note: \(error)")
            }
        }
    }

    private func startEditingNote(_ note: Note) {
        noteToEdit = note
        editTitle = note.title ?? ""
        editContent = note.content ?? ""
    }

    // Child view that owns the FetchRequest and re-initializes when sortAscending changes
    private struct NotesList: View {
       
        @Environment(\.managedObjectContext) private var viewContext
        @FetchRequest private var notes: FetchedResults<Note>
        private let onReachEnd: () -> Void

        var onEdit: ((Note) -> Void)?
        var onDelete: ((FetchedResults<Note>, IndexSet) -> Void)?

        let paginationLimit: Int

        init(searchText: String , sortAscending: Bool, paginationLimit : Int,
             onEdit: ((Note) -> Void)? = nil,
             onDelete: ((FetchedResults<Note>, IndexSet) -> Void)? = nil,
             onReachEnd: @escaping () -> Void) {
            
            let predicate : NSPredicate?
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                predicate = nil
            }
            else{
                predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText,searchText)
            }
            self.paginationLimit = paginationLimit
            self.onReachEnd = onReachEnd

            let request: NSFetchRequest<Note> = Note.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Note.createdAt, ascending: sortAscending)
            ]
            request.predicate = predicate
            request.fetchBatchSize = 50
            request.returnsObjectsAsFaults = true

            // Pagination window
            request.fetchLimit = paginationLimit
            
            _notes = FetchRequest(fetchRequest: request, animation: .default)

            
//            _notes = FetchRequest<Note>(
//                sortDescriptors: [NSSortDescriptor(keyPath: \Note.createdAt, ascending: sortAscending)],
//                predicate: predicate,
//                animation: .default
//            )
//            
            self.onEdit = onEdit
            self.onDelete = onDelete
        }

        var body: some View {
            List {
                ForEach(Array(notes.enumerated()), id: \.element.objectID) { index, note in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(note.title ?? "Untitled")
                                .font(.headline)
                            Text(note.content ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Text(note.createdAt ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(action: { onEdit?(note) }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        if index == notes.count - 1 {
                            onReachEnd()
                        }
                    }
                }
                .onDelete { offsets in
                    if let onDelete {
                        onDelete(notes, offsets)
                    } else {
                        // default delete if no handler provided
                        withAnimation {
                            offsets.forEach { index in
                                viewContext.delete(notes[index])
                            }
                            try? viewContext.save()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

