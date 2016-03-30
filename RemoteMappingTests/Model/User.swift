import Foundation
import CoreData


public final class User: NSManagedObject {
    
    @NSManaged
    public var age: Int16
    
    @NSManaged
    private var favoriteWordsValue: NSData
    public var favoriteWords: [String] {
        get {
            guard let favoriteWords = NSKeyedUnarchiver.unarchiveObjectWithData(favoriteWordsValue) as? [String]
            else {
                return []
            }
            
            return favoriteWords
        }
        set {
            favoriteWordsValue = NSKeyedArchiver.archivedDataWithRootObject(newValue)
        }
    }
    
    @NSManaged
    public var transformable: [String]
    
    @NSManaged
    public var birthdate: NSDate
    
    @NSManaged
    public var height: Float
    
    @NSManaged
    public var name: String
    
    @NSManaged
    public var detail: String
    
    /// MARK: Relationships
    
    @NSManaged
    public var friends: Set<User>
    
    @NSManaged
    public var followers: Set<User>
    
    @NSManaged
    public var significantOther: User
}