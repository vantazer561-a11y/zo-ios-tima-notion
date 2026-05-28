import SwiftUI

struct AIToolbar: View {
    let isWorking: Bool
    @Binding var isPreview: Bool
    let onAction: (AIAction) -> Void
    let onAsk: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    PrimaryAIButton(title: "Спросить ИИ",
                                    systemImage: "sparkles",
                                    action: onAsk)
                        .disabled(isWorking)

                    ForEach(AIAction.allCases) { action in
                        SecondaryAIButton(title: action.title,
                                          systemImage: action.icon) {
                            onAction(action)
                        }
                        .disabled(isWorking)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(.thinMaterial)
        }
    }
}

private struct PrimaryAIButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

private struct SecondaryAIButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
