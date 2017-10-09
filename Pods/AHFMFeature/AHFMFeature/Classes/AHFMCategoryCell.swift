//
//  AHFMCategoryCell.swift
//  Pods
//
//  Created by Andy Tong on 7/30/17.
//
//

import UIKit

class AHFMCategoryCell: UITableViewCell {
    @IBOutlet var categoryName: UILabel!
    @IBOutlet var containerView: UIView!
    
    weak var targetView: UIView? {
        didSet {
            if let targetView = targetView {
                containerView.subviews.forEach { (view) in
                    view.removeFromSuperview()
                }
                
                targetView.willMove(toSuperview: containerView)
                targetView.frame = containerView.bounds
                containerView.addSubview(targetView)
                targetView.didMoveToSuperview()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
}
