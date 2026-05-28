import SwiftUI

struct FolderManagerView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Folder.createdAt, ascending: true)]
    )
    private var folders: FetchedResults<Folder>

    @State private var newName: String = ""
    @State private var newSymbol: String = "folder"

    private let symbols: [String] = [
        "folder", "tray", "briefcase", "graduationcap", "lightbulb",
        "book", "heart", "star", "flag", "tag", "bolt",
        "leaf", "music.note", "gamecontroller", "house", "cart"
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Новая папка") {
                    TextField("Название", text: $newName)
                    LazyVGrid(columns: [.init(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(symbols, id: \.self) { sym in
                            Button {
                                newSymbol = sym
                            } label: {
                                Image(systemName: sym)
                                    .font(.headline)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        sym == newSymbol
                                            ? AnyShapeStyle(Color.accentColor.opacity(0.2))
                                            : AnyShapeStyle(Color.secondary.opacity(0.1)),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .foregroundStyle(sym == newSymbol ? Color.accentColor : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    Button {
                        addFolder()
                    } label: {
                        Label("Создать", systemImage: "plus.circle.fill")
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section("Папки") {
                    if folders.isEmpty {
                        Text("Пока ничего нет")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(folders, id: \.objectID) { f in
                            HStack {
                                Image(systemName: f.symbol)
                                    .foregroundStyle(.tint)
                                Text(f.name)
                                Spacer()
                                Text("\(f.notesCount)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Папки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func addFolder() {
        let f = Folder(context: ctx)
        f.id = UUID()
        f.name = newName.trimmingCharacters(in: .whitespaces)
        f.symbol = newSymbol
        f.createdAt = Date()
        PersistenceController.shared.save()
        newName = ""
        newSymbol = "folder"
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { folders[$0] }.forEach(ctx.delete)
        PersistenceController.shared.save()
    }
}

struct FolderPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Folder.name, ascending: true)]
    )
    private var folders: FetchedResults<Folder>

    let current: Folder?
    let onPick: (Folder?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onPick(nil); dismiss()
                } label: {
                    HStack {
                        Label("Без папки", systemImage: "tray")
                        Spacer()
                        if current == nil {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
                ForEach(folders, id: \.objectID) { f in
                    Button {
                        onPick(f); dismiss()
                    } label: {
                        HStack {
                            Label(f.name, systemImage: f.symbol)
                            Spacer()
                            if current == f {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выбрать папку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
