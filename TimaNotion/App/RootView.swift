import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NotesListView()
            .onAppear { settings.syncToAIService() }
            .onChange(of: settings.aiBaseURL) { _ in settings.syncToAIService() }
            .onChange(of: settings.aiModel)   { _ in settings.syncToAIService() }
            .onChange(of: settings.aiLanguage){ _ in settings.syncToAIService() }
    }
}

#Preview {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppSettings())
}
