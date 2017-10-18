//
//  AHFMMainVC.swift
//  Pods
//
//  Created by Andy Tong on 9/1/17.
//
//

import UIKit
import UIImageExtension
import AHCategoryView

@objc public protocol AHFMMainVCDelegate: class {
    func AHFMMainVCGetUserCenterVC(_ vc: UIViewController)  -> UIViewController?
    func AHFMMainVCGetFeatureVC(_ vc: UIViewController) -> UIViewController?
    func AHFMMainVCGetCategoryVC(_ vc: UIViewController) -> UIViewController?
    func AHFMMainVCGetSearchVC(_ vc: UIViewController) -> UIViewController?
}

private let ScreenSize = UIScreen.main.bounds.size


public class AHFMMainVC: UIViewController {
    public var manager: AHFMMainVCDelegate?
    
    
    fileprivate weak var categoryView: AHCategoryView!
    var childVCs = [UIViewController]()
    lazy var featureVC: UIViewController? = {
        return self.manager?.AHFMMainVCGetFeatureVC(self)
    }()
    lazy var userCenterVC: UIViewController? = {
        return self.manager?.AHFMMainVCGetUserCenterVC(self)
    }()
    lazy var categoryVC: UIViewController? = {
        return self.manager?.AHFMMainVCGetCategoryVC(self)
    }()
    lazy var searchVC: UIViewController? = {
        return self.manager?.AHFMMainVCGetSearchVC(self)
    }()
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        
        
        let searchBtn = UIButton(type: .custom)
        let searchImg = UIImage(name: "search-magnifier", user: self)
        searchBtn.setImage(searchImg, for: .normal)
        searchBtn.addTarget(self, action: #selector(self.searchBtnTapped(_:)), for: .touchUpInside)
        searchBtn.sizeToFit()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchBtn)
        
        
        var meItem = AHCategoryItem()
        meItem.normalImage = UIImage(name: "me-normal", user: self)
        meItem.selectedImage = UIImage(name: "me-selected", user: self)
        
        
        var featureItem = AHCategoryItem()
        featureItem.title = "Feature"
        var chartItem = AHCategoryItem()
        chartItem.title = "Categories"
        var radioItem = AHCategoryItem()
        radioItem.title = "Radio"
        var liveItem = AHCategoryItem()
        liveItem.title = "Live"
        
        
        let items = [meItem, featureItem, chartItem, radioItem, liveItem]
        
        
        childVCs.append(userCenterVC!)
        childVCs.append(featureVC!)
        childVCs.append(categoryVC!)
        
        for _ in 0..<2 {
            let vc = UIViewController()
            vc.view.backgroundColor = UIColor.red
            childVCs.append(vc)
        }
        
        let frame = CGRect(x: 0, y: 64.0, width: ScreenSize.width, height: ScreenSize.height - 64.0)
        var style = AHCategoryNavBarStyle()
        //        style.offsetX = -16.0
        style.interItemSpace = 7.0
        style.itemPadding = 8.0
        style.isScrollable = false
        style.layoutAlignment = .left
        style.isEmbeddedToView = false
        style.showBottomSeparator = false
        style.indicatorColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        style.normalColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        style.selectedColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        self.view.backgroundColor = UIColor.white
        
        let categoryView = AHCategoryView(frame: frame, categories: items, childVCs: childVCs, parentVC: self, barStyle: style)
        self.view.addSubview(categoryView)
        self.categoryView = categoryView
        categoryView.navBar.frame = CGRect(x: 0, y: 0, width: 359.0, height: 44.0)
        categoryView.select(at: 1)
        self.navigationItem.titleView = categoryView.navBar
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.categoryView.setBadge(atIndex: 0, badgeNumber: 1)
    }
    
    func searchBtnTapped(_ btn: UIButton) {
        guard let searchVC = self.searchVC else {
            return
        }
        if self.navigationController != nil {
            self.navigationController?.pushViewController(searchVC, animated: true)
        }
    }
    
}

