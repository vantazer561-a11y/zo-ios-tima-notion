import Foundation

// MARK: - Конфигурация ИИ

struct AISettings {
    /// База URL OpenAI-совместимого провайдера.
    var baseURL: URL
    /// Имя модели.
    var model: String
    /// Системный язык для ответов модели.
    var preferredLanguage: String

    static let `default` = AISettings(
        baseURL: URL(string: "https://api.openai.com/v1")!,
        model: "gpt-4o-mini",
        preferredLanguage: "ru"
    )
}

// MARK: - Готовые действия над текстом

enum AIAction: String, CaseIterable, Identifiable {
    case summarize
    case improve
    case continueWriting
    case shorten
    case expand
    case toBulletList
    case fixGrammar
    case translateRU
    case translateEN
    case actionItems
    case suggestTitle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summarize:       return "Кратко изложить"
        case .improve:         return "Улучшить стиль"
        case .continueWriting: return "Продолжить мысль"
        case .shorten:         return "Сократить"
        case .expand:          return "Развернуть"
        case .toBulletList:    return "В список"
        case .fixGrammar:      return "Исправить ошибки"
        case .translateRU:     return "Перевод на русский"
        case .translateEN:     return "Перевод на английский"
        case .actionItems:     return "Извлечь задачи"
        case .suggestTitle:    return "Подобрать заголовок"
        }
    }

    var icon: String {
        switch self {
        case .summarize:       return "text.alignleft"
        case .improve:         return "wand.and.stars"
        case .continueWriting: return "arrow.right.to.line"
        case .shorten:         return "arrow.down.right.and.arrow.up.left"
        case .expand:          return "arrow.up.left.and.arrow.down.right"
        case .toBulletList:    return "list.bullet"
        case .fixGrammar:      return "checkmark.seal"
        case .translateRU:     return "globe"
        case .translateEN:     return "globe.americas"
        case .actionItems:     return "checklist"
        case .suggestTitle:    return "character.cursor.ibeam"
        }
    }

    /// Возвращает true, если результат должен заменять весь текст,
    /// а не дописываться к нему.
    var replacesContent: Bool {
        switch self {
        case .summarize, .improve, .shorten, .expand,
             .toBulletList, .fixGrammar, .translateRU, .translateEN:
            return true
        case .continueWriting, .actionItems, .suggestTitle:
            return false
        }
    }

    fileprivate func prompt(language: String) -> String {
        switch self {
        case .summarize:
            return "Сделай краткое резюме текста в 3–5 пунктах. Сохраняй смысл. Отвечай на языке: \(language)."
        case .improve:
            return "Улучши стиль текста, сделай его читаемым и аккуратным. Не меняй смысл и факты. Отвечай на языке оригинала."
        case .continueWriting:
            return "Продолжи текст в том же стиле и регистре. Верни ТОЛЬКО продолжение, без повтора того, что уже написано."
        case .shorten:
            return "Сократи текст в 1.5–2 раза, сохранив ключевые мысли. Отвечай на языке оригинала."
        case .expand:
            return "Разверни текст, добавь полезные детали и примеры. Не выдумывай факты. Отвечай на языке оригинала."
        case .toBulletList:
            return "Преобразуй текст в чистый маркированный список. Каждый пункт — короткая мысль. Отвечай на языке оригинала."
        case .fixGrammar:
            return "Исправь грамматические и пунктуационные ошибки. Стиль и смысл не меняй. Верни только исправленный текст."
        case .translateRU:
            return "Переведи текст на русский язык, аккуратно и естественно. Верни только перевод."
        case .translateEN:
            return "Translate the text to natural English. Return only the translation."
        case .actionItems:
            return "Извлеки из текста чёткий список задач (action items). Каждая задача начинается с глагола. Без вступления и заключения."
        case .suggestTitle:
            return "Предложи короткий точный заголовок (до 60 символов) для текста. Верни только заголовок, без кавычек."
        }
    }
}

// MARK: - Ошибки

enum AIError: LocalizedError {
    case missingAPIKey
    case badResponse(Int, String?)
    case decoding
    case network(Error)
    case empty

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:      return "Не задан API-ключ. Откройте настройки и добавьте ключ OpenAI."
        case .badResponse(let c, let msg):
            return "Сервер ИИ вернул ошибку (\(c))." + (msg.map { " " + $0 } ?? "")
        case .decoding:           return "Не удалось разобрать ответ модели."
        case .network(let e):     return "Сетевая ошибка: \(e.localizedDescription)"
        case .empty:              return "Модель вернула пустой ответ."
        }
    }
}

// MARK: - Сервис

/// Тонкий клиент к OpenAI-совместимому Chat Completions API.
/// Любой провайдер с этой схемой подойдёт (OpenAI, OpenRouter, локальные шлюзы).
final class AIService {

    static let shared = AIService()

    var settings: AISettings = .default
    var apiKey: String? { KeychainStore.get(SecretKey.openAIAPIKey) }
    var isConfigured: Bool { !(apiKey?.isEmpty ?? true) }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Применяет действие к выделенному (или всему) тексту.
    func run(_ action: AIAction, on text: String) async throws -> String {
        let system = "Ты — встроенный AI-ассистент в заметках. Действуй точно и лаконично. Никогда не вставляй пояснений к своим ответам, только результат."
        let user   = action.prompt(language: settings.preferredLanguage) + "\n\n---\n" + text
        return try await chat(system: system, user: user)
    }

    /// Свободный чат-вопрос (можно использовать для AI-командной строки).
    func ask(_ question: String, context: String? = nil) async throws -> String {
        let system = "Ты — встроенный AI-ассистент. Отвечай ясно и по делу на языке вопроса."
        var user = question
        if let context, !context.isEmpty {
            user += "\n\nКонтекст заметки:\n\(context)"
        }
        return try await chat(system: system, user: user)
    }

    // MARK: - Сеть

    private func chat(system: String, user: String) async throws -> String {
        guard let key = apiKey, !key.isEmpty else { throw AIError.missingAPIKey }

        let url = settings.baseURL.appendingPathComponent("chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body: [String: Any] = [
            "model": settings.model,
            "temperature": 0.4,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw AIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.decoding }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)?.prefix(400).description
            throw AIError.badResponse(http.statusCode, msg)
        }

        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
            }
            let choices: [Choice]
        }
        guard let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = decoded.choices.first?.message.content?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw AIError.empty
        }
        return content
    }
}
