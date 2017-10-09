//
//  Manager.swift
//  AHFMShowPage
//
//  Created by Andy Tong on 10/6/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMBottomPlayerServices
import AHFMDownloadListServices
import AHFMAudioPlayerVCServices
import AHFMShowPageServices

import AHFMDataCenter
import AHFMNetworking
import AHFMDataTransformers
import SwiftyJSON




class Manager: NSObject {
    public var showId: Int?
    lazy var networking = AHFMNetworking()
    
    deinit {
        networking.cancelAllRequests()
    }
    
    /// Call localInitialShow(_ data: [String: Any]?)
    func showPageVCShouldLoadInitialShow(_ vc: UIViewController){
        guard let showId = self.showId else {
            vc.perform(Selector(("localInitialShow:")), with: nil)
            return
        }
        
        self.fetchShow(byShowId: showId) {[weak vc] (show) in
            
            if let show = show {
                let subShow = AHFMSubscribedShow.query(byPrimaryKey: showId)
                let isSubscribed = subShow != nil ? true : false
                let dict = self.mergeShowInfo(show, isSubscribedShow: isSubscribed)
                let _ = vc?.perform(Selector(("localInitialShow:")), with: dict)
            }else{
                let _ = vc?.perform(Selector(("localInitialShow:")), with: nil)
            }
            
            
        }
        
    }
    
