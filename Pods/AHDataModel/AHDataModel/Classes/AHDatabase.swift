//
//  AHDatabase.swift
//  AHDB2
//
//  Created by Andy Tong on 6/28/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

//import CSQLite
import SQLite3

public enum AHDBDataType: String, CustomStringConvertible {
    case integer = "Integer"
    case real = "Real"
    case text = "Text"
    
    public var description: String {
        return self.rawValue
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public enum AHDBError: Error, CustomStringConvertible {
    case open(message: String)
    case preapre(message: String)
    case step(message: String)
    case bind(message: String)
    case transaction(message: String)
    case `internal`(message: String)
    case other(message: String)
    public var description: String {
        switch self {
        case .open(let message):
            return "AHDB open error: \(message)"
        case .preapre(let message):
            return "AHDB preapre error: \(message)"
        case .step(let message):
            return "AHDB step error: \(message)"
        case .bind(let message):
            return "AHDB bind error: \(message)"
        case .transaction(let message):
            return "AHDB transaction error: \(message)"
        case .internal(message: let message):
            return "AHDB internal error: \(message)"
        case .other(let message):
            return "AHDB other error: \(message)"
        }
    }
}

/// This struct stores a column's key/value and its infomations when created
internal struct AHDBAttribute: CustomStringConvertible, Equatable {
    var key: String
    var value: Any?
    var type: AHDBDataType?
    var isPrimaryKey = false
    var isForeginKey = false
    init(key: String, value: Any?, type: AHDBDataType?) {
        self.value = value
        self.type = type
        self.key = key
    }
    
    var description: String {
        return "AHDBAttribute{key: \(key) value: \(value ?? "undefined") type:\(String(describing: type)) isPrimaryKey:\(isPrimaryKey) isForeginkey:\(isForeginKey)}"
    }
    
    static func ==(lhs: AHDBAttribute, rhs: AHDBAttribute) -> Bool {
        let keysEqual = lhs.key == rhs.key
        let typeEqual = lhs.type == rhs.type
        let primaryEqual = lhs.isPrimaryKey == rhs.isPrimaryKey
        let foreginEqual = lhs.isForeginKey == rhs.isForeginKey
        if keysEqual && typeEqual && primaryEqual && foreginEqual {
            if let valueA = lhs.value, let valueB = rhs.value {
                return valuesEqual(valueA, valueB, lhs.type)
            }else if lhs.value == nil && rhs.value == nil{
                return true
            }else{
                return false
            }
            
        }else{
            return false
        }
        
    }
    
    private static func valuesEqual(_ valueA: Any, _ valueB: Any, _ type: AHDBDataType?) -> Bool {
        guard let type = type else {
            if let valueANum = valueA as? NSNumber, let valueBNum = valueB as? NSNumber{
                return valueANum == valueBNum
            }
            if let valueAStr = valueA as? String, let valueBStr = valueB as? String{
                return valueAStr == valueBStr
            }
            return false
        }
        switch type {
        case .integer, .real:
            if let valueANum = valueA as? NSNumber, let valueBNum = valueB as? NSNumber{
                return valueANum == valueBNum
            }
        case .text:
            if let valueAStr = valueA as? String, let valueBStr = valueB as? String{
                return valueAStr == valueBStr
            }
        }
        
        return false
    }
}


class AHDatabase {
    fileprivate(set) var dbPath: String?
    fileprivate static var dbArray = [String : AHDatabase]()
    
    var latestError: String {
        if let message = String(cString: sqlite3_errmsg(dbPointer), encoding: .utf8) {
            return message
        }else{
            return "No msg provided from sqlite"
        }
        
    }
    
    fileprivate var dbPointer: OpaquePointer?
    fileprivate init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        if let dbPointer = dbPointer {
            // It returns SQLITE_OK if the db is actually being terminated
            // returns SQLITE_BUSY, the db keeps open, when a prepareStmt or sqlite3_backup is unfinalized.
            sqlite3_close(dbPointer)
        }
    }
}

//MARK:- APIs
extension AHDatabase {
    
