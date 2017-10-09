//
//  AHFMDownloadedCell.swift
//  Pods
//
//  Created by Andy Tong on 8/8/17.
//
//

import UIKit
import StringExtension
import SDWebImage

protocol AHFMDownloadedCellDelegate: class {
    func downloadedCell(_ cell: AHFMDownloadedCell, didTappedDelete showId: Int)
}


class AHFMDownloadedCell: UITableViewCell {
    weak var delegate: AHFMDownloadedCellDelegate?
    
    @IBOutlet weak var hasNewDownloadView: UIView!
    @IBOutlet weak var showCover: UIImageView!
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var numberOfDownloaded: UILabel!
    @IBOutlet weak var totalDownloadedSize: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    
    
    var show: Show? {
        didSet {
            if let show = show {
                showTitleLabel.text = show.title
                numberOfDownloaded.text = "\(show.numberOfDownloaded) downloaded"
                totalDownloadedSize.text = "\(String.bytesToMegaBytes(UInt64(show.totalDownloadedSize)))MB"
                hasNewDownloadView.isHidden = !show.hasNewDownload
                let url = URL(string: show.thumbCover)
                showCover.sd_setImage(with: url)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let img = UIImage(name: "download-trash-can", user: self)
        deleteBtn.setImage(img, for: .normal)
    }
    
    @IBAction func deleteEpisode(_ sender: UIButton) {
        guard let show = show else {
            return
        }
        delegate?.downloadedCell(self, didTappedDelete: show.id)
    }
    
}
