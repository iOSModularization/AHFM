//
//  AHProgressSlider.swift
//  AHProgress
//
//  Created by Andy Tong on 8/13/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

public class AHProgressSlider: UISlider {
    public var trackHeight: CGFloat = 2.0 {
        didSet {
            layoutIfNeeded()
        }
    }
    
    public var loadedProgressTintColor = UIColor.gray {
        didSet {
            self.progressView?.progressTintColor = loadedProgressTintColor
        }
    }
    
    public var loadedProgress: CGFloat {
        set {
            guard newValue >= 0.0 && newValue <= 1.0 else{
                return
            }
            self.progressView?.progress = newValue
        }
        
        get {
            return self.progressView?.progress ?? 0.0
        }
    }
    
    private weak var progressView: AHProgressView?
    
    /// the offset for progressView to match minimumValueImage's left edge
    private let offset: CGFloat = 3.0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.maximumTrackTintColor = UIColor.clear
        let progressView = AHProgressView()
        insertSubview(progressView, at: 0)
        self.progressView = progressView
    }

    // Disable user-defined MaximumTrackImage
    public override func setMaximumTrackImage(_ image: UIImage?, for state: UIControlState) {
        return
    }
    
    
    // Make sure the progressView matches the original track
    open override func trackRect(forBounds bounds: CGRect) -> CGRect{
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = trackHeight
        self.progressView?.frame = newBounds
        return newBounds
    }
}












