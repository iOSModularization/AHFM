//
//  AHFMDownloadingVC.swift
//  Pods
//
//  Created by Andy Tong on 8/8/17.
//
//

import UIKit
import AHDownloader

private let AHFMDownloadingCellId = "AHFMDownloadingCellId"

protocol AHFMDownloadingVCDelegate:class {
    func downloadingVCDownloadTaskDidChange(_ vc: AHFMDownloadingVC, currentTasks tasks: Int)
    /// Call addCurrentDownloads(_:)
    func downloadingVCGetCurrentDownloads(_ vc: AHFMDownloadingVC, urls: [String])
    /// Call addArchivedDownloads(_:)
    func downloadingVCGetArchivedDownloads(_ vc: AHFMDownloadingVC)
    
    /// Delete any info related to download in the DB, AND need to remove actual unfinished temp files.
    func downloadingVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int)
}

//MARK:-
class AHFMDownloadingVC: UIViewController {
    weak var delegate: AHFMDownloadingVCDelegate?

    fileprivate lazy var eps = [Episode]()
    
    fileprivate var currentDownloads = [Episode]()
    fileprivate var archivedDownloads = [Episode]()
    
    /// true when both current downloads and archived downloads arrived
    fileprivate lazy var isCurrentDownloadsArrived = false
    fileprivate lazy var isArchivedDownloadsArrived = false
    fileprivate weak var sectonView: UIView!
    fileprivate weak var tableView: UITableView!
    fileprivate weak var allPauseOrContinueBtn: UIButton!
    fileprivate weak var deleteAllBtn: UIButton!
    
}

//MARK:- VC Life Cycles
extension AHFMDownloadingVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        setupSectionView()
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.downloadingVCGetArchivedDownloads(self)
        let urls = AHDownloader.getCurrentTaskURLs()
        self.delegate?.downloadingVCGetCurrentDownloads(self, urls: urls)
        
    }
}


//MARK:- Loading Methods
extension AHFMDownloadingVC {
    func addCurrentDownloads(_ eps: [Episode]) {
        isCurrentDownloadsArrived = true
        guard eps.count > 0 else {
            return
        }
        currentDownloads.removeAll()
        currentDownloads.append(contentsOf: eps)
        if isArchivedDownloadsArrived {
            reload()
        }
        
    }
    
    func addArchivedDownloads(_ eps: [Episode]) {
        isArchivedDownloadsArrived = true
        guard eps.count > 0 else {
            return
        }
        archivedDownloads.removeAll()
        archivedDownloads.append(contentsOf: eps)
        if isCurrentDownloadsArrived {
            reload()
        }
    }
    
    fileprivate func reload() {
        self.eps.removeAll()
        self.eps.append(contentsOf: currentDownloads)
        self.eps.append(contentsOf: archivedDownloads)
        
        
        isCurrentDownloadsArrived = false
        isArchivedDownloadsArrived = false
        AHDownloader.addDelegate(self)
        self.tableView.reloadData()
    }
}


//MARK:- TableView Delegate/DataSource
extension AHFMDownloadingVC: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eps.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMDownloadingCellId, for: indexPath) as! AHFMDownloadingCell
        cell.delegate = self
        cell.episode = self.eps[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? AHFMDownloadingCell else {
            return
        }
        let ep = self.eps[indexPath.row]
        checkState(for: cell, with: ep.remoteURL)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
}

//MARK:- AHDownloaderDelegate
extension AHFMDownloadingVC: AHDownloaderDelegate {
    public func downloaderWillStartDownload(url:String){
        // cell should be in downloading mode once user tapp on the btn for downloading.
        
//        checkState(url)
    }
    public func downloaderDidStartDownload(url:String){
        checkState(url)
    }
    public func downloaderDidUpdate(url:String, progress:Double){
        guard let index = indexForUrl(url) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        
        guard let cell = self.tableView.cellForRow(at: indexPath) as? AHFMDownloadingCell else {
            return
        }
        
        cell.setProgressView(progress)
        
        checkState(url)
        
    }
    public func downloaderDidUpdate(url:String, fileSize:Int){
        guard let index = indexForUrl(url) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        var ep = self.eps[index]
        if ep.fileSize == nil {
            ep.fileSize = fileSize
            self.eps[index] = ep
            self.tableView.rectForRow(at: indexPath)
        }
        
    }
    
