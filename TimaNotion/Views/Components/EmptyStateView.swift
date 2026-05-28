import SwiftUI

struct EmptyStateView: View {
    let query: String
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: query.isEmpty ? "sparkles.rectangle.stack" : "magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
            Text(query.isEmpty ? "Здесь будут ваши заметки" : "Ничего не найдено")
                .font(.title3.weight(.semibold))
            Text(query.isEmpty
                 ? "Создайте первую заметку — ИИ-помощник под рукой."
                 : "Попробуйте изменить запрос или фильтр.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if query.isEmpty {
                Button(action: onCreate) {
                    Label("Создать заметку", systemImage: "square.and.pencil")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
