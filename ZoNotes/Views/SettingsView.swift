import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var savedFlash: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Внешний вид") {
                    Picker("Тема", selection: Binding(
                        get: { settings.colorScheme },
                        set: { settings.colorScheme = $0 }
                    )) {
                        ForEach(AppSettings.AppColorScheme.allCases) { c in
                            Text(c.title).tag(c)
                        }
                    }
                    Toggle("Предпросмотр Markdown", isOn: $settings.useMarkdownPreview)
                }

                Section {
                    HStack {
                        if showKey {
                            TextField("sk-…", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-…", text: $apiKey)
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("Сохранить ключ") {
                            KeychainStore.set(apiKey, for: SecretKey.openAIAPIKey)
                            savedFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                savedFlash = false
                            }
                        }
                        .disabled(apiKey.isEmpty)
                        Spacer()
                        if savedFlash {
                            Label("Сохранено", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .transition(.opacity)
                        }
                    }
                    if KeychainStore.get(SecretKey.openAIAPIKey) != nil {
                        Button(role: .destructive) {
                            KeychainStore.delete(SecretKey.openAIAPIKey)
                            apiKey = ""
                        } label: {
                            Label("Удалить ключ", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Ключ OpenAI")
                } footer: {
                    Text("Ключ хранится только на устройстве в Keychain. Подойдёт любой OpenAI-совместимый провайдер (OpenAI, OpenRouter и т.д.).")
                }

                Section("Модель ИИ") {
                    TextField("Base URL", text: $settings.aiBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Имя модели", text: $settings.aiModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Язык ответов", selection: $settings.aiLanguage) {
                        Text("Русский").tag("ru")
                        Text("English").tag("en")
                    }
                }

                Section("О приложении") {
                    LabeledContent("Версия") {
                        Text(Bundle.main.shortVersion)
                    }
                    LabeledContent("Сборка") {
                        Text(Bundle.main.bundleVersion)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear {
                if let k = KeychainStore.get(SecretKey.openAIAPIKey) { apiKey = k }
            }
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }
    var bundleVersion: String {
        (object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
    }
}
