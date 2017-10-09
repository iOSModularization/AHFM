//
//  AHFMUserCell.swift
//  Pods
//
//  Created by Andy Tong on 8/26/17.
//
//

import UIKit

class AHFMUserCell: UITableViewCell {
    @IBOutlet var userIcon: UIImageView!
    @IBOutlet var userNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        userIcon.layer.masksToBounds = true
        userIcon.layer.cornerRadius = 30.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
