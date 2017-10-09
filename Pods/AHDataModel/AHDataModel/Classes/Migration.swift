//
//  AHMigration.swift
//  Pods
//
//  Created by Andy Tong on 9/23/17.
//
//

import Foundation
//MARK:- Migration
extension AHDataModel {
    public static func migrate(ToVersion version: Int, migrationBlock: (_ migrator: Migrator, _ newProperty: String)->Void) throws {
        guard let db = Self.db else {
            throw AHDBError.internal(message: "Internal error, database connection does not exist!")
        }
        guard db.tableExists(tableName: Self.tableName()) else {
            throw AHDBError.other(message: "Current model table does not exist!")
        }
        guard version > 0 else {
            throw AHDBError.internal(message: "Migration version must be greater than zero.")
        }
        guard let lastVersion = Self.lastVersion() else{
            throw AHDBError.internal(message: "lastVersion did get saved at installation time. Migration failed! Already rolled back")
        }
        
        if version == lastVersion {
            // already migrated!
            return
        }
        
        guard version > lastVersion else {
            throw AHDBError.internal(message: "version must be larger than lastVersion")
        }
        db.turnOffForeinKey()
        
        guard Self.beginExclusive() else {
            throw AHDBError.transaction(message: "Failed to start migration in transaction!")
        }
        
        //### 2. create table using the latest column schema
        let lastColumns = Self.unarchive(forVersion: lastVersion)
        let currentColumns = Self.columnInfo()
        guard lastColumns.count > 0 && currentColumns.count > 0 else {
            throw AHDBError.other(message: "lastColumns.count and currentColumns.count must all be non-zero!")
        }
        
        let tempTableName = "tempTableName"
        
        
        //### 3. create temp table
        try db.createTable(tableName: tempTableName, columns: currentColumns)
        
        
        //### 4. insert primary keys
        let lastPK_Attrs = lastColumns.filter { (column) -> Bool in
            return column.isPrimaryKey
        }
        
        guard let lastPK_Attr = lastPK_Attrs.first else {
            throw AHDBError.internal(message: "lastPrimaryKey doesn't exist??")
        }
        
        let currentPK_Attrs = currentColumns.filter { (column) -> Bool in
            return column.isPrimaryKey
        }
        
        guard let currentPK_Attr = currentPK_Attrs.first else {
            throw AHDBError.other(message: "new coloumnInfo() must contain a primary key!")
        }
        
        guard lastPK_Attr.name == currentPK_Attr.name else {
            throw AHDBError.other(message: "Primary key must not be changed!")
        }
        
        let primaryKeyName = currentPK_Attr.name
        
        let insertSQL = "INSERT INTO \(tempTableName) (\(primaryKeyName)) SELECT \(primaryKeyName) FROM \(Self.tableName())"
        do {
            try db.executeSQL(sql: insertSQL, bindings: [])
        } catch let error {
            Self.rollback()
            throw error
        }
        
        
        //### 5. update unchanged columns
        var unchangedColumnNames = [String]()
        var newColumnNames = [String]()
        let lastColumnNames = lastColumns.map { (column) -> String in
            return column.name
        }
        for column in currentColumns {
            if column.isPrimaryKey {
                continue
            }
            if lastColumnNames.contains(column.name) {
                unchangedColumnNames.append(column.name)
            }else{
                newColumnNames.append(column.name)
            }
        }
        
        for columnName in unchangedColumnNames {
            let updateSQL = "UPDATE \(tempTableName) SET \(columnName) = (SELECT \(columnName) FROM \(Self.tableName()) WHERE \(tempTableName).\(currentPK_Attr.name) = \(Self.tableName()).\(lastPK_Attr.name))"
            do {
                try db.executeSQL(sql: updateSQL, bindings: [])
            } catch let error {
                Self.rollback()
                throw error
            }
        }
        
        
        //### 6. update renamed and new columns one by one
        for columnName in newColumnNames {
            let migrator = Migrator(oldTableName: Self.tableName(), newTableName: tempTableName, primaryKey: primaryKeyName, property: columnName)
            migrationBlock(migrator, columnName)
            
            guard let sql = migrator.sql else {
                continue
            }
            
            do {
                try db.executeSQL(sql: sql, bindings: [])
            } catch let error {
                Self.rollback()
                throw error
            }
        }
        
        
        
        //## 7. drop old table and rename temp table
        try db.deleteTable(name: Self.tableName())
        try db.executeSQL(sql: "ALTER TABLE \(tempTableName) RENAME TO \(Self.tableName());", bindings: [])
        
        
        //## 8. save current columnInfo
        Self.archive(forVersion: version)
        
        
        //### 9. commit migration
        guard Self.commit() else {
            Self.rollback()
            throw AHDBError.transaction(message: "Commit failed during migration! Already rolled back.")
        }
        
        db.turnOnForeignKey()
    }
    
    
    /// If return nil, that means this model haven't had any migration yet
    public static func lastVersion() -> Int? {
        if let lastVersion = UserDefaults.standard.value(forKey: Self.lastVersionKey) as? Int {
            return lastVersion
        }
        return nil
    }
    
    public static func shouldMigrate() -> Bool{
        guard let lastVersion = Self.lastVersion() else{
            return false
        }
        let lastColumns = Self.unarchive(forVersion: lastVersion).sorted { (columnA, columnB) -> Bool in
            return columnA.name > columnB.name
        }
        let currentColumns = Self.columnInfo().sorted { (columnA, columnB) -> Bool in
            return columnA.name > columnB.name
        }
        
        return lastColumns != currentColumns
        
    }
    
    /// DANGER!!! WON'T BE ABLE TO MIGRATE CORRECTLY. IT'T ONLY FOR TESTING PURPOSE!
    public static func clearArchivedColumnInfo() {
        do {
            try FileManager.default.removeItem(atPath: Self.archivedColumnsPath)
            UserDefaults.standard.set(nil, forKey: Self.lastVersionKey)
        } catch _ {
            
        }
    }
    
    /// Archive current model columnInfo.
    /// version must be >= 1
    public static func archive(forVersion version: Int) {
        let columns = Self.columnInfo()
        NSKeyedArchiver.archiveRootObject([version: columns.encoded], toFile: Self.archivedColumnsPath)
        UserDefaults.standard.set(version, forKey: Self.lastVersionKey)
    }
    
    public static func unarchive(forVersion version: Int) -> [AHDBColumnInfo] {
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: Self.archivedColumnsPath) as? [Int: [AHDBColumnInfo.Coding]]
        if let columns = data?[version]?.decoded as? [AHDBColumnInfo] {
            return columns
        }else{
            return []
        }
        
        
    }
    
    
    
    
    
    /// The last version this model called archive(forVersion version: Int)
    fileprivate static var lastVersionKey: String {
        return "\(Self.tableName)_lastVersionKey"
    }
    
    /// The file path for storing column information
    fileprivate static var archivedColumnsPath: String {
        return (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("\(Self.tableName())_archivedColumns)")
    }
}
