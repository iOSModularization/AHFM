//
//  AHFMDownloadCenter.swift
//  Pods
//
//  Created by Andy Tong on 8/8/17.
//
//

import UIKit
import AHCategoryView
import AHDownloader

private let ScreenSize = UIScreen.main.bounds.size

@objc public protocol AHFMDownloadCenterDelegate: class {
    //###### From downloadCeter itself
    /// Call loadTotalNumbOfTasks:
    func downloadCenter(_ vc: UIViewController, shouldCountTaskWithCurrentTasks urls: [String])
    
    //###### From downloadedVC and showPage
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectShow showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int)
    func downloadedVCShowPage(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int)
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    
    /// Delete downloaded episodes for this showId
    /// You should delete the info in the DB, AND their local actual files
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int)
    
    /// Call loadDownloadedShows(_:) when ready
    /// Load all shows with at least one downloaded episode
    func downloadedVCLoadDownloadedShows(_ vc: UIViewController)
    
    /// Delete all downloaded episodes for this showId
    func downloadedVC(_ vc: UIViewController, shouldDeleteShow showId: Int)
    
    /// You should unmark AHFMShow's hasNewDownload property for the showId
    func downloadedVC(_ vc: UIViewController, willEnterShowPageWithShowId showId: Int)
    
    /// Fetch the show that has an episode with that specific remote URL
    /// Call addHasNewDownloaded(_) when the data is ready
    func downloadedVC(_ vc: UIViewController, shouldFetchShowWithEpisodeRemoteURL url: String)
    
    
    
    
    //##### From downloadingVC
    func downloadingVCGetCurrentDownloads(_ vc: UIViewController, urls: [String])
    func downloadingVCGetArchivedDownloads(_ vc: UIViewController)
    
    /// Delete any info related to download in the DB, AND need to remove actual unfinished temp files.
    func downloadingVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int)
    
    
    
}


struct Show: Equatable {
    var id: Int
    var hasNewDownload = false
    var thumbCover: String
    var title: String
    var detail: String
    var numberOfDownloaded: Int
    var totalDownloadedSize: Int
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.hasNewDownload = dict["hasNewDownload"] as! Bool
        self.thumbCover = dict["thumbCover"] as! String
        self.title = dict["title"] as! String
        self.detail = dict["detail"] as! String
        self.numberOfDownloaded = dict["numberOfDownloaded"] as! Int
        self.totalDownloadedSize = dict["totalDownloadedSize"] as! Int
    }
    
    public static func ==(lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Episode {
    var id: Int
    var showId: Int
    var remoteURL: String
    var title: String
    var fileSize: Int?
    var duration: TimeInterval?
    var lastPlayedTime: TimeInterval?
    var downloadedProgress: Double?
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.remoteURL = dict["remoteURL"] as! String
        self.title = dict["title"] as! String
        self.fileSize = dict["fileSize"] as? Int
        self.duration = dict["duration"] as? TimeInterval
        self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
        self.downloadedProgress = dict["downloadedProgress"] as? Double
    }
    
    public static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }
}


public class AHFMDownloadCenter: UIViewController {
    public var manager: AHFMDownloadCenterDelegate?
    
    fileprivate lazy var downloadedVC:AHFMDownloadedVC = AHFMDownloadedVC()
    fileprivate lazy var downloadingVC:AHFMDownloadingVC = AHFMDownloadingVC()
    fileprivate weak var categoryView: AHCategoryView!
    
    fileprivate var totalNumbOfTasks = 0
    fileprivate var isDownloadingVCLoaded = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.lightGray
        self.automaticallyAdjustsScrollViewInsets = false

        downloadedVC.delegate = self
        downloadingVC.delegate = self
        AHDownloader.addDelegate(self)
        
        
        var downloadedItem = AHCategoryItem()
        downloadedItem.title = "Downloaded"
        var downloadingItem = AHCategoryItem()
        downloadingItem.title = "Downloading"
        let items = [downloadedItem, downloadingItem]
        
        let frame = CGRect(x: 0, y: 64.0, width: ScreenSize.width, height: ScreenSize.height - 64.0)
        
        var style = AHCategoryNavBarStyle()
        style.isScrollabel = false
        style.layoutAlignment = .center
        style.showBottomSeparator = true
        style.indicatorColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        style.normalColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        style.selectedColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        let categoryView = AHCategoryView(frame: frame, categories: items, childVCs: [downloadedVC, downloadingVC], parentVC: self, barStyle: style)
        self.view.addSubview(categoryView)
        self.categoryView = categoryView
        
        // setup navBar
        let backBtn = UIButton()
        let backImg = UIImage(name: "back-black", user: self)
        backBtn.setImage(backImg, for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnTapped(_:)), for: .touchUpInside)
        backBtn.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        self.navigationItem.title = "Download Center"
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let urls = AHDownloader.getCurrentTaskURLs()
        self.manager?.downloadCenter(self, shouldCountTaskWithCurrentTasks: urls)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    func backBtnTapped(_ button: UIButton) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
}

