import CoreData
import ISO8601


func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

public typealias JSONObject = [String: AnyObject]

public enum RelationshipType: Int {
    case None
    case Array
}

/// To JSON methods

public extension NSManagedObject {
    /// Serializes a `NSManagedObject` to a JSONObject, as specified by the RemoteMapping implementation
    func toJSON(parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Array) -> JSONObject {
        return jsonObjectForProperties(entity.remoteProperties, parent: parent, relationshipType: relationshipType)
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject representing only the changed properties, as specified by the RemoteMapping implementation
    func toChangedJSON(parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Array) -> JSONObject {
        let changedPropertyKeys: Set<String> = Set(self.changedValues().keys)
        let remoteProperties = entity.remoteProperties.filter { changedPropertyKeys.contains($0.name) }
        
        return jsonObjectForProperties(remoteProperties, parent: parent, relationshipType: relationshipType)
    }
    
    /// TODO: It'd be really cool if `remotePropertyName` could use dot syntax to represent nested objects
    private func jsonObjectForProperties(properties: [NSPropertyDescription], parent: NSManagedObject? = nil, relationshipType: RelationshipType = .Array) -> JSONObject {
        var json = JSONObject()
        
        for propertyDescription in properties {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                let remoteKey = attributeDescription.remotePropertyName
                let value = valueForAttribueDescription(attributeDescription)
                
                json[remoteKey] = value
            } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription where (relationshipType != .None) {
                let isValidRelationship = !(parent != nil && (parent?.entity == relationshipDescription.destinationEntity) && !relationshipDescription.toMany)
                
                if isValidRelationship {
                    let relationshipName = relationshipDescription.remotePropertyName
                    if let relationships = valueForKey(relationshipName) {
                        if let destinationObject = relationships as? NSManagedObject {
                            let toOneRelationshipAttributes = jsonAttributesForToOneRelationship(destinationObject, relationshipName: relationshipName, relationshipType: relationshipType, parent: self)
                            
                            json += toOneRelationshipAttributes
                        } else if let relationshipSet = relationships as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: relationshipName, relationshipType: relationshipType, parent: self)
                            
                            json += toManyRelationshipAttributes
                        } else if let relationshipSet = (relationships as? NSOrderedSet)?.set as? Set<NSManagedObject> {
                            let toManyRelationshipAttributes = jsonAttributesForToManyRelationship(relationshipSet, relationshipName: relationshipName, relationshipType: relationshipType, parent: self)
                            
                            json += toManyRelationshipAttributes
                        }
                    }
                }
            }
        }
        
        return json
    }
    
    private func jsonAttributesForToOneRelationship(object: NSManagedObject, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?) -> JSONObject {
        var relationshipAttributes = JSONObject()
        let attributes = object.toJSON(parent, relationshipType: relationshipType)
        
        relationshipAttributes[relationshipName] = attributes
        
        return relationshipAttributes
    }
    
    private func jsonAttributesForToManyRelationship(objects: Set<NSManagedObject>, relationshipName: String, relationshipType: RelationshipType, parent: NSManagedObject?) -> JSONObject {
        var relationshipAttributes = JSONObject()
        var relationshipArray: [JSONObject] = []
        for object in objects {
            let attributes = object.toJSON(parent, relationshipType: relationshipType)
            
            if attributes.count > 0 {
                relationshipArray.append(attributes)
            }
        }
        
        relationshipAttributes[relationshipName] = relationshipArray
        
        return relationshipAttributes
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