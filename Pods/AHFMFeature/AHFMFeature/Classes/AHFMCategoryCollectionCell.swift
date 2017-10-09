//
//  AHFMCategoryCollectionCell.swift
//  Pods
//
//  Created by Andy Tong on 7/31/17.
//
//

import UIKit
import SDWebImage
class AHFMCategoryCollectionCell: UICollectionViewCell {
    @IBOutlet var showImageView: UIImageView!
    @IBOutlet var showTitleLabel: UILabel!
    @IBOutlet weak var showDetail: UILabel!
    
    var show: Show? {
        didSet {
            if let show = show {
                showTitleLabel.text = show.title
                showDetail.text = show.detail
                let url = URL(string: show.thumbCover ?? "")
                showImageView.sd_setImage(with: url)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
