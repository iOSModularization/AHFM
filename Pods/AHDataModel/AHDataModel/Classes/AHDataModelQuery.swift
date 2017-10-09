//
//  AHDataModelQuery.swift
//  Pods
//
//  Created by Andy Tong on 9/21/17.
//
//

import Foundation
public class AHDataModelQuery<T: AHDataModel> {
    internal(set) var sql: String
    internal var attributes = [AHDBAttribute]()
    internal var db: AHDatabase
    
    internal init(rawSQL: String, db: AHDatabase){
        self.sql = rawSQL
        self.db = db
    }
    public func AND(_ property: String, _ Operator: String, _ value: Any?) -> AHDataModelQuery{
        sql += " AND "
        let (newSql, attributes) = AHDBHelper.decodeFilter(sql, property, Operator, value)
        self.sql = newSql
        self.attributes.append(contentsOf: attributes)
        return self
    }
    
    public func OR(_ property: String, _ Operator: String, _ value: Any?) -> AHDataModelQuery{
        sql += " OR "
        let (newSql, attributes) = AHDBHelper.decodeFilter(sql, property, Operator, value)
        self.sql = newSql
        self.attributes.append(contentsOf: attributes)
        return self
    }
    
    public func OrderBy(_ property: String, isASC: Bool) -> AHDataModelQuery{
        sql += " ORDER BY \(property) \(isASC ? "ASC" : "DESC") "
        return self
    }
    
    
    public func Limit(_ amount: Int) -> AHDataModelQuery {
        sql += "LIMIT \(amount) "
        return self
    }
    
    /// Offset counting starts from Offset + 1.
    /// If there's not enough data, then returns whatever left.
    /// If offset is out of bound, returns nothing.
    public func Limit(_ amount: Int, offset: Int) -> AHDataModelQuery {
        sql += "LIMIT \(amount) OFFSET \(offset) "
        return self
    }
    
    public func run() -> [T] {
        return T.runQuery(sql: self.sql, attributes: self.attributes)
    }
}
