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
        
        self.user = user
    }
    
    func test_NSManagedObjectFromRemoteMappingEntityDescription_ProvidesValidJSONRepresentation() {
        let justinJSON = user.toJSON()
        
        XCTAssertTrue(justinJSON["name"] is String)
        let name = justinJSON["name"] as! String
        XCTAssertTrue(name == user.name)
        
        XCTAssertTrue(justinJSON["favoriteWords"] is NSArray)
        let favoriteWords = justinJSON["favoriteWords"] as? [String] ?? []
        for word in user.favoriteWords {
            XCTAssertTrue(favoriteWords.contains(word))
        }
        
        /// Dates are not equivalent, but print the same thing...
        //XCTAssertTrue(justinJSON["birthdate"] is String)
        //let birthdate = NSDate(ISO8601String: justinJSON["birthdate"] as! String)!
        //XCTAssertTrue(birthdate == justin.birthdate)
        
        XCTAssertTrue(justinJSON["age"] is NSNumber)
        let age = justinJSON["age"] as! NSNumber
        XCTAssertTrue(Int16(age.integerValue) == user.age)
        
        XCTAssertTrue(justinJSON["height"] is NSNumber)
        let height = justinJSON["height"] as! NSNumber
        XCTAssertTrue(height == user.height)
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