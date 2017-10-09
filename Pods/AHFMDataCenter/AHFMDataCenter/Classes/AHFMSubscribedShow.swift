//
//  AHFMSubscribeShowObject.swift
//  Pods
//
//  Created by Andy Tong on 8/16/17.
//
//

import Foundation
import AHDataModel

public struct AHFMSubscribedShow {
    public var id: Int = 0
    public var addedAt: Double = 0
}
extension AHFMSubscribedShow: AHDataModel {
    public static func columnInfo() -> [AHDBColumnInfo] {
        let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
        let addedAt = AHDBColumnInfo(name: "addedAt", type: .real)
        return [id,addedAt]
    }
    
    public init(with dict: [String: Any?]){
        self.id = dict["id"] as! Int
        self.addedAt = dict["addedAt"] as! Double
    }
    
    public static func tableName() -> String{
        return "AHFMSubscribedShow"
    }
    public static func databaseFilePath() -> String {
        return AHFMDatabasePath
    }
    public func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = self.id
        dict["addedAt"] = self.addedAt
        return dict
    }
}
