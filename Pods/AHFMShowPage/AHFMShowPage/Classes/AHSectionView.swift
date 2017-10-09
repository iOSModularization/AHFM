//
//  AHSectionView.swift
//  Pods
//
//  Created by Andy Tong on 7/27/17.
//
//

import UIKit

open class AHSectionView: UIView {
    public var indicatorColor = UIColor.red
    public var indicatorHeight: CGFloat = 2.0
    public private(set) var sections = [UIButton]()
    public var separatorColor = UIColor.lightGray
    public var showTopSeparator = true
    public var showBottomSeparator = true
    fileprivate lazy var indicator: UIView? = { () -> UIView in
        let indicator = UIView()
        indicator.backgroundColor = self.indicatorColor
        
        // width is uncertain at this point, probably.
        indicator.frame = CGRect(x: 0, y: self.frame.height - self.indicatorHeight, width: 0.0, height: self.indicatorHeight)
        self.addSubview(indicator)
        return indicator
    }()
    fileprivate var separators = [UIView]()
    fileprivate var needToLayout = false
    fileprivate var currentSectionIndex: Int = -1
    fileprivate var unitWidth: CGFloat = 0.0
    fileprivate var topSeparator: UIView?
    fileprivate var bottomSeparator: UIView?
    
    public func addSection(_ button: UIButton) {
        sections.append(button)
        
        separators.forEach { (separator) in
            separator.removeFromSuperview() // will call layoutSubviews()
        }
        separators.removeAll()
        self.addSubview(button)
        // remove separators first then set needToLayout = true
        needToLayout = true
        layoutSubviews()
    }
    /// manually select section. sendEvent set to true if you want to trigger the section button's event(touchUpInside)
    public func select(index: Int, sendEvent: Bool = false) {
        guard index >= 0 && index < sections.count else {
            fatalError("index out of bound")
        }
        
        guard index != currentSectionIndex else {
            return
        }
        currentSectionIndex = index
        
        let sectionBtn = sections[index]
        let indicatorCenterX = sectionBtn.center.x
        indicator?.center.x = indicatorCenterX
        
        if sendEvent {
            sectionBtn.sendActions(for: .touchUpInside)
        }
    }
    
    
    private func createSeparator() -> UIView{
        let view = UIView()
        view.backgroundColor = separatorColor
        view.frame.size = CGSize(width: 0.5, height: self.frame.height * 0.5)
        view.alpha = 0.6
        view.center.y = self.frame.height * 0.5
        // only center.x left to set
        return view
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutSections()
        
    }
    
    private func layoutSections() {
        guard sections.count > 0 else {
            return
        }
        
        if topSeparator == nil {
            let view = UIView()
            view.backgroundColor = separatorColor
            view.frame.size = CGSize(width: self.frame.width, height: 0.5)
            view.frame.origin = .init(x: 0, y: 0)
            view.alpha = 0.6
            self.addSubview(view)
            self.topSeparator = view
        }
        
        if bottomSeparator == nil {
            let view = UIView()
            view.backgroundColor = separatorColor
            view.frame.size = CGSize(width: self.frame.width, height: 0.5)
            view.frame.origin = .init(x: 0, y: self.frame.height - 0.5)
            view.alpha = 0.6
            self.addSubview(view)
            self.bottomSeparator = view
        }
        
        guard needToLayout else {
            return
        }
        unitWidth = self.frame.width / CGFloat(sections.count)
        indicator?.frame.size.width = unitWidth
        for i in 0..<sections.count {
            let sectionBtn = sections[i]
            
            let y: CGFloat = 0.0
            let x: CGFloat = CGFloat(i) * unitWidth
            // 1 less to the bottom to give space for indicator
            let height: CGFloat = self.frame.height - indicatorHeight
            let width: CGFloat = unitWidth
            
            sectionBtn.frame = CGRect(x: x, y: y, width: width, height: height)
            
            if i != 0 {
                // add separator in font of this section
                let separator = createSeparator()
                separator.frame.origin.x = x
                self.addSubview(separator)
                separators.append(separator)
            }
        }
        
        needToLayout = false
    }

    private func getSectionIndex(for point: CGPoint) -> Int {
        return Int(point.x / unitWidth)
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInside = super.point(inside: point, with: event)
        if isInside {
            let index = getSectionIndex(for: point)
            // don't need to set event since method point(inside point:, with event:) is coming from user tapping.
            select(index: index)
        }
        
        
        return isInside
    }
    
    
}








