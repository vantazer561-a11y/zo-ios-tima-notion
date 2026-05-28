import SwiftUI

struct NoteRow: View {
    @ObservedObject var note: Note
    @EnvironmentObject private var biometric: BiometricAuth

    private var isVisible: Bool {
        !note.isLocked || biometric.isUnlocked(note.id)
    }

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
                    if note.isLocked {
                        Image(systemName: isVisible ? "lock.open.fill" : "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(isVisible ? note.displayTitle : "Защищённая заметка")
                        .font(.headline)
                        .lineLimit(1)
                }
                if isVisible, !note.snippet.isEmpty {
                    Text(note.snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if !isVisible {
                    Text("Разблокируйте, чтобы прочитать")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
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

                    if isVisible {
                        ForEach(note.tagList.prefix(3), id: \.self) { tag in
                            TagChip(tag: tag)
                        }
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
