import SwiftUI
import CoreData

struct NotesListView: View {

    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject private var settings: AppSettings

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Note.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)
        ],
        animation: .default
    )
    private var notes: FetchedResults<Note>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Folder.name, ascending: true)],
        animation: .default
    )
    private var folders: FetchedResults<Folder>

    @State private var query: String = ""
    @State private var selectedFolder: Folder?
    @State private var showSettings = false
    @State private var showFolderManager = false
    @State private var newNote: Note?

    private var filtered: [Note] {
        notes.filter { note in
            (selectedFolder == nil || note.folder == selectedFolder) &&
            (query.isEmpty
                || note.title.localizedCaseInsensitiveContains(query)
                || note.body.localizedCaseInsensitiveContains(query)
                || note.tagsCSV.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.10), Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                content
            }
            .navigationTitle("Заметки")
            .toolbar { toolbar }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Поиск по заметкам и тегам")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showFolderManager) { FolderManagerView() }
            .sheet(item: $newNote) { note in
                NavigationStack {
                    NoteEditorView(note: note)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            FolderStrip(folders: Array(folders),
                        selected: $selectedFolder,
                        onManage: { showFolderManager = true })

            if filtered.isEmpty {
                EmptyStateView(query: query) {
                    createNote()
                }
            } else {
                List {
                    ForEach(filtered, id: \.objectID) { note in
                        NavigationLink {
                            NoteEditorView(note: note)
                        } label: {
                            NoteRow(note: note)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(note)
                            } label: {
                                Label(note.isPinned ? "Открепить" : "Закрепить",
                                      systemImage: note.isPinned ? "pin.slash" : "pin")
                            }.tint(.orange)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(note)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Настройки")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: createNote) {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("Новая заметка")
        }
    }

    // MARK: - Actions

    private func createNote() {
        let note = Note(context: ctx)
        note.id = UUID()
        note.title = ""
        note.body = ""
        note.createdAt = Date()
        note.updatedAt = Date()
        note.tagsCSV = ""
        note.isPinned = false
        note.folder = selectedFolder
        PersistenceController.shared.save()
        newNote = note
    }

    private func togglePin(_ note: Note) {
        note.isPinned.toggle()
        note.updatedAt = Date()
        PersistenceController.shared.save()
    }

    private func delete(_ note: Note) {
        ctx.delete(note)
        PersistenceController.shared.save()
    }
}

#Preview {
    NotesListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppSettings())
}
