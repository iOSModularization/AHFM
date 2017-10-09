//
//  Manager.swift
//  AHFMUserCenter_Example
//
//  Created by Andy Tong on 10/7/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMDataCenter

import AHFMBottomPlayerServices
import AHFMShowPageServices
import AHFMHistoryVCServices
import AHFMDownloadCenterServices

class Manager: NSObject {
    
    /// Call loadNumberOfSubscriptions(_ data: ["number": Any])
    func userCenterLoadNumberOfSubscriptions(_ vc: UIViewController){
        let subShows = AHFMSubscribedShow.queryAll().run()
        vc.perform(Selector(("loadNumberOfSubscriptions:")), with: ["number": subShows.count])
    }
    
    /// Call loadNumbberOfDownloads(_ data: ["number": Any])
    func userCenterLoadNumberOfDownloadedEpisodes(_ vc: UIViewController){
        DispatchQueue.global().async {
            let shows = AHFMShow.query("numberOfEpDownloaded", ">", 0).run()
            var count = 0
            for show in shows {
                count += show.numberOfEpDownloaded
            }
            DispatchQueue.main.async {
                vc.perform(Selector(("loadNumbberOfDownloads:")), with: ["number": count])
            }
        }
    }
    
    /// Call loadLastPlayedEpisode(_ data: [String: Any]?)
    func userCenterLoadLastPlayedEpisode(_ vc: UIViewController){
        let epHistoryArr = AHFMEpisodeHistory.queryAll().OrderBy("addedAt", isASC: false).Limit(1).run()
        if epHistoryArr.count > 0,
            let epHistory = epHistoryArr.first,
            let ep = AHFMEpisode.query(byPrimaryKey: epHistory.id) {
            let epDict = self.episodeToDict(ep)
            vc.perform(Selector(("loadLastPlayedEpisode:")), with: epDict)
        
        }else{
            vc.perform(Selector(("loadLastPlayedEpisode:")), with: nil)
        }
    }
    
    func userCenterDidSelectDownloadSection(_ vc: UIViewController){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC: navVC)
        
        AHServiceRouter.navigateVC(AHFMDownloadCenterServices.service, taskName: AHFMDownloadCenterServices.taskNavigation, userInfo: [:], type: type, completion: nil)
    }
    
    func userCenterDidSelectHistorySection(_ vc: UIViewController){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        
        AHServiceRouter.navigateVC(AHFMHistoryVCServices.service, taskName: AHFMHistoryVCServices.taskNavigation, userInfo: [:], type: type, completion: nil)
    }
    
    func userCenter(_ vc: UIViewController, didSelectSubscribedShow showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        
        let type = AHServiceNavigationType.push(navVC: navVC)
        
        let info: [String : Any] = [AHFMShowPageServices.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    func subscriptionVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: !isEditing, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    /// Call loadSubcribedShows(_ data: [[String: Any]]?)
    func subscriptionVCShouldLoadSubcribedShows(_ vc: UIViewController){
        DispatchQueue.global().async {
            var shows = [[String: Any]]()
            let subShows = AHFMSubscribedShow.queryAll().OrderBy("addedAt", isASC: false).run()
            for subShow in subShows {
                if let show = AHFMShow.query(byPrimaryKey: subShow.id) {
                    let showDict = self.showToDict(show)
                    shows.append(showDict)
                }
            }
            DispatchQueue.main.async {
                if shows.count == 0 {
                    vc.perform(Selector(("loadSubcribedShows:")), with: nil)
                }else{
                    vc.perform(Selector(("loadSubcribedShows:")), with: shows)
                }
            }
        }
    }
    
    func subscriptionVC(_ vc: UIViewController, shouldUnsubcribedShows showIDs: [Int]){
        AHFMSubscribedShow.write {
            var shows = [AHFMSubscribedShow]()
            for showId in showIDs {
                if let subscribedShow = AHFMSubscribedShow.query(byPrimaryKey: showId) {
                    shows.append(subscribedShow)
                }
            }
            try? AHFMSubscribedShow.delete(models: shows)
        }
        
    }
    
    func subscriptionVCWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func subscriptionVCWillDisappear(_ vc: UIViewController){
        
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
//    self.title = dict["title"] as? String
//    self.detail = dict["detail"] as? String
//    self.thumbCover = dict["thumbCover"] as? String
    func showToDict(_ show: AHFMShow) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = show.id
        dict["title"] = show.title
        dict["detail"] = show.detail
        dict["thumbCover"] = show.thumbCover
        return dict
    }
    
    
    
    
//    self.id = dict["id"] as! Int
//    self.showId = dict["showId"] as! Int
//    self.title = dict["title"] as? String
    func episodeToDict(_ ep: AHFMEpisode) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = ep.id
        dict["showId"] = ep.showId
        dict["title"] = ep.title
        return dict
    }
    
    
}










