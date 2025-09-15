import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "SpeakNative")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                assertionFailure("Unresolved CoreData error: \(error)")
            }
            self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }

    func saveIfNeeded() {
        let ctx = context
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            assertionFailure("CoreData save error: \(error)")
        }
    }
}