    /// Call loadEpisodes(_ data: [[String: Any]]?)
    func showPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int){
        let eps = AHFMEpisode.query("showId", "=", showId).OrderBy("createdAt", isASC: false).run()
        if eps.count > 0{
            var dictArr = [[String:Any]]()
            for ep in eps {
                let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id)
                let dict = self.mergeEpInfo(ep: ep, epInfo: epInfo)
                dictArr.append(dict)
            }
            
            vc.perform(Selector(("loadEpisodes:")), with: dictArr)
            return
        }
        
        self.fetchEpisodes(byShowId: showId) {[weak self] (eps) in
            guard self != nil else {
                return
            }
            var dictArr = [[String:Any]]()
            for ep in eps {
                let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id)
                let dict = self!.mergeEpInfo(ep: ep, epInfo: epInfo)
                dictArr.append(dict)
            }
            
            vc.perform(Selector(("loadEpisodes:")), with: dictArr)
            return
        }
        
        
        
    }
    
    /// Call shouldLoadRecommendedShows(_ data: [[String: Any]]?)
    func showPageVC(_ vc: UIViewController, shouldLoadRecommendedShowsForShow showId: Int){
        networking.shows(byRelatedShowId: showId) {[weak vc] (data, _) in
            DispatchQueue.global().async {
                guard let vc = vc else {
                    return
                }
                if let data = data, let jsonShows = JSON(data).array {
                    let showArrDict = AHFMShowTransform.transformJsonShows(jsonShows)
                    var showIDs = [Int]()
                    for showDict in showArrDict{
                        if let id = showDict["id"] as? Int {
                            showIDs.append(id)
                        }
                    }
                    
                    
                    let group = DispatchGroup()
                    // shows with details included
                    var newShows = [AHFMShow]()
                    for showId in showIDs {
                        group.enter()
                        DispatchQueue.global().async {
                            self.fetchShow(byShowId: showId, { (show) in
                                group.leave()
                                if let show = show {
                                    newShows.append(show)
                                }
                            })
                        }
                        
                    }
                    
                    group.notify(queue: DispatchQueue.global(), execute: {[weak vc] in
                        guard let vc = vc else {
                            return
                        }
                        
                        var dictArr = [[String:Any]]()
                        for show in newShows {
                            let subShow = AHFMSubscribedShow.query(byPrimaryKey: showId)
                            let isSubscribed = subShow != nil ? true : false
                            let dict = self.mergeShowInfo(show, isSubscribedShow: isSubscribed)
                            dictArr.append(dict)
                        }
                        
                        DispatchQueue.main.async {
                            vc.perform(Selector(("shouldLoadRecommendedShows:")), with: dictArr)
                        }
                        
                    })
                    
                }else{
                    DispatchQueue.main.async {
                        vc.perform(Selector(("shouldLoadRecommendedShows:")), with: nil)
                    }
                }
            }
            
        }
    }
    
    /// Did select show's episode
    func showPageVCDidSelectEpisode(_ vc: UIViewController, show showId: Int, currentEpisode episodeId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        let info = [AHFMAudioPlayerVCServices.keyTrackId: episodeId]
        AHServiceRouter.navigateVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    /// Did select recommended show
    func showPageVCDidSelectRecommendedShow(_ vc: UIViewController, recommendedShow showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        let info = [AHFMShowPageServices.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    /// Call loadSubscribeOrUnSubcribeShow(_ data: [String:Any]?)
    /// data example: ["showId": Int, "isSubcribed": Bool]
    /// isSubcribed is the current state after this method is called.
    func showPageVC(_ vc: UIViewController, shouldSubscribeOrUnSubcribeShow showId: Int, shouldSubscribed: Bool){
        var isSubscribed = false
        if let subscribedShow = AHFMSubscribedShow.query(byPrimaryKey: showId) {
            // it's already subscribed, not unsubcribe
            isSubscribed = false
            AHFMSubscribedShow.write {
                do {
                    try AHFMSubscribedShow.delete(model: subscribedShow)
                }catch let error {
                    print("AHFMShowPageManager showPageVC(shouldSubscribeOrUnSubcribeShow) when deleting\(error)")
                }
            }
        }else{
            isSubscribed = true
            let subscribedShow = AHFMSubscribedShow(with: ["id": showId, "addedAt": Date().timeIntervalSinceReferenceDate])
            AHFMSubscribedShow.write {
                do {
                    try AHFMSubscribedShow.insert(model: subscribedShow)
                }catch let error {
                    print("AHFMShowPageManager showPageVC(shouldSubscribeOrUnSubcribeShow) when inserting\(error)")
                }
            }
        }
        
        let info: [String: Any] = ["showId": showId, "isSubcribed": isSubscribed]
        vc.perform(Selector(("loadSubscribeOrUnSubcribeShow:")), with: info)
    }
    
    /// This method should lead to some other VC page
    func showPageVCDidTappDownloadBtnTapped(_ vc: UIViewController, forshow showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        let dict = [AHFMDownloadListService.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMDownloadListService.service, taskName: AHFMDownloadListService.taskNavigation, userInfo: dict, type: .push(navVC: navVC), completion: nil)
    }
    
    func showPageVCWillPresentIntroVC(_ showVC: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: false, AHFMBottomPlayerServices.keyParentVC: showVC]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func showPageVCWillDismissIntroVC(_ showVC: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: showVC]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController){
        
    }
    
}

extension Manager {
    fileprivate func fetchShow(byShowId showId: Int, _ completion: @escaping (_ show: AHFMShow?)->Void) {
        if let show = AHFMShow.query(byPrimaryKey: showId) {
            completion(show)
            return
        }
        
        
        networking.show(byShowId: showId) { (data, _) in
            if let data = data {
                let jsonShow = JSON(data)
                let showDict = AHFMShowTransform.jsonToShow(jsonShow)
                let show = AHFMShow(with: showDict)
                
                AHFMShow.write {
                    try? AHFMShow.insert(model: show)
                }
                completion(show)
                
            }else{
                completion(nil)
            }
        }
    }
    
    fileprivate func fetchEpisodes(byShowId: Int, _ completion: @escaping (_ eps: [AHFMEpisode])->Void) {
        self.networking.episodes(byShowID: byShowId) {(data, _) in
            if let data = data, let jsonEpisodes = JSON(data).array {
                let episodeArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                var eps = [AHFMEpisode]()
                for ep in episodeArr {
                    let model = AHFMEpisode(with: ep)
                    eps.append(model)
                }
                AHFMEpisode.write {
                    AHFMEpisode.insert(models: eps)
                    DispatchQueue.main.async {
                        completion(eps)
                    }
                }
                
            }
        }
    }
    
    
    
//    self.id = dict["id"] as! Int
//    self.remoteURL = dict["remoteURL"] as! String
//    self.title = dict["title"] as? String
//    self.duration = dict["duration"] as? TimeInterval
//    self.createdAt = dict["createdAt"] as? String
//    self.downloadedProgress = dict["downloadedProgress"] as? Double
//    if let isDownloaded = dict["isDownloaded"] as? Bool
    
    func mergeEpInfo(ep: AHFMEpisode, epInfo: AHFMEpisodeInfo?) -> [String: Any] {
        var dict = [String: Any]()
        
        dict["id"] = ep.id
        dict["remoteURL"] = ep.audioURL
        dict["title"] = ep.title
        dict["duration"] = ep.duration
        dict["createdAt"] = ep.createdAt
        
        
        if let epInfo = epInfo {
            dict["downloadedProgress"] = epInfo.downloadedProgress
            dict["isDownloaded"] = epInfo.isDownloaded
        }
        return dict
    }
    
//    self.id = dict["id"] as! Int
//    self.title = dict["title"] as! String
//    self.fullCover = dict["fullCover"] as! String
//    self.thumbCover = dict["thumbCover"] as! String
//    self.detail = dict["detail"] as! String
//    self.isSubscribed = dict["isSubscribed"] as! Bool
    
    func mergeShowInfo(_ show: AHFMShow, isSubscribedShow: Bool?) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = show.id
        dict["title"] = show.title
        dict["fullCover"] = show.fullCover
        dict["thumbCover"] = show.thumbCover
        dict["detail"] = show.detail
        dict["isSubscribed"] = isSubscribedShow
        return dict
    }
}







