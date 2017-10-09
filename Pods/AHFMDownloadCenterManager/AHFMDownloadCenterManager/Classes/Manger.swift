//
//  Manger.swift
//  AHFMDownloadCenter
//
//  Created by Andy Tong on 10/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHFMDataCenter
import AHFMNetworking
import AHFMDataTransformers
import AHFMDownloadListServices
import AHFMAudioPlayerVCServices
import AHFMBottomPlayerServices
import AHFMShowPageServices
import AHServiceRouter
import AHDownloadTool


class Manager: NSObject {
    lazy var netwroking = AHFMNetworking()
    
    deinit {
        netwroking.cancelAllRequests()
    }
    
}

//MARK:- From downloadCenter itslef
extension Manager {
    /// Call loadTotalNumbOfTasks:
    func downloadCenter(_ vc: UIViewController, shouldCountTaskWithCurrentTasks urls: [String]) {
        DispatchQueue.global().async {
            var count = 0
            let urls = urls
            let epInfoArr = AHFMEpisodeInfo.query("downloadedProgress", ">", 0.0).AND("downloadedProgress", "<", 100.0).run()
            for epInfo in epInfoArr {
                if urls.count > 0 {
                    let eps = AHFMEpisode.query("id", "=", epInfo.id).AND("audioURL", "NOT IN", urls).run()
                    if eps.count > 0, let _ = eps.first {
                        count += 1
                    }
                }else{
                    count += 1
                }
            }
            count += urls.count
            DispatchQueue.main.async {
                vc.perform(Selector(("loadTotalNumbOfTasks:")), with: ["count": count])
            }
        }
    }
}

