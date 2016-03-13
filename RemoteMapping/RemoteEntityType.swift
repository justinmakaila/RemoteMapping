import CoreData


/// Represents an entity and it's primary keys
protocol RemoteEntityType {
    /// The remote primary key name.
    var remotePrimaryKeyName: String { get }
    /// The local primary key name.
    var localPrimaryKeyName: String { get }
}

enum Key: String {
    case RemotePrimaryKey = "primaryKey.remote"
    case LocalPrimaryKey = "primaryKey.local"
    case DefaultLocalPrimaryKey = "remoteID"
    
    case PropertyMapping = "remotePropertyName"
    case Ignore = "remoteShouldIgnore"
}

extension NSEntityDescription: RemoteEntityType {
    /// The remote primary key name.
    ///
    /// Defaults to `localPrimaryKeyName` if none provided.
    var remotePrimaryKeyName: String {
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
    var localPrimaryKeyName: String {
        if let localPrimaryKey = userInfo?[Key.LocalPrimaryKey.rawValue] as? String {
            return localPrimaryKey
        }
        
        if let superentityLocalPrimaryKey = superentity?.userInfo?[Key.LocalPrimaryKey.rawValue] as? String {
            return superentityLocalPrimaryKey
        }
        
        return Key.DefaultLocalPrimaryKey.rawValue
    }
    
    /// The value for `localPrimaryKeyName`.
    var localPrimaryKey: AnyObject? {
        return valueForKey(localPrimaryKeyName)
    }
    
    /// The value for `remotePrimaryKeyName`.
    var remotePrimaryKey: AnyObject? {
        return valueForKey(remotePrimaryKeyName)
    }
}