//
//  AHFMAudioPlayerVCServices.swift
//  AHFMAudioPlayerVC
//
//  Created by Andy Tong on 9/29/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMDataTransformers
import AHFMNetworking
import AHFMDataCenter
import SwiftyJSON

import AHServiceRouter
import AHFMBottomPlayerServices
import AHFMEpisodeListVCServices
import AHFMShowPageServices


public class AHFMManagerHandler: NSObject {
    
    var initialTrackId: Int?
    
    
    /// episodes for the this show, will be cached.
    lazy var episodes = [AHFMEpisode]()
    
    lazy var networking = AHFMNetworking()
    
    
    func viewWillAppear(_ vc: UIViewController) {
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: false, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController) {
        
    }
    
    func audioPlayerVCListBarTapped(_ vc: UIViewController, trackId: Int, albumnId: Int){
        var type: AHServiceNavigationType
        type = .present(currentVC: vc)
        
        
        AHServiceRouter.navigateVC(AHFMEpisodeListVCServices.service, taskName: AHFMEpisodeListVCServices.taskNavigation, userInfo: [AHFMEpisodeListVCServices.keyShowId : albumnId], type: type, completion: nil)
        
    }
    func audioPlayerVCAlbumnCoverTapped(_ vc: UIViewController, atIndex index:Int, trackId: Int, albumnId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        let info: [String : Any] = [AHFMShowPageServices.keyShowId: albumnId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    /// When the data is ready, call reload()
    func audioPlayerVCFetchInitialTrack(_ vc: UIViewController){
        guard let id = initialTrackId else {
            return
        }
        
        self.getEpisodeAndPerform(vc, trackId: id)
        
    }
    func audioPlayerVCFetchTrack(_ vc: UIViewController, trackId: Int){
        self.getEpisodeAndPerform(vc, trackId: trackId)
    }
    func audioPlayerVCFetchNextTrack(_ vc: UIViewController, trackId: Int, albumnId: Int){
        handleNextOrPrevious(vc, trackId: trackId, albumnId: albumnId, shouldGetNext: true)
    }
    func audioPlayerVCFetchPreviousTrack(_ vc: UIViewController, trackId: Int, albumnId: Int){
        handleNextOrPrevious(vc, trackId: trackId, albumnId: albumnId, shouldGetNext: false)
    }
    
    deinit {
        networking.cancelAllRequests()
    }
    
}

extension AHFMManagerHandler {
    func handleNextOrPrevious(_ vc: UIViewController,trackId: Int, albumnId:Int,shouldGetNext: Bool) {
        if self.episodes.count > 0{
            var ep: AHFMEpisode?
            if shouldGetNext {
                ep = self.getNext(trackId, self.episodes)
            }else{
                ep = self.getPrevious(trackId, self.episodes)
            }
            self.getEpisodeAndPerform(vc, trackId: ep?.id ?? nil)
            return
        }
        
        
        let eps = AHFMEpisode.query("showId", "=", albumnId).OrderBy("createdAt", isASC: true).run()
        self.episodes.append(contentsOf: eps)
        if eps.count > 0{
            
            var ep: AHFMEpisode?
            if shouldGetNext {
                ep = self.getNext(trackId, self.episodes)
            }else{
                ep = self.getPrevious(trackId, self.episodes)
            }
            self.getEpisodeAndPerform(vc, trackId: ep?.id ?? nil)
            
        }else{
            // should have already fetched eps at intial load.
            self.getEpisodeAndPerform(vc, trackId: nil)
        }
        
        
    }
    
    func getNext(_ currentEpisodeId: Int, _ eps: [AHFMEpisode]) -> AHFMEpisode? {
        let ep = eps.filter { (ep) -> Bool in
            return ep.id == currentEpisodeId
            }.first
        
        guard let currentEp = ep else {
            return nil
        }
        
        guard let index = eps.index(of: currentEp) else {
            return nil
        }
        
        guard index >= 0 && index < eps.count - 1 else {
            return nil
        }
        
        return eps[index + 1]
    }
    
    func getPrevious(_ currentEpisodeId: Int, _ eps: [AHFMEpisode]) -> AHFMEpisode? {
        let ep = eps.filter { (ep) -> Bool in
            return ep.id == currentEpisodeId
            }.first
        
        guard let currentEp = ep else {
            return nil
        }
        
        guard let index = eps.index(of: currentEp) else {
            return nil
        }
        
        guard index > 0 && index < eps.count else {
            return nil
        }
        
        return eps[index - 1]
    }
    
    /// If trackId is nil, it means there's an error in the way of fetching it.
    /// So we need to notify the vc by passing a nil to its selector.
    func getEpisodeAndPerform(_ vc:UIViewController,trackId: Int?){
        guard let trackId = trackId else {
            vc.perform(Selector(("reload:")), with: nil)
            return
        }
        
        if let ep = AHFMEpisode.query(byPrimaryKey: trackId) {
            let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: trackId)
            let dict = mergeInfo(ep: ep, epInfo: epInfo)
            
            
            if self.episodes.count == 0{
                let eps = AHFMEpisode.query("showId", "=", ep.showId).OrderBy("createdAt", isASC: true).run()
                self.episodes.append(contentsOf: eps)
            }
            vc.perform(Selector(("reload:")), with: dict)
        }else{
            networking.episode(byEpisodeId: trackId, {[weak self] (data, _) in
                guard self != nil else {return}
                
                if let data = data {
                    let epJson = JSON(data)
                    if let epDict = AHFMEpisodeTransform.jsonToEpisode(epJson) {
                        let ep = AHFMEpisode(with: epDict)
                        let eps = AHFMEpisode.query("showId", "=", ep.showId).run()
                        
                        /// no eps in the DB, fetch now.
                        if eps.count == 0 {
                            self?.fetchEpisodes(byShowId: ep.showId, {
                                DispatchQueue.main.async {
                                    if self?.episodes.index(of: ep) == nil {
                                        self?.episodes.append(ep)
                                        AHFMEpisode.write {
                                            try? AHFMEpisode.insert(model: ep)
                                        }
                                    }
                                    let eps = self?.episodes.sorted(by: { (ep1, ep2) -> Bool in
                                        if ep1.createdAt == nil {
                                            return false
                                        }
                                        if ep2.createdAt == nil {
                                            return true
                                        }
                                        return ep1.createdAt! > ep2.createdAt!
                                    })
                                    
                                    if eps != nil {
                                        self?.episodes = eps!
                                    }
                                    
                                    // since there's no ep before saving it, there's no epInfo in the DB for sure.
                                    let dict = self?.mergeInfo(ep: ep, epInfo: nil) ?? nil
                                    vc.perform(Selector(("reload:")), with: dict)
                                }
                            })
                        }else{
                            
                            DispatchQueue.main.async {
                                // since there's no ep before saving it, there's no epInfo in the DB for sure.
                                let dict = self?.mergeInfo(ep: ep, epInfo: nil) ?? nil
                                vc.perform(Selector(("reload:")), with: dict)
                                return
                            }
                        }
                        
                    }
                }
                vc.perform(Selector(("reload:")), with: nil)
            })
        }
    }
    
    
    fileprivate func fetchEpisodes(byShowId: Int, _ completion: @escaping ()->Void) {
        self.networking.episodes(byShowID: byShowId) {[weak self] (data, _) in
            if let data = data, let jsonEpisodes = JSON(data).array {
                let episodeArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                var eps = [AHFMEpisode]()
                for ep in episodeArr {
                    let model = AHFMEpisode(with: ep)
                    eps.append(model)
                }
                if self?.episodes.count == 0 {
                    self?.episodes.append(contentsOf: eps)
                }
                AHFMEpisode.write {
                    AHFMEpisode.insert(models: eps)
                }
                
            }
            completion()
        }
    }
    

    /// AHFMEpisode doesn't have lastPlayedTime property and AHFMEpisodeInfo has it.
    func mergeInfo(ep: AHFMEpisode, epInfo: AHFMEpisodeInfo?) -> [String: Any] {
        var dict = [String: Any]()
        
        dict["albumnId"] = ep.showId
        dict["trackId"] = ep.id
        dict["audioURL"] = ep.audioURL
        dict["fullCover"] = ep.showFullCover
        dict["thumbCover"] = ep.showThumbCover
        dict["albumnTitle"] = ep.showTitle
        dict["trackTitle"] = ep.title
        dict["duration"] = ep.duration
        
        if let epInfo = epInfo {
            dict["lastPlayedTime"] = epInfo.lastPlayedTime
            dict["localFilePath"] = epInfo.localFilePath
        }
        return dict
    }
}
