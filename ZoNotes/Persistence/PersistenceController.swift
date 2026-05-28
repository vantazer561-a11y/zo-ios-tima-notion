import CoreData
import Foundation

/// Точка входа для CoreData-стека.
/// Содержит singleton для боевого использования и `preview` для SwiftUI Preview.
struct PersistenceController {

    static let shared = PersistenceController()

    /// In-memory стек с демо-данными для превью.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let inbox = Folder(context: ctx)
        inbox.id = UUID()
        inbox.name = "Входящие"
        inbox.symbol = "tray"
        inbox.createdAt = Date()

        let work = Folder(context: ctx)
        work.id = UUID()
        work.name = "Работа"
        work.symbol = "briefcase"
        work.createdAt = Date()

        for i in 0..<6 {
            let n = Note(context: ctx)
            n.id = UUID()
            n.title = "Заметка #\(i + 1)"
            n.body = "Демо-текст для предпросмотра. Здесь может быть **Markdown**, списки, идеи и т.д."
            n.createdAt = Date().addingTimeInterval(-Double(i) * 3600)
            n.updatedAt = n.createdAt
            n.tagsCSV = i % 2 == 0 ? "идея,скетч" : "todo"
            n.isPinned = i == 0
            n.folder = i % 2 == 0 ? inbox : work
        }

        try? ctx.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ZoNotes")
        if inMemory, let description = container.persistentStoreDescriptions.first {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // В реальном проде — отчёт в Crashlytics/Sentry.
                assertionFailure("CoreData load error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Сохранить контекст безопасно.
    @discardableResult
    func save() -> Bool {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return true }
        do {
            try ctx.save()
            return true
        } catch {
            assertionFailure("CoreData save error: \(error)")
            return false
        }
    }
}