//MARK:- Loading Methods
extension AHFMDownloadCenter {
    public func loadTotalNumbOfTasks(_ totalCountDict: [String: Any]) {
        totalNumbOfTasks = totalCountDict["count"] as! Int
        self.categoryView.setBadge(atIndex: 1, numberOfBadge: totalNumbOfTasks)
    }
    
    
    public func loadDownloadedShows(_ showArr: [[String: Any]]) {
        var shows = [Show]()
        for showDict in showArr {
            let show = Show(showDict)
            shows.append(show)
        }
        downloadedVC.loadDownloadedShows(shows)
    }
    
    public func loadEpisodesForShow(_ showId: Int, episodeArr: [[String: Any]]) {
        var eps = [Episode]()
        for epDict in episodeArr {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        downloadedVC.loadEpisodesForShow(showId, eps: eps)
    }
    
    func addCurrentDownloads(_ episodeArr: [[String: Any]]) {
        var eps = [Episode]()
        for epDict in episodeArr {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        isDownloadingVCLoaded = true
        downloadingVC.addCurrentDownloads(eps)
    }
    
    func addArchivedDownloads(_ episodeArr: [[String: Any]]) {
        var eps = [Episode]()
        for epDict in episodeArr {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        downloadingVC.addArchivedDownloads(eps)
    }
    
    func addHasNewDownloaded(_ showDict: [String: Any]?) {
        if let showDict = showDict {
            let show = Show(showDict)
            downloadedVC.addHasNewDownloaded(show)
        }else{
            downloadedVC.addHasNewDownloaded(nil)
        }
        
    }
}

//MARK:- AHDownloaderDelegate
extension AHFMDownloadCenter: AHDownloaderDelegate {
    public func downloaderDidFinishDownload(url: String, localFilePath: String) {
        if isDownloadingVCLoaded == false {
            totalNumbOfTasks -= 1
            if totalNumbOfTasks < 0 {
                totalNumbOfTasks = 0
            }
            self.categoryView.setBadge(atIndex: 1, numberOfBadge: totalNumbOfTasks)
        }
    }
}


//MARK:- AHFMDownloadingVC Delegate
extension AHFMDownloadCenter: AHFMDownloadingVCDelegate {
    func downloadingVCDownloadTaskDidChange(_ vc: AHFMDownloadingVC, currentTasks tasks: Int) {
        self.categoryView.setBadge(atIndex: 1, numberOfBadge: tasks)
    }
    /// Call addCurrentDownloads(_:)
    func downloadingVCGetCurrentDownloads(_ vc: AHFMDownloadingVC, urls: [String]){
        self.manager?.downloadingVCGetCurrentDownloads(self, urls: urls)
    }
    /// Call addArchivedDownloads(_:)
    func downloadingVCGetArchivedDownloads(_ vc: AHFMDownloadingVC){
        self.manager?.downloadingVCGetArchivedDownloads(self)
    }
    
    func downloadingVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int){
        self.manager?.downloadingVC(self, shouldDeleteEpisodes: episodeIDs, forShow: showId)
    }
}

//MARK:- AHFMDownloadedVC Delegate
extension AHFMDownloadCenter: AHFMDownloadedVCDelegate {
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int){
        self.manager?.downloadedShowPageVC(self, shouldLoadEpisodesForShow: showId)
    }
    func downloadedVCShowPage(_ vc: UIViewController, didSelectShow showId: Int){
        self.manager?.downloadedVCShowPage(self, didSelectShow: showId)
    }
    func downloadedVCShowPage(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int){
        self.manager?.downloadedVCShowPage(self, didSelectEpisode: episodeId, showId: showId)
    }
    func downloadedVCShowPage(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int){
        self.manager?.downloadedVCShowPage(self, didSelectDownloadMoreForShow: showId)
    }
    
    /// Should hide or show bottomBar if there's any
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        self.manager?.downloadedShowPageVC(self, editingModeDidChange: isEditing)
    }
    
    /// Delete downloaded episodes for this showId
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int){
        self.manager?.downloadedShowPageVC(self, shouldDeleteEpisodes: episodeIDs, forShow: showId)
    }
    
    
    /// Call loadDownloadedShows(_:) when ready
    /// Load all shows with at least one downloaded episode
    func downloadedVCLoadDownloadedShows(_ vc: UIViewController){
        self.manager?.downloadedVCLoadDownloadedShows(self)
    }
    
    /// Delete all downloaded episodes for this showId
    func downloadedVC(_ vc: UIViewController, shouldDeleteShow showId: Int){
        self.manager?.downloadedVC(self, shouldDeleteShow: showId)
    }
    
    /// You should unmark AHFMShow's hasNewDownload property for the showId
    func downloadedVC(_ vc: UIViewController, willEnterShowPageWithShowId showId: Int){
        self.manager?.downloadedVC(self, willEnterShowPageWithShowId: showId)
    }
    
    /// Call addNewDownloaded(_:) when the data is ready
    func downloadedVC(_ vc: UIViewController, shouldFetchShowWithEpisodeRemoteURL url: String){
        self.manager?.downloadedVC(self, shouldFetchShowWithEpisodeRemoteURL: url)
    }
}




