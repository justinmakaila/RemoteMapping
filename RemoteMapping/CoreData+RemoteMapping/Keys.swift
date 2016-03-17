import CoreData

public struct RemoteMapping {
    public enum Key: String {
        case RemotePrimaryKey = "primaryKey.remote"
        case LocalPrimaryKey = "primaryKey.local"
        case DefaultLocalPrimaryKey = "remoteID"
        
        case PropertyMapping = "remotePropertyName"
        case Ignore = "remoteShouldIgnore"
    }
}
