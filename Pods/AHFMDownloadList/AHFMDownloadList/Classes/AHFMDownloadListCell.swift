//
//  AHFMDownloadListCell.swift
//  AHFMDataCenter
//
//  Created by Andy Tong on 8/3/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHDownloader
import StringExtension
import UIImageExtension


protocol AHFMDownloadListCellDelegate: class {
    func listCellDidTapDownloadBtn(_ cell: AHFMDownloadListCell)
}

public class AHFMDownloadListCell: UITableViewCell {
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    weak var delegate: AHFMDownloadListCellDelegate?
    
    var downloadItem: DownloadItem? {
        didSet {
            if let downloadItem = downloadItem {
                titleLabel.text = downloadItem.title
                createdAtLabel.text = downloadItem.createdAt
                if let duration = downloadItem.duration {
                    durationLabel.text = String.secondToTime(TimeInterval(duration))
                }else{
                    durationLabel.text = "Unknown"
                }
                
                refreshFileSize()
                
            }
        }
    }
    @IBAction func downloadBtnTapped(_ sender: UIButton) {
        guard let downloadItem = self.downloadItem else {
            return
        }
        // only 'notStarted' or 'failed' can do the download.
        guard downloadItem.downloadState == .notStarted || downloadItem.downloadState == .failed else {
            return
        }
        
        
        showPending()
        
        delegate?.listCellDidTapDownloadBtn(self)
        
    }
    
    func showPending() {
        indicator.stopAnimating()
        indicator.isHidden = true
        downloadBtn.isHidden = false
        let img = UIImage(name: "download-pending", user: self)
        downloadBtn.setImage(img, for: .normal)
    }
    
    func refreshFileSize() {
        guard let downloadItem = self.downloadItem else {
            return
        }
        
        if let size = downloadItem.fileSize {
            sizeLabel.text = String.bytesToMegaBytes(UInt64(size)) + "MB"
        }else{
            sizeLabel.text = "Unknown"
        }
    }
    
    /// Should be called at tableView cellWillDisplay
    func refreshDownloadState() {
        guard let downloadItem = self.downloadItem else {
            return
        }
        switch downloadItem.downloadState {
        case .succeeded:
            indicator.stopAnimating()
            indicator.isHidden = true
            downloadBtn.isHidden = false
            let img = UIImage(name: "download-check", user: self)
            downloadBtn.setImage(img, for: .normal)
        case .downloading:
            indicator.startAnimating()
            indicator.isHidden = false
            downloadBtn.isHidden = true
        case .pausing:
            indicator.stopAnimating()
            indicator.isHidden = true
            downloadBtn.isHidden = false
            let img = UIImage(name: "download-pending", user: self)
            downloadBtn.setImage(img, for: .normal)
        
        case .notStarted:
            // not started yet has a progress > 0.0 -- an archived task
            if let progress = downloadItem.downloadedProgress, progress > 0.0 {
                indicator.stopAnimating()
                indicator.isHidden = true
                downloadBtn.isHidden = false
                let img = UIImage(name: "download-pending", user: self)
                downloadBtn.setImage(img, for: .normal)
                
            }else {
                fallthrough
            }
        default:
            indicator.stopAnimating()
            indicator.isHidden = true
            downloadBtn.isHidden = false
            let img = UIImage(name: "download", user: self)
            downloadBtn.setImage(img, for: .normal)
        }
    }
    override public func awakeFromNib() {
        super.awakeFromNib()
        let downloadImg = UIImage(name: "download", user: self)
        downloadBtn.setImage(downloadImg, for: .normal)
        downloadBtn.isHidden = false
        indicator.isHidden = true
    }
    
}











