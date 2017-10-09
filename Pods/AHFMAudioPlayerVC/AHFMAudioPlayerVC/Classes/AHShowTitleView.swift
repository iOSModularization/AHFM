//
//  AHShowTitle.swift
//  Pods
//
//  Created by Andy Tong on 7/23/17.
//
//

import UIKit
import AHFloatingTextView

public class AHShowTitleView: UIView {
    public var title: String = "" {
        didSet {
            if !title.isEmpty {
                titleLabel.textAlignment = .center
                titleLabel.text = self.title
                titleLabel.font = self.titleFont
            }
        }
    }
    public var detail: String = "" {
        didSet {
            if !detail.isEmpty {
                detailScrollView.text = self.detail
                detailScrollView.font = self.detailFont
                detailScrollView.color = self.textColor
                layoutSubviews()
            }
        }
    }
    public var detailFont: UIFont = UIFont.systemFont(ofSize: 20.0)
    public var titleFont: UIFont = UIFont.systemFont(ofSize: 17.0)
    public var textColor: UIColor = UIColor.white
    
    fileprivate var titleLabel = UILabel()
    fileprivate var detailScrollView = AHFloatingTextView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        addSubview(detailScrollView)
        titleLabel.textColor = textColor
        addSubview(titleLabel)
    }
    
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        detailScrollView.frame = bounds
        detailScrollView.frame.size.height = detailFont.lineHeight
        
        titleLabel.font = titleFont
        titleLabel.frame.size.width = bounds.width
        titleLabel.frame.size.height = bounds.height - detailScrollView.frame.height
        titleLabel.frame.origin.y = bounds.height - titleLabel.intrinsicContentSize.height
        titleLabel.frame.origin.x = 0.0
        
    }
    
}