    public func downloaderDidFinishDownload(url:String, localFilePath: String){
//        guard let index = self.urlToIndex[url] else {
//            return
//        }
        // index wouldn't be consistent if there a task cell above this one and finished it ealier, then the index in self.urlToIndex won't be accurate anymore.
        
        guard let index = indexForUrl(url) else {
            return
        }
        
        self.eps.remove(at: index)
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.top)
        delegate?.downloadingVCDownloadTaskDidChange(self, currentTasks: self.eps.count)
    }
    public func downloaderDidPaused(url: String){
        checkState(url)
    }
    
    public func downloaderDidPausedAll(){
        for ep in self.eps {
            let url = ep.remoteURL
            checkState(url)
        }
    
    }
    public func downloaderDidResumedAll(){
        for ep in self.eps {
            let url = ep.remoteURL
            checkState(url)
        }
    }
    public func downloaderDidResume(url:String){
        checkState(url)
    }

}

//MARK:- AHFMDownloadingCellDelegate
extension AHFMDownloadingVC: AHFMDownloadingCellDelegate{
    func downloadingCellDidTapDownloadButtion(_ cell: AHFMDownloadingCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let ep = self.eps[indexPath.row]
        
        download(ep, cell: cell)
    }
    func download(_ ep: Episode, cell: AHFMDownloadingCell) {
        let state = AHDownloader.getState(ep.remoteURL)
        
        switch state {
        case .downloading:
            cell.pause()
            AHDownloader.pause(url: ep.remoteURL)
        case .pausing:
            cell.resume()
            AHDownloader.resume(url: ep.remoteURL)
        default:
            cell.resume()
            AHDownloader.download(ep.remoteURL)
        }
    }
}


//MARK:- Control Events
extension AHFMDownloadingVC {
    /// The sender being selected means it's in pause, normal is downloading.
    @objc fileprivate func allPauseOrContinue(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            sender.setTitle("Pause All", for: .normal)
            
            for ep in self.eps {
                let state = AHDownloader.getState(ep.remoteURL)
                if state == .notStarted{
                    AHDownloader.download(ep.remoteURL)
                }else if state == .pausing {
                    AHDownloader.resume(url: ep.remoteURL)
                }
                guard let index = indexForUrl(ep.remoteURL) else {
                    continue
                }
                let indexPath = IndexPath(row: index, section: 0)
                
                guard let cell = self.tableView.cellForRow(at: indexPath) as? AHFMDownloadingCell else {
                    continue
                }
                cell.resume()
            }
            
        }else{
            sender.isSelected = true
            for ep in self.eps {
                guard let index = indexForUrl(ep.remoteURL) else {
                    continue
                }
                let indexPath = IndexPath(row: index, section: 0)
                
                guard let cell = self.tableView.cellForRow(at: indexPath) as? AHFMDownloadingCell else {
                    continue
                }
                cell.pause()
            }
            sender.setTitle("Resume All", for: .normal)
            AHDownloader.pauseAll()
        }
    }
    
    @objc fileprivate func deleteAll(_ sender: UIButton) {
        
        var urlsInDownloader = [String]()
        for ep in self.eps {
            let state = AHDownloader.getState(ep.remoteURL)
            if state == .notStarted{
                self.delegate?.downloadingVC(self, shouldDeleteEpisodes: [ep.id], forShow: ep.showId)
            }else if state != .succeeded {
                urlsInDownloader.append(ep.remoteURL)
            }
        }
        
        self.eps.removeAll()
        self.tableView.reloadData()
        self.delegate?.downloadingVCDownloadTaskDidChange(self, currentTasks: 0)
        AHDownloader.deleteUnfinishedTasks(urlsInDownloader, nil)
    }
}

//MARK:- Helpers
extension AHFMDownloadingVC {
    func epForUrl(_ url: String) -> Episode? {
        let ep = self.eps.filter { (ep) -> Bool in
            return ep.remoteURL == url
        }.first
        return ep
    }
    
    func indexForUrl(_ url: String) -> Int? {
        guard let episode = epForUrl(url) else {
            return nil
        }
        let indexOptional = self.eps.index { (ep) -> Bool in
            return ep.remoteURL == episode.remoteURL
        }
        
        return indexOptional
        
    }
    
