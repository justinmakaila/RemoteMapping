import XCTest
import CoreData

@testable
import RemoteMapping

class RemoteEntityTypeTests: RemoteMappingTestCase {
    /// An entity description can provide a custom remote primary key.
    func test_RemoteEntityType_ProvidesCustomRemotePrimaryKey() {
        let customRemotePrimaryKeyEntity = entityForName("CustomRemotePrimaryKeyEntity")
        
        let remotePrimaryKeyName = customRemotePrimaryKeyEntity.remotePrimaryKeyName
        XCTAssertTrue(remotePrimaryKeyName == "_id", "\"\(remotePrimaryKeyName)\" is not equal to \"_id\"")
    }
    
    /// An entity description can provide a default remote primary key.
    /// The default value is the local primary key.
    func test_RemoteEntityType_ProvidesDefaultRemotePrimaryKey() {
        let emptyEntity = entityForName("EmptyEntity")
        
        let remotePrimaryKeyName = emptyEntity.remotePrimaryKeyName
        let localPrimaryKeyName = emptyEntity.localPrimaryKeyName
        XCTAssertTrue(remotePrimaryKeyName == localPrimaryKeyName, "\"\(remotePrimaryKeyName)\" is not equal to \"\(localPrimaryKeyName)\"")
    }
    
    /// An entity description can provide a custom local primary key.
    func test_RemoteEntityType_ProvidesCustomLocalPrimaryKey() {
        let customLocalPrimaryKeyEntity = entityForName("CustomLocalPrimaryKeyEntity")
        
        let remotePrimaryKeyName = customLocalPrimaryKeyEntity.localPrimaryKeyName
        XCTAssertTrue(remotePrimaryKeyName == "customPrimaryKey", "\"\(remotePrimaryKeyName)\" is not equal to \"customPrimaryKey\"")
    }
    
    /// An entity description can provide a default local primary key.
    /// The default value is "remoteID".
    func test_RemoteEntityType_ProvidesDefaultLocalPrimaryKey() {
        let emptyEntity = entityForName("EmptyEntity")
        
        let remotePrimaryKeyName = emptyEntity.localPrimaryKeyName
        XCTAssertTrue(remotePrimaryKeyName == "remoteID", "\"\(remotePrimaryKeyName)\" is not equal to \"remoteID\"")
    }
    
    /// An entity description can inherit a local primary key from it's superentity.
    /// "CustomKeyEntity" inherits from "CustomKeyAbstractEntity", which provides
    /// remote and local primary keys.
    func test_RemoteEntityType_InheritsLocalPrimaryKey() {
        let customKeyEntity = entityForName("CustomKeyEntity")
        
        let localPrimaryKeyName = customKeyEntity.localPrimaryKeyName
        XCTAssertTrue(localPrimaryKeyName == "customPrimaryKey", "\"\(localPrimaryKeyName)\" is not equal to \"customPrimaryKey\"")
    }
    
    /// An entity description can inherit a remote primary key from it's superentity.
    /// "CustomKeyEntity" inherits from "CustomKeyAbstractEntity", which provides
    /// remote and local primary keys.
    func test_RemoteEntityType_InheritsRemotePrimaryKey() {
        let customKeyEntity = entityForName("CustomKeyEntity")
        
        let remotePrimaryKeyName = customKeyEntity.remotePrimaryKeyName
        XCTAssertTrue(remotePrimaryKeyName == "_id", "\"\(remotePrimaryKeyName)\" is not equal to \"_id\"")
    }
}
