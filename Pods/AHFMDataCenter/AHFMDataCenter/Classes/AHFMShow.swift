//
//  AHFMAlbum.swift
//  Pods
//
//  Created by Andy Tong on 7/20/17.
//
//

import Foundation
import AHDataModel


public struct AHFMShow: Equatable {
    public var categories: [String]?
    
    public var categoryStr: String
    public var id = 0
    public var title = ""
    public var detail = ""
    public var thumbCover = ""
    public var fullCover = ""
    public var buzzScore: Double = 0.0
    //##### Belows are local managed properties
    
    // Number of episodes downloaded
    public var numberOfEpDownloaded: Int = 0
    
    // The sum size for all episodes downloaded
    public var totalFilesSize: Int = 0
    
    // Indicates whether there's a new just downloaded episode
    public var hasNewDownload = false

    
    public static func ==(lhs: AHFMShow, rhs: AHFMShow) -> Bool {
        return lhs.id == rhs.id
    }
}


extension AHFMShow: AHDataModel{
    public static func columnInfo() -> [AHDBColumnInfo] {
        let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
        let numberOfEpDownloaded = AHDBColumnInfo(name: "numberOfEpDownloaded", type: .integer)
        let totalFilesSize = AHDBColumnInfo(name: "totalFilesSize", type: .integer)
        let hasNewDownload = AHDBColumnInfo(name: "hasNewDownload", type: .integer)
        
        let categoryStr = AHDBColumnInfo(name: "categoryStr", type: .text)
        let title = AHDBColumnInfo(name: "title", type: .text)
        let detail = AHDBColumnInfo(name: "detail", type: .text)
        let thumbCover = AHDBColumnInfo(name: "thumbCover", type: .text)
        let fullCover = AHDBColumnInfo(name: "fullCover", type: .text)
        let buzzScore = AHDBColumnInfo(name: "buzzScore", type: .real)
        
        return [id,numberOfEpDownloaded,totalFilesSize,hasNewDownload,categoryStr,title,detail,thumbCover,fullCover,buzzScore]
    }
    
    public init(with dict: [String: Any?]){
        self.id = dict["id"] as! Int
        self.numberOfEpDownloaded = dict["numberOfEpDownloaded"] as? Int ?? 0
        self.totalFilesSize = dict["totalFilesSize"] as? Int ?? 0
        
        let hasNewDownload = dict["hasNewDownload"] as? Int ?? 0
        self.hasNewDownload = Bool(hasNewDownload) ?? false
        
        self.categoryStr = dict["categoryStr"] as? String ?? ""
        self.categories = categoryStr.components(separatedBy: ",")
        
        self.title = dict["title"] as! String
        self.detail = dict["detail"] as! String
        self.thumbCover = dict["thumbCover"] as! String
        self.fullCover = dict["fullCover"] as! String
        self.buzzScore = dict["buzzScore"] as! Double
    }
    
    public static func tableName() -> String{
        return "AHFMShow"
    }
    public static func databaseFilePath() -> String {
        return AHFMDatabasePath
    }
    public func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = self.id
        dict["numberOfEpDownloaded"] = self.numberOfEpDownloaded
        dict["totalFilesSize"] = self.totalFilesSize
        dict["hasNewDownload"] = self.hasNewDownload
        dict["categoryStr"] = self.categoryStr
        dict["title"] = self.title
        dict["detail"] = self.detail
        dict["thumbCover"] = self.thumbCover
        dict["fullCover"] = self.fullCover
        dict["buzzScore"] = self.buzzScore
        return dict
    }
}

