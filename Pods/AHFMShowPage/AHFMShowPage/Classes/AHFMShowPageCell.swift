//
//  AHFMShowPageCell.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import UIKit
import AHAudioPlayer
import AHDownloader
import AHNibLoadable
import UIImageExtension
import StringExtension

protocol AHFMShowPageCellDelegate: class {
    func showPageCellDidTapDownloadBtn(_ cell: UITableViewCell)
}


public class AHFMShowPageCell: UITableViewCell, AHNibLoadable {
    @IBOutlet var titleLabel: UILabel!
@IBOutlet var durationLabel: UILabel!
    @IBOutlet var dateCreated: UILabel!
    @IBOutlet weak var playingIndicator: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadBtn: UIButton!
    
    weak var delegate: AHFMShowPageCellDelegate?
    
    fileprivate var notificationHandler = [NSObjectProtocol]()
    
    @IBAction func downloadBtnTapped(_ sender: UIButton) {
        guard let ep = self.episode else {
            return
        }
        guard ep.downloadState != .succeeded else {
            return
        }
        
        delegate?.showPageCellDidTapDownloadBtn(self)
        
    }
    
    var episode: Episode? {
        didSet {
            if let episode = episode {
                titleLabel.text = episode.title
                
                dateCreated.text = episode.createdAt
                if let duration = episode.duration {
                    durationLabel.text = String.secondToTime(TimeInterval(duration))
                }else{
                    durationLabel.text = "Unknown"
                }
                
                
                checkCurrentEpisode()
            }
        }
    }
    
    
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        checkCurrentEpisode()
        
        let switchPlayHanlder = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidSwitchPlay, object: nil, queue: nil) {[weak self] (_) in
            guard self != nil else {return}
            self?.checkCurrentEpisode()
        }
        notificationHandler.append(switchPlayHanlder)
        
//        let reachEndHanlder = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidReachEnd, object: nil, queue: nil) {[weak self] (_) in
//            guard self != nil else {return}
//            self?.checkCurrentEpisode()
//        }
//        notificationHandler.append(reachEndHanlder)
    }

    deinit {
        notificationHandler.forEach { (handler) in
            NotificationCenter.default.removeObserver(handler)
        }
    }
    
    // won't be called at first load
    public override func prepareForReuse() {
        super.prepareForReuse()
        checkCurrentEpisode()
    }
    
    
    
}


//MARK:- State Controlling Methods
extension AHFMShowPageCell {
    fileprivate func checkCurrentEpisode() {
        guard let ep = episode else {
            return
        }
        
        if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId,ep.id == playingTrackId {
            playingIndicator.isHidden = false
        }else{
            playingIndicator.isHidden = true
        }
    }
    
    func downloading() {
        self.indicator.startAnimating()
        self.indicator.isHidden = false
        self.downloadBtn.isHidden = true
    }
    
    func downloaded() {
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
        let img = UIImage(name: "download-check", user: self)
        self.downloadBtn.setImage(img, for: .normal)
        self.downloadBtn.isHidden = false
    }
    
    func pause() {
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
        let img = UIImage(name: "download-pending", user: self)
        self.downloadBtn.setImage(img, for: .normal)
        self.downloadBtn.isHidden = false
    }
    
    func normal() {
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
        let img = UIImage(name: "download-2-icon", user: self)
        self.downloadBtn.setImage(img, for: .normal)
        self.downloadBtn.isHidden = false
    }
}






