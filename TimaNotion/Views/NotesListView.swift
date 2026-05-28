import SwiftUI
import CoreData

struct NotesListView: View {

    @Environment(\.managedObjectContext) private var ctx
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var biometric: BiometricAuth

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
    @State private var openedNoteID: NSManagedObjectID?
    @State private var lockErrorMessage: String?

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
            .navigationDestination(isPresented: Binding(
                get: { openedNoteID != nil },
                set: { if !$0 { openedNoteID = nil } }
            )) {
                if let id = openedNoteID,
                   let note = try? ctx.existingObject(with: id) as? Note {
                    NoteEditorView(note: note)
                }
            }
            .alert("Не удалось разблокировать",
                   isPresented: Binding(get: { lockErrorMessage != nil },
                                        set: { if !$0 { lockErrorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(lockErrorMessage ?? "")
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
                        Button {
                            openNote(note)
                        } label: {
                            NoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(note)
                            } label: {
                                Label(note.isPinned ? "Открепить" : "Закрепить",
                                      systemImage: note.isPinned ? "pin.slash" : "pin")
                            }.tint(.orange)

                            Button {
                                Task { await toggleLock(note) }
                            } label: {
                                Label(note.isLocked ? "Снять защиту" : "Защитить",
                                      systemImage: note.isLocked ? "lock.open" : "lock")
                            }.tint(.indigo)
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

    private func openNote(_ note: Note) {
        if note.isLocked && !biometric.isUnlocked(note.id) {
            Task {
                let ok = await biometric.unlock(noteID: note.id,
                                                reason: "Откройте «\(note.displayTitle)»")
                if ok {
                    openedNoteID = note.objectID
                } else {
                    lockErrorMessage = "Аутентификация не пройдена."
                }
            }
        } else {
            openedNoteID = note.objectID
        }
    }

    private func toggleLock(_ note: Note) async {
        let reason = note.isLocked
            ? "Снять защиту с заметки"
            : "Защитить заметку Face ID"
        let ok = await biometric.confirmToggleProtection(reason: reason)
        guard ok else { return }
        note.isLocked.toggle()
        if !note.isLocked {
            // если сняли защиту — больше не считаем разблокированной отдельно
        }
        note.updatedAt = Date()
        PersistenceController.shared.save()
    }

    private func createNote() {
        let note = Note(context: ctx)
        note.id = UUID()
        note.title = ""
        note.body = ""
        note.createdAt = Date()
        note.updatedAt = Date()
        note.tagsCSV = ""
        note.isPinned = false
        note.isLocked = false
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
        .environmentObject(BiometricAuth.shared)
}
