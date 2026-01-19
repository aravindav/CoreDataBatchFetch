//
//  ContentView.swift
//  CoreDataBatchFetch
//
//  Created by Aravind on 16/01/26.
//


import SwiftUI
import CoreData

struct ContentView: View {

    // Sorting state toggled by toolbar button
    @State private var sortAscending = false

    @State private var newTitle = ""
    @State private var newContent = ""

    @State private var noteToEdit: NoteDTO?
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var searchText = ""
    
    private let pageSize = 50
    
    @State private var limit: Int = 50
    @State private var isLoadingMore = false

    @StateObject var viewModel: NotesViewModel
    
    private var filteredNotes: [NoteDTO] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return viewModel.notes }
        return viewModel.notes.filter { note in
            note.title.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
            note.content.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private var sortedNotes: [NoteDTO] {
        filteredNotes.sorted { lhs, rhs in
            sortAscending
            ? lhs.createdAt < rhs.createdAt
            : lhs.createdAt > rhs.createdAt
        }
    }

    private var visibleNotes: [NoteDTO] {
        Array(sortedNotes.prefix(limit))
    }
    
    
    var body: some View {
        NavigationStack {
            VStack {

                NotesList(
                    visibleNotes: visibleNotes,
                    onReachEnd: { loadMore() },
                    onEdit: { dto in
                        noteToEdit = dto
                        editTitle = dto.title
                        editContent = dto.content
                    },
                    onDelete: { offsets in
                        viewModel.deleteNotes(ids: offsets.map { visibleNotes[$0].id })
                    }
                )

                VStack {
                    TextField("Title", text: $newTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Content", text: $newContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button {
                        viewModel.addNote(title: newTitle, content: newContent)
                    } label: {
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
                                     viewModel.sync(count: 500)
                                 }
                             }
            }
        }
        .task {
            viewModel.load()
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
                        viewModel.saveEdit(id: note.id, title: editTitle, content: editContent)
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
    
    private struct NotesList: View {
        let visibleNotes: [NoteDTO]
        let onReachEnd: () -> Void
        let onEdit: (NoteDTO) -> Void
        let onDelete: (IndexSet) -> Void

        var body: some View {
            List {
                ForEach(Array(visibleNotes.enumerated()), id: \.element.id) { index, note in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(note.title).font(.headline)
                            Text(note.content).font(.subheadline).foregroundStyle(.gray)
                            Text(note.createdAt, style: .date)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { onEdit(note) } label: {
                            Image(systemName: "pencil").foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        if index == visibleNotes.count - 1 {
                            onReachEnd()
                        }
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}





