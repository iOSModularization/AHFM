//
//  AHFMDownloadList.swift
//  AHFMDataCenter
//
//  Created by Andy Tong on 8/3/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHDownloader
import AHDownloadTool
import UIDeviceExtension
import BundleExtension
import SVProgressHUD

//private let ScreenSize = UIScreen.main.bounds.size
private let AHFMDownloadListCellID = "AHFMDownloadListCellID"
private let BottomBarHeight: CGFloat = 49.0
private let TopSeparatorHeight: CGFloat = 25.0

@objc public protocol AHFMDownloadListVCDelegate: class {
    func downloadListVCDidTapNavBarRightButton(_ vc: AHFMDownloadListVC)
    
    /// Tells manager to fetch data
    func downloadListVCShouldLoadData(_ vc: AHFMDownloadListVC)
    
    // info [url: fileSize]
    func downloadListVC(_ vc: AHFMDownloadListVC, didUpdateFileSizes info:[String:Int])
    
    func viewWillAppear(_ vc: UIViewController)
    func viewWillDisappear(_ vc: UIViewController)
}


struct DownloadItem {
    var id: Int
    var remoteURL: String
    var title: String?
    var createdAt: String?
    var duration: TimeInterval?
    var fileSize: Int?
    var downloadedProgress: Double?
    var downloadState: AHDataTaskState = .notStarted
    
    
    init(dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.remoteURL = dict["remoteURL"] as! String
        
        self.title = dict["title"] as? String
        self.duration = dict["duration"] as? TimeInterval
        self.fileSize = dict["fileSize"] as? Int
        self.createdAt = dict["createdAt"] as? String
        self.downloadedProgress = dict["downloadedProgress"] as? Double
        if let isDownloaded = dict["isDownloaded"] as? Bool, isDownloaded == true {
            self.downloadState = .succeeded
        }else if let progress = self.downloadedProgress, progress > 0, AHDownloader.getState(self.remoteURL) == .notStarted{
            // the task is not started yet there's a downloaded progress -- this is an archived task.
            self.downloadState = .pausing
        }else{
            self.downloadState = AHDownloader.getState(self.remoteURL)
        }
        
    }
    
}


public class AHFMDownloadListVC: UIViewController {
    fileprivate lazy var downloadItems = [DownloadItem]()
    fileprivate weak var tableView: UITableView!
    fileprivate lazy var spaceUsedLabel = UILabel()
    fileprivate lazy var urlToIndex = [String: Int]()
    
    public var manager: AHFMDownloadListVCDelegate?
    
    // should the listVC show the 'More' btn at the top right corner in the navBar? 'More' btn leads to downloadCenter.
    public var shouldShowRightNavBarButton = true

    public override var title: String? {
        didSet {
            self.navigationItem.title = title
        }
    }
    
    public func reload(_ data: [[String: Any]]?) {
        guard let data = data else {
            SVProgressHUD.dismiss()
            return
        }
        guard data.count > 0 else {
            SVProgressHUD.dismiss()
            return
        }
        
        self.downloadItems.removeAll()
        self.urlToIndex.removeAll()
        
        for itemDict in data {
            let item = DownloadItem(dict: itemDict)
            self.downloadItems.append(item)
        }
        
        let group = DispatchGroup()
        var urlToSize = [String: Int]()
        // AHFileSizeProbe has a default timeout, 8 seconds, for each task.
        for (i, item) in self.downloadItems.enumerated() {
            if item.fileSize == nil {
                group.enter()
                AHFileSizeProbe.probe(urlStr: item.remoteURL, {[weak self] (fileSize) in
                    
                    guard self != nil else {
                        group.leave()
                        return
                    }
                    let index = i
                    self?.downloadItems[index].fileSize = Int(fileSize)
                    self?.urlToIndex[item.remoteURL] = index
                    urlToSize[item.remoteURL] = Int(fileSize)
                    group.leave()
                })
            }else{
                let index = i
                self.urlToIndex[item.remoteURL] = index
            }
        }
        

        group.notify(queue: DispatchQueue.main) {[weak self] in
            SVProgressHUD.dismiss()
            guard self != nil else {return}
            self?.manager?.downloadListVC(self!, didUpdateFileSizes: urlToSize)
            
            self?.tableView.reloadData()
            AHDownloader.addDelegate(self!)
        }
        
    }
    
    
}

//MARK:- VC Life Cycle
extension AHFMDownloadListVC {
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        setupUI()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.spaceUsedLabel.text = "Free Space: \(UIDevice.freeDiskSpaceStr)MB"
        self.manager?.viewWillAppear(self)
        SVProgressHUD.show()
        self.manager?.downloadListVCShouldLoadData(self)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.manager?.viewWillDisappear(self)
    }
    
}


//MARK:- TableView Delegate/DataSource
extension AHFMDownloadListVC: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloadItems.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMDownloadListCellID, for: indexPath) as! AHFMDownloadListCell
        
        
        var item = self.downloadItems[indexPath.row]
        // first check was at creation of the item
        if item.downloadState != .succeeded {
            item.downloadState = AHDownloader.getState(item.remoteURL)
            self.downloadItems[indexPath.row] = item
        }
        
        cell.downloadItem = item
        if cell.delegate == nil {
            cell.delegate = self
        }
        return cell
    }
    
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? AHFMDownloadListCell else {
            return
        }

        cell.refreshFileSize()
        cell.refreshDownloadState()
        
    }
    
}

