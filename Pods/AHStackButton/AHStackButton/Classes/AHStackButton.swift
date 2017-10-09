//
//  AHStackButton.swift
//  AHStackButtonTest
//
//  Created by Andy Tong on 6/2/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

/// Is the title on top, buttom, left, or right??
public enum AHStackButtonOn {
    case top
    case bottom
    case left
    case right
}


open class AHStackButton: UIButton {
    /// Sytem default is title on right
    public var isTitleOn: AHStackButtonOn = .right {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    // Padding space between titleLbael and imageView
    public var padding: CGFloat = 5.0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    func setup() {
        imageView?.contentMode = .scaleAspectFit
        titleLabel?.textAlignment  = .center
    }
    
    
    open override func setTitle(_ title: String?, for state: UIControlState) {
        super.setTitle(title, for: state)
        self.setNeedsLayout()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        
        guard let imageView = self.imageView, let titleLabel = self.titleLabel else {
            return
        }
        titleLabel.sizeToFit()
        switch isTitleOn {
        case .top:
            titleOnTop(imageView, titleLabel)
        case .bottom:
            titleOnBottom(imageView, titleLabel)
        case .left:
            titleOnLeft(imageView, titleLabel)
        case .right:
            titleOnRight(imageView, titleLabel)
        }
        
        
    }
}


extension AHStackButton {
    func titleOnTop(_ imageView: UIImageView, _ titleLabel: UILabel) {
        titleLabel.frame.origin.y = 0.0
        titleLabel.center.x = self.bounds.width * 0.5

        imageView.frame.size.width = self.bounds.width
        imageView.frame.size.height = self.bounds.height - titleLabel.intrinsicContentSize.height
        imageView.frame.origin.y = titleLabel.frame.maxY + padding
        imageView.center.x = self.bounds.width * 0.5
        
    }
    func titleOnBottom(_ imageView: UIImageView, _ titleLabel: UILabel) {
        titleLabel.frame.origin.y = self.bounds.height - titleLabel.intrinsicContentSize.height
        titleLabel.center.x = self.bounds.width * 0.5
        
        
        imageView.frame.size.width = self.bounds.width
        imageView.frame.size.height = self.bounds.height - titleLabel.frame.height
        imageView.frame.origin.y = titleLabel.frame.origin.y - imageView.frame.size.height  - padding
        imageView.center.x = self.bounds.width * 0.5
 
    }
    func titleOnLeft(_ imageView: UIImageView, _ titleLabel: UILabel) {
        titleLabel.frame.origin.x = 0.0
        titleLabel.center.y = self.bounds.height * 0.5
        
        imageView.frame.size.width = self.bounds.width - titleLabel.intrinsicContentSize.width
        imageView.frame.size.height = self.bounds.height
        imageView.frame.origin.x = titleLabel.frame.maxX + padding
        imageView.center.y = self.bounds.height * 0.5
        
    }
    func titleOnRight(_ imageView: UIImageView, _ titleLabel: UILabel) {
        titleLabel.frame.origin.x = self.bounds.width - titleLabel.intrinsicContentSize.width
        titleLabel.center.y = self.bounds.height * 0.5
        
        imageView.frame.size.width = self.bounds.width - titleLabel.intrinsicContentSize.width
        imageView.frame.size.height = self.bounds.height
        imageView.frame.origin.x = titleLabel.frame.origin.x - imageView.frame.size.width - padding
        imageView.center.y = self.bounds.height * 0.5
    }
}







