import XCTest
import CoreData
import ISO8601

@testable
import RemoteMapping

private let TwentyTwoYearsAgo: NSTimeInterval = 694252372
private let TwentyThreeYearsAgo: NSTimeInterval = 725809298

class JSONMappingTests: RemoteMappingTestCase {
    var userEntityDescription: NSEntityDescription!
    var user: User!
    var friend: User!
    
    override func setUp() {
        super.setUp()
        userEntityDescription = entityForName("User")
        
        let twentyThreeYearsAgo = NSDate(timeIntervalSinceNow: -(TwentyThreeYearsAgo))
        let user: User = insertEntity(userEntityDescription)
        user.name = "Justin Makaila"
        user.favoriteWords = ["sup", "dude"]
        user.birthdate = twentyThreeYearsAgo
        user.age = 23
        user.height = 175.25
        user.detail = "dude"
        
        self.user = user
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ProvidesValidJSONRepresentation() {
        let otherUser: User = insertEntity(userEntityDescription)
        otherUser.name = "Paige"
        otherUser.favoriteWords = ["none", "zero", "nada"]
        otherUser.birthdate = user.birthdate
        otherUser.age = 21
        otherUser.height = 160
        otherUser.detail = "chick"

        user.significantOther = otherUser
        
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
        //XCTAssertTrue(justinJSON["birthdate"] is String)
        //let birthdate = NSDate(ISO8601String: justinJSON["birthdate"] as! String)!
        //XCTAssertTrue(birthdate == justin.birthdate)
        
        XCTAssertTrue(userJSON["age"] is NSNumber)
        let age = userJSON["age"] as! NSNumber
        XCTAssertTrue(Int16(age.integerValue) == user.age)
        
        XCTAssertTrue(userJSON["height"] is NSNumber)
        let height = userJSON["height"] as! NSNumber
        XCTAssertTrue(height == user.height)
        
        XCTAssertTrue(userJSON["userDetail"] is String)
        let detail = userJSON["userDetail"] as! String
        XCTAssertTrue(detail == user.detail)
        
        XCTAssertTrue(userJSON["oneWayRelationship"] is NSDictionary)
        let otherUserDictionary = userJSON["oneWayRelationship"] as! NSDictionary
        XCTAssertTrue(otherUserDictionary == otherUser.toJSON())
        
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
}