//MARK:- AHDownloaderDelegate
extension AHFMDownloadListVC: AHDownloaderDelegate {
    public func downloaderWillStartDownload(url:String){
        guard let index = self.urlToIndex[url] else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? AHFMDownloadListCell {
            cell.downloadItem?.downloadState = self.downloadItems[indexPath.row].downloadState
            cell.showPending()
        }
    }
    public func downloaderDidStartDownload(url:String){
        checkState(url)
    }
    public func downloaderDidFinishDownload(url:String, localFilePath: String){
        checkState(url)
    }
    public func downloaderDidPaused(url: String){
        checkState(url)
    }
    public func downloaderDidPausedAll(){
        for url in self.urlToIndex.keys {
            checkState(url)
        }
    }
    public func downloaderDidResumedAll(){
        for url in self.urlToIndex.keys {
            checkState(url)
        }
    }
    public func downloaderDidResume(url:String){
        checkState(url)
    }
    public func downloaderCancelAll(){
        for url in self.urlToIndex.keys {
            checkState(url)
        }
    }
    public func downloaderDidCancel(url:String){
        checkState(url)
    }
    
    fileprivate func checkState(_ urlStr: String) {
        guard let index = self.urlToIndex[urlStr] else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        
        self.downloadItems[indexPath.row].downloadState = AHDownloader.getState(urlStr)
        if let cell = tableView.cellForRow(at: indexPath) as? AHFMDownloadListCell {
            cell.downloadItem?.downloadState = self.downloadItems[indexPath.row].downloadState
            cell.refreshDownloadState()
        }
    }
    
}

//MARK:- AHFMDownloadListCellDelegate
extension AHFMDownloadListVC: AHFMDownloadListCellDelegate{
    func listCellDidTapDownloadBtn(_ cell: AHFMDownloadListCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let item = self.downloadItems[indexPath.row]
            if item.downloadState == .notStarted {
                if let progress = item.downloadedProgress, progress > 0.0 {
                    
                }else{
                    AHDownloader.download(item.remoteURL)
                }
                
            }
           
    
        }
    }
}

//MARK:- UIControl Events
extension AHFMDownloadListVC {
    func downloadCenterBtn(_ sender: UIButton) {
        manager?.downloadListVCDidTapNavBarRightButton(self)
    }
    
    func allBtnTapped(_ sender: UIButton) {
        for item in self.downloadItems{
            if item.downloadState == .notStarted || item.downloadState == .failed {
                AHDownloader.download(item.remoteURL)
            }
        }
        
    }
    func backBtnTapped(_ sender: UIButton) {
        if self.navigationController == nil {
            self.dismiss(animated: true, completion: nil)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
}

//MARK:- Setup
extension AHFMDownloadListVC {
    fileprivate func setupUI() {
        // setup tableView
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        let currentBundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMDownloadListCell.self)", bundle: currentBundle)
        tableView.register(nib, forCellReuseIdentifier: AHFMDownloadListCellID)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.lightGray
        tableView.backgroundColor = UIColor.white
        // this line is to prevent extra separators in the bottom
        tableView.tableFooterView = UIView()
        tableView.contentInset.top = 64.0
        tableView.contentInset.bottom = BottomBarHeight + TopSeparatorHeight
        tableView.estimatedRowHeight = 100.0
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        
        // setup navBar
        let backBtn = UIButton()
        let backImg = UIImage(name: "back-black", user: self)
        backBtn.setImage(backImg, for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnTapped(_:)), for: .touchUpInside)
        backBtn.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        if shouldShowRightNavBarButton {
            let downloadsBtn = UIButton()
            downloadsBtn.setTitle("More", for: .normal)
            downloadsBtn.setTitleColor(UIColor.black, for: .normal)
            downloadsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
            downloadsBtn.addTarget(self, action: #selector(downloadCenterBtn(_:)), for: .touchUpInside)
            downloadsBtn.contentVerticalAlignment = .bottom
            downloadsBtn.contentHorizontalAlignment = .right
            downloadsBtn.sizeToFit()
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: downloadsBtn)
        }
        
        
        
        // setup bottom download option
        let bottomBar = UIView()
        bottomBar.frame = CGRect(x: 0, y: self.view.bounds.height - BottomBarHeight, width: self.view.bounds.width, height: BottomBarHeight)
        bottomBar.backgroundColor = UIColor.white
        self.view.addSubview(bottomBar)
        // add 'download all' button
        let allBtn = UIButton()
        allBtn.setTitle("Download All", for: .normal)
        allBtn.setTitleColor(UIColor.black, for: .normal)
        allBtn.titleLabel?.textAlignment = .center
        allBtn.frame.size = CGSize(width: bottomBar.frame.width * 0.5, height: bottomBar.frame.height * 0.8)
        allBtn.center = CGPoint(x: bottomBar.frame.width * 0.5, y: bottomBar.frame.height * 0.5)
        allBtn.layer.cornerRadius = 5.0
        allBtn.layer.borderColor = UIColor.gray.cgColor
        allBtn.layer.borderWidth = 1.0
        
        allBtn.addTarget(self, action: #selector(allBtnTapped(_:)), for: .touchUpInside)
        bottomBar.addSubview(allBtn)
        // add top separator
        let topSeparator = UIView()
        topSeparator.frame = CGRect(x: 0, y: -TopSeparatorHeight, width: bottomBar.frame.width, height: TopSeparatorHeight)
        topSeparator.backgroundColor = UIColor.lightGray
        self.spaceUsedLabel.text = "Free Space: \(UIDevice.freeDiskSpaceStr)MB"
        self.spaceUsedLabel.font = UIFont.systemFont(ofSize: 17.0)
        self.spaceUsedLabel.textColor = UIColor.white
        self.spaceUsedLabel.textAlignment = .center
        self.spaceUsedLabel.frame = topSeparator.bounds
        topSeparator.addSubview(self.spaceUsedLabel)
        
        bottomBar.addSubview(topSeparator)
        
    }
}



