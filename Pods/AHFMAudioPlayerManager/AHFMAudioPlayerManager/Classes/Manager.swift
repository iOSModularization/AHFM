//
//  AHFMAudioPlayerDelegate.swift
//  AHAudioPlayer
//
//  Created by Andy Tong on 9/28/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyJSON
import AHFMDataCenter
import SDWebImage
import AHAudioPlayer

public class Manager: NSObject {
    public static let shared = Manager()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didSwitchPlay(_:)), name: AHAudioPlayerDidSwitchPlay, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func didSwitchPlay(_ notification: Notification) {
        if let trackId = AHAudioPlayerManager.shared.playingTrackId {
            let history = AHFMEpisodeHistory(with: ["id": trackId, "addedAt": Date().timeIntervalSinceReferenceDate])
            AHFMEpisodeHistory.write {
                let ones = AHFMEpisodeHistory.insert(models: [history])
                if ones.count > 0 {
                    AHFMEpisodeHistory.update(models: [history])
                }
            }
        }
    }
}

extension Manager: AHAudioPlayerMangerDelegate {
    public func playerMangerGetAlbumCover(_ player: AHAudioPlayerManager, trackId: Int, _ callback: @escaping (UIImage?) -> Void) {
        if let ep = AHFMEpisode.query(byPrimaryKey: trackId), let showFullCover = ep.showFullCover {
            let url = URL(string: showFullCover)
            SDWebImageDownloader.shared().downloadImage(with: url, options: .useNSURLCache, progress: nil, completed: { (image, _, _, _) in
                callback(image)
            })
            
            
        }
        callback(nil)
    }

    public func playerManger(_ manager: AHAudioPlayerManager, updateForTrackId trackId: Int, duration: TimeInterval){
        AHFMEpisode.write {
            // assuming there's episode already in the DB since episodes will always be saved first before being played.
            try? AHFMEpisode.update(byPrimaryKey: trackId, forProperties: ["duration": duration])
        }
    }
    public func playerManger(_ manager: AHAudioPlayerManager, updateForTrackId trackId: Int, playedProgress: TimeInterval){
        if playedProgress < 5 {
            return
        }
        
        AHFMEpisodeInfo.write {
            // failed update won't throw!!
            // so we need to manually check existence.
            
            if var info = AHFMEpisodeInfo.query(byPrimaryKey: trackId) {
                info.lastPlayedTime = playedProgress
                try? AHFMEpisodeInfo.update(model: info)
            }else{
                let info = AHFMEpisodeInfo(with: ["id": trackId, "lastPlayedTime": playedProgress])
                do {
                    try AHFMEpisodeInfo.insert(model: info)
                }catch let error {
                    print("playerManger updateForTrackId playedProgress error:\(error)")
                }
            }
        }
    }
    
    /// The following five are for audio background mode
    /// Both requiring the delegate to return a dict [trackId: id, trackURL: URL]
    /// trackId is Int, trackURL is URL
    public func playerMangerGetPreviousTrackInfo(_ manager: AHAudioPlayerManager, currentTrackId: Int) -> [String: Any] {
        if let currentEp = AHFMEpisode.query(byPrimaryKey: currentTrackId) {
            let eps = AHFMEpisode.query("showId", "=", currentEp.showId).OrderBy("createdAt", isASC: true).run()
            guard eps.count > 0 else {
                return [:]
            }
            if let currentIndex = eps.index(of: currentEp) {
                if currentIndex > 0 && currentIndex < eps.count {
                    let previousEp = eps[currentIndex - 1]
                    let url = getEpisodeURL(ep: previousEp)
                    
                    return ["trackId": previousEp.id, "trackURL": url]
                }
            }
        }
        
        return [:]
    }
    public func playerMangerGetNextTrackInfo(_ manager: AHAudioPlayerManager, currentTrackId: Int) -> [String: Any]{
        if let currentEp = AHFMEpisode.query(byPrimaryKey: currentTrackId) {
            let eps = AHFMEpisode.query("showId", "=", currentEp.showId).OrderBy("createdAt", isASC: true).run()
            guard eps.count > 0 else {
                return [:]
            }
            if let currentIndex = eps.index(of: currentEp) {
                if currentIndex >= 0 && currentIndex < eps.count - 1 {
                    let nextEp = eps[currentIndex + 1]
                    let url = getEpisodeURL(ep: nextEp)
                    
                    return ["trackId": nextEp.id, "trackURL": url]
                }
            }
        }
        return [:]
    }
    public func playerMangerGetTrackTitle(_ player: AHAudioPlayerManager, trackId: Int) -> String?{
        if let ep = AHFMEpisode.query(byPrimaryKey: trackId) {
            return ep.title
        }else{
            return nil
        }
    }
    public func playerMangerGetAlbumTitle(_ player: AHAudioPlayerManager, trackId: Int) -> String?{
        if let ep = AHFMEpisode.query(byPrimaryKey: trackId), let show = AHFMShow.query(byPrimaryKey: ep.showId) {
            return show.title
        }
        return nil
    }

}

extension Manager {
    func getEpisodeURL(ep: AHFMEpisode) -> URL {
        var url: URL?
        if let epInfo = AHFMEpisodeInfo.query(byPrimaryKey: ep.id), epInfo.isDownloaded == true {
            
            if let localFilePath = epInfo.localFilePath {
                url = URL(fileURLWithPath: localFilePath)
            }
        }
        
        if url == nil {
            if let audioURL = ep.audioURL {
                url = URL(string: audioURL)
            }else{
                print("ERROR episodeId:\(ep.id) doesn't have an audioURL nor localFilePath")
                url = URL(string: "")
            }
            
        }
        return url!
    }
}
