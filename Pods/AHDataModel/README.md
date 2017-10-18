# AHDataModel
If you like SQLite then this wrapper is for you!
It abstacts enough details away from tedious SQL related works, yet remains flexible and open to customization.

## Content
- [Modeling](#modeling)
- [Examples](#examples)
- [Query](#query)
- [Write Operations](#write-operations)
- [Insert](#insert)
- [Update](#update)
- [Delete](#delete)
- [Transaction](#transaction)
- [Migration](#migration)
- [Adding and/or Deleting a Property](#adding-andor-deleting-a-property)
- [Renaming a Property](#renaming-a-property)
- [Combining Two Sting Properties](#combining-two-sting-properties)
- [Extend Migrator for Advanced Usages](#extend-migrator-for-advanced-usages)


### Modeling
(This might be a bit complex. Be patient, good stuff will get to you soon!)
AHDataModel has minimum of 5 methods needed to be implemented for your models:
```Swift
#### Three Core Methods
/// In method, you need to privide necessary column(or property) infomations.
static func columnInfo() -> [AHDBColumnInfo]

/// Core method, it's for AHDataModel to create models when data being queried from a SQLite database.
init(with dict: [String: Any])

/// Core method, it's for saving model's datas into database.
/// You can intentionally ignore some properties in here by not assigning a key-value pair to the returning dict.
func toDict() -> [String: Any]
###

/// The table name for this model
static func tableName() -> String

/// Database file path
static func databaseFilePath() -> String
```

What AHDataModel protocol really cares about are those informations provided by the three core methods mentioned above.
Make sure you correctly handle:
```Swift
init(with dict: [String: Any?])
func toDict() -> [String: Any]
```
and also the informations produced by those two methods match the infomations you provide in
```Swift
static func columnInfo() -> [AHDBColumnInfo]
```
then everything is going to be fine.

#### Examples
The following example is for models that have non-nil properties. The codes seems long, but they really don't have anything complicated. You can easily read through them quickly:)
NOTE: Every model must have a primary key!
Will show you the case when a model indeed doesn't have anything to do with a primary key later.
```Swift
struct User: Equatable {
var id: Int
var firstName: String
var lastName: String
var age: Int
var isVIP: Bool
/// Optional properties can be nil then being inserted or updated into database with NULL value.
/// Don't specify it as 'NOT NULL' in columnInfo's contraint.
var balance: Double?

/// If we want this property to have nothing to do with the database, we simplely just ignore it in the protocol methods.
var position: String = "PM"

/// Like normal struct, you use an initializer to create it, you can insert it into the database later.
public init(id: Int, firstName: String, lastName: String, age: Int, isVIP: Bool, balance: Double?) {
self.id = id
self.firstName = firstName
self.lastName = lastName
self.age = age
self.isVIP = isVIP
self.balance = balance
}



/// Here we assume the id is unique and will be our primary key
public static func ==(lhs: User, rhs: User) -> Bool {
return lhs.id == rhs.id
}
}

/// Imlement AHDataModel protocol
extension User: AHDataModel {
/// Core method, handling data coming from database
init(with dict: [String : Any?]) {
self.id = dict["id"] as! Int
self.firstName = dict["firstName"] as! String
self.lastName = dict["lastName"] as! String
self.age = dict["age"] as! Int
/// NOTE: You have to use Bool() to convert an integer to boolean value.
/// See columnInfo() for how to define boolean property.
self.isVIP = Bool(dict["isVIP"])!
/// Even though 'balance' is optional, we can ignore it in any of the three core methods.
self.balance = dict["balance"] as? Double
}

/// There are 3 types for columns(or properties): text(or String), real(or Double), integer(or Int).
/// NOTE: Every model must have a primary key!
/// Will show you the case when a model indeed doesn't have anything to do with a primary key later.
static func columnInfo() -> [AHDBColumnInfo] {
/// add constraint terms as you use SQLite before.
let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
let firstName = AHDBColumnInfo(name: "firstName", type: .text, constraints: "not null")
let lastName = AHDBColumnInfo(name: "lastName", type: .text)
let age = AHDBColumnInfo(name: "age", type: .integer)

/// Since SQLite can't represent a boolean value in the database, you use integer instead.
let isVIP = AHDBColumnInfo(name: "isVIP", type: .integer)
/// Even though 'balance' is optional, we can ignore it in any of the three core methods.
let balance = AHDBColumnInfo(name: "balance", type: .real)

return [id,firstName,lastName,age,isVIP,balance]
}
/// This method is for converting the Swift Struct model into a dict data so that AHDataModel can manipulate it in database level.
func toDict() -> [String : Any] {
var dict = [String: Any]()
dict["id"] = self.id
dict["firstName"] = self.firstName
dict["lastName"] = self.lastName
dict["age"] = self.age
/// Don't need to convert the boolean value to integer.
dict["isVIP"] = self.isVIP
/// Even though 'balance' is optional, we can ignore it in any of the three core methods.
dict["balance"] = self.balance
return dict
}

/// Use the struct's name as the table name
static func tableName() -> String {
return "\(self)"
}
/// Return a path in the cache directory
static func databaseFilePath() -> String {
return (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("db.sqlte")
}

}
```
Let's use the User model right now.
```Swift
/// Every model has a write closure for globel transaction. All write operations have to be executed in a write closure.
/// NOTE: currently there's no difference for which model's write closure to use. They all share the same queue. If you want, you can use some other model's write closure, but not recommended.
/// More info described in the 'Write' section later.
/// That's why the operations in the write block is like a exclusive transaction in database level, not table level.
User.write {
let user1 = User(id: 42, firstName: "Michael", lastName: "Jackson", age: 29, isVIP: true, balance: nil)
/// insert user1 with a nil balance.
try! User.insert(model: user1)

var user1_copy = User.query(byPrimaryKey: 42)!
if user1_copy.balance == nil {
print("balance is nil")
}
user1_copy.balance = 9999999.0
try! User.update(model: user1_copy)

// reassign value to user1_copy
user1_copy = User.query(byPrimaryKey: 42)!
if user1_copy.balance != nil {
print("balance is not nil")
}
}
```


#### Now let create a chat message model which has only 3 main properties: text, userId, addedAt. But since every model must have a primary key. We'll have to give it a 'id' property, but we just put it there.
```Swift
/// Remember to implement Equatable for a struct, always!
struct Chat: Equatable {
/// Since we don't are about primary key for a chat message. We only query them by their userId. So we give it an optional so that we don't have to put it in the initializer, or in this case, use Swift's implicit struct initializer.
var id: Int?
var text: String
var userId: Int

/// This is a custom initializer, NOT the AHDataModel's core init method!!
/// It's for the convenience to create them.
init(text: String, userId: Int) {
self.text = text
self.userId = userId
}

public static func ==(lhs: Chat, rhs: Chat) -> Bool {
return lhs.text == rhs.text && lhs.userId == rhs.userId
}
}

/// AHDataModel implementaion
extension Chat: AHDataModel {
init(with dict: [String : Any]) {
/// Though we will not be using the id property, but we still have to put it there!!
/// It will be treated as an implicit primary key(rowid) in SQLite.
self.id = dict["id"] as? Int
self.text = dict["text"] as! String
self.userId = dict["userId"] as! Int
}

static func columnInfo() -> [AHDBColumnInfo] {
/// Though we will not be using the id property, but we still have to put it there!!
/// It will be treated as an implicit primary key(rowid) in SQLite.
let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
let text = AHDBColumnInfo(name: "text", type: .text)

/// NOTE: Since userId here is a foregin key, when the corresponding user gets deleted, the related chats would be deleted too.
let userId = AHDBColumnInfo(foreginKey: "userId", type: .integer, referenceKey: "id", referenceTable: "\(User.tableName())")
return [id,text,userId]
}

func toDict() -> [String : Any] {
var dict = [String: Any]()
/// Again:
/// Though we will not be using the id property, but we still have to put it there!!
/// It will be treated as an implicit primary key(rowid) in SQLite.
dict["id"] = self.id
dict["text"] = self.text
dict["userId"] = self.userId
return dict
}
static func databaseFilePath() -> String {
return (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("db.sqlte")
}

static func tableName() -> String {
return "\(self)"
}
}
```
We now use the Chat model along with the User model.
```Swift
let chat1 = ChatModel(text: "There's a place ... chat_1", userId: 42)
let chat2 = ChatModel(text: "in your heart ... chat_2", userId: 42)
let chat3 = ChatModel(text: "and I know that ... chat_3", userId: 42)
let chat4 = ChatModel(text: "it is ... chat_4", userId: 42)
let chat5 = ChatModel(text: "love ... chat_5", userId: 42)

/// If all the insertions succeeded, the batch insert method would return 0 count.
/// If one of them failed, the method would return the unsuccessfully inserted ones.
let count = ChatModel.insert(models: [chat1,chat2,chat3,chat4,chat5])
if count == 0 {
print("batch insert succeeded!")
}
/// query chats for userId = 12
/// We don't need the id primary key at all. But we still have to put it there:)
var chats = ChatModel.query("userId", "=", 12).run()
```
#### That's it for the modeling!
If you need more examples about modeling, you can clone or download this repository, there's an example project which contains several sample models and also lots of tests. You can learn from them too!

Additionally, ![AHFMDataCenter](https://github.com/iOSModularization/AHFMDataCenter/tree/master/AHFMDataCenter/Classes) have some demonstration models for splitting a data model.
For example, anything that comes from your server stores in one model. Hopefully they are not too many, otherwise you neeed to categorize them and put them into different models.
And you shuld categorize those local managed properties into different models too, e.g. PlayerItemDownloadInfo for storing download progress and its local file path.

### Query
Query is easy. Read through the following examples, you'll be good to go.
```Swift
let chats = ChatModel.query("userId", "=", 55).OrderBy("userId", isASC: true).run()

/// Don't need to .run()
let dog = Dog.query(byPrimaryKey: 11)

var masters = Master.query("age", "IS NOT", nil).run()
masters.aster.query("age", "IS", nil).run()
masters = Master.query("age", "IN", [33,66,88]).run()

masters = Master.queryAll().OrderBy("id", isASC: false).Limit(2).run()
masters = Master.queryAll().OrderBy("id", isASC: false).Limit(3, offset: 2).run()
masters = Master.query("name", "LIKE", "fun%").AND("age", "<=", "77").AND("score", ">", 65).OrderBy("score", isASC: false).run()
```

### Write Operations
All write operations must be executed within a write closure, including insert, update and delete.

#### Insert
Insert operation will only succeed when there's no duplicate record in the database with the same primary key.
Two insert methods:
```Swift
/// Single insertion, throws
public static func insert(model: Self) throws

/// Batch insertion, return those unsuccessfully inserted ones.
/// NOTE: This method surpresses exceptions!!
public static func insert(models: [Self]) -> [Self]
```
Example:
```Swift
let dog1 = Dog(masterId: master.id, name: "dog_1", age: 12)
let dog2 = Dog(masterId: master.id, name: "dog_2", age: 12)
let dog3 = Dog(masterId: master.id, name: "dog_3", age: 12)
/// this could be Master.write{}, but you are doing things related to Dog, why use Master? Though both closure are identical.
Dog.write{
/// Return value can be ignored
let ones = Dog.insert(models: [dog1,dog2,dog3])

if ones.count == 0 {
// all of the models are successfully inserted
}else{
// there's at least one model failed to be inserted, which most of the time, due to duplication.
// you can do updates here to make sure that old values to be overridden, if needed.
}
}

```

#### Update
Update operation will only succeed when there's already a record with the same primary key.
Four update methods:
```Swift
public static func update(model: Self) throws

/// Return those unsuccessfully updated ones.
/// NOTE: This method surpresses exceptions!!
public static func update(models: [Self]) -> [Self]

/// Update specific properties of this model into the database
/// Note: This will override existing values.
public static func update(model: Self, forProperties properties: [String]) throws

/// Update specific properties of this model into the database
/// Note1: This will override existing values.
/// Note2: You can't set a property to nil for now since dict cannot contain nil value. Use the model method to set a property to nil if you already have one.
public static func update(byPrimaryKey primaryKey: Any, forProperties properties: [String : Any]) throws
```
The first two update methods are like the two insert methods -- insert or update singly or in batch with exception thrown or returning failed models.

The last two are for updating specific properties, or partial updating.
For 'update(model: Self, forProperties properties: [String]) throws', you at least need a model which could be just created or from a query.
And you assign some new values for the properties then you use this method to update, partially.
You might ask, why not use the second update method?
The reason is that, sometimes you just want to update some properties then quickly switch to do something else, untill some point, you have already collected all the info and now you can do a full update.

For the last update method, you don't need a model in advance, you just need to know the value of the primary key and the key-value pairs you need to update.
The short shortcoming of this method is that, it can't update a property to nil since the key-value dict doesn't allow containing a nil value. So in this case, use the previous update method(query the model first).

```Swift
Dog.write {
/// assumeing the name of the dog is the primary key
var dog42 = Dog.query(byPrimaryKey: 42)!
dog42.age = 99
dog42.masterId = 122
try! Dog.update(model: dog42, forProperties: ["masterId", "age"])

try! Dog.update(byPrimaryKey: 42, forProperties: ["masterId": 122, "age": 99])
}
```



#### Delete
Five methods for deletion
```Swift
public static func delete(model: Self) throws

/// Return unsuccessfully deleted ones.
public static func delete(models: [Self]) -> [Self]

public static func delete(byPrimaryKey primaryKey: Any) throws

/// Returns unsuccessfully deleted primary keys
public static func delete(byPrimaryKeys primaryKeys: [Any]) -> [Any]

/// Internally, it will drop the table containing the data model
public static func deleteAll() throws
```
They are pretty much self-explanatory.
Example is not provided. You can checkout the example project's tests to learn more.

### Transaction
The AHDataModel's transaction functionality is from its super protocol AHDB.
If you want a in depth usage, you can checkout AHDB protocol.
In general, all models' .write{} closure method satisfy most of the situations.
```Swift
Dog.write {
// do stuff here
}
```

Again, that closure method is not related to any model. You just need a model to call .write{}.
You can even conform AHDB with any struct or class and call the .write{} from there.

This .write{} method is actually a 'fake' transaction. It's not a database transaction which has rollback and some other fancy stuff.
What the method does here is the closure you created when call the method, is being dispatched asynchronously to a built-in queue and executed the codes over there. Since all write operations are forced to use .write{}, so all your data queried within the closure, are guaranteed to be atomic.
Some might say, all the write operations are in one queue, would it become a performance problem?
NO! You are building an iOS MOBILE application, not a backend server. You shouldn't write too many data, too much at once, for example, querying 1000 records into the memory at once and use them in a tableView. NO!



### Migration
#### Adding and/or Deleting a Property
AHDataModel implements a semi-auto migration process -- you don't need to do anything if you just merely delete or add columns(properties) without using any previous data.
For example, if a Dog model has a masterId at initial version, it's zero. Then you decide to free all the dogs and delete all masterId related info in Dog model. The only thing you need to do in this case is:
```Swift
/// Do the migration within 'application didFinishLaunchingWithOptions'
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
/// Specify the toVersion to 1, since the initial version by default is 0.
try! Dog.migrate(toVersion: 1, migrationBlock: { (migrator, newProperty) in
// do nothing here
})
}

```
The same code applied to adding a property.
NOTE: Remember to delete or add the properties in the model struct(or class),
AND modified AHDataModel's three core methods:
'columnInfo() -> [AHDBColumnInfo]'
'init(with dict: [String: Any?])'
'toDict() -> [String: Any]'

#### Process Legacy Data While Migrating
In this case, mostly adding a property, you want to do something with the legacy data, e.g. aggregating some numbers to form a value for a new property, combining 'firstName', 'lastName' into a 'fullName' property.

##### Renaming a Property
```Swift
/// Migrate property name 'sex' to 'gender'
try! User.migrate(ToVersion: 1, migrationBlock: { (migrator, newProperty) in
/// Check the newProperty is actually the one you want to do something about it
if newProperty == "gender" {
/// Using migrator's built-in method to do the work
migrator.renameProperty(from: "sex")
}

})
```

##### Combining Two Sting Properties
```Swift
/// if the 'firstName' is "Michael", 'lastName' is "Jackson", then the newProperty 'fullName' will be "Jackson, Micheal"
try! User.migrate(toVersion: 1) { (migrator, newProperty) in
if newProperty == "fullName" {
/// the separator is the one between propertyA and propertyB
migrator.combineProperties(propertyA: "lastName", separator: ", ", propertyB: "firstName")
}

}
```

##### Extend Migrator for Advanced Usages
As shown aboved, most of the migrating works are done by using the migrator's built-in methods.
So what if you want to do custom works during migration? Extend Migrator.
The Migrator has 4 properties:
```Swift
public let oldTableName: String
public let tempTableName: String
/// This is the newProperty name, the same property name as the one passed in the migration closure paramter shown previously.
public let property: String
public let primaryKey: String
```
Now let's say, we want to add a 'msgCount' property for the User model. And this 'msgCount' is the count of all the chats with userId = user.id.
Here's the raw SQL:
```SQL
-- tempTableName is the intermediate table's name for migrating. It will be changed to the original table' name later.
"UPDATE tempTableName SET 'msgCount' = (SELECT count(*) FROM Chat WHERE tempTableName.id = Chat.userId)"
```
In Swift:
```Swift
extension Migrator {
func aggreateMsgCount(chatTableName: String, chatPrimaryKeyName: String) {
/// NOTE: the new property name is self.property
let sql = "UPDATE \(self.tempTableName) SET \(self.property) = (SELECT count(*) FROM \(chatTableName) WHERE \(chatTableName).\(chatPrimaryKeyName) = \(self.tempTableName).\(self.primaryKey))"
migrator.runRawSQL(sql: sql)
}
}

/// Then use the extension method
try! User.migrate(toVersion: 1) { (migrator, newProperty) in
/// NOTE: newProperty == migrator.property
if newProperty == "msgCount" {
migrator.aggreateMsgCount(chatTableName: "Chat", chatPrimaryKeyname: "userId")
}

}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
You can learn more from the tests in the project.
Additionally, some sample models from ![AHFMDataCenter](https://github.com/iOSModularization/AHFMDataCenter/tree/master/AHFMDataCenter/Classes)

## Requirements

## Installation

AHDataModel is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AHDataModel'
```

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHDataModel is available under the MIT license. See the LICENSE file for more info.

