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
                            TextField("fw_…", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("fw_…", text: $apiKey)
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
                    Text("Ключ Fireworks AI")
                } footer: {
                    Text("Ключ хранится только на устройстве в Keychain. Получить его можно на fireworks.ai → API Keys. По умолчанию используется Llama 3.3 70B Instruct.")
                }

                Section {
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
                    HStack(spacing: 8) {
                        Button {
                            settings.aiBaseURL = "https://api.fireworks.ai/inference/v1"
                            settings.aiModel   = "accounts/fireworks/models/llama-v3p3-70b-instruct"
                        } label: {
                            Label("Fireworks", systemImage: "flame.fill")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            settings.aiBaseURL = "https://api.openai.com/v1"
                            settings.aiModel   = "gpt-4o-mini"
                        } label: {
                            Label("OpenAI", systemImage: "circle.hexagongrid")
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Модель ИИ")
                } footer: {
                    Text("Поддерживается любой OpenAI-совместимый API. Для Fireworks см. fireworks.ai/models — скопируйте идентификатор вида accounts/fireworks/models/…")
                }

                Section {
                    let kind = BiometricAuth.shared.availableKind()
                    HStack {
                        Image(systemName: kind.systemImage)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title)
                                .font(.body)
                            Text(kind == .none
                                 ? "Биометрия недоступна на этом устройстве."
                                 : "Используется для защиты приватных заметок.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Безопасность")
                } footer: {
                    Text("Чтобы защитить заметку, откройте её → меню ⋯ → «Защитить Face ID». Свайп влево по заметке в списке делает то же самое.")
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
