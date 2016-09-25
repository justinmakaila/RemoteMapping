import CoreData
import ISO8601


func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

public typealias JSONObject = [String: Any]

/// Represents relationships for JSON serialization
public enum RelationshipType: String {
    /// Don't include any relationship
    case none = "none"
    /// Include embedded objects
    case embedded = "embedded"
    /// Include refrences by primary key
    case reference = "reference"
}

/// To JSON methods
public extension NSManagedObject {
    /// The receiver's local primary key
    var localPrimaryKeyName: String {
        return entity.localPrimaryKeyName
    }
    
    /// The receiver's remote primary key
    var remotePrimaryKeyName: String {
        return entity.remotePrimaryKeyName
    }
    
    /// The value for `localPrimaryKeyName`.
    var primaryKey: AnyObject? {
        return value(forKey: localPrimaryKeyName) as AnyObject?
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject, as specified by the RemoteMapping implementation
    ///
    /// - Parameters:
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model, not the remote property name.
    ///
    func toJSON(_ parent: NSManagedObject? = nil, relationshipType: RelationshipType = .embedded, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        return jsonObjectForProperties(entity.remoteProperties, parent: parent, relationshipType: relationshipType, excludeKeys: excludeKeys, includeNilValues: includeNilValues)
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject representing only the changed properties, as specified by the RemoteMapping implementation
    ///
    /// - Parameters:
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model, not the remote property name.
    ///
    func toChangedJSON(_ parent: NSManagedObject? = nil, relationshipType: RelationshipType = .embedded, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        let changedPropertyKeys: Set<String> = Set(self.changedValues().keys)
        let remoteProperties = entity.remoteProperties.filter { changedPropertyKeys.contains($0.name) }
        
        return jsonObjectForProperties(remoteProperties, parent: parent, relationshipType: relationshipType, excludeKeys: excludeKeys, includeNilValues: includeNilValues)
    }
    
    /// Returns a JSON object.
    ///
    /// - Parameters:
    ///     - properties: The properties to use for serialization.
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model, not the remote property name.
    ///
    fileprivate func jsonObjectForProperties(_ properties: [NSPropertyDescription], parent: NSManagedObject? = nil, relationshipType: RelationshipType = .embedded, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        var json = JSONObject()
        
        let jsonProperties = properties.filter { !excludeKeys.contains($0.name) }
        
        /// For each property descriptions...
        for propertyDescription in jsonProperties {
            /// Get the relationship names
            let localRelationshipName = propertyDescription.name
            let remoteRelationshipName = propertyDescription.remotePropertyName
            
            /// If it's an attribute description...
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                let value = valueForAttribueDescription(attributeDescription)
                
                /// Update `json`
                if let value = value {
                    json[remoteRelationshipName] = value
                } else if includeNilValues {
                    json[remoteRelationshipName] = NSNull()
                }
                
            /// If the property is a relationship description...
            } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription , (relationshipType != .none) {
                let relationshipMappingType = relationshipDescription.relationshipMapping ?? relationshipType
                
                /// A valid relationship is one which does not go back up the relationship heirarchy...
                /// TODO: This condition could be much clearer
                let isValidRelationship = !(parent != nil && (parent?.entity == relationshipDescription.destinationEntity) && !relationshipDescription.isToMany)
                
                if isValidRelationship {
                    /// If there are relationships at `localRelationshipName`
                    if let relationshipValue = value(forKey: localRelationshipName) {
                        /// If the relationship is to a single object...
                        if let destinationObject = relationshipValue as? NSManagedObject {
                            let toOneRelationshipAttributes = jsonAttributesForToOneRelationship(destinationObject, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self, includeNilValues: includeNilValues)
                            
                            json += toOneRelationshipAttributes
                            
                        /// If the relationship is to a set of objects...
                        } else if let relationshipSet = relationshipValue as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self, includeNilValues: includeNilValues)
                            
                            json += toManyRelationshipAttributes
                            
                        /// If the relationship is to an ordered set of objects...
                        } else if let relationshipSet = (relationshipValue as? NSOrderedSet)?.set as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self, includeNilValues: includeNilValues)
                            
                            json += toManyRelationshipAttributes
                        }
                    } else if includeNilValues {
                        json += [
                            remoteRelationshipName: NSNull()
                        ]
                    }
                }
            }
        }
        
        return json
    }
    
    /// Returns the JSON attributes for a to-one relationship.
    fileprivate func jsonAttributesForToOneRelationship(_ object: NSManagedObject, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?, includeNilValues: Bool = true) -> JSONObject {
        return [
            relationshipName: jsonAttributesForObject(object, parent: parent, relationshipType: relationshipType, includeNilValues: includeNilValues)
        ]
    }
    
    /// Returns the JSON attributes for a to-many relationship.
    /// Internally maps `objects` to `jsonAttributesForObject`
    fileprivate func jsonAttributesForToManyRelationship(_ objects: Set<NSManagedObject>, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?, includeNilValues: Bool = true) -> JSONObject {
        let jsonObjects: [AnyObject] = objects.map { object in
            return jsonAttributesForObject(object, parent: parent, relationshipType: relationshipType, includeNilValues: includeNilValues)
        }
        
        return [
            relationshipName: jsonObjects
        ]
    }
    
    /// Transforms an object to JSON, using the supplied `relationshipType`.
    fileprivate func jsonAttributesForObject(_ object: NSManagedObject, parent: NSManagedObject?, relationshipType: RelationshipType, includeNilValues: Bool = true) -> AnyObject {
        switch relationshipType {
        case .embedded:
            return object.toJSON(parent, relationshipType: relationshipType, includeNilValues: includeNilValues) as AnyObject
        case .reference:
            return object.primaryKey ?? NSNull()
        default:
            return NSNull()
        }
    }
}