//MARK:- From downloadedVC and showPage
extension Manager {
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int){

        DispatchQueue.global().async {
            let eps = AHFMEpisode.query("showId", "=", showId).run()
            var arrDict = [[String: Any]]()
            if eps.count > 0 {
                for ep in eps {
                    let epInfos = AHFMEpisodeInfo.query("id", "=", ep.id).AND("downloadedProgress", "=", 100.0).run()
                    if let epInfo = epInfos.first {
                        let dict = self.merge(ep: ep, epInfo: epInfo)
                        arrDict.append(dict)
                    }
                    
                }
            }
            DispatchQueue.main.async {
                vc.perform(Selector(("loadEpisodesForShow:episodeArr:")), with: showId, with: arrDict)
            }
        }
        
    }
    
    func downloadedVCShowPage(_ vc: UIViewController, didSelectShow showId: Int){
        guard let navVC = vc.navigationController else {
            return
        }
        
        let type = AHServiceNavigationType.push(navVC: navVC)
        
        let info: [String : Any] = [AHFMShowPageServices.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    func downloadedVCShowPage(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int){
        var type: AHServiceNavigationType
        if vc.navigationController != nil {
            type = .push(navVC: vc.navigationController!)
        }else{
            type = .presentWithNavVC(currentVC: vc)
        }
        AHServiceRouter.navigateVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation, userInfo: [AHFMAudioPlayerVCServices.keyTrackId: episodeId], type: type, completion: nil)
    }
    
    func downloadedVCShowPage(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int){
        // go to AHFMDownloadList
        
        var type: AHServiceNavigationType
        if vc.navigationController != nil {
            type = .push(navVC: vc.navigationController!)
        }else{
            type = .presentWithNavVC(currentVC: vc)
        }
        
        let infoDict: [String : Any] = [AHFMDownloadListService.keyShouldShowRightNavBarButton: false, AHFMDownloadListService.keyShowId: showId]
        AHServiceRouter.navigateVC(AHFMDownloadListService.service, taskName: AHFMDownloadListService.taskNavigation, userInfo: infoDict, type: type, completion: nil)
    }
    
    
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: !isEditing, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    
    /// Delete downloaded episodes for this showId
    /// You should delete the info in the DB, AND their local actual files
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int){
        DispatchQueue.global().async {
            AHFMEpisode.write {
                // Delete files first so that you will still have their localFilePaths
                for epId in episodeIDs {
                    if var epInfo = AHFMEpisodeInfo.query(byPrimaryKey: epId),var show = AHFMShow.query(byPrimaryKey: showId) {
                        show.totalFilesSize -= epInfo.fileSize ?? 0
                        show.hasNewDownload = false
                        show.numberOfEpDownloaded -= 1
                        
                        
                        if let localFilePath = epInfo.localFilePath {
                            DispatchQueue.global().async {
                                AHFileTool.remove(filePath: localFilePath)
                            }
                            
                        }

                        
                        epInfo.downloadedProgress = 0.0
                        epInfo.unfinishedFilePath = nil
                        epInfo.localFilePath = nil
                        epInfo.isDownloaded = false
                        
                        
                        
                        do{
                            try AHFMShow.update(model: show)
                        }catch let error{
                            print("AHFMDownloadCenterManager downloadedShowPageVC updating show:\(error)")
                        }
                        
                        do{
                            try AHFMEpisodeInfo.update(model: epInfo)
                        }catch let error{
                            print("AHFMDownloadCenterManager downloadedShowPageVC updating epInfo:\(error)")
                        }
                        
                    }
                    
                }
            }
        }
        
    }
    
    
    /// Call loadDownloadedShows(_:) when ready
    /// Load all shows with at least one downloaded episode
    func downloadedVCLoadDownloadedShows(_ vc: UIViewController){
        AHFMShow.write {
            let shows = AHFMShow.query("numberOfEpDownloaded", ">", 0).run()
            var showArr = [[String: Any]]()
            for show in shows {
                let dict = self.transformShowToDict(show: show)
                showArr.append(dict)
            }
            
            DispatchQueue.main.async {
                vc.perform(Selector(("loadDownloadedShows:")), with: showArr)
            }
        }
    }
    
    /// Delete all downloaded episodes for this showId
    func downloadedVC(_ vc: UIViewController, shouldDeleteShow showId: Int){
        DispatchQueue.global().async {
            AHFMEpisode.write {
                // Delete files first so that you will still have their localFilePaths
                let eps = AHFMEpisode.query("showId", "=", showId).run()
                for ep in eps {
                    guard var epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id) else {
                        continue
                    }
                    
                    guard let progres  = epInfo.downloadedProgress else {
                        continue
                    }
                    
                    if progres > 99.99,var show = AHFMShow.query(byPrimaryKey: showId) {
                        show.totalFilesSize -= epInfo.fileSize ?? 0
                        show.hasNewDownload = false
                        show.numberOfEpDownloaded -= 1
                        
                        if let localFilePath = epInfo.localFilePath {
                            DispatchQueue.global().async {
                                AHFileTool.remove(filePath: localFilePath)
                            }
                        }
                        
                        
                        epInfo.downloadedProgress = 0.0
                        epInfo.unfinishedFilePath = nil
                        epInfo.localFilePath = nil
                        epInfo.isDownloaded = false
                        
                        
                        
                        
                        
                        do{
                            try AHFMShow.update(model: show)
                        }catch let error{
                            print("AHFMDownloadCenterManager downloadedVC(shouldDeleteShow) updating show:\(error)")
                        }
                        
                        do{
                            try AHFMEpisodeInfo.update(model: epInfo)
                        }catch let error{
                            print("AHFMDownloadCenterManager downloadedVC(shouldDeleteShow) updating epInfo:\(error)")
                        }
                    }
                }
            }
        }
    }
    
    /// You should unmark AHFMShow's hasNewDownload property for the showId
    func downloadedVC(_ vc: UIViewController, willEnterShowPageWithShowId showId: Int){
        AHFMShow.write {
            if var show = AHFMShow.query(byPrimaryKey: showId) {
                show.hasNewDownload = false
                
                do {
                    try AHFMShow.update(model: show)
                }catch let error {
                    print("AHFMDownloadCenterManager downloadedVC(willEnterShowPageWithShowId) updating epInfo:\(error)")
                }
            }
        }
        
    }
    
    /// Fetch the show that has an episode with that specific remote URL
    /// Call addHasNewDownloaded(_) when the data is ready
    func downloadedVC(_ vc: UIViewController, shouldFetchShowWithEpisodeRemoteURL url: String){
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { 
            AHFMShow.write {
                let eps = AHFMEpisode.query("audioURL", "=", url).run()
                if eps.count > 0 , let ep = eps.first {
                    if let show = AHFMShow.query(byPrimaryKey: ep.showId) {
                        let showDict = self.transformShowToDict(show: show)
                        DispatchQueue.main.async {
                            vc.perform(Selector(("addHasNewDownloaded:")), with: showDict)
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    vc.perform(Selector(("addHasNewDownloaded:")), with: nil)
                }
            }
        }
    }
}

//MARK:- From downloadingVC
extension Manager {
    /// Call addCurrentDownloads(_:)
    func downloadingVCGetCurrentDownloads(_ vc: UIViewController, urls: [String]){
        // get current download task
        
        DispatchQueue.global().async {
            let urls = urls
            var currentArrDict = [[String: Any]]()
            for url in urls {
                let eps = AHFMEpisode.query("audioURL", "=", url).run()
                if eps.count > 0, let ep = eps.first {
                    let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id)
                    let dict = self.merge(ep: ep, epInfo: epInfo)
                    currentArrDict.append(dict)
                }
            }
            print("currentArrDict download :\(currentArrDict.count)")
            DispatchQueue.main.async {
                vc.perform(Selector(("addCurrentDownloads:")), with: currentArrDict)
            }
        }
        
        // get archived download task
        DispatchQueue.global().async {
            let urls = urls
            var archivedArrDict = [[String: Any]]()
            let epInfoArr = AHFMEpisodeInfo.query("downloadedProgress", ">", 0.0).AND("downloadedProgress", "<", 100.0).run()
            for epInfo in epInfoArr {
                if urls.count > 0 {
                    let eps = AHFMEpisode.query("id", "=", epInfo.id).AND("audioURL", "NOT IN", urls).run()
                    if eps.count > 0, let ep = eps.first {
                        let dict = self.merge(ep: ep, epInfo: epInfo)
                        archivedArrDict.append(dict)
                    }
                }else{
                    let eps = AHFMEpisode.query("id", "=", epInfo.id).run()
                    if eps.count > 0, let ep = eps.first {
                        let dict = self.merge(ep: ep, epInfo: epInfo)
                        archivedArrDict.append(dict)
                    }
                }
            }
            print("archived download :\(archivedArrDict.count)")
            DispatchQueue.main.async {
                vc.perform(Selector(("addArchivedDownloads:")), with: archivedArrDict)
            }
        }
    }
    /// Call addArchivedDownloads(_:)
    func downloadingVCGetArchivedDownloads(_ vc: UIViewController){
        // implemented in downloadingVCGetCurrentDownloads, for convenience.
    }
    
    /// Only help empty out related info in the DB. You don't need to take care of actual unfinished temp files.
    func downloadingVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int){
        AHFMEpisode.write {
            for epId in episodeIDs {
                if var epInfo = AHFMEpisodeInfo.query(byPrimaryKey: epId),var show = AHFMShow.query(byPrimaryKey: showId) {
                    show.totalFilesSize -= epInfo.fileSize ?? 0
                    show.hasNewDownload = false
                    show.numberOfEpDownloaded -= 1
                    
                    
                    if let unfinishedFilePath = epInfo.unfinishedFilePath {
                        DispatchQueue.global().async {
                            AHFileTool.remove(filePath: unfinishedFilePath)
                        }
                    }
                    
                    epInfo.downloadedProgress = 0.0
                    epInfo.unfinishedFilePath = nil
                    epInfo.localFilePath = nil
                    epInfo.isDownloaded = false
                    
                    do{
                        try AHFMShow.update(model: show)
                    }catch let error{
                        print("AHFMDownloadCenterManager downloadedVC(shouldDeleteShow) updating show:\(error)")
                    }
                    
                    do{
                        try AHFMEpisodeInfo.update(model: epInfo)
                    }catch let error{
                        print("AHFMDownloadCenterManager downloadedVC(shouldDeleteShow) updating epInfo:\(error)")
                    }
                }
                
            }
        }
    }
}

