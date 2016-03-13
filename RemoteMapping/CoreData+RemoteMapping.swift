import CoreData


enum Key: String {
    case RemotePrimaryKey = "primaryKey.remote"
    case LocalPrimaryKey = "primaryKey.local"
    case DefaultLocalPrimaryKey = "remoteID"
    
    case PropertyMapping = "remotePropertyName"
    case Ignore = "remoteShouldIgnore"
}

extension NSPropertyDescription: RemoteObjectMappingType {
    /// The remote property key.
    ///
    /// Defaults to `name`.
    public var remotePropertyKey: String {
        return userInfo?[Key.PropertyMapping.rawValue] as? String ?? name
    }
    
    /// Whether or not the property should be ignored.
    ///
    /// Checks to see if the "remoteShouldIgnore" key is
    /// present in `userInfo`. If it is, returns true.
    public var remoteShouldIgnore: Bool {
        return userInfo?[Key.Ignore.rawValue] != nil
    }
}

extension NSEntityDescription: RemoteEntityType {
    /// The remote primary key name.
    ///
    /// Defaults to `localPrimaryKeyName` if none provided.
    public var remotePrimaryKeyName: String {
        if let remotePrimaryKey = userInfo?[Key.RemotePrimaryKey.rawValue] as? String {
            return remotePrimaryKey
        }
        
        if let superentityRemotePrimaryKey = superentity?.userInfo?[Key.RemotePrimaryKey.rawValue] as? String {
            return superentityRemotePrimaryKey
        }
        
        return localPrimaryKeyName
    }
    
    /// The local primary key name.
    ///
    /// Defaults to "remoteID" if none is provided
    public var localPrimaryKeyName: String {
        if let localPrimaryKey = userInfo?[Key.LocalPrimaryKey.rawValue] as? String {
            return localPrimaryKey
        }
        
        if let superentityLocalPrimaryKey = superentity?.userInfo?[Key.LocalPrimaryKey.rawValue] as? String {
            return superentityLocalPrimaryKey
        }
        
        return Key.DefaultLocalPrimaryKey.rawValue
    }
    
    /// The value for `localPrimaryKeyName`.
    public var localPrimaryKey: AnyObject? {
        return valueForKey(localPrimaryKeyName)
    }
    
    /// The value for `remotePrimaryKeyName`.
    public var remotePrimaryKey: AnyObject? {
        return valueForKey(remotePrimaryKeyName)
    }
    
    /// `properties` filtered by `remoteShouldIgnore`.
    public var remoteProperties: [NSPropertyDescription] {
        return properties.filter { !$0.remoteShouldIgnore }
    }
    
    /// An index of remote property keys and the corresponding
    /// property description.
    public var remotePropertiesByName: [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                var properties = remotePropertiesByName
                properties[propertyDescription.remotePropertyKey] = propertyDescription
                
                return properties
            }
    }
    
    /// An index of local property names and the corresponding
    /// property description of `remoteProperties`.
    public var remotePropertiesByLocalName: [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                var properties = remotePropertiesByName
                properties[propertyDescription.name] = propertyDescription
                
                return properties
            }
    }
}
