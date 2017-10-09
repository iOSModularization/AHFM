//
//  AHFMRecommandCell.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import UIKit
import SDWebImage

class AHFMShowRecommendCell: UITableViewCell {
    @IBOutlet weak var showTitle: UILabel!
    @IBOutlet weak var starImg: UIImageView!
    @IBOutlet weak var thumbImg: UIImageView!
    
    public var show: Show? {
        didSet {
            if let show = show {
                showTitle.text = show.title
//                let scoreInt = Int(show.buzzScore * 100) / 10 / 5
                // The buzzScores are not included in related(Recommend) shows,
                // so let's do it randomly.
                // range [1, 5]
                let score = arc4random_uniform(6)
                let imgStr = "\(score)-star"
                starImg.image = UIImage(name: imgStr, user: self)
                
                let url = URL(string: show.thumbCover)
                thumbImg.sd_setImage(with: url)
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
