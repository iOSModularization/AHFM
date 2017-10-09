//
//  AHFMFeatureVC.swift
//  Pods
//
//  Created by Andy Tong on 7/30/17.
//
//

import UIKit
import AHBannerView
import SVProgressHUD
import UIImageExtension

private let AHFMCategoryCellID = "AHFMCategoryCellID"


@objc public protocol AHFMFeatureVCDelegate: class {
    func featureVC(_ vc: UIViewController, didTapCategoryWithShow showId: Int)
    
    func featureVC(_ vc:UIViewController, bannerViewDidTappedAtIndex index: Int, forShow showId: Int, episodeId: Int)
    
    /// Call loadShowForCategories(_ data: [String: [[String:Any]]]?)
    func featureVC(_ vc:UIViewController ,shouldLoadShowsForCategory categories: [String])
    
    /// Call loadBannerEpisodes(_ data: [[String:Any]]?)
    func featureVC(_ vc:UIViewController, shouldLoadBannerEpisodesWithLimit limit: Int)
    
    func viewWillAppear(_ vc: UIViewController)
    
    func viewWillDisappear(_ vc: UIViewController)
}



let CollectionCellSize = CGSize(width: 100.0, height: 150.0)
let CategoryTitleLabelHeight: CGFloat = 21.0
let Padding: CGFloat = 16.0
let CategoryCellHeight: CGFloat = Padding + CategoryTitleLabelHeight + Padding + CollectionCellSize.height + Padding

public class AHFMFeatureVC: UITableViewController {
    public var manager: AHFMFeatureVCDelegate?
    
    lazy var collectionVCHandler: AHFMCategoryHandler = {
       let handler = AHFMCategoryHandler()
        handler.featureVC = self
        return handler
    }()
    
    lazy var bannerView: AHBannerView = AHBannerView()
    lazy var style: AHBannerStyle = AHBannerStyle()
    
    var categoryArray: [String: [Show]]?
    var categoryStrings: [String]?
    
    let strs = ["Technology", "Philosophy", "Design", "Business News", "Outdoor"]
    
    var bannerEpisodes: [Episode]?
    
    /// Can use this to prevent reload everthing every time it comes back from a navVC popping.
    var shouldReloadEverything = true
    
    
    /// Call loadShowForCategories(_ data: [String: [[String:Any]]]?)
    func loadShowForCategories(_ data: [String: [[String:Any]]]?) {
        guard let data = data else {
            SVProgressHUD.dismiss()
            return
        }
        DispatchQueue.global().async {
            var showDictArr = [String: [Show]]()
            
            // the category without containing a show
            var noShowsCategory = [String]()
            
            for categoryStr in self.strs {
                if let showArr = data[categoryStr] {
                    for showDict in showArr {
                        let show = Show(showDict)
                        if var arr = showDictArr[categoryStr]{
                            arr.append(show)
                            showDictArr[categoryStr] = arr
                        }else{
                            var arr = [Show]()
                            arr.append(show)
                            showDictArr[categoryStr] = arr
                        }
                    }
                }else{
                    noShowsCategory.append(categoryStr)
                }
            }
            self.categoryArray = showDictArr
            self.categoryStrings = showDictArr.keys.map({ (str) -> String in
                return str
            })
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.shouldReloadEverything = false
                self.tableView.reloadData()
            }
        }
    }
    
    /// Call loadBannerEpisodes(_ data: [[String:Any]]?)
    func loadBannerEpisodes(_ data: [[String:Any]]?) {
        guard let data = data else {
            return
        }
        var eps = [Episode]()
        for epDict in data {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        self.bannerEpisodes = eps
        self.bannerView.setup(imageCount: eps.count, Style: style)
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        bannerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200.0)

        tableView.contentInset.bottom = 49.0
        tableView.tableHeaderView = bannerView
        tableView.tableFooterView = UIView()
        setup()
        
        let currentBundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMCategoryCell.self)", bundle: currentBundle)
        tableView.register(nib, forCellReuseIdentifier: AHFMCategoryCellID)
        
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        manager?.viewWillAppear(self)
        
        
        if self.shouldReloadEverything {
             SVProgressHUD.show()
            manager?.featureVC(self, shouldLoadBannerEpisodesWithLimit: 8)
            manager?.featureVC(self, shouldLoadShowsForCategory: self.strs)
        }
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manager?.viewWillDisappear(self)
    }
    
    func setup() {
        style.isAutoSlide = true
        style.isInfinite = true
        style.isPagingEnabled = true
        style.timeInterval = 3.5
        style.showIndicator = true
        style.indicatorColor = UIColor.red
        style.showPageControl = false
        style.bottomHeight = 5.0
        style.pageControlColor = UIColor.gray
        style.pageControlSelectedColor = UIColor.red
        style.placeholder = UIImage(name: "shameless-placeholder-ad", user: self)
        bannerView.delegate = self
        
    }
    
//    func loadBanners() {
//        AHFMDataCenter.requestTrending { (topicArray) in
//            if let sorted = topicArray.sorted(by: { (show1, show2) -> Bool in
//                return show1.count > show2.count
//            }).first {
//                self.bannerEpisodes = sorted
//                self.bannerView.setup(imageCount: self.bannerEpisodes.count, Style: self.style) { (imageView, index) in
//                    let ep = self.bannerEpisodes[index]
//                    let url = URL(string: ep.showFullCover)
//                    imageView.sd_setImage(with: url)
//                    imageView.contentMode = .scaleAspectFill
//                }
//                self.bannerView.refresh()
//            }
//            
//            
//        }
//    }
    
    
}

extension AHFMFeatureVC {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return categoryStrings?.count ?? 0
    }
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMCategoryCellID, for: indexPath) as! AHFMCategoryCell
        let categoryName = categoryStrings![indexPath.section]
        let shows = categoryArray![categoryName]
        self.collectionVCHandler.setup(self, cell: cell, showArray: shows!, section: indexPath.section, categoryName: categoryName)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CategoryCellHeight
    }
    
}




extension AHFMFeatureVC: AHBannerViewDelegate {
    public func bannerViewForImage(_ bannerView: AHBannerView, imageView: UIImageView, atIndex: Int) {
        guard let eps = self.bannerEpisodes else {
            return
        }
        let ep = eps[atIndex]
        let url = URL(string: ep.fullCover ?? "")
        imageView.sd_setImage(with: url)
        imageView.contentMode = .scaleAspectFill
        
    }

    public func bannerView(_ bannerView: AHBannerView, didTapped atIndex: Int) {
        guard let eps = self.bannerEpisodes else {
            return
        }
        let ep = eps[atIndex]
        manager?.featureVC(self, bannerViewDidTappedAtIndex: atIndex, forShow: ep.showId, episodeId: ep.id)
        
        
    }
    public func bannerView(_ bannerView: AHBannerView, didSwitch toIndex: Int){}
}



struct Show: Equatable {
    var id: Int
    var title: String?
    var detail: String?
    var thumbCover: String?
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.title = dict["title"] as? String
        self.thumbCover = dict["thumbCover"] as? String
        self.detail = dict["detail"] as? String
    }
    
    public static func ==(lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}



struct Episode: Equatable {
    var id: Int
    var showId: Int
    var title: String?
    var detail: String?
    var fullCover: String?
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.title = dict["title"] as? String
        self.fullCover = dict["fullCover"] as? String
        self.detail = dict["detail"] as? String
    }
    
    public static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }
}