    /// One db file for one db connection!!
    static func connection(path: String) throws -> AHDatabase {
        if let db = dbArray[path] {
            return db
        }
        
        
        var dbPointer: OpaquePointer? = nil
        // SQLITE_OPEN_NOMUTEX: multi-thread mode, each connection can be used in one single thread
        // SQLITE_OPEN_FULLMUTEX: serialized mode, all operations are serialized
        if sqlite3_open_v2(path, &dbPointer, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
        // 1. open
//        if sqlite3_open(path, &dbPointer) == SQLITE_OK {
            let db = AHDatabase(dbPointer: dbPointer!)
            
            // turn on foreign_keys by default
            do {
                try db.executeSQL(sql: "PRAGMA foreign_keys = ON;", bindings: [])
            } catch _ {
                throw AHDBError.open(message: "Setting 'foreign_keys = On' failed")
            }
            
            db.dbPath = path
            dbArray[path] = db
            return db
        }else{
            // 2. a 'defer' block is called everytime a method block ends. It acts like a clean-up block.
            // Note: defer has to go before the following error-throwing code.
            defer {
                if dbPointer != nil {
                    // even the open is failed, the pointer is still needed to be close
                    sqlite3_close(dbPointer!)
                }
                if let db = dbArray[path] {
                    db.close()
                }
            }
            
            // 3. throw error for open failture
            // sqlite3_errmsg always returns the latest error message
            if let message = String(cString: sqlite3_errmsg(dbPointer), encoding: .utf8) {
                throw AHDBError.open(message: message)
            }else{
                throw AHDBError.open(message: "DB open faliture without system error message")
            }
            
            
            
        }
        
    }
    
    @discardableResult
    func turnOnForeignKey() -> Bool {
        do {
            try self.executeSQL(sql: "PRAGMA foreign_keys = ON;", bindings: [])
            return true
        } catch let error {
            print("turnOnForeignKey error:\(error)")
        }
        return false
    }
    
    @discardableResult
    func turnOffForeinKey() -> Bool {
        do {
            try self.executeSQL(sql: "PRAGMA foreign_keys = OFF;", bindings: [])
            return true
        } catch let error {
            print("turnOffForeinKey error:\(error)")
        }
        return false
    }
    
    func close() {
        if dbPointer != nil {
            sqlite3_close(dbPointer!)
            AHDatabase.dbArray.removeValue(forKey: self.dbPath!)
        }
        
    }
    
    
    func createTable(tableName: String, columns: [AHDBColumnInfo]) throws {
        guard columns.count > 0 else {
            throw AHDBError.other(message: "Columns.cout must not be zero!")
        }
        // 1. create sql statement
        let clearnTableName = cleanUpString(str: tableName)
        var createTableSql = "CREATE TABLE IF NOT EXISTS \(clearnTableName) ("
        // NOTE: Binding parameters may not be used for column or table names.
        // So here we hardcoded the table name and column names.
        // see https://www.sqlite.org/cintro.html and search 'Parameters may not be used for column or table names.'
        
        for i in 0..<columns.count {
            let columnInfo = columns[i]
            if i == (columns.count - 1) {
                createTableSql.append("\(columnInfo.bindingSql));")
            }else{
                createTableSql.append("\(columnInfo.bindingSql),")
            }
        }

        
        var stmt: OpaquePointer? = nil
        
        // 2. try, if there's an error in prepareStatement, let it throws since this method is throwing error too
        let createStmt = try prepareStatement(sql: createTableSql)
        
        
        // 3. finalize stmt everytime you finish using it
        defer {
            sqlite3_finalize(createStmt)
        }
        
        // 4. use sqlite3_step to execute the sql statement
        guard sqlite3_step(createStmt) == SQLITE_DONE else {
            throw AHDBError.step(message: latestError)
        }
        
    }
    

    
    func tableExists(tableName: String) -> Bool {
        let sql = "select 1 from sqlite_master where type='table' and name=?"
        let property = AHDBAttribute(key: "",value: tableName, type: .text)
        let binding = [property]
        
        
        do {
            let results = try query(sql: sql, bindings: binding)
            return results.count > 0
        } catch _ {
        
        }

        return false
    }
    
    /// read/write exclusively without other process or thread to read or write
    func beginExclusive() throws {
        try executeSQL(sql: "BEGIN EXCLUSIVE", bindings: [])
    }
    
    func rollback() throws {
        try executeSQL(sql: "ROLLBACK", bindings: [])
    }
    
    func commit() throws {
        try executeSQL(sql: "COMMIT", bindings: [])
    }
    
