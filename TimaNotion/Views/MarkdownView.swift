import SwiftUI

/// Простой Markdown-рендерер на базе системного `AttributedString(markdown:)`.
/// Заголовки и списки отрисовываются построчно для лучшего вида.
struct MarkdownView: View {
    let text: String

    var body: some View {
        let blocks = text.split(separator: "\n", omittingEmptySubsequences: false)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, line in
                renderLine(String(line))
            }
        }
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
            Text(parse(String(trimmed.dropFirst(2))))
                .font(.title.weight(.bold))
        } else if trimmed.hasPrefix("## ") {
            Text(parse(String(trimmed.dropFirst(3))))
                .font(.title2.weight(.semibold))
        } else if trimmed.hasPrefix("### ") {
            Text(parse(String(trimmed.dropFirst(4))))
                .font(.title3.weight(.semibold))
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•").foregroundStyle(.tint)
                Text(parse(String(trimmed.dropFirst(2))))
            }
        } else if trimmed.isEmpty {
            Spacer().frame(height: 4)
        } else {
            Text(parse(trimmed))
                .font(.body)
        }
    }

    private func parse(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s,
                               options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
        ?? AttributedString(s)
    }
}
