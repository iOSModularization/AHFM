//
//  Manager.swift
//  AHFMDownloadList
//
//  Created by Andy Tong on 10/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHFMNetworking
import AHFMDataCenter
import SwiftyJSON
import AHFMDataTransformers
import AHServiceRouter
import AHFMDownloadCenterServices
import AHFMBottomPlayerServices


class Manager: NSObject {
    lazy var networking = AHFMNetworking()
    var showId: Int?
    
    deinit {
        networking.cancelAllRequests()
    }
    
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: false, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController){
        
    }
    
    
    func downloadListVCDidTapNavBarRightButton(_ vc: UIViewController){
        var type: AHServiceNavigationType
        if vc.navigationController != nil {
            type = .push(navVC: vc.navigationController!)
        }else{
            type = .presentWithNavVC(currentVC: vc)
        }
        
        AHServiceRouter.navigateVC(AHFMDownloadCenterServices.service, taskName: AHFMDownloadCenterServices.taskNavigation, userInfo: [:], type: type, completion: nil)
    }
    
    // info [url: fileSize]
    func downloadListVC(_ vc: UIViewController, didUpdateFileSizes info:[String:Int]){
        DispatchQueue.global().async {
            let info = info
            var infos = [AHFMEpisodeInfo]()
            for (offset: _, element: (key: url, value: fileSize)) in info.enumerated() {
                if let ep = AHFMEpisode.query("audioURL", "=", url).run().first {
                    if var info = AHFMEpisodeInfo.query(byPrimaryKey: ep.id) {
                        info.fileSize = fileSize
                        infos.append(info)
                    }else{
                        var info = AHFMEpisodeInfo(with: ["id": ep.id])
                        info.fileSize = fileSize
                        infos.append(info)
                    }
                }
            }
            AHFMEpisodeInfo.write {
                let ones = AHFMEpisodeInfo.insert(models: infos)
                if ones.count > 0 {
                    AHFMEpisodeInfo.update(models: ones)
                }
            }
        }
    }
    
    /// Tells manager to fetch data
    func downloadListVCShouldLoadData(_ vc: UIViewController){
        guard let showId = self.showId else {
            vc.perform(Selector(("reload:")), with: nil)
            return
        }
        
        let eps = AHFMEpisode.query("showId", "=", showId).OrderBy("createdAt", isASC: false).run()
        if eps.count > 0 {
            let arr = processEpisodes(eps)
            vc.perform(Selector(("reload:")), with: arr)
        }else{
            fetchEpisode(by: showId, {[weak vc] (arr) in
                /// vc might be nil at this time after networking.
                guard let vc = vc else {return}
                
                if arr == nil {
                    vc.perform(Selector(("reload:")), with: nil)
                }else{
                    AHFMEpisode.write {
                        let eps = AHFMEpisode.query("showId", "=", showId).OrderBy("createdAt", isASC: false).run()
                        if eps.count > 0 {
                            let arr = self.processEpisodes(eps)
                            DispatchQueue.main.async {
                                vc.perform(Selector(("reload:")), with: arr)
                            }
                        }
                    }
                    
                    
                }
            })
        }
        
        
        
    }
    
    func fetchEpisode(by showId: Int,_ completion: @escaping ([[String: Any]]?)->Void) {
        networking.episodes(byShowID: showId) {[weak self] (data, _) in
            guard self != nil else {return}
            
            if let data = data, let jsonEpisodes = JSON(data).array {
                let episodesDict = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                var episodes = [AHFMEpisode]()
                for epDict in episodesDict {
                    let ep = AHFMEpisode(with: epDict)
                    episodes.append(ep)
                }
                
                let arr = self?.processEpisodes(episodes)
                completion(arr)
                
                AHFMEpisode.write {
                    // returns unsuccessfully inserted ones. Try update them.
                    let ones = AHFMEpisode.insert(models: episodes)
                    if ones.count > 0 {
                        AHFMEpisode.update(models: ones)
                    }
                }
                
            }else{
                completion(nil)
            }
            
        }
    }
    
    
    func processEpisodes(_ eps: [AHFMEpisode]) -> [[String: Any]] {
        var arr = [[String: Any]]()
        for ep in eps {
            let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id)
            let epDict = mergeInfo(ep: ep, info: epInfo)
            arr.append(epDict)
        }
        return arr
    }
    
//    var id: Int
//    var fileURL: String
//    var title: String?
//    var createdAt: String?
//    var duration: TimeInterval?
//    var fileSize: Int?
//    var isDownloaded
    
    func mergeInfo(ep: AHFMEpisode, info: AHFMEpisodeInfo?) -> [String: Any] {
        var infoDict = [String: Any]()
        infoDict["id"] = ep.id
        infoDict["remoteURL"] = ep.audioURL!
        infoDict["title"] = ep.title
        infoDict["createdAt"] = ep.createdAt
        infoDict["duration"] = ep.duration
        if let info = info {
            infoDict["fileSize"] = info.fileSize
            infoDict["isDownloaded"] = info.isDownloaded
            infoDict["downloadedProgress"] = info.downloadedProgress
        }
        
        return infoDict
    }
    
    
}






