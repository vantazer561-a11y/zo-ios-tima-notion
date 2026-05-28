import SwiftUI

@main
struct ZoNotesApp: App {

    @StateObject private var settings = AppSettings()
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(settings)
                .tint(.accentColor)
                .preferredColorScheme(settings.colorScheme.swiftUI)
        }
    }
}
