import Foundation
import CoreData
import SwiftUI

extension Note {

    /// Сниппет тела для превью в списке.
    var snippet: String {
        let stripped = body
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(stripped.prefix(140))
    }

    /// Заголовок с фолбэком.
    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        // Берём первую строку тела.
        if let firstLine = body.split(separator: "\n").first {
            let s = String(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { return String(s.prefix(80)) }
        }
        return "Без названия"
    }

    var tagList: [String] {
        tagsCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func setTags(_ tags: [String]) {
        let clean = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        tagsCSV = Array(Set(clean)).sorted().joined(separator: ",")
    }

    var accentColor: Color {
        guard let hex = colorHex, let c = Color(hex: hex) else { return .accentColor }
        return c
    }

    /// Кол-во слов — пригодится в счётчике и для оценки токенов.
    var wordCount: Int {
        body.split { $0.isWhitespace || $0.isNewline }.count
    }
}

extension Folder {
    /// Удобный счётчик заметок.
    var notesCount: Int {
        (notes as? Set<Note>)?.count ?? 0
    }
}

// MARK: - Color hex

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xff) / 255.0
        let g = Double((v >>  8) & 0xff) / 255.0
        let b = Double( v        & 0xff) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
