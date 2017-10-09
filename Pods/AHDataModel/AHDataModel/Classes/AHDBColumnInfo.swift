//
//  AHDBColumnInfo.swift
//  Pods
//
//  Created by Andy Tong on 9/21/17.
//
//

import Foundation


/// This struct describes a column's infomations when created
public struct AHDBColumnInfo: Equatable {
    var name: String
    var type: AHDBDataType
    var isPrimaryKey = false
    var isForeignKey = false
    
    /// The key the foreign key is referring to
    var referenceKey: String = ""
    /// The foregin table's name
    var referenceTable: String = ""
    
    fileprivate(set) var constraints: [String] = [String]()
    
    
    /// This init method is used to add foregin key for this table
    ///
    /// - Parameters:
    ///   - foreginKey: the foregin key's name in this table
    ///   - type: the type should be the same as the one in the foreign table
    ///   - referenceKey: the name that foreginKey is referring to in the foreign table
    ///   - referenceTable: foreign table's name
    public init(foreginKey: String, type: AHDBDataType, referenceKey: String, referenceTable: String) {
        self.name = foreginKey
        self.referenceKey = referenceKey.lowercased()
        self.referenceTable = referenceTable.lowercased()
        self.isForeignKey = true
        self.type = type
    }
    
    
    public init(name: String, type: AHDBDataType, constraints: String... ) {
        self.name = name
        self.type = type
        for constraint in constraints {
            guard constraint.characters.count > 0 else {
                continue
            }
            let lowercased = constraint.lowercased()
            if lowercased.contains("primary key") {
                isPrimaryKey = true
            }
            self.constraints.append(lowercased)
        }
    }
    
    public init(name: String, type: AHDBDataType) {
        self.name = name
        self.type = type
    }
    
    public var bindingSql: String {
        if isForeignKey {
            let constraintString = constraints.joined(separator: " ")
            return "\(name) \(type.rawValue) \(constraintString) REFERENCES \(referenceTable)(\(referenceKey)) ON UPDATE CASCADE ON DELETE CASCADE"
        }else{
            let constraintString = constraints.joined(separator: " ")
            return "\(name) \(type.rawValue) \(constraintString)"
        }
    }
    
    public static func ==(lhs: AHDBColumnInfo, rhs: AHDBColumnInfo) -> Bool {
        let b1 = lhs.name == rhs.name && lhs.type == rhs.type && lhs.isPrimaryKey == rhs.isPrimaryKey && lhs.referenceKey == rhs.referenceKey && lhs.referenceTable == rhs.referenceTable && lhs.constraints.count == rhs.constraints.count
        
        if b1 {
            for constraint in lhs.constraints {
                if rhs.constraints.contains(constraint) == false {
                    return false
                }
            }
            
            for constraint in rhs.constraints {
                if lhs.constraints.contains(constraint) == false {
                    return false
                }
            }
            return true
        }
        
        return false
    }
    
}
    
    
    



extension AHDBColumnInfo {
    @objc(_TtCV11AHDataModel14AHDBColumnInfo6Coding)internal class Coding: NSObject, NSCoding {
        let info: AHDBColumnInfo?
        
        init(info: AHDBColumnInfo) {
            self.info = info
            super.init()
        }
        //    var name: String
        //    var type: AHDBDataType
        //    var isPrimaryKey = false
        //    var isForeignKey = false
        //
        //    var referenceKey: String = ""
        //    var referenceTable: String = ""
        //
        //    private(set) var constraints: [String] = [String]()
        
        required public init?(coder aDecoder: NSCoder) {
            let name: String = aDecoder.decodeObject(forKey: "name") as! String
            let typeStr = aDecoder.decodeObject(forKey: "type") as! String
            let type: AHDBDataType = AHDBDataType(rawValue: typeStr)!
            let isPrimaryKey = aDecoder.decodeBool(forKey: "isPrimaryKey")
            let isForeignKey = aDecoder.decodeBool(forKey: "isForeignKey")
        
            let referenceKey: String = aDecoder.decodeObject(forKey: "referenceKey") as! String
            let referenceTable: String = aDecoder.decodeObject(forKey: "referenceTable") as! String
            
            let constraints: [String] = aDecoder.decodeObject(forKey: "constraints") as! [String]
            
            var info = AHDBColumnInfo(name: name, type: type)
            info.isPrimaryKey = isPrimaryKey
            info.isForeignKey = isForeignKey
            info.referenceKey = referenceKey
            info.referenceTable = referenceTable
            info.constraints = constraints
            self.info = info
            super.init()
        }
        
        internal func encode(with aCoder: NSCoder) {
            guard let info = self.info else {
                return
            }
            
            aCoder.encode(info.name, forKey: "name")
            aCoder.encode(info.type.description, forKey: "type")
            aCoder.encode(info.isPrimaryKey, forKey: "isPrimaryKey")
            aCoder.encode(info.isForeignKey, forKey: "isForeignKey")
            aCoder.encode(info.referenceKey, forKey: "referenceKey")
            aCoder.encode(info.referenceTable, forKey: "referenceTable")
            aCoder.encode(info.constraints, forKey: "constraints")
        }
        
    }
}

internal protocol Encodable {
    var encoded: Decodable? { get }
}
internal protocol Decodable {
    var decoded: Encodable? { get }
}

extension AHDBColumnInfo: Encodable {
    var encoded: Decodable? {
        return AHDBColumnInfo.Coding(info: self)
    }
}
extension AHDBColumnInfo.Coding: Decodable {
    public var decoded: Encodable? {
        return self.info
    }
}

internal extension Sequence where Iterator.Element: Encodable {
    var encoded: [Decodable] {
        return self.filter({ $0.encoded != nil }).map({ $0.encoded! })
    }
}
internal extension Sequence where Iterator.Element: Decodable {
    var decoded: [Encodable] {
        return self.filter({ $0.decoded != nil }).map({ $0.decoded! })
    }
}





