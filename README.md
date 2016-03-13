# RemoteMapping
Provides direct mapping from Core Data entities to remote properties.

This library was built in order to make serialization of objects from Core Data to remote representations and vice versa much easier.
You can map core data attributes and relationships to custom remote property names by adding a key and value to their user info dictionaries.
You can also mark properties as local/remote primary keys.

### Usage
#### Primary Keys
To set primary keys on an entity description, just update the `userInfo` of the `NSEntityDescription` in the "Data Model Inspector" in Xcode, or explicitly set the `userInfo` dictionary in code.

#### Remote Properties
To set custom remote property names, select the attribute or relationship in your `.xcdatamodeld`, and add the proper keys and values to the `userInfo` dictionary in the "Data Model Inspector".

You can ignore properties in the same way.

### Core Data Extensions
This library adds conformation of `RemoteEntityType` to `NSEntityDescription`, and `RemoteObjectMappingType` to `NSPropertyDescription`. 

All instances of `NSPropertyDescription` will return the `name` for `remotePropertyKey` by default.

All instances of `NSEntityDescrption` will return "remoteID" as the value for `remotePrimaryKeyName` and `localPrimaryKeyName` by default. There are also variables added for `remotePrimaryKey` and `localPrimaryKey`.

This also adds `remoteProperties`, `remotePropertiesByName`, and `remotePropertiesByLocalName` to `NSEntityDescription` instances, which filter `properties` by the information provided by `RemoteObjectMappingType` instances.

