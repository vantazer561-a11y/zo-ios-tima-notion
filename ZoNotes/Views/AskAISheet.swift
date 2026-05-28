import SwiftUI

struct AskAISheet: View {
    @Environment(\.dismiss) private var dismiss
    let noteBody: String
    let onInsert: (String) -> Void

    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Спросите про эту заметку или попросите что-то новое.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Например: «Сформулируй вывод одной фразой»",
                          text: $question, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(10)
                    .background(Color.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 12))
                    .focused($focused)

                HStack {
                    Button {
                        ask()
                    } label: {
                        Label(isWorking ? "Спрашиваю…" : "Спросить",
                              systemImage: "sparkles")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorking || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !answer.isEmpty {
                    ScrollView {
                        Text(answer)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.thinMaterial,
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    HStack {
                        Button {
                            onInsert(answer); dismiss()
                        } label: {
                            Label("Вставить в заметку", systemImage: "text.insert")
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = answer
                        } label: {
                            Label("Скопировать", systemImage: "doc.on.doc")
                        }
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Спросить ИИ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear { focused = true }
            .alert("Ошибка ИИ",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func ask() {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isWorking = true
        Task {
            do {
                let res = try await AIService.shared.ask(q, context: noteBody)
                await MainActor.run {
                    answer = res
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                    isWorking = false
                }
            }
        }
    }
}
