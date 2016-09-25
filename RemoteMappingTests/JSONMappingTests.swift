import XCTest
import CoreData
import ISO8601

@testable
import RemoteMapping

private let TwentyTwoYearsAgo: TimeInterval = 694252372
private let TwentyThreeYearsAgo: TimeInterval = 725809298

class JSONMappingTests: RemoteMappingTestCase {
    var userEntityDescription: NSEntityDescription!
    var user: User!
    var friend: User!
    
    override func setUp() {
        super.setUp()
        userEntityDescription = entityForName("User")
        
        let twentyThreeYearsAgo = Date(timeIntervalSinceNow: -(TwentyThreeYearsAgo))
        let user: User = insertEntity(userEntityDescription)
        user.name = "Justin Makaila"
        user.favoriteWords = ["sup", "dude"]
        user.birthdate = twentyThreeYearsAgo
        user.age = 23
        user.height = 175.25
        user.detail = "dude"
        
        let friend: User = insertEntity(userEntityDescription)
        friend.name = "Paige"
        friend.favoriteWords = ["none", "zero", "nada"]
        friend.birthdate = user.birthdate
        friend.age = 21
        friend.height = 160
        friend.detail = "chick"
        
        user.bestFriend = friend
        
        self.user = user
        self.friend = friend
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ProvidesValidJSONRepresentation() {
        let userJSON = user.toJSON()
        
        XCTAssertTrue(userJSON["name"] is String)
        let name = userJSON["name"] as! String
        XCTAssertTrue(name == user.name)
        
        XCTAssertTrue(userJSON["favoriteWords"] is NSArray)
        let favoriteWords = userJSON["favoriteWords"] as? [String] ?? []
        for word in user.favoriteWords {
            XCTAssertTrue(favoriteWords.contains(word))
        }
        
        /// Dates are not equivalent, but print the same thing...
        XCTAssertTrue(userJSON["birthdate"] is String)
        let birthdate = NSDate(iso8601String: userJSON["birthdate"] as! String)! as Date
        XCTAssertTrue(birthdate == user.birthdate)
        
        XCTAssertTrue(userJSON["age"] is NSNumber)
        let age = userJSON["age"] as! NSNumber
        XCTAssertTrue(Int16(age.intValue) == user.age)
        
        XCTAssertTrue(userJSON["height"] is NSNumber)
        let height = userJSON["height"] as! NSNumber
        XCTAssertTrue(height.floatValue == user.height)
        
        XCTAssertTrue(userJSON["userDetail"] is String)
        let detail = userJSON["userDetail"] as! String
        XCTAssertTrue(detail == user.detail)
        
        XCTAssertTrue(userJSON["bestFriend"] is JSONObject)
        let bestFriend = userJSON["bestFriend"] as! JSONObject
        let bestFriendJSON: JSONObject = user.bestFriend?.toJSON(user, relationshipType: .reference) ?? [:]
        //XCTAssertTrue(bestFriend == bestFriendJSON)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ProvidesChangedJSONRepresentation() {
        let newUser: User = insertEntity(userEntityDescription)
        newUser.name = "Dan"
        
        let changedJSON = newUser.toChangedJSON()
        
        /// In this case, changed JSON should only include the "name" key and value.
        XCTAssertTrue(changedJSON.count == 1)
        XCTAssertTrue(changedJSON["name"] != nil)
        XCTAssertTrue(changedJSON["name"] as! String == newUser.name)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_EmbedsRelationships() {
        let userJSON = user.toJSON(relationshipType: .embedded)
        let significantOtherJSON = userJSON["bestFriend"]
        XCTAssertTrue(significantOtherJSON is NSDictionary)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ReferencesRelationships() {
        let userJSON = user.toJSON(relationshipType: .reference)
        let significantOtherJSON = userJSON["bestFriend"]
        XCTAssertTrue(significantOtherJSON is String)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_NoRelationships() {
        let userJSON = user.toJSON(relationshipType: .none)
        let significantOtherJSON = userJSON["bestFriend"]
        XCTAssertNil(significantOtherJSON)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ExcludeKeysFromJSON() {
        let userJSON = user.toJSON(relationshipType: .none, excludeKeys: ["birthdate"])
        let birthdateJSON = userJSON["birthdate"]
        
        XCTAssertTrue(birthdateJSON == nil)
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_IncludesNilValuesAsNull() {
        let bestFriend = user.bestFriend
        let originalJSON = user.toJSON(relationshipType: .embedded)

        XCTAssertTrue(originalJSON["bestFriend"] != nil)
        
        user.bestFriend = nil
        let userJSON = user.toJSON(relationshipType: .embedded)
        let significantOther = userJSON["bestFriend"] as? NSNull
        
        XCTAssertTrue(significantOther != nil)
        
        user.bestFriend = bestFriend
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ReturnsValueForAttributeDescription() {
        let testDateString = "2016-09-23T18:38:29.392Z"
        guard let birthdateAttributeDescription = user.attributeDescriptionForRemoteKey("birthdate")
        else {
            return XCTAssert(false)
        }
        
        let value = user.valueForAttributeDescription(birthdateAttributeDescription, usingRemoteValue: testDateString as
            NSObject)
        XCTAssertNotNil(value)
        XCTAssertTrue(value is Date)
    }
}