    fileprivate func checkState(_ url: String) {
        guard let index = indexForUrl(url) else {
            return
        }
        checkState(index)
    }
    
    
    fileprivate func checkState(_ index: Int) {
        let ep = self.eps[index]
        let indexPath = IndexPath(row: index, section: 0)
        
        guard let cell = self.tableView.cellForRow(at: indexPath) as? AHFMDownloadingCell else {
            return
        }
        
        checkState(for: cell, with: ep.remoteURL)
    }
    
    func checkState(for cell: AHFMDownloadingCell, with remotURL: String) {
        let state = AHDownloader.getState(remotURL)
        
        switch state {
        case .notStarted:
            cell.pause()
        case .downloading:
            cell.resume()
        case .pausing:
            cell.pause()
        case .succeeded:
            cell.finish()
        case .failed:
            cell.cancel()
        }
    }
}




//MARK:- Setup UI
extension AHFMDownloadingVC {
    fileprivate func setupSectionView() {
        let sectonView = UIView()
        sectonView.frame.origin.x = 0
        sectonView.frame.origin.y = 0
        sectonView.frame.size = CGSize(width: self.view.frame.width, height: 49.0)
        sectonView.backgroundColor = UIColor.white
        
        //        let topSeparator = UIView()
        //        topSeparator.frame = CGRect(x: 0, y: 0, width: sectonView.frame.width, height: 0.5)
        //        topSeparator.backgroundColor = UIColor.lightGray
        //        sectonView.addSubview(topSeparator)
        
        let bottomSeparator = UIView()
        bottomSeparator.frame = CGRect(x: 0, y: sectonView.frame.height - 1, width: sectonView.frame.width, height: 0.5)
        bottomSeparator.backgroundColor = UIColor.lightGray
        sectonView.addSubview(bottomSeparator)
        
        
        let btnWidth: CGFloat = (sectonView.frame.width - 16 * 3) / 2
        
        let allPauseOrContinueBtn = UIButton(type: .custom)
        allPauseOrContinueBtn.setTitle("Pause All", for: .normal)
        allPauseOrContinueBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        allPauseOrContinueBtn.setTitleColor(UIColor.lightGray, for: .normal)
        allPauseOrContinueBtn.layer.borderWidth = 0.5
        allPauseOrContinueBtn.layer.borderColor = UIColor.lightGray.cgColor
        allPauseOrContinueBtn.layer.cornerRadius = 5.0
        allPauseOrContinueBtn.addTarget(self, action: #selector(allPauseOrContinue(_:)), for: .touchUpInside)
        allPauseOrContinueBtn.frame.size.width = btnWidth
        allPauseOrContinueBtn.frame.size.height = sectonView.frame.height - 20.0
        allPauseOrContinueBtn.frame.origin.x = 16.0
        allPauseOrContinueBtn.frame.origin.y = 10.0
        sectonView.addSubview(allPauseOrContinueBtn)
        self.allPauseOrContinueBtn = allPauseOrContinueBtn
        
        let deleteAllBtn = UIButton(type: .custom)
        deleteAllBtn.setTitle("Delete All", for: .normal)
        deleteAllBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        deleteAllBtn.setTitleColor(UIColor.lightGray, for: .normal)
        deleteAllBtn.layer.borderWidth = 0.5
        deleteAllBtn.layer.borderColor = UIColor.lightGray.cgColor
        deleteAllBtn.layer.cornerRadius = 5.0
        deleteAllBtn.addTarget(self, action: #selector(deleteAll(_:)), for: .touchUpInside)
        deleteAllBtn.frame.size.width = btnWidth
        deleteAllBtn.frame.size.height = sectonView.frame.height - 20.0
        deleteAllBtn.frame.origin.x = 16.0 + allPauseOrContinueBtn.frame.maxX
        deleteAllBtn.frame.origin.y = 10.0
        sectonView.addSubview(deleteAllBtn)
        self.deleteAllBtn = deleteAllBtn
        
        self.view.addSubview(sectonView)
        self.sectonView = sectonView
    }
    
    
    fileprivate func setupTableView() {
        let tableViewFrame = CGRect(x: 0, y: sectonView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - sectonView.frame.height)
        let tableView = UITableView(frame: tableViewFrame, style: .plain)
        tableView.frame.origin.y = sectonView.frame.maxY
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset.bottom = 64.0
        tableView.separatorColor = UIColor.lightGray
        tableView.backgroundColor = UIColor.lightGray
        let currentBundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMDownloadingCell.self)", bundle: currentBundle)
        tableView.register(nib, forCellReuseIdentifier: AHFMDownloadingCellId)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
}