/// Helpers
extension NSManagedObject {
    static func reservedAttributes() -> [String] {
        return [
            "type",
            "description",
            "signed"
        ]
    }
    
    /// Returns the value for `attributeDescription` if it's `attributeType` is not a "Transformable" attribute.
    ///
    /// - Note:
    ///     All NSDate attributes are transformed to ISO-8601
    public func valueForAttribueDescription(_ attributeDescription: NSAttributeDescription) -> AnyObject? {
        var value: AnyObject?
        
        if attributeDescription.attributeType != .transformableAttributeType {
            value = self.value(forKey: attributeDescription.name) as AnyObject?
            
            if let date = value as? Date {
                value = (date as NSDate).iso8601String(with: nil, using: nil) as AnyObject?
            } else if let data = value as? Data {
                value = NSKeyedUnarchiver.unarchiveObject(with: data) as AnyObject?
            }
        }
        
        return value
    }
    
    /// Gets a `NSAttributeDescription` matching `key`, or nil.
    public func attributeDescriptionForRemoteKey(_ key: String) -> NSAttributeDescription? {
        var foundAttributeDescription: NSAttributeDescription?
        
        for (_, propertyDescription) in entity.properties.enumerated() {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                let remoteKey = attributeDescription.remotePropertyName
                
                if remoteKey == key || attributeDescription.name == key {
                    foundAttributeDescription = attributeDescription
                }
            }
        }
        
        return foundAttributeDescription
    }
    
    /// Returns a valid JSON value for the attribute description by transforming from the remote value.
    public func valueForAttributeDescription(_ attributeDescription: NSAttributeDescription, usingRemoteValue remoteValue: AnyObject) -> AnyObject? {
        var value: AnyObject?
        
        var attributeClass: AnyClass?
        if let attributeValueClass = attributeDescription.attributeValueClassName {
            attributeClass = NSClassFromString(attributeValueClass)
        }
        
        if let attributeClass = attributeClass , remoteValue.isKind(of: attributeClass) {
            value = remoteValue
        }
        
        let remoteValueIsString = remoteValue is NSString || remoteValue is String
        let remoteValueIsNumber = remoteValue is NSNumber
        
        let attributeIsNumber = attributeClass == NSNumber.self
        let attributeIsString = attributeClass == NSString.self || attributeClass == String.self
        let attributeIsDate = attributeClass == Date.self || attributeClass == NSDate.self
        let attributeIsData = attributeClass == Data.self || attributeClass == NSData.self
        let attributeIsDecimalNumber = attributeClass == NSDecimalNumber.self
        
        let stringValueAndNumberAttribute = remoteValueIsString && attributeIsNumber
        let numberValueAndStringAttribute = remoteValueIsNumber && attributeIsString
        let stringValueAndDateAttribute = remoteValueIsString && attributeIsDate
        let numberValueAndDateAttribute = remoteValueIsNumber && attributeIsDate
        let dataAttribute = attributeIsData
        let numberValueAndDecimalAttribute = remoteValueIsNumber && attributeIsDecimalNumber
        let stringValueAndDecimalAttribute = remoteValueIsString && attributeIsDecimalNumber
        
        if let remoteValue = remoteValue as? String , stringValueAndNumberAttribute {
            let numberFormatter = NumberFormatter()
            numberFormatter.locale = Locale(identifier: "en_US")
            value = numberFormatter.number(from: remoteValue)
        } else if numberValueAndStringAttribute {
            value = "\(remoteValue)" as AnyObject?
        } else if let remoteValue = remoteValue as? String, stringValueAndDateAttribute {
            value = NSDate(iso8601String: remoteValue)
        } else if let remoteValue = remoteValue as? TimeInterval, numberValueAndDateAttribute {
            value = Date(timeIntervalSince1970: remoteValue) as AnyObject?
        } else if dataAttribute {
            value = NSKeyedArchiver.archivedData(withRootObject: remoteValue) as AnyObject?
        } else if let remoteValue = remoteValue as? NSNumber , numberValueAndDecimalAttribute {
            value = NSDecimalNumber(decimal: remoteValue.decimalValue)
        } else if let remoteValue = remoteValue as? String , stringValueAndDecimalAttribute {
            value = NSDecimalNumber(string: remoteValue)
        }
        
        return value
    }
    
    func reservedKeys() -> [String] {
        return NSManagedObject.reservedAttributes()
    }
}
