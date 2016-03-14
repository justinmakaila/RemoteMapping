import XCTest
import CoreData

@testable
import RemoteMapping


class RemoteObjectMappingTypeTests: RemoteMappingTestCase {
    var entity: NSEntityDescription!
    
    override func setUp() {
        super.setUp()
        
        self.entity = entityForName("RemoteObjectEntity")
    }
    
    /// A property description can provide custom property names.
    /// In this case, `entity` has a property named "customRemoteProperty",
    /// which provides a custom remote property name of "remoteProperty".
    func test_RemoteObjectMappingType_ProvidesCustomPropertyNames() {
        guard let customRemotePropertyDescription = entity.propertiesByName["customRemoteProperty"]
            else {
                fatalError("Could not find property")
        }
        
        let remotePropertyName = customRemotePropertyDescription.remotePropertyName
        XCTAssertTrue(remotePropertyName == "remoteProperty")
    }
    
    /// A property description can provide default property names.
    /// In this case, `entity` has a property named "defaultRemoteProperty",
    /// which equals the property description's name.
    func test_RemoteObjectMappingType_ProvidesDefaultPropertyNames() {
        guard let defaultRemotePropertyDescription = entity.propertiesByName["defaultRemoteProperty"]
            else {
                fatalError("Could not find property")
        }
        
        let remotePropertyName = defaultRemotePropertyDescription.remotePropertyName
        XCTAssertTrue(remotePropertyName == defaultRemotePropertyDescription.name)
    }
    
    /// A property description can indicate whether or not it should
    /// be ignored in a remote representation.
    /// In this case, `entity` has a property named "remoteShouldIgnore",
    /// which should not exist in a remote representation.
    func test_RemoteObjectMappingType_ProvidesIgnoredProperties() {
        guard let remoteShouldIgnorePropertyDescription = entity.propertiesByName["remoteShouldIgnore"]
            else {
                fatalError("Could not find property")
        }
        
        let shouldIgnore = remoteShouldIgnorePropertyDescription.remoteShouldIgnore
        
        XCTAssertTrue(shouldIgnore)
        XCTAssertTrue(entity.properties.count == 3)
        XCTAssertTrue(entity.remoteProperties.count == 2)
    }
}
