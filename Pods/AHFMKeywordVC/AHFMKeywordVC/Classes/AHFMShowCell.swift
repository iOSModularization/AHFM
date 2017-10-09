//
//  AHFMShowCell.swift
//  Pods
//
//  Created by Andy Tong on 9/5/17.
//
//

import UIKit
import SDWebImage

class AHFMShowCell: UITableViewCell {
    @IBOutlet weak var showCover: UIImageView!

    @IBOutlet weak var showTitle: UILabel!
    @IBOutlet weak var showDetail: UILabel!
    
 var item: DisplayItem? {
        didSet {
            if let item = item {
                showTitle.text = item.title
                showDetail.text = item.detail
                let url = URL(string: item.thumbCover ?? "")
                showCover.sd_setImage(with: url, completed: { (image, error, _, _) in
                    guard error == nil else {
                        return
                    }
                    
                    guard item == self.item else {
                        return
                    }
                    
                    self.showCover.image = image
                    
                    
                })
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
