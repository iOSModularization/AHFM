//
//  Migrator.swift
//  Pods
//
//  Created by Andy Tong on 9/24/17.
//
//

import Foundation
/// Migrator will only be passed in migrationBlock for newly added properties, just in case you want to provide more information for that particular new property.
public class Migrator {
    public let oldTableName: String
    public let newTableName: String
    public let property: String
    public let primaryKey: String
    
    var sql: String?
    
    init(oldTableName: String, newTableName: String, primaryKey: String,property: String) {
        self.oldTableName = oldTableName
        self.newTableName = newTableName
        self.primaryKey = primaryKey
        self.property = property
    }
}

extension Migrator {
    /** With provided old/new table names and currently processing property, you can run a raw customized sql.
     Example1 merge two string properties in to one:
     "UPDATE newTableName SET property = (SELECT firstName || \"-\" || lastName FROM oldTableName WHERE newTableName.id = oldTableName.id)"
     NOTE: in Sqlite3, operator '||' is the concat command in other SQL languages, e.g. MySQL.
     
     Example2 getting chat messages counts for each user for 'property':
     "UPDATE newTableName SET property = (SELECT count(*) FROM ChatMessage WHERE newTableName.id = ChatMessage.id)"
     */
    public func runRawSQL(sql: String){
        self.sql = sql
    }
    
    public func renameProperty(from oldProperty: String) {
        self.sql = "UPDATE \(newTableName) SET \(property) = (SELECT \(oldProperty) FROM \(oldTableName) WHERE \(newTableName).\(primaryKey) = \(oldTableName).\(primaryKey))"
    }
    
    /// Combine two string properties into one.
    /// NOTE: make sure two properties are actually in the old table and they are indeed 'TEXT' type.
    public func combineProperties(propertyA: String, separator: String, propertyB: String) {
        self.sql = "UPDATE \(newTableName) SET \(property) = (SELECT \(propertyA) || \"\(separator)\" || \(propertyB) FROM \(oldTableName) WHERE \(newTableName).\(primaryKey) = \(oldTableName).\(primaryKey))"
    }
    
}
