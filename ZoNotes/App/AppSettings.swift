import SwiftUI

/// Пользовательские настройки уровня приложения.
@MainActor
final class AppSettings: ObservableObject {

    enum AppColorScheme: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "Системная"
            case .light:  return "Светлая"
            case .dark:   return "Тёмная"
            }
        }
        var swiftUI: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    @AppStorage("ui.colorScheme")    var colorSchemeRaw: String = AppColorScheme.system.rawValue
    @AppStorage("ui.useMarkdown")    var useMarkdownPreview: Bool = true
    @AppStorage("ai.model")          var aiModel: String = AISettings.default.model
    @AppStorage("ai.baseURL")        var aiBaseURL: String = AISettings.default.baseURL.absoluteString
    @AppStorage("ai.language")       var aiLanguage: String = "ru"

    var colorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: colorSchemeRaw) ?? .system }
        set { colorSchemeRaw = newValue.rawValue }
    }

    /// Подтянуть AI-настройки в общий сервис.
    func syncToAIService() {
        var s = AISettings.default
        if let url = URL(string: aiBaseURL) { s.baseURL = url }
        s.model = aiModel
        s.preferredLanguage = aiLanguage
        AIService.shared.settings = s
    }
}
