//
//  AHDB.swift
//  Pods
//
//  Created by Andy Tong on 9/27/17.
//
//

import Foundation

fileprivate let QueueKey = DispatchSpecificKey<Void>()
fileprivate var WriteQueue: DispatchQueue = DispatchQueue(label: "AHDataModelWriteQueue") {
    didSet {
        WriteQueue.setSpecific(key: QueueKey, value: ())
    }
}

public protocol AHDB {
    static func databaseFilePath() -> String
}
extension AHDB {
    
    internal static var db: AHDatabase? {
        let dbPath: String = Self.databaseFilePath()
        do {
            let db = try AHDatabase.connection(path: dbPath)
            return db
        }catch _ {
            return nil
        }
    }
    
    public static func write(_ writeBlock: @escaping ()->Void) {
        WriteQueue.async {
            writeBlock()
        }
    }
    
    /// Should the DB check if all write operations are in a safe write queue.
    /// Default is true
    public static var shouldCheckWriteQueue: Bool {
        get {
            return Helper.shouldCheckWriteQueue
        }
        
        set {
            Helper.shouldCheckWriteQueue = newValue
        }
    }
    
    /// Any struct/class can call this method to do transaction, regardless what model it is, what models will be involved in the transaction and what thread it is -- it is a 'beginExclusive' global Sqlite transaction.
    @discardableResult
    public static func transaction(_ tasks: () throws ->Void) rethrows -> Bool {
        guard let db = Self.db else {
            fatalError("Internal error, database connection does not exist!")
        }
        
        guard beginExclusive() else {
            return false
        }
        
        
        try tasks()
        
        guard commit() else {
            do {
                try db.rollback()
            } catch let error {
                print("rollback error after commit failed:\(error)")
            }
            return false
        }
        
        return true
    }
    
    /// read/write exclusively without other process or thread to read or write
    @discardableResult
    public static func beginExclusive() -> Bool {
        guard let db = Self.db else {
            fatalError("Internal error, database connection does not exist!")
        }
        
        do {
            try db.beginExclusive()
            return true
        } catch let error {
            print("beginExclusive error:\(error)")
        }
        return false
    }
    
    @discardableResult
    public static func rollback() -> Bool {
        guard let db = Self.db else {
            fatalError("Internal error, database connection does not exist!")
        }
        
        do {
            try db.rollback()
            return true
        } catch let error {
            print("rollback error:\(error)")
        }
        return false
    }
    
    @discardableResult
    public static func commit() -> Bool {
        guard let db = Self.db else {
            fatalError("Internal error, database connection does not exist!")
        }
        
        do {
            try db.commit()
            return true
        } catch let error {
            print("commit error:\(error)")
        }
        return false
    }
}

extension AHDataModel {
    static func checkWriteQueue() {
        guard Self.shouldCheckWriteQueue else {
            return
        }
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(WriteQueue))
        } else if DispatchQueue.getSpecific(key: QueueKey) == nil{
            precondition(false, "You should put all your write operations in the provided write queue by using Self.write(){}")
        }
    }
}


struct Helper {
    static var shouldCheckWriteQueue = true
}

