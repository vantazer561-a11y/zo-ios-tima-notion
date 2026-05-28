import SwiftUI

@main
struct TimaNotionApp: App {

    @StateObject private var settings = AppSettings()
    @StateObject private var biometric = BiometricAuth.shared
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(settings)
                .environmentObject(biometric)
                .tint(.accentColor)
                .preferredColorScheme(settings.colorScheme.swiftUI)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { biometric.lockAll() }
        }
    }
}
