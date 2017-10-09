//
//  AHProgressView.swift
//  AHProgress
//
//  Created by Andy Tong on 8/13/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

public class AHProgressView: UIView {
    let path = UIBezierPath()
    public var progress: CGFloat = 0.0 {
        didSet {
            guard progress >= 0.0 && progress <= 1.0 else{
                progress = oldValue
                return
            }
            
            progressView.frame.size.width = self.progress * self.bounds.width
        }
        
    }
    
    public var progressTintColor = UIColor.gray {
        didSet {
            progressView.backgroundColor = progressTintColor
        }
    }
    public var trackTintColor = UIColor.black {
        didSet {
            backgroundColor = trackTintColor
        }
    }
    public lazy var progressView: UIView = {
        let progressView = UIView()
        progressView.frame = self.bounds
        progressView.frame.size.width = self.progress * self.bounds.width
        progressView.backgroundColor = self.progressTintColor
        return progressView
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = trackTintColor
        addSubview(progressView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = trackTintColor
        addSubview(progressView)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        progressView.frame = self.bounds
        progressView.frame.size.width = self.progress * self.bounds.width
    }
    
}
