//
//  Manager.swift
//  AHFMEpisodeListVC
//
//  Created by Andy Tong on 10/4/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHFMDataCenter
import AHFMNetworking
import AHFMDataTransformers
import SwiftyJSON

class Manager: NSObject {
    lazy var networking = AHFMNetworking()
    public var showId: Int?
    
    deinit {
        networking.cancelAllRequests()
    }
    
    /// ["showId": 666]
    /// Call loadIntialShowid(_:)
    func AHFMEpisodeListVCShouldLoadInitialShowId(_ vc: UIViewController){
        guard let showId = showId else {
            vc.perform(Selector(("loadIntialShowid:")), with: nil)
            return
        }
        
        vc.perform(Selector(("loadIntialShowid:")), with: ["showId": showId])
        
    }
    
    
    
//    self.id = dict["id"] as! Int
//    self.title = dict["title"] as! String
//    self.fullCover = dict["fullCover"] as? String
    
    /// Call loadShow(_:)
    func AHFMEpisodeListVC(_ vc: UIViewController, shouldLoadShow showId:Int){
        if let show = AHFMShow.query(byPrimaryKey: showId) {
            var dict = [String: Any]()
            dict["id"] = show.id
            dict["title"] = show.title
            dict["fullCover"] = show.fullCover
            vc.perform(Selector(("loadShow:")), with: dict)

        }else{
            networking.show(byShowId: showId) { (data, _) in
                if let data = data {
                    let jsonShow = JSON(data)
                    let showDict = AHFMShowTransform.jsonToShow(jsonShow)
                    let show = AHFMShow(with: showDict)
                    var dict = [String: Any]()
                    dict["id"] = show.id
                    dict["title"] = show.title
                    dict["fullCover"] = show.fullCover
                    
                    AHFMShow.write {
                        do {
                            // it's ok to have failed inserted ones since they are already in the DB. And here we don't need to update any episode.
                            try AHFMShow.insert(model: show)
                            
                        }catch let error{
                            print("AHFMEpisodeListVCManager AHFMEpisodeListVC(shouldLoadShow) :\(error) ")
                        }
                    }
                    
                    vc.perform(Selector(("loadShow:")), with: dict)
                    
                }else{
                    vc.perform(Selector(("loadShow:")), with: nil)
                }
            }
        }
    }
    
    
    /// Call loadEpisode(_:episodeArr:)
    func AHFMEpisodeListVC(_ vc: UIViewController, shouldLoadEpisodes showId:Int){
        let eps = AHFMEpisode.query("showId", "=", showId).run()
        if eps.count > 0 {
            var epArr = [[String: Any]]()
            for ep in eps {
                let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: showId)
                let dict = self.merge(ep, epInfo: epInfo)
                epArr.append(dict)
            }
            
            
            vc.perform(Selector(("loadEpisodes:episodeArr:")), with: ["count":showId],with: epArr)
            
        }else{
            networking.episodes(byShowID: showId, { (data, _) in
                DispatchQueue.global().async {
                    var epArr = [[String: Any]]()
                    if let data = data, let jsonEpisodes = JSON(data).array {
                        let episodeDictArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                        var eps = [AHFMEpisode]()
                        for epDict in episodeDictArr{
                            let ep = AHFMEpisode(with: epDict)
                            eps.append(ep)
                            let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: showId)
                            let dict = self.merge(ep, epInfo: epInfo)
                            epArr.append(dict)
                        }
                        
                        AHFMEpisode.write {
                            AHFMEpisode.insert(models: eps)
                        }
                        
                    }
                    
                    
                    vc.perform(Selector(("loadEpisodes:episodeArr:")), with: ["count":showId],with: epArr)

                }
            })
        }
    }
    
    
    
    //    self.id = dict["id"] as! Int
    //    self.showId = dict["showId"] as! Int
    //    self.remoteURL = dict["remoteURL"] as! String
    //    self.title = dict["title"] as! String
    //    self.duration = dict["duration"] as? TimeInterval
    //    self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
    //    self.localFilePath = dict["localFilePath"] as? String
    //    self.isDownloaded = dict["isDownloaded"] as? Bool
    
    func merge(_ ep: AHFMEpisode, epInfo: AHFMEpisodeInfo?) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = ep.id
        dict["showId"] = ep.showId
        dict["remoteURL"] = ep.audioURL
        dict["title"] = ep.title
        dict["duration"] = ep.duration
        if let epInfo = epInfo {
            dict["lastPlayedTime"] = epInfo.lastPlayedTime
            dict["localFilePath"] = epInfo.localFilePath
            dict["isDownloaded"] = epInfo.isDownloaded
        }
        return dict
    }
    
}










