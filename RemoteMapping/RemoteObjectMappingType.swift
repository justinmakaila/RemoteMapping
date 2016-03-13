/// Represents mapping from a local object property to a remote object property
public protocol RemoteObjectMappingType {
    /// The remote property key.
    var remotePropertyKey: String { get }
    /// Whether or not the property should be ignored.
    var remoteShouldIgnore: Bool { get }
}
