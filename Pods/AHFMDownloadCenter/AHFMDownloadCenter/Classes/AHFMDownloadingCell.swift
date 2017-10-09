//
//  AHFMDownloadingCell.swift
//  Pods
//
//  Created by Andy Tong on 8/8/17.
//
//

import UIKit
import UIImageExtension

protocol AHFMDownloadingCellDelegate: class {
    func downloadingCellDidTapDownloadButtion(_ cell: AHFMDownloadingCell)
}

class AHFMDownloadingCell: UITableViewCell {
    
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var downloadState: UILabel!

    @IBOutlet weak var downloadedSize: UILabel!
    @IBOutlet weak var progressConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var downloadControlBtn: UIButton!
    
    @IBOutlet weak var progressSuperView: UIView! {
        didSet {
            progressSuperView.clipsToBounds = true
        }
    }

    public weak var delegate: AHFMDownloadingCellDelegate?
    
    public var episode: Episode? {
        didSet {
            if let episode = episode {
                if let progress = episode.downloadedProgress {
                    self.setProgress(progress)
                    
                    if let fileSize = episode.fileSize {
                        self.setDownloadSize(progress, fileSize: fileSize)
                    }
                }else{
                    if let fileSize = episode.fileSize {
                        self.setDownloadSize(0.0, fileSize: fileSize)
                    }
                }
                
                episodeTitle.text = episode.title
                
            }
        }
    }

    @IBAction func downloadControlBtnTapped(_ sender: UIButton) {
        delegate?.downloadingCellDidTapDownloadButtion(self)
        
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        initSetup()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        initSetup()
    }
    func initSetup() {
        let img = UIImage(name: "download-paused", user: self)
        downloadControlBtn.setImage(img, for: .normal)
        setProgress(0.0)
    }
    
    fileprivate func setProgress(_ progress: Double) {
        self.progressConstraint.constant = self.progressSuperView.frame.width * (1 - CGFloat(progress)) * -1
    }
    
    fileprivate func setDownloadSize(_ progress: Double, fileSize: Int) {
        let downloaded = progress * Double(fileSize)
        self.downloadedSize.text = "\(String.bytesToMegaBytes(UInt64(downloaded))) MB/\(String.bytesToMegaBytes(UInt64(fileSize))) MB"
    }

}

//MARK:- Handle Download Events
extension AHFMDownloadingCell {
    
    func handleDidStart() {
        let img = UIImage(name: "download-paused", user: self)
        self.downloadControlBtn.setImage(img, for: .normal)
        self.downloadState.text = "downloading"
    }
    
    func setProgressView(_ progress: Double) {
        guard let ep = self.episode, let fileSize = ep.fileSize else {
            return
        }
        self.setDownloadSize(progress, fileSize: fileSize)
        self.setProgress(progress)
    }
    
    func finish() {
        self.downloadState.text = "downloaded"
    }
    
    func pause() {
        let img = UIImage(name: "download-continue", user: self)
        self.downloadControlBtn.setImage(img, for: .normal)
        self.downloadState.text = "paused"
    }
    
    func resume() {
        let img = UIImage(name: "download-paused", user: self)
        self.downloadControlBtn.setImage(img, for: .normal)
        self.downloadState.text = "downloading"
    }

    func cancel() {
        self.downloadControlBtn.setTitle("????", for: .normal)
        self.downloadState.text = "Canceled"
    }
    
    func error() {
        self.downloadControlBtn.setTitle("????", for: .normal)
        self.downloadState.text = "Error"
    }
}






