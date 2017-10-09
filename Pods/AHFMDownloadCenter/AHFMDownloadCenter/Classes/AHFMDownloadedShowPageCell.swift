//
//  AHFMDownloadedShowPageCell.swift
//  Pods
//
//  Created by Andy Tong on 8/29/17.
//
//

import UIKit
import AHAudioPlayer
import StringExtension

class AHFMDownloadedShowPageCell: UITableViewCell {
    @IBOutlet weak var percentPlayed: UILabel!
    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    
    var episode: Episode? {
        didSet {
            if let episode = episode {
                if let duration = episode.duration, duration > 0 {
                    let lastPlayedTime = episode.lastPlayedTime == nil ? 0 : episode.lastPlayedTime!
                    percentPlayed.isHidden = false
                    let percent = Int(lastPlayedTime / duration * 100)
                    if percent > 0 {
                        percentPlayed.textColor = UIColor.blue
                        percentPlayed.text = "\(percent)% played"
                    }else{
                        percentPlayed.textColor = UIColor.red
                        percentPlayed.text = "Not started"
                    }
                    
                    let durationStr = String.secondToTime(duration)
                    let fileSizeStr = episode.fileSize == nil ? "0" : String.bytesToMegaBytes(UInt64(episode.fileSize!))
                    metaLabel.text = "🕙\(durationStr)      📁\(fileSizeStr)MB"
                    
                }else{
                    percentPlayed.isHidden = true
                }
                
                
                
                titleLabel.text = episode.title
                
                if let epId = AHAudioPlayerManager.shared.playingTrackId, epId == episode.id {
                    titleLabel.textColor = UIColor.red
                }else{
                    titleLabel.textColor = UIColor.black
                }
                
            }
        }
    }
    var isEditingMode = false
    var editControlLeftPadding: CGFloat = 8.0
    weak var editControlBtn: UIButton!
    var editControlSize: CGSize = CGSize(width: 20.0, height: 20.0)
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        let editControlBtn = UIButton(type: .custom)
        editControlBtn.isUserInteractionEnabled = false
        editControlBtn.frame.size = editControlSize
        editControlBtn.frame.origin = CGPoint(x: -editControlSize.width - editControlLeftPadding, y: 0)
        let normalImg = UIImage(name: "editing-mark-normal", user: self)
        editControlBtn.setImage(normalImg, for: .normal)
        let selectedImg = UIImage(name: "editing-mark-selected", user: self)
        editControlBtn.setImage(selectedImg, for: .selected)
        self.addSubview(editControlBtn)
        self.editControlBtn = editControlBtn
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeEpisode(_:)), name: AHAudioPlayerDidSwitchPlay, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func didChangeEpisode(_ notification: Notification) {
        guard let episode = self.episode else {
            return
        }
        
        if let epId = AHAudioPlayerManager.shared.playingTrackId, epId == episode.id {
            titleLabel.textColor = UIColor.red
        }else{
            titleLabel.textColor = UIColor.black
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // cell will be checked at layoutSubviews()
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.isEditingMode = editing
        UIView.animate(withDuration: 0.3) {
            self.checkEditingMode()
        }
    }
    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        editControlBtn.isSelected = selected
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        checkEditingMode()
    }
    
    func checkEditingMode() {
        editControlBtn.frame.origin.y = self.bounds.height * 0.5 - editControlSize.height * 0.5
        let offset: CGFloat = self.editControlSize.width + self.editControlLeftPadding * 2
        self.contentView.frame.origin.x = offset
        self.editControlBtn.frame.origin.x = self.editControlLeftPadding
        
        if self.isEditingMode {
            self.contentView.frame.origin.x = offset
            self.editControlBtn.frame.origin.x = self.editControlLeftPadding
        }else{
            self.contentView.frame.origin.x = 0.0
            self.editControlBtn.frame.origin.x = -offset
        }
    }
}
