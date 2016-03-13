import CoreData


/// Represents mapping from a local object property to a remote object property
protocol RemoteObjectMappingType {
    /// The remote property key.
    var remotePropertyKey: String { get }
    /// Whether or not the property should be ignored.
    var remoteShouldIgnore: Bool { get }
}

extension NSPropertyDescription: RemoteObjectMappingType {
    /// The remote property key.
    ///
    /// Defaults to `name`.
    var remotePropertyKey: String {
        return userInfo?[Key.PropertyMapping.rawValue] as? String ?? name
    }
    
    /// Whether or not the property should be ignored.
    ///
    /// Checks to see if the "remoteShouldIgnore" key is
    /// present in `userInfo`. If it is, returns true.
    var remoteShouldIgnore: Bool {
        return userInfo?[Key.Ignore.rawValue] != nil
    }
}

extension NSEntityDescription {
    /// `properties` filtered by `remoteShouldIgnore`.
    var remoteProperties: [NSPropertyDescription] {
        return properties.filter { !$0.remoteShouldIgnore }
    }
    
    /// An index of remote property keys and the corresponding
    /// property description.
    var remotePropertiesByName: [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                var properties = remotePropertiesByName
                properties[propertyDescription.remotePropertyKey] = propertyDescription
                
                return properties
            }
    }
    
    /// An index of local property names and the corresponding
    /// property description of `remoteProperties`.
    var remotePropertiesByLocalName: [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                var properties = remotePropertiesByName
                properties[propertyDescription.name] = propertyDescription
                
                return properties
            }
    }
}
