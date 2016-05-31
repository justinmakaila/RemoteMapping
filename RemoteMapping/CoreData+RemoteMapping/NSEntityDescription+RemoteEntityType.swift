import CoreData


extension NSEntityDescription: RemoteEntityType {
    /// The remote primary key name.
    ///
    /// Defaults to `localPrimaryKeyName` if none provided.
    public var remotePrimaryKeyName: String {
        let remotePrimaryKeyValue = RemoteMapping.Key.RemotePrimaryKey.rawValue
        
        if let remotePrimaryKey = userInfo?[remotePrimaryKeyValue] as? String {
            return remotePrimaryKey
        } else if let superentityRemotePrimaryKey = superentity?.remotePrimaryKeyName {
            return superentityRemotePrimaryKey
        }
        
        return localPrimaryKeyName
    }
    
    /// The local primary key name.
    ///
    /// Defaults to "remoteID" if none is provided
    public var localPrimaryKeyName: String {
        if let localPrimaryKey = userInfo?[RemoteMapping.Key.LocalPrimaryKey.rawValue] as? String {
            return localPrimaryKey
        }
        
        if let superentityLocalPrimaryKey = superentity?.userInfo?[RemoteMapping.Key.LocalPrimaryKey.rawValue] as? String {
            return superentityLocalPrimaryKey
        }
        
        /// TODO: Decide if this should provide a default or fail
        //fatalError("No local primary key was set. You must add `localPrimaryKey` to this `NSEntityDescription`s `userInfo` dictionary.")
        return RemoteMapping.Key.DefaultLocalPrimaryKey.rawValue
    }
    
    /// The properties represented on the remote.
    public var remoteProperties: [NSPropertyDescription] {
        return properties.filter { !$0.remoteShouldIgnore }
    }
    
    /// An index of remote property names and the corresponding
    /// property description.
    public func remotePropertiesByName(useLocalNames: Bool = false) -> [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                let key = (useLocalNames) ? propertyDescription.name : propertyDescription.remotePropertyName
                var properties = remotePropertiesByName
                properties[key] = propertyDescription
                
                return properties
        }
    }
    
    /// The relationships represented on the remote.
    public var remoteRelationships: [NSRelationshipDescription] {
        return remoteProperties.flatMap { $0 as? NSRelationshipDescription }
    }
    
    /// An index of remote property names and the corresponding
    /// relationship description
    public func remoteRelationshipsByName(useLocalNames: Bool = false) -> [String: NSRelationshipDescription] {
        return remoteRelationships
            .reduce([String: NSRelationshipDescription]()) { remoteRelationshipsByName, relationshipDescription in
                let key = (useLocalNames) ? relationshipDescription.name : relationshipDescription.remotePropertyName
                var relationships = remoteRelationshipsByName
                relationships[key] = relationshipDescription
                
                return relationships
        }
    }
    
    public var remoteAttributes: [NSAttributeDescription] {
        return remoteProperties.flatMap { $0 as? NSAttributeDescription }
    }
    
    public func remoteAttributesByName(useLocalNames: Bool = false) -> [String: NSAttributeDescription] {
        return remoteAttributes
            .reduce([String: NSAttributeDescription]()) { remoteAttributesByName, attributeDescription in
                let key = (useLocalNames) ? attributeDescription.name : attributeDescription.remotePropertyName
                var attributes = remoteAttributesByName
                attributes[key] = attributeDescription
                
                return attributes
            }
    }
}