//
//  AHFloatingTextView.swift
//  Pods
//
//  Created by Andy Tong on 7/23/17.
//
//

import UIKit

open class AHFloatingTextView: UIScrollView {
    open var pausingInterval: TimeInterval = 3.0
    open var font: UIFont = UIFont.systemFont(ofSize: 17.0)
    open var color: UIColor = UIColor.white
    open var text: String = "" {
        
        didSet {
            if oldValue == text {
                return
            }
            if !text.isEmpty {
                isSetup = false
                self.timer?.invalidate()
                setupScrollView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.fireTimer()
                }
                
            }
        }
    }
    
    fileprivate var updateTimeInterval: TimeInterval = 0.01
    fileprivate var isSetup = false
    fileprivate var labels = [UILabel]()
    fileprivate var padding: CGFloat = 10.0
    fileprivate var timer: Timer?
    fileprivate var textSize: CGSize {
        return text.stringSize(boundWdith: CGFloat.greatestFiniteMagnitude, boundHeight: font.lineHeight, font: font)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
    }
    
    override open func didMoveToSuperview() {
        setupScrollView()
    }
    
    fileprivate func setupScrollView() {
        guard !text.isEmpty else {return}
        guard !self.frame.isEmpty else {
            return
        }
        labels.forEach { (label) in
            label.removeFromSuperview()
        }
        labels.removeAll()
        
        // add labels
        // if this text string for detail, is less than this view's width, show only one label
        // DO NOT use bounds since it's based on scrollView's inner coordinate system
        let count = textSize.width > self.frame.width ? 2 : 1
        for _ in 0..<count {
            let label = UILabel()
            labels.append(label)
            self.addSubview(label)
        }
        
        // positin labels
        if count > 1 {
            // place labels from left to right, when there are mutiple labels
            for i in 0..<labels.count {
                let label = labels[i]
                label.text = self.text
                label.font = self.font
                label.textColor = self.color
                label.sizeToFit()
                
                let x = CGFloat(i) * (label.intrinsicContentSize.width + padding)
                label.frame.origin.x = x
            }
        }else{
            // place this only label on the cetner
            let label = labels.first!
            label.text = self.text
            label.font = self.font
            label.textColor = self.color
            label.sizeToFit()
            
            label.center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        }
        
        
        let width = labels.last!.frame.maxX
        self.contentSize = CGSize(width: width, height: 0.0)
        self.contentOffset.x = 0.0
        isSetup = true
    }
    
    fileprivate func fireTimer() {
        guard labels.count > 1 else {
            // there are more than 1 labels -- the text string's width > self.width
            return
        }
        timer?.invalidate()
        timer = nil
        timer = Timer(timeInterval: updateTimeInterval, target: self, selector: #selector(scrolling), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer!, forMode: .commonModes)
        
    }
    
    @objc fileprivate func scrolling() {
        contentOffset.x += CGFloat(0.5)
    }
    
    override open var contentOffset: CGPoint {
        didSet {
            if contentOffset.x >= textSize.width + padding {
                timer?.invalidate()
                timer = nil
                let zeroPt = CGPoint(x: 0, y: 0)
                setContentOffset(zeroPt, animated: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + pausingInterval, execute: {
                    self.fireTimer()
                })
            }
        }
    }
    

    
    /**
     https://stackoverflow.com/questions/728372/when-is-layoutsubviews-called
     Setting contentSize won't triggered layoutSubviews().
     But scrolling will.
     
     */
    override open func layoutSubviews() {
        super.layoutSubviews()
        if !isSetup {
            setupScrollView()
        }
    }
}

extension String {
    fileprivate func stringSize(boundWdith: CGFloat, boundHeight: CGFloat, font: UIFont) -> CGSize {
        let boundSize: CGSize =  CGSize(width: boundWdith, height: boundHeight)
        
        let size = (self as NSString).boundingRect(with: boundSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size
        return size
    }
}







