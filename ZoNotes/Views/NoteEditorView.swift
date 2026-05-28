import SwiftUI

struct NoteEditorView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @ObservedObject var note: Note

    @State private var title: String = ""
    @State private var body_: String = ""
    @State private var tagsText: String = ""

    @State private var isPreview: Bool = false
    @State private var showActions: Bool = false
    @State private var showAskSheet: Bool = false
    @State private var showMoveSheet: Bool = false

    @State private var isWorking: Bool = false
    @State private var errorMessage: String?

    @FocusState private var focused: Field?
    private enum Field { case title, body }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                editor
                AIToolbar(
                    isWorking: isWorking,
                    isPreview: $isPreview,
                    onAction: { action in
                        runAction(action)
                    },
                    onAsk: { showAskSheet = true }
                )
            }

            if isWorking {
                Color.black.opacity(0.06).ignoresSafeArea()
                ProgressView("ИИ думает…")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear(perform: load)
        .onDisappear(perform: save)
        .sheet(isPresented: $showAskSheet) {
            AskAISheet(noteBody: body_) { answer in
                insert(text: "\n\n— ИИ ответ —\n\(answer)\n")
            }
        }
        .sheet(isPresented: $showMoveSheet) {
            FolderPickerSheet(current: note.folder) { folder in
                note.folder = folder
                PersistenceController.shared.save()
            }
        }
        .alert("Ошибка ИИ",
               isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Editor body

    @ViewBuilder
    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Заголовок", text: $title, axis: .vertical)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .focused($focused, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focused = .body }

                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    TextField("теги через запятую", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                Divider().padding(.vertical, 4)

                if isPreview {
                    MarkdownView(text: body_)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Начните писать…", text: $body_, axis: .vertical)
                        .font(.system(.body, design: .rounded))
                        .focused($focused, equals: .body)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Text("\(note.wordCount) слов")
                    Spacer()
                    Text("Изменено \(note.updatedAt.formatted(.dateTime.day().month().hour().minute()))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 16)
            }
            .padding(16)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    isPreview.toggle()
                } label: {
                    Label(isPreview ? "Редактировать" : "Превью Markdown",
                          systemImage: isPreview ? "pencil" : "eye")
                }
                Button {
                    note.isPinned.toggle()
                    PersistenceController.shared.save()
                } label: {
                    Label(note.isPinned ? "Открепить" : "Закрепить",
                          systemImage: note.isPinned ? "pin.slash" : "pin")
                }
                Button {
                    showMoveSheet = true
                } label: {
                    Label("Переместить в папку…", systemImage: "folder")
                }
                ShareLink(item: shareText) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive) {
                    ctx.delete(note)
                    PersistenceController.shared.save()
                    dismiss()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var shareText: String {
        let head = title.isEmpty ? "Заметка" : title
        return "\(head)\n\n\(body_)"
    }

    // MARK: - Load / Save

    private func load() {
        title = note.title
        body_ = note.body
        tagsText = note.tagList.joined(separator: ", ")
        if title.isEmpty && body_.isEmpty {
            focused = .title
        }
    }

    private func save() {
        note.title = title
        note.body = body_
        note.setTags(tagsText.split(separator: ",").map { String($0) })
        note.updatedAt = Date()
        PersistenceController.shared.save()
    }

    // MARK: - AI

    private func runAction(_ action: AIAction) {
        guard AIService.shared.isConfigured else {
            errorMessage = AIError.missingAPIKey.errorDescription
            return
        }
        let source = body_
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Сначала напишите хоть немного текста."
            return
        }

        isWorking = true
        Task {
            do {
                let result = try await AIService.shared.run(action, on: source)
                await MainActor.run {
                    apply(result: result, for: action)
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func apply(result: String, for action: AIAction) {
        switch action {
        case .suggestTitle:
            title = result.trimmingCharacters(in: .whitespacesAndNewlines)
        case .actionItems:
            insert(text: "\n\n— Задачи —\n" + result + "\n")
        case .continueWriting:
            insert(text: (body_.hasSuffix("\n") ? "" : "\n") + result)
        default:
            if action.replacesContent { body_ = result }
        }
        save()
    }

    private func insert(text: String) {
        body_ += text
    }
}

#Preview {
    NavigationStack {
        NoteEditorView(note: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Note }.first!)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .environmentObject(AppSettings())
}
