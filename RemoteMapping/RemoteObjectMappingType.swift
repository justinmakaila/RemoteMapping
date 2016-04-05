/// Represents mapping from a local object property to a remote object property
public protocol RemoteObjectMappingType {
    /// The remote property key name.
    var remotePropertyName: String { get }
    /// Whether or not the property should be ignored.
    var remoteShouldIgnore: Bool { get }
    /// The relationship mapping type to be used for a specific property
    var relationshipMapping: RelationshipType? { get }
}
