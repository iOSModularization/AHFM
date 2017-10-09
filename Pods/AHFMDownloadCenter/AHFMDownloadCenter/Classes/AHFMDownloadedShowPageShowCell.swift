//
//  AHFMDownloadedShowPageShowCell.swift
//  Pods
//
//  Created by Andy Tong on 8/29/17.
//
//

import UIKit
import SDWebImage

class AHFMDownloadedShowPageShowCell: UITableViewCell {

    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImg: UIImageView!
    
    var show: Show? {
        didSet {
            if let show = show {
                titleLabel.text = show.title
                metaLabel.text = show.detail
                
                let url = URL(string: show.thumbCover)
                coverImg.sd_setImage(with: url, completed: { (image, error, _, _) in
                    guard error == nil else {
                        return
                    }
                    
                    guard self.show == show else {
                        return
                    }
                    
                    guard let image = image else {
                        return
                    }
                    
                    self.coverImg.image = image
                    
                })
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
