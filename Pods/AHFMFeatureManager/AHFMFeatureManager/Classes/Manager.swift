//
//  Manager.swift
//  AHFMFeature
//
//  Created by Andy Tong on 10/7/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter

import AHFMDataCenter
import AHFMNetworking
import AHFMDataTransformers
import SwiftyJSON

import AHFMShowPageServices
import AHFMBottomPlayerServices

class Manager: NSObject {
    lazy var networking = AHFMNetworking()
    
    deinit {
        networking.cancelAllRequests()
    }
    
    
    func featureVC(_ vc: UIViewController, didTapCategoryWithShow showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        
        let type = AHServiceNavigationType.push(navVC: navVC)
        
        let info: [String : Any] = [AHFMShowPageServices.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    func featureVC(_ vc:UIViewController, bannerViewDidTappedAtIndex index: Int, forShow showId: Int, episodeId: Int) {
        guard let navVC = vc.navigationController else {
            return
        }
        
        let type = AHServiceNavigationType.push(navVC: navVC)
        
        let info: [String : Any] = [AHFMShowPageServices.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    /// Call loadShowForCategories(_ data: [String: [[String:Any]]]?)
    func featureVC(_ vc:UIViewController ,shouldLoadShowsForCategory categories: [String]){
        var dict = [String: [[String: Any]]]()
        let group = DispatchGroup()
        for category in categories {
            group.enter()
            networking.showsByCategory(category) {[weak vc] (data, _) in
                guard let _ = vc else {
                    group.leave()
                    return
                }
                var arr = [[String: Any]]()
                if let data = data, let jsonShows = JSON(data)["results"].array {
                    let showArr = AHFMShowTransform.transformJsonShows(jsonShows)
                    var shows = [AHFMShow]()
                    for showRaw in showArr {
                        let ep = AHFMShow(with: showRaw)
                        shows.append(ep)
                        
                        let showDict = self.filterShow(showRaw)
                        arr.append(showDict)
                    }
                    AHFMShow.write {
                        AHFMShow.insert(models: shows)
                    }
                    
                }
                dict[category] = arr
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) { [weak vc] in
            guard let vc = vc else {
                return
            }
            let dict = dict
            if dict.keys.count == 0 {
                vc.perform(Selector(("loadShowForCategories:")), with: nil)
            }else{
                vc.perform(Selector(("loadShowForCategories:")), with: dict)
            }
        }
    }
    
    /// Call loadBannerEpisodes(_ data: [[String:Any]]?)
    func featureVC(_ vc:UIViewController, shouldLoadBannerEpisodesWithLimit limit: Int){
        networking.trending {[weak vc] (data, _) in
            guard let vc = vc else {return}
            let limit = limit
            
            if let data = data {
                DispatchQueue.global().async {[weak vc] in
                    guard let vc = vc else {return}
                    
                    var episodeArr = [[String: Any]]()
                    if let jsonData = JSON(data).array {
                        var count = 0
                        for jsonTopic in jsonData {
                            if let jsonEps = jsonTopic["related_episodes"].array {
                                let epDictArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEps)
                                for epDict in epDictArr {
                                    count += 1
                                    let ep = self.filterEpisode(epDict)
                                    episodeArr.append(ep)
                                    if count > limit {
                                        break
                                    }
                                }
                            }
                        }
                        
                        
                    }
                    
                    DispatchQueue.main.async {
                        if episodeArr.count == 0 {
                            vc.perform(Selector(("loadBannerEpisodes:")), with: nil)
                        }else{
                            vc.perform(Selector(("loadBannerEpisodes:")), with: episodeArr)
                        }
                        
                    }
                    
                }
                
            }else{
                vc.perform(Selector(("loadBannerEpisodes:")), with: nil)
            }
        }
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController){
        
    }
}

//MARK:- Helpers
extension Manager {
//    self.id = dict["id"] as! Int
//    self.showId = dict["showId"] as! Int
//    self.title = dict["title"] as? String
//    self.fullCover = dict["fullCover"] as? String
//    self.detail = dict["detail"] as? String
    
    func filterEpisode(_ epDict: [String: Any]) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = epDict["id"] as! Int
        dict["showId"] = epDict["showId"] as! Int
        dict["title"] = epDict["title"] as? String
        dict["fullCover"] = epDict["showFullCover"] as? String
        dict["detail"] = epDict["detail"] as? String
        return dict
    }
    
    
//    self.id = dict["id"] as! Int
//    self.title = dict["title"] as? String
//    self.thumbCover = dict["thumbCover"] as? String
//    self.detail = dict["detail"] as? String
    
    func filterShow(_ showDict: [String: Any]) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = showDict["id"] as! Int
        dict["title"] = showDict["title"] as? String
        dict["thumbCover"] = showDict["thumbCover"] as? String
        dict["detail"] = showDict["detail"] as? String
        return dict
    }
    
}










