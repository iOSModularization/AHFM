//
//  DummyCell.swift
//  Pods
//
//  Created by Andy Tong on 9/4/17.
//
//

import UIKit

class DummyCell: UICollectionViewCell {
    @IBOutlet weak var categoryImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.systemFont(ofSize: 12.0)
    }

}
