//
//  Manger.swift
//  AHFMKeywordVC_Example
//
//  Created by Andy Tong on 10/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter

import AHFMDataCenter
import AHFMNetworking
import SwiftyJSON
import AHFMDataTransformers

import AHFMBottomPlayerServices
import AHFMAudioPlayerVCServices
import AHFMShowPageServices

class Manager: NSObject {
    lazy var networking = AHFMNetworking()
    
    var isSearchingForShows: Bool?
    var keyword: String?
    
    deinit {
        networking.cancelAllRequests()
    }
    
    
    func keywordVCSearchBtnTapped(_ vc: UIViewController){
        print("keywordVC should go to a searchVC")
    }
    
    func keywordVCGetInitialKeyword(_ vc: UIViewController) -> String?{
        guard let keyword = self.keyword else {
            return nil
        }
        
        return keyword
        
    }
    
    /// Call searchKeyword(_ data: [[String:Any]]?)
    func keywordVC(_ vc: UIViewController, shouldSearchForKeyword keyword: String){
        guard let isSearchingForShows = self.isSearchingForShows else {
            return
        }
        vc.perform(Selector(("willSearchKeyword:")), with: ["keyword": keyword])
        if isSearchingForShows {
            searchForShows(vc, keyword : keyword, { (data) in
                guard let dictArr = data else {
                    vc.perform(Selector(("searchKeyword:")), with: nil)
                    return
                }
                
                vc.perform(Selector(("searchKeyword:")), with: dictArr)
        
            })
        }else{
            searchForEpisodes(vc, keyword : keyword, { (data) in
                guard let dictArr = data else {
                    vc.perform(Selector(("searchKeyword:")), with: nil)
                    return
                }
                
                vc.perform(Selector(("searchKeyword:")), with: dictArr)
            })
        }
        
    }
    
    func keywordVC(_ vc: UIViewController, didTapItemWith id: Int, subId: Int){
        guard let isSearchingForShows = self.isSearchingForShows else {
            return
        }
        
        if isSearchingForShows {
            guard let navVC = vc.navigationController else {
                return
            }
            let type: AHServiceNavigationType = .push(navVC:navVC)
            let info: [String : Any] = [AHFMShowPageServices.keyShowId: id]
            AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
        }else{
            guard let navVC = vc.navigationController else {
                return
            }
            let type: AHServiceNavigationType = .push(navVC:navVC)
            let info = [AHFMAudioPlayerVCServices.keyTrackId: id]
            AHServiceRouter.navigateVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation, userInfo: info, type: type, completion: nil)
        }
        
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController) {
        
    }
}


//MARK:- Search Helpers
extension Manager {
    func searchForShows(_ vc: UIViewController, keyword: String, _ completion: @escaping (_ data : [[String:Any]]?)-> Void) {
        networking.episodesByKeyword(keyword) {[weak vc] (data, _) in
            if let data = data, let jsonEpisodes = JSON(data)["results"].array {
                let episodeDictArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                
                /// shodId could be repeated
                var showIdDict = [Int: Int]()
                
                for episodeDict in episodeDictArr {
                    if let showId = episodeDict["showId"] as? Int {
                        showIdDict[showId] = showId
                    }
                }
                
                
                var shows = [[String :Any]]()
                let group = DispatchGroup()
                for showId in showIdDict.keys {
                    group.enter()
                    DispatchQueue.global().async {[weak self] in
                        guard let _ = vc else {return}
                        guard self != nil else {return}
                        self?.fetchShow(byShowId: showId, { (show) in
                            if let show = show {
                                let showDict = self!.showToDict(show)
                                shows.append(showDict)
                            }
                            group.leave()
                        })
                    }
                }
                group.notify(queue: DispatchQueue.main, execute: {[weak self] in
                    let shows = shows
                    guard let _ = vc else {return}
                    guard self != nil else {return}
                    completion(shows)
                })
                
            }else{
                completion(nil)
            }
        }
    }
    
    func searchForEpisodes(_ vc: UIViewController, keyword: String, _ completion: @escaping (_ data : [[String:Any]]?)-> Void){
        networking.episodesByKeyword(keyword) {[weak vc,weak self] (data, _) in
            guard let _ = vc else {return}
            guard self != nil else {return}
            if let data = data, let jsonEpisodes = JSON(data)["results"].array {
                let episodeDictArr = AHFMEpisodeTransform.transformJsonEpisodes(jsonEpisodes)
                var eps = [[String: Any]]()
                for epDict in episodeDictArr {
                    let ep = AHFMEpisode(with: epDict)
                    let epInfo = self!.episodeToDict(ep)
                    eps.append(epInfo)
                }
                completion(eps)
            }else{
                completion(nil)
            }
        }
    }
}

//MARK:- Networking
extension Manager {
    fileprivate func fetchShow(byShowId showId: Int, _ completion: @escaping (_ show: AHFMShow?)->Void) {
        if let show = AHFMShow.query(byPrimaryKey: showId) {
            DispatchQueue.main.async {
                completion(show)
            }
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
                DispatchQueue.main.async {
                    completion(show)
                }
                
            }else{
                DispatchQueue.main.async {
                    completion(nil)
                }
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
}

//MARK:- Helpers
extension Manager {
//    self.id = dict["id"] as! Int
//    self.subId = dict["subId"] as? Int
//    self.title = dict["title"] as? String
//    self.detail = dict["detail"] as? String
//    self.thumbCover = dict["thumbCover"] as? String
    func showToDict(_ show: AHFMShow) -> [String: Any] {
        var info = [String: Any]()
        info["id"] = show.id
        info["thumbCover"] = show.thumbCover
        info["title"] = show.title
        info["detail"] = show.detail
//        print("\n\ninfo:\(info)\n\n")
        return info
    }
    
    func episodeToDict(_ ep: AHFMEpisode) -> [String: Any] {
        var info = [String: Any]()
        info["id"] = ep.id
        info["thumbCover"] = ep.showThumbCover
        info["title"] = ep.title
        if let detail = ep.detail {
            let headWhiteSpaces = "    "
            let c = CharacterSet.init(charactersIn: headWhiteSpaces)
            let detailA = (detail as NSString).replacingOccurrences(of: "\n", with: "")
            let detailB = (detailA as NSString).trimmingCharacters(in: c)
            info["detail"] = detailB
        }
        
        
        return info
    }
}