    /// bindings could be empty, i.e. []
    func insert(table:String, bindings: [AHDBAttribute]) throws {
        // INSERT INTO TABLE_NAME (column1, column2, column3,...columnN)
        // VALUES (value1, value2, value3,...valueN);
        var bindingHolders = ""
        var names = ""

        var shouldSkippedPK: AHDBAttribute?
        for i in 0..<bindings.count {
            let attribute = bindings[i]
            if attribute.isPrimaryKey && attribute.value == nil {
                // It's ok to ignore primary key and keep inserting since Sqlite will take care of it if it's a integer
                if attribute.type == .integer{
                    // remove this PK attribute, otherswise the binding would fail.
                    shouldSkippedPK = attribute
                    continue
                }else{
                    throw AHDBError.other(message: "\(table) must have at least an integer primary key")
                }
                
            }
            let name = attribute.key
            let cleanName = cleanUpString(str: name)
            
            if i == (bindings.count - 1) {
                names += "\(cleanName)"
                bindingHolders = bindingHolders + "?"
            }else{
                names += "\(cleanName), "
                bindingHolders = bindingHolders + "?, "
            }
            
        }
        
        let cleanTableName = cleanUpString(str: table)

        let sql = "INSERT INTO \(cleanTableName) (\(names)) VALUES(\(bindingHolders))"
        var bindings = bindings
        if shouldSkippedPK != nil {
            if let index = bindings.index(of: shouldSkippedPK!) {
                bindings.remove(at: index)
            }
        }
        try executeSQL(sql: sql, bindings: bindings)
        
    }
    
    /// Won't use AHDBAttribute'key. You should include attributes keys into the sql String.
    func query(sql: String, bindings: [AHDBAttribute]) throws -> [[AHDBAttribute]] {
        let stmt = try prepareStatement(sql: sql)
        
        defer {
            sqlite3_finalize(stmt)
        }
        
        try bind(stmt: stmt, bindings: bindings)
        var results = [[AHDBAttribute]]()
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            let columnCount = sqlite3_column_count(stmt)
            var singleRow = [AHDBAttribute]()
            for i in 0..<columnCount {
                
                guard let columnName = String(utf8String: sqlite3_column_name(stmt, i)) else {continue}
                
                
                let columnType = sqlite3_column_type(stmt, i)
                
                var value: Any?
                var type: AHDBDataType?
                switch columnType {
                case SQLITE_INTEGER:
                    type = .integer
                    value = Int(sqlite3_column_int(stmt, i))
                    
                case SQLITE_FLOAT:
                    type = .real
                    value = Double(sqlite3_column_double(stmt, i))
                    
                case SQLITE3_TEXT:
                    if let tempValue = sqlite3_column_text(stmt, i) {
                        type = .text
                        value = String(cString: tempValue)
                    }else{
                        throw AHDBError.other(message: "Can not extract string from database")
                    }
                    
                case SQLITE_NULL:
                    type = nil
                    value = nil
                default:
                    continue
                }
                let property = AHDBAttribute(key: columnName, value: value, type: type)
                singleRow.append(property)
            }
            results.append(singleRow)
        }
        return results
    }
    
    func delete(tableName: String, primaryKey: AHDBAttribute) throws {
        let cleanTableName = cleanUpString(str: tableName)
        let sql: String = "DELETE FROM \(cleanTableName) WHERE \(primaryKey.key) = ?"
       
        try executeSQL(sql: sql, bindings: [primaryKey])
        
    }
    
    func delete(tableName: String, conditions: [AHDBAttribute]) throws {
        guard conditions.count > 0 else {
            return
        }
        let cleanTableName = cleanUpString(str: tableName)
        var sql = "DELETE FROM \(cleanTableName) WHERE "
        
        for i in 0..<conditions.count {
            let property = conditions[i]
            
            if i == conditions.count - 1 {
                sql += "\(property.key) = ?"
            }else{
                sql += "\(property.key) = ? AND "
            }
        }

        try executeSQL(sql: sql, bindings: conditions)
        
    }
    

    func update(tableName: String, bindings: [AHDBAttribute], conditions: [AHDBAttribute]) throws {
        guard bindings.count > 0 else {
            return
        }
        let cleanTableName = cleanUpString(str: tableName)
        var sql = "UPDATE \(cleanTableName) SET "

        for i in 0..<bindings.count {
            let binding = bindings[i]
            if binding.isPrimaryKey && binding.value == nil {
                throw AHDBError.other(message: "primary must not be nil")
            }
            if i == bindings.count - 1 {
                sql += "\(binding.key) = ? "
            }else{
                sql += "\(binding.key) = ?, "
            }
        }
        sql += "WHERE "
        
        for i in 0..<conditions.count {
            let condition = conditions[i]
            if condition.isPrimaryKey && condition.value == nil {
                throw AHDBError.other(message: "primary must not be nil")
            }
            if i == bindings.count - 1 {
                sql += "\(condition.key) = ? "
            }else{
                sql += "\(condition.key) = ? AND "
            }
        }
        
        var newBindings = bindings
        newBindings.append(contentsOf: conditions)
        try executeSQL(sql: sql, bindings: newBindings)
    }
    
