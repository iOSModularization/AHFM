//
//  AHFMEpisode.swift
//  Pods
//
//  Created by Andy Tong on 7/21/17.
//
//

import Foundation
import AHDataModel


public struct AHFMEpisode: Equatable {
    public var id:Int = 0
    public var showId:Int = 0
    public var duration:Double?
    public var createdAt: String? = ""
    public var showTitle: String? = ""
    public var title: String? = ""
    public var detail: String? = ""
    public var audioURL: String? = ""
    public var buzzScore: Double? = 0.0
    public var showFullCover: String? = ""
    public var showThumbCover: String? = ""
    
    public static func ==(lhs: AHFMEpisode, rhs: AHFMEpisode) -> Bool {
        return lhs.id == rhs.id && lhs.showId == rhs.showId
    }
}

extension AHFMEpisode: AHDataModel {
    public static func columnInfo() -> [AHDBColumnInfo] {
        let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
        let showId = AHDBColumnInfo(name: "showId", type: .integer)
        let duration = AHDBColumnInfo(name: "duration", type: .real)
        let createdAt = AHDBColumnInfo(name: "createdAt", type: .text)
        let showTitle = AHDBColumnInfo(name: "showTitle", type: .text)
        let title = AHDBColumnInfo(name: "title", type: .text)
        let detail = AHDBColumnInfo(name: "detail", type: .text)
        let audioURL = AHDBColumnInfo(name: "audioURL", type: .text)
        let buzzScore = AHDBColumnInfo(name: "buzzScore", type: .real)
        let showFullCover = AHDBColumnInfo(name: "showFullCover", type: .text)
        let showThumbCover = AHDBColumnInfo(name: "showThumbCover", type: .text)
        
        return [id,showId,duration,createdAt,showTitle,title,detail,audioURL,buzzScore,showFullCover,showThumbCover]
    }
    
    public init(with dict: [String: Any?]){
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.buzzScore = dict["buzzScore"] as? Double
        self.duration = dict["duration"] as? Double
        self.createdAt = dict["createdAt"] as? String
        self.showTitle = dict["showTitle"] as? String
        self.title = dict["title"] as? String
        self.detail = dict["detail"] as? String
        self.audioURL = dict["audioURL"] as? String
        self.showFullCover = dict["showFullCover"] as? String
        self.showThumbCover = dict["showThumbCover"] as? String
    }
    
    public static func tableName() -> String{
        return "AHFMEpisode"
    }
    public static func databaseFilePath() -> String {
        return AHFMDatabasePath
    }
    public func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = self.id
        dict["showId"] = self.showId
        dict["buzzScore"] = self.buzzScore
        dict["duration"] = self.duration
        dict["createdAt"] = self.createdAt
        dict["showTitle"] = self.showTitle
        dict["title"] = self.title
        dict["detail"] = self.detail
        dict["audioURL"] = self.audioURL
        dict["showFullCover"] = self.showFullCover
        dict["showThumbCover"] = self.showThumbCover
        return dict
    }
}
