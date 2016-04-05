import CoreData
import ISO8601


func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

public typealias JSONObject = [String: AnyObject]

public enum RelationshipType: String {
    /// Don't include any relationship
    case None = "none"
    /// Include embedded objects
    case Embedded = "embedded"
    /// Include refrences by primary key
    case Reference = "reference"
}

/// To JSON methods

extension NSManagedObject {
    /// The value for `localPrimaryKeyName`.
    public var localPrimaryKey: AnyObject? {
        return valueForKey(entity.localPrimaryKeyName)
    }
    
    /// The value for `remotePrimaryKeyName`.
    public var remotePrimaryKey: AnyObject? {
        return valueForKey(entity.remotePrimaryKeyName)
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject, as specified by the RemoteMapping implementation
    func toJSON(parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Embedded, excludeKeys: Set<String> = []) -> JSONObject {
        return jsonObjectForProperties(entity.remoteProperties, parent: parent, relationshipType: relationshipType)
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject representing only the changed properties, as specified by the RemoteMapping implementation
    func toChangedJSON(parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Embedded, excludeKeys: Set<String> = []) -> JSONObject {
        let changedPropertyKeys: Set<String> = Set(self.changedValues().keys)
        let remoteProperties = entity.remoteProperties.filter { changedPropertyKeys.contains($0.name) }.filter { !excludeKeys.contains($0.name) }
        
        return jsonObjectForProperties(remoteProperties, parent: parent, relationshipType: relationshipType)
    }
    
    /// TODO: It'd be really cool if `remotePropertyName` could use dot syntax to represent nested objects
    private func jsonObjectForProperties(properties: [NSPropertyDescription], parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Embedded, excludeKeys: Set<String> = []) -> JSONObject {
        var json = JSONObject()
        
        /// For each property descriptions...
        for propertyDescription in properties {
            /// If it's an attribute description...
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                /// Get the remote key and a value for the attribute description
                let remoteKey = attributeDescription.remotePropertyName
                let value = valueForAttribueDescription(attributeDescription)
                
                /// Update `json`
                json[remoteKey] = value
                
            /// If the property is a relationship description...
            } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription where (relationshipType != .None) {
                let relationshipMappingType = relationshipDescription.relationshipMapping ?? relationshipType
                
                /// A valid relationship is one which does not go back up the relationship heirarchy...
                /// TODO: This condition could be much clearer
                let isValidRelationship = !(parent != nil && (parent?.entity == relationshipDescription.destinationEntity) && !relationshipDescription.toMany)
                
                if isValidRelationship {
                    /// Get the relationship names
                    let localRelationshipName = relationshipDescription.name
                    let remoteRelationshipName = relationshipDescription.remotePropertyName
                    
                    /// If there are relationships at `localRelationshipName`
                    if let relationships = valueForKey(localRelationshipName) {
                        /// If the relationship is to a single object...
                        if let destinationObject = relationships as? NSManagedObject {
                            let toOneRelationshipAttributes = jsonAttributesForToOneRelationship(destinationObject, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self)
                            
                            json += toOneRelationshipAttributes
                            
                        /// If the relationship is to a set of objects...
                        } else if let relationshipSet = relationships as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self)
                            
                            json += toManyRelationshipAttributes
                            
                        /// If the relationship is to an ordered set of objects...
                        } else if let relationshipSet = (relationships as? NSOrderedSet)?.set as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: remoteRelationshipName, relationshipType: relationshipMappingType, parent: self)
                            
                            json += toManyRelationshipAttributes
                        }
                    }
                }
            }
        }
        
        return json
    }
    
    private func jsonAttributesForToOneRelationship(object: NSManagedObject, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?) -> JSONObject {
        return [
            relationshipName: jsonAttributesForObject(object, parent: parent, relationshipType: relationshipType)
        ]
    }
    
    private func jsonAttributesForToManyRelationship(objects: Set<NSManagedObject>, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?) -> JSONObject {
        return [
            relationshipName: objects.map { jsonAttributesForObject($0, parent: parent, relationshipType: relationshipType) }
        ]
    }
    
    private func jsonAttributesForObject(object: NSManagedObject, parent: NSManagedObject?, relationshipType: RelationshipType) -> AnyObject {
        switch relationshipType {
        case .Embedded:
            return object.toJSON(parent, relationshipType: relationshipType)
        case .Reference:
            return object.remotePrimaryKey ?? NSNull()
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
    /// !!!: All NSDate attributes are transformed to ISO-8601
    public func valueForAttribueDescription(attributeDescription: NSAttributeDescription) -> AnyObject? {
        var value: AnyObject?
        
        if attributeDescription.attributeType != .TransformableAttributeType {
            value = valueForKey(attributeDescription.name)
            
            if let date = value as? NSDate {
                value = date.ISO8601StringWithTimeZone(nil, usingCalendar: nil)
            } else if let data = value as? NSData {
                value = NSKeyedUnarchiver.unarchiveObjectWithData(data)
            }
        }
        
        return value
    }
    
    /// Gets a `NSAttributeDescription` matching `key`, or nil
    public func attributeDescriptionForRemoteKey(key: String) -> NSAttributeDescription? {
        var foundAttributeDescription: NSAttributeDescription?
        
        for (_, propertyDescription) in entity.properties.enumerate() {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                let remoteKey = attributeDescription.remotePropertyName
                
                if remoteKey == key || attributeDescription.name == key {
                    foundAttributeDescription = attributeDescription
                }
            }
        }
        
        return foundAttributeDescription
    }
    
    /// Returns the value for the attribute description, transformed from the remote value.
    public func valueForAttributeDescription(attributeDescription: NSAttributeDescription, usingRemoteValue remoteValue: AnyObject) -> AnyObject? {
        var value: AnyObject?
        
        var attributeClass: AnyClass?
        if let attributeValueClass = attributeDescription.attributeValueClassName {
            attributeClass = NSClassFromString(attributeValueClass)
        }
        
        if let attributeClass = attributeClass where remoteValue.isKindOfClass(attributeClass) {
            value = remoteValue
        }
        
        let remoteValueIsString = remoteValue is NSString
        let remoteValueIsNumber = remoteValue is NSNumber
        
        let attributeIsNumber = attributeClass == NSNumber.self
        let attributeIsString = attributeClass == NSString.self
        let attributeIsDate = attributeClass == NSDate.self
        let attributeIsData = attributeClass == NSData.self
        let attributeIsDecimalNumber = attributeClass == NSDecimalNumber.self
        
        let stringValueAndNumberAttribute = remoteValueIsString && attributeIsNumber
        let numberValueAndStringAttribute = remoteValueIsNumber && attributeIsString
        let stringValueAndDateAttribute = remoteValueIsString && attributeIsDate
        let numberValueAndDateAttribute = remoteValueIsNumber && attributeIsDate
        let dataAttribute = attributeIsData
        let numberValueAndDecimalAttribute = remoteValueIsNumber && attributeIsDecimalNumber
        let stringValueAndDecimalAttribute = remoteValueIsString && attributeIsDecimalNumber
        
        if let remoteValue = remoteValue as? String where stringValueAndNumberAttribute {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale(localeIdentifier: "en_US")
            value = numberFormatter.numberFromString(remoteValue)
        } else if numberValueAndStringAttribute {
            value = "\(remoteValue)"
        } else if let remoteValue = remoteValue as? String where stringValueAndDateAttribute {
            value = NSDate(ISO8601String: remoteValue)
        } else if let remoteValue = remoteValue as? NSTimeInterval where numberValueAndDateAttribute {
            value = NSDate(timeIntervalSince1970: remoteValue)
        } else if dataAttribute {
            value = NSKeyedArchiver.archivedDataWithRootObject(remoteValue)
        } else if let remoteValue = remoteValue as? NSNumber where numberValueAndDecimalAttribute {
            value = NSDecimalNumber(decimal: remoteValue.decimalValue)
        } else if let remoteValue = remoteValue as? String where stringValueAndDecimalAttribute {
            value = NSDecimalNumber(string: remoteValue)
        }
        
        return value
    }
    
    func reservedKeys() -> [String] {
        return NSManagedObject.reservedAttributes()
    }
}