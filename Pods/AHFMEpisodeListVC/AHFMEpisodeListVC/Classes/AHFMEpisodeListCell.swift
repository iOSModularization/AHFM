//
//  AHFMEpisodeListCell.swift
//  Pods
//
//  Created by Andy Tong on 7/24/17.
//
//

import UIKit
import AHAudioPlayer
import AHNibLoadable
import UIImageExtension
import StringExtension

private let iconWidth: CGFloat = 20.0

public class AHFMEpisodeListCell: UITableViewCell, AHNibLoadable {
    @IBOutlet weak var isPurchasedImg: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var isDownloadedImg: UIImageView!
    @IBOutlet weak var playStateImg: UIImageView!
    @IBOutlet weak var playStateImgWidth: NSLayoutConstraint!

    @IBOutlet weak var isDownloadImgWidth: NSLayoutConstraint!
    
    fileprivate var notificationhandlers = [NSObjectProtocol]()
    
    var episode: Episode? {
        didSet {
            if let episode = episode {
                episodeTitle.text = episode.title
                durationLabel.text = episode.duration != nil ? String.secondToTime(Double(episode.duration!)) : "Unknown"
                
                
                checkCurrentEpisode()
            }
        }
    }
    
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        isPurchasedImg.image = UIImage(name: "is-purchased", user: self)
        playStateImg.image = UIImage(name: "is-pausing", user: self)
        playStateImgWidth.constant = 0.0
        isDownloadedImg.image = UIImage(name: "is-downloaded", user: self)
        
        checkCurrentEpisode()
        
        let switchPlayHandler = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidSwitchPlay, object: nil, queue: nil) { (_) in
            self.checkCurrentEpisode()
        }
        notificationhandlers.append(switchPlayHandler)
        
        
        let reachEndHandler = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidReachEnd, object: nil, queue: nil) { (_) in
            self.checkCurrentEpisode()
        }
        notificationhandlers.append(reachEndHandler)
    }

    deinit {
        for handler in notificationhandlers {
            NotificationCenter.default.removeObserver(handler)
        }
    }
    
    // won't be called at first load
    public override func prepareForReuse() {
        super.prepareForReuse()
        checkCurrentEpisode()
    }
    
    func checkCurrentEpisode() {
        guard let ep = episode else {
            return
        }

        var shouldHide = true
        if ep.isDownloaded == nil {
            shouldHide = true
        }else{
            shouldHide = ep.isDownloaded!
        }
        isDownloadImgWidth.constant = shouldHide ? 0.0 : iconWidth
        isDownloadedImg.isHidden = shouldHide
        
        

        if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId,ep.id == playingTrackId {
            playStateImgWidth.constant = iconWidth
            playStateImg.isHidden = false
        }else{
            playStateImgWidth.constant = 0.0
            playStateImg.isHidden = true
        }
        
    }
    
}
