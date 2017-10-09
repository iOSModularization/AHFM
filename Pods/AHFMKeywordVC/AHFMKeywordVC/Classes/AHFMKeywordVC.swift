//
//  AHFMKeywordVC.swift
//  Pods
//
//  Created by Andy Tong on 9/5/17.
//
//

import UIKit
import UIImageExtension
import BundleExtension
import SVProgressHUD


private let CellID = "CellID"

@objc public protocol AHFMKeywordVCDelegate: class {
    func keywordVCSearchBtnTapped(_ vc: UIViewController)
    func keywordVCGetInitialKeyword(_ vc: UIViewController) -> String?
    
    /// Call searchKeyword(_ data: [[String:Any]]?)
    func keywordVC(_ vc: UIViewController, shouldSearchForKeyword keyword: String)
    
    func keywordVC(_ vc: UIViewController, didTapItemWith id: Int, subId: Int)
    
    func viewWillAppear(_ vc: UIViewController)
    func viewWillDisappear(_ vc: UIViewController)
}


public class AHFMKeywordVC: UITableViewController {
    public var manager: AHFMKeywordVCDelegate?
    public var keyword: String?
    
    var items: [DisplayItem]?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        let nib = UINib(nibName: "\(AHFMShowCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(nib, forCellReuseIdentifier: CellID)
        if self.navigationController != nil {
            tableView.contentInset.top = 64.0
        }
        tableView.contentInset.bottom = 49.0
        tableView.tableFooterView = UIView()
        
        let backBtn = UIButton()
        let backImg = UIImage(name: "back-black", user: self)
        backBtn.setImage(backImg, for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnTapped(_:)), for: .touchUpInside)
        backBtn.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        let searchBtn = UIButton()
        let searchImg = UIImage(name: "search", user: self)
        searchBtn.setImage(searchImg, for: .normal)
        searchBtn.addTarget(self, action: #selector(searchBtnTapped(_:)), for: .touchUpInside)
        searchBtn.sizeToFit()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchBtn)
        
        
        
    }
    
    /// manager should this method when it's about to search so that ketwordVC can do something like showing a progressHub.
    /// ["keyword": String]
    public func willSearchKeyword(_ data: [String: String]) {
        SVProgressHUD.show()
    }
    
    
    /// Call searchKeyword(_ data: [[String:Any]]?)
    public func searchKeyword(_ data: [[String:Any]]?) {
        SVProgressHUD.dismiss()
        guard let data = data else {
            return
        }
        var items = [DisplayItem]()
        for itemDict in data {
            let item = DisplayItem(itemDict)
            items.append(item)
        }
        self.items = items
        self.tableView.reloadData()
        let topIndexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: topIndexPath, at: UITableViewScrollPosition.top, animated: false)
    }
    
    deinit {
        SVProgressHUD.dismiss()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager?.viewWillAppear(self)
        guard let keyword = manager?.keywordVCGetInitialKeyword(self) else {
            return
        }
        self.keyword = keyword
        self.navigationItem.title = keyword
        manager?.keywordVC(self, shouldSearchForKeyword: keyword)
        
    }
    
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manager?.viewWillDisappear(self)
    }
    
    func backBtnTapped(_ button: UIButton) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func searchBtnTapped(_ button: UIButton) {
        manager?.keywordVCSearchBtnTapped(self)
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath) as! AHFMShowCell
        let item = self.items![indexPath.row]
        cell.item = item
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92.0
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = self.items?[indexPath.row] else {
            return
        }
        manager?.keywordVC(self, didTapItemWith: item.id, subId: item.subId ?? -1)
    }
    
}


struct DisplayItem: Equatable {
    var id: Int
    /// this could a showId or some other ID that could also identify this item besides its actual 'id'.
    var subId: Int?
    var title: String?
    var detail: String?
    var thumbCover: String?
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.subId = dict["subId"] as? Int
        self.title = dict["title"] as? String
        self.detail = dict["detail"] as? String
        self.thumbCover = dict["thumbCover"] as? String
    }
    
    public static func ==(lhs: DisplayItem, rhs: DisplayItem) -> Bool {
        return lhs.id == rhs.id
    }
}