//MARK:- Data Transform
extension Manager {
    // Show
//    self.id = dict["id"] as! Int
//    self.hasNewDownload = dict["hasNewDownload"] as! Bool
//    self.thumbCover = dict["thumbCover"] as! String
//    self.title = dict["title"] as! String
//    self.detail = dict["detail"] as! String
//    self.numberOfDownloaded = dict["numberOfDownloaded"] as! Int
//    self.totalDownloadedSize = dict["totalDownloadedSize"] as! Int
    
    func transformShowToDict(show: AHFMShow) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = show.id
        dict["hasNewDownload"] = show.hasNewDownload
        dict["thumbCover"] = show.thumbCover
        dict["title"] = show.title
        dict["detail"] = show.detail
        dict["numberOfDownloaded"] = show.numberOfEpDownloaded
        dict["totalDownloadedSize"] = show.totalFilesSize
        return dict
    }
    
    // Episode
//    self.id = dict["id"] as! Int
//    self.showId = dict["showId"] as! Int
//    self.remoteURL = dict["remoteURL"] as! String
//    self.title = dict["title"] as! String
//    self.fileSize = dict["fileSize"] as? Int
//    self.duration = dict["duration"] as? TimeInterval
//    self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
//    self.downloadedProgress = dict["downloadedProgress"] as? Double
    
    func merge(ep: AHFMEpisode, epInfo: AHFMEpisodeInfo?) -> [String: Any] {
        var dict = [String: Any]()
        dict["id"] = ep.id
        dict["showId"] = ep.id
        dict["remoteURL"] = ep.audioURL
        dict["title"] = ep.title
        dict["duration"] = ep.duration
        if let epInfo = epInfo {
            dict["fileSize"] = epInfo.fileSize
            dict["downloadedProgress"] = epInfo.downloadedProgress
        }

        return dict
    }
}





