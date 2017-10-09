//
//  Manager.swift
//  AHFMBottomPlayer
//
//  Created by Andy Tong on 10/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter
import AHFMDataCenter
import AHFMNetworking
import SwiftyJSON
import AHFMDataTransformers
import AHFMEpisodeListVCServices
import AHFMAudioPlayerVCServices
import AHFMHistoryVCServices

class Manager: NSObject {
    static let shared = Manager()
    lazy var networking = AHFMNetworking()
    
    deinit {
        networking.cancelAllRequests()
    }
    
    
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController, didTapListBarForShow showId:Int){
        
        var type: AHServiceNavigationType
        type = .present(currentVC: parentVC)
        
        
        AHServiceRouter.navigateVC(AHFMEpisodeListVCServices.service, taskName: AHFMEpisodeListVCServices.taskNavigation, userInfo: [AHFMEpisodeListVCServices.keyShowId : showId], type: type, completion: nil)
        
        vc.setValue(false, forKey: "shouldShowPlayer")
    }
    
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController,didTapHistoryBtnForShow showId:Int){
        guard let navVC = parentVC.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        
        AHServiceRouter.navigateVC(AHFMHistoryVCServices.service, taskName: AHFMHistoryVCServices.taskNavigation, userInfo: [:], type: type, completion: nil)
    }
    
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController,didTapInsideWithForShow showId:Int, episodeID: Int){
        guard let navVC = parentVC.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        let info = [AHFMAudioPlayerVCServices.keyTrackId: episodeID]
        AHServiceRouter.navigateVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    /// Call loadShow(_:)
    /// parameter = [String:Any]
    func bottomPlayerLoadShow(_ vc: UIViewController, parentVC: UIViewController, showId: Int){
        if let show = AHFMShow.query(byPrimaryKey: showId) {
            var dict = [String: Any]()
            dict["id"] = show.id
            dict["title"] = show.title
            dict["fullCover"] = show.fullCover
            vc.perform(Selector(("loadShow:")), with: dict)
            
        }else{
            self.requestShow(by: showId, { (dict) in
                if let dict = dict {
                    vc.perform(Selector(("loadShow:")), with: dict)
                }else{
                    vc.perform(Selector(("loadShow:")), with: nil)
                }
            })
        }
    }
    
    /// Call loadEpisode(_:)
    /// parameter = [String:Any]
    func bottomPlayerLoadEpisode(_ vc: UIViewController, parentVC: UIViewController, episodeId: Int){
        if let ep = AHFMEpisode.query(byPrimaryKey: episodeId) {
            let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: episodeId)
            let dict = self.merge(ep, epInfo: epInfo)
            vc.perform(Selector(("loadEpisode:")), with: dict)
            
        }else{
            self.requestEpisode(by: episodeId, { (dict) in
                vc.perform(Selector(("loadEpisode:")), with: dict)
            })
        }
    }
    
    /// Call loadLastPlayedEpisode(_:), pass both episode and its show within a dict parameter.
    /// parameter = ["episode": [String:Any], "show": [String:Any]]
    func bottomPlayerLoadLastPlayedEpisode(_ vc: UIViewController, parentVC: UIViewController){
        let epHistoryArr = AHFMEpisodeHistory.queryAll().OrderBy("addedAt", isASC: false).Limit(1).run()
        if epHistoryArr.count > 0, let epHistory = epHistoryArr.first {
            let epId = epHistory.id
            if let ep = AHFMEpisode.query(byPrimaryKey: epId) {
                let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id)
                let epDict = self.merge(ep, epInfo: epInfo)
                self.getShow(ep.showId, epDict: epDict, { (data) in
                    guard let data = data else {
                        vc.perform(Selector(("loadLastPlayedEpisode:")), with: nil)
                        return
                    }
                    vc.perform(Selector(("loadLastPlayedEpisode:")), with: data)
                })
            }else{
                self.requestEpisode(by: epId, { (dict) in
                    guard let dict = dict else {
                        vc.perform(Selector(("loadLastPlayedEpisode:")), with: nil)
                        return
                    }
                    let showID = dict["showId"] as! Int
                    
                    self.getShow(showID, epDict: dict, { (data) in
                        guard let data = data else {
                            vc.perform(Selector(("loadLastPlayedEpisode:")), with: nil)
                            return
                        }
                        vc.perform(Selector(("loadLastPlayedEpisode:")), with: data)
                    })
                })
            }
            
        }else{
            vc.perform(Selector(("loadLastPlayedEpisode:")), with: nil)
        }
    }
}


//MARK:- Helpers
extension Manager {
    func getShow(_ showID:Int,epDict: [String:Any], _ completion: @escaping (_ data: [String:Any]?)->Void) {
        if let show = AHFMShow.query(byPrimaryKey: showID) {
            var showDict = [String: Any]()
            showDict["id"] = show.id
            showDict["title"] = show.title
            showDict["fullCover"] = show.fullCover
            
            let data = ["episode": epDict, "show": showDict]
            completion(data)
            
        }else{
            self.requestShow(by: showID, { (dict) in
                if let showDict = dict {
                    
                    let data = ["episode": epDict, "show": showDict]
                    completion(data)
                }else{
                    completion(nil)
                }
            })
        }
    }
    
    func requestShow(by showID: Int, _ completion: @escaping (_ dict:[String:Any]?)->Void) {
        networking.show(byShowId: showID) { (data, _) in
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
                        print("AHFMBottomPlayer bottomPlayerLoadShow(showId) :\(error) ")
                    }
                }
                
                completion(dict)
                
            }else{
                completion(nil)
            }
        }
    }
    
    func requestEpisode(by episdoeID: Int, _ completion: @escaping (_ dict:[String:Any]?)->Void) {
        networking.episode(byEpisodeId: episdoeID, { (data, _) in
            if let data = data {
                let jsonEpisode = JSON(data)
                if let episodeDict = AHFMEpisodeTransform.jsonToEpisode(jsonEpisode) {
                    let ep = AHFMEpisode(with: episodeDict)
                    let dict = self.merge(ep, epInfo: nil)
                    completion(dict)
                    return
                }
            }
            completion(nil)
        })
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