    func update(tableName: String, bindings: [AHDBAttribute], primaryKey: AHDBAttribute) throws {
        guard bindings.count > 0 else {
            return
        }
        let cleanTableName = cleanUpString(str: tableName)
        var sql = "UPDATE OR FAIL \(cleanTableName) SET "
        
        for i in 0..<bindings.count {
            let property = bindings[i]
            
            if i == bindings.count - 1 {
                sql += "\(property.key) = ? "
            }else{
                sql += "\(property.key) = ?, "
            }
        }
        sql += "WHERE \(primaryKey.key) = ?"
        var newBindings = bindings
        newBindings.append(primaryKey)
        try executeSQL(sql: sql, bindings: newBindings)
    }
    
    func deleteTable(name: String) throws {
        let cleanTableName = cleanUpString(str: name)
        let sql: String = "DROP TABLE IF EXISTS \(cleanTableName)"
        
        try executeSQL(sql: sql, bindings: [])
    }
    
    
    /// Binding attributes's key is not required. It only binds values to '?'.
    /// Yet, attributes's type IS required if the value is one of real, integer, text.
    /// Attributes's type could be nil when NULL value needed.
    public func executeSQL(sql: String, bindings: [AHDBAttribute]) throws{
        let stmt = try prepareStatement(sql: sql)
        
        defer {
            sqlite3_finalize(stmt)
        }
        
        try bind(stmt: stmt, bindings: bindings)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw AHDBError.step(message: latestError)
        }
    }

    
    private func bind(stmt: OpaquePointer, bindings: [AHDBAttribute]) throws {
        for i in 0..<bindings.count {
            let property = bindings[i]
            let type = property.type
            let valueRaw = property.value
            let position: Int32 = Int32(i + 1)
            
            try bindVaue(value: valueRaw, type: type, position: position, stmt: stmt)
        }
    }
    
    private func bindVaue(value: Any?, type: AHDBDataType?, position: Int32, stmt:OpaquePointer) throws {
        
        if value == nil{
            let code = sqlite3_bind_null(stmt, position)
            if code != SQLITE_OK {
                throw AHDBError.bind(message: "Binding error")
            }
            return
        }
        
        guard let type = type else {
            throw AHDBError.bind(message: "Type must not be nil if the value is not nil")
        }
        var valueRaw: Any?
        
        if let value = value as? Bool {
            valueRaw = value ? 1 : 0
        }else{
            valueRaw = value
        }
        
        switch type {
        case .integer:
            if let valueInt = valueRaw as? Int {
                if let value = Int64(exactly: valueInt) {
                    let code = sqlite3_bind_int64(stmt, position, Int64(value))
                    if code != SQLITE_OK {
                        throw AHDBError.bind(message: "Binding error")
                    }
                }
                
            }else{
                throw AHDBError.bind(message: "Type error: can't convert value to Int64")
            }
            
        case .real:
            if let value = valueRaw as? Double {
                let code = sqlite3_bind_double(stmt, position, value)
                if code != SQLITE_OK {
                    throw AHDBError.bind(message: "Binding error")
                }
            }else{
                throw AHDBError.bind(message: "Type error: can't convert value to Double")
            }
        case .text:
            if let value = valueRaw as? String {
                
                /*
                 https://stackoverflow.com/questions/1229102/when-to-use-sqlite-transient-vs-sqlite-static
                 SQLITE_TRANSIENT tells SQLite to copy your string. Use this when your string('s buffer) is going to go away before the query is executed.
                 
                 SQLITE_STATIC tells SQLite that you promise that the pointer you pass to the string will be valid until after the query is executed. Use this when your buffer is, um, static, or at least has dynamic scope that exceeds that of the binding.
                */
                let code = sqlite3_bind_text(stmt, position, value.cString(using: .utf8), -1, SQLITE_TRANSIENT)
                if code != SQLITE_OK {
                    throw AHDBError.bind(message: "Binding error")
                }
            }else{
                throw AHDBError.bind(message: "Type error: can't convert value to String")
            }
        }
    }
    
}


//MARK:- Private Methods
extension AHDatabase {
    fileprivate func cleanUpString(str: String) -> String{
        return str.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ",", with: "")
    }
    fileprivate func prepareStatement(sql: String) throws -> OpaquePointer {
        guard let dbPointer = dbPointer else {
            throw AHDBError.preapre(message: "DB is not connected")
        }
        
        var stmt: OpaquePointer? = nil
        
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw AHDBError.preapre(message: latestError)
        }
        // don't need to finalize stmt since this stmt is supposed to be used by the caller, e.g. bind or step
        return stmt!
    }
}











