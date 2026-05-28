import Foundation
import CoreData

@objc(Note)
public final class Note: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var body: String
    @NSManaged public var tagsCSV: String
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isPinned: Bool
    @NSManaged public var isLocked: Bool
    @NSManaged public var folder: Folder?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        NSFetchRequest<Note>(entityName: "Note")
    }
}
