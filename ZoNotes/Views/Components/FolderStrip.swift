import SwiftUI

struct FolderStrip: View {
    let folders: [Folder]
    @Binding var selected: Folder?
    var onManage: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Все",
                     systemImage: "tray.full",
                     isSelected: selected == nil) {
                    selected = nil
                }

                ForEach(folders, id: \.objectID) { folder in
                    Chip(title: folder.name,
                         systemImage: folder.symbol,
                         isSelected: selected == folder) {
                        selected = (selected == folder) ? nil : folder
                    }
                }

                Button(action: onManage) {
                    Label("Папки", systemImage: "folder.badge.plus")
                        .labelStyle(.iconOnly)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct Chip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    isSelected
                    ? AnyShapeStyle(Color.accentColor)
                    : AnyShapeStyle(.thinMaterial),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
