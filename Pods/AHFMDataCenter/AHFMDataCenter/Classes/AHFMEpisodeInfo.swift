//
//  AHFMEpDownloadInfo.swift
//  Pods
//
//  Created by Andy Tong on 9/27/17.
//
//

import Foundation
import AHDataModel

public struct AHFMEpisodeInfo:Equatable {
    public var id:Int = 0
    
    //##### Belows are local managed properties
    
    // The size for this episode
    public var fileSize: Int?
    
    // If downloaded, this path is the audio file's path
    public var localFilePath: String?
    
    // This path for the unfinished download file
    public var unfinishedFilePath: String?
    
    // This time is the history time from last time
    public var lastPlayedTime: Double?
    
    // This progress is for download progress
    public var downloadedProgress: Double?
    
    public var isDownloaded: Bool?
    
    public static func ==(lhs: AHFMEpisodeInfo, rhs: AHFMEpisodeInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

extension AHFMEpisodeInfo: AHDataModel {
    public static func columnInfo() -> [AHDBColumnInfo] {
        let id = AHDBColumnInfo(name: "id", type: .integer, constraints: "primary key")
        let localFilePath = AHDBColumnInfo(name: "localFilePath", type: .text)
        let unfinishedFilePath = AHDBColumnInfo(name: "unfinishedFilePath", type: .text)
        let fileSize = AHDBColumnInfo(name: "fileSize", type: .integer)
        let lastPlayedTime = AHDBColumnInfo(name: "lastPlayedTime", type: .real)
        let downloadedProgress = AHDBColumnInfo(name: "downloadedProgress", type: .real)
        let isDownloaded = AHDBColumnInfo(name: "isDownloaded", type: .integer)
        
        return [id,localFilePath,unfinishedFilePath,fileSize,lastPlayedTime,downloadedProgress,isDownloaded]
    }
    
    public init(with dict: [String: Any?]){
        self.id = dict["id"] as! Int
        self.localFilePath = dict["localFilePath"] as? String
        self.unfinishedFilePath = dict["unfinishedFilePath"] as? String
        self.fileSize = dict["fileSize"] as? Int
        self.lastPlayedTime = dict["lastPlayedTime"] as? Double
        self.downloadedProgress = dict["downloadedProgress"] as? Double
        
        let isDownloaded = dict["isDownloaded"] as? Int
        self.isDownloaded = isDownloaded != nil ? Bool(isDownloaded) : nil
    }
    
    public static func tableName() -> String{
        return "AHFMEpisodeInfo"
    }
    public static func databaseFilePath() -> String {
        return AHFMDatabasePath
    }
    public func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = self.id
        dict["localFilePath"] = self.localFilePath
        dict["unfinishedFilePath"] = self.unfinishedFilePath
        dict["fileSize"] = self.fileSize
        dict["lastPlayedTime"] = self.lastPlayedTime
        dict["downloadedProgress"] = self.downloadedProgress
        dict["isDownloaded"] = self.isDownloaded
        return dict
    }
}
