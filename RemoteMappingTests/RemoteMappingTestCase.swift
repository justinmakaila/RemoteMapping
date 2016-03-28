import XCTest
import CoreData


private let CoreDataStoreURL = {
    return try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("RemoteMappingTests.tests")
}()

class RemoteMappingTestCase: XCTestCase {
    var managedObjectContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()

        self.managedObjectContext = setupManagedObjectContext()
    }
    
    func entityForName(name: String) -> NSEntityDescription {
        guard let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: self.managedObjectContext)
            else {
                fatalError("Could not load entity")
        }
        
        return entity
    }
    
    func insertEntity<A: NSManagedObject>(entityDescription: NSEntityDescription) -> A {
        guard let object =  NSEntityDescription.insertNewObjectForEntityForName(entityDescription.name!, inManagedObjectContext: self.managedObjectContext) as? A
        else {
            fatalError("Could not insert object for entity \(entityDescription.name)")
        }
        
        return object
    }
    
    func setupManagedObjectContext() -> NSManagedObjectContext {
        // Load the model from `Wellth.xcdatamodeld`
        guard let modelURL = NSBundle(forClass: RemoteMappingTestCase.self).URLForResource("TestModel", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOfURL: modelURL)
            else {
                fatalError("Model not found")
        }
        
        // Create a persistent store coordinator for the model
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Add the `NSSQLiteStoreType` to the coordinator
        // !!!: Because there is no feasible way to handle the error, `try!` will result in a runtime error if this operation fails.
        try! persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: CoreDataStoreURL, options: nil)
        
        // Create the `NSManagedObjectContext`
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        
        return context
    }
}