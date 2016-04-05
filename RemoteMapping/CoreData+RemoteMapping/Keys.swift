import CoreData

public struct RemoteMapping {
    public enum Key: String {
        case RemotePrimaryKey = "remotePrimaryKey"
        case LocalPrimaryKey = "localPrimaryKey"
        case DefaultLocalPrimaryKey = "remoteID"
        
        case PropertyMapping = "remotePropertyName"
        case RelationshipMapping = "relationshipMapping"
        case Ignore = "remoteShouldIgnore"
    }
}
