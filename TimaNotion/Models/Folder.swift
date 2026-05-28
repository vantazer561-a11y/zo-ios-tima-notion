import Foundation
import CoreData

@objc(Folder)
public final class Folder: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var symbol: String
    @NSManaged public var createdAt: Date
    @NSManaged public var notes: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        NSFetchRequest<Folder>(entityName: "Folder")
    }
}

// MARK: Notes accessors

extension Folder {
    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: Note)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: Note)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)
}
