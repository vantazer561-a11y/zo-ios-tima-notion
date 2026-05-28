import SwiftUI

struct NoteRow: View {
    @ObservedObject var note: Note

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(note.accentColor)
                .frame(width: 4)
                .opacity(note.colorHex == nil ? 0.0 : 1.0)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(note.displayTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
                if !note.snippet.isEmpty {
                    Text(note.snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 6) {
                    Text(note.updatedAt, format: .dateTime.day().month().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let folder = note.folder {
                        Label(folder.name, systemImage: folder.symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }

                    ForEach(note.tagList.prefix(3), id: \.self) { tag in
                        TagChip(tag: tag)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct TagChip: View {
    let tag: String
    var body: some View {
        Text("#\(tag)")
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}
