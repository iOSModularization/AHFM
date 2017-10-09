//
//  Manager.swift
//  AHFMHistoryVC
//
//  Created by Andy Tong on 10/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHFMDataCenter
import AHServiceRouter
import AHFMBottomPlayerServices
import AHFMAudioPlayerVCServices

class Manager: NSObject {
    
  
    /// Call loadHistoryEpisodes(_:)
    func hisotryVCShouldLoadHistoryEpisodes(_ vc: UIViewController){
        DispatchQueue.global().async {
            let historyEps = AHFMEpisodeHistory.queryAll().OrderBy("addedAt", isASC: false).Limit(15).run()
            var epArrDict = [[String: Any]]()
            for hisEp in historyEps {
                if let ep = AHFMEpisode.query(byPrimaryKey: hisEp.id) {
                    let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: hisEp.id)
                    let dict = self.merge(ep, epInfo: epInfo)
                    epArrDict.append(dict)
                }
            }

            DispatchQueue.main.async {
                vc.perform(Selector(("loadHistoryEpisodes:")), with: epArrDict)
            }
        }
        
    }
    
    func hisotryVC(_ vc: UIViewController, didSelectHisotryEpisode episodeID: Int, showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC:navVC)
        let info = [AHFMAudioPlayerVCServices.keyTrackId: episodeID]
        AHServiceRouter.navigateVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    func hisotryVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: !isEditing, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func hisotryVC(_ vc: UIViewController, shouldDeleteEpisodes episodes: [Int]){
        AHFMEpisodeHistory.write {
            try? AHFMEpisodeHistory.delete(byPrimaryKeys: episodes)
        }
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController){
        // do nothing
    }
}


//MARK:- Helpers
extension Manager {
    //    self.id = dict["id"] as! Int
    //    self.showId = dict["showId"] as! Int
    //    self.title = dict["title"] as! String
    //    self.showTitle = dict["showTitle"] as? String
    //    self.duration = dict["duration"] as? TimeInterval
    //    self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
    //    self.showThumbCover = dict["showThumbCover"] as? String
    
    func merge(_ ep: AHFMEpisode, epInfo: AHFMEpisodeInfo?) -> [String:Any] {
        var dict = [String: Any]()
        dict["id"] = ep.id
        dict["showId"] = ep.showId
        dict["title"] = ep.title
        dict["showTitle"] = ep.showTitle
        dict["duration"] = ep.duration
        dict["showThumbCover"] = ep.showThumbCover
        if let epInfo = epInfo {
            dict["lastPlayedTime"] = epInfo.lastPlayedTime
        }
        return dict
    }
}








