//
//  AHFMSeachKeywordCell.swift
//  Pods
//
//  Created by Andy Tong on 9/6/17.
//
//

import UIKit

class AHFMSeachKeywordCell: UICollectionViewCell {

    @IBOutlet weak var termLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        termLabel.textColor = UIColor.darkGray
        
        self.layer.masksToBounds = true
        
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.layer.cornerRadius = layoutAttributes.frame.height * 0.5
    }

    
}
