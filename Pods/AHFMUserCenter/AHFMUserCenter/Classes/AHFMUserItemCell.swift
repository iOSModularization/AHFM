//
//  AHFMUserItem.swift
//  Pods
//
//  Created by Andy Tong on 8/26/17.
//
//

import UIKit

class AHFMUserItemCell: UITableViewCell {
    @IBOutlet weak var itemIcon: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemAmount: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
