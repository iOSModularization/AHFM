//
//  AHFMShowPageVC.swift
//  Pods
//
//  Created by Andy Tong on 7/25/17.
//
//

import UIKit
import AHAudioPlayer
import SVProgressHUD
import AHDownloader
import AHDownloadTool

fileprivate let ScreenSize = UIScreen.main.bounds.size

fileprivate let NavBarHeight: CGFloat = 64.0

fileprivate let ShowHeaderHeight: CGFloat = NavBarHeight + 150.0 + 40.0
fileprivate let ShowHeaderOriginY: CGFloat = 0.0

fileprivate let SectionViewHeight: CGFloat = 38.0
fileprivate let SectionOriginY: CGFloat = ShowHeaderOriginY + ShowHeaderHeight

fileprivate let Y_Inset: CGFloat = SectionOriginY + SectionViewHeight


@objc public protocol AHFMShowPageVCDelegate: class {
    /// Call localInitialShow(_ data: [String: Any]?)
    func showPageVCShouldLoadInitialShow(_ vc: UIViewController)
    
    /// Call loadEpisodes(_ data: [[String: Any]]?)
    func showPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int)
    
    /// Call shouldLoadRecommendedShows(_ data: [[String: Any]]?)
    func showPageVC(_ vc: UIViewController, shouldLoadRecommendedShowsForShow showId: Int)
    
    /// Did select show's episode
    func showPageVCDidSelectEpisode(_ vc: UIViewController, show showId: Int, currentEpisode episodeId: Int)
    
    /// Did select recommended show
    func showPageVCDidSelectRecommendedShow(_ vc: UIViewController, recommendedShow showId: Int)
    
    /// Call loadSubscribeOrUnSubcribeShow(_ data: [String:Any]?)
    /// data example: ["showId": Int, "isSubcribed": Bool]
    /// isSubcribed is the current state after this method is called.
    func showPageVC(_ vc: UIViewController, shouldSubscribeOrUnSubcribeShow showId: Int, shouldSubscribed: Bool)
    
    /// This method should lead to some other VC page
    func showPageVCDidTappDownloadBtnTapped(_ vc: UIViewController, forshow showId: Int)
    
    func showPageVCWillPresentIntroVC(_ showVC: UIViewController)
    func showPageVCWillDismissIntroVC(_ showVC: UIViewController)
    
    func viewWillAppear(_ vc: UIViewController)
    func viewWillDisappear(_ vc: UIViewController)
}


//MARK:-
public final class AHFMShowPageVC: UIViewController {
    public var manager: AHFMShowPageVCDelegate?
    
    var show: Show? {
        didSet {
            if let show = show {
                showHeader.show = show
                titleLabel.text = show.title
                showHeader.isSubscribed = show.isSubscribed
            }
        }
    }
    
    var episodes: [Episode]? {
        didSet {
            if let episodes = episodes {
                showPageCellDataSource.episodes = episodes
            }
        }
    }
    
    fileprivate let titleLabel = UILabel()
    fileprivate weak var navBar: UINavigationBar!
    fileprivate weak var showHeader: AHFMShowHeader!
    fileprivate var recommendedShows: [Show]? {
        didSet{
            if let recommendedShows = recommendedShows {
                showRecommendDataSource.shows = recommendedShows
            }
        }
    }
    
    /// For current shows' episodes
    fileprivate var currentTableView: UITableView!
    
    /// For recommended episodes
    fileprivate var recommendedTableView: UITableView!
    fileprivate weak var sectionView: AHSectionView!
    
    fileprivate var epSectionleft = UIButton(type: .custom)
    fileprivate var epSectionRight = UIButton(type: .custom)
    
    
    
    fileprivate let showPageCellDataSource = AHFMShowPageDataSource()
    fileprivate let showRecommendDataSource = AHFMShowRecomendDataSource()
    
    // when there's playing episode in this show
    fileprivate var playingMode = false
    fileprivate var playingModeOffsetY = Y_Inset
    // determine wether or not to call checkCurrentEpisode()
    fileprivate var shouldCheckCurrentEpisode = true
    
    
}

//MARK:- Loading Methods
extension AHFMShowPageVC {
    /// Call localInitialShow(_ data: [String: Any]?)
    public func localInitialShow(_ data: [String: Any]?) {
        guard let data = data else {
            return
        }
        self.show = Show(data)
        manager?.showPageVC(self, shouldLoadEpisodesForShow: self.show!.id)
    }
    
    public func loadEpisodes(_ data: [[String: Any]]?) {
        guard let data = data else {
            return
        }
        var eps = [Episode]()
        for epDict in data {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        self.episodes = eps
        SVProgressHUD.dismiss()
    }
    
    /// Call loadSubscribeOrUnSubcribeShow(_ data: [String:Any]?)
    /// data example: ["showId": Int, "isSubcribed": Bool]
    /// isSubcribed is the current state after this method is called.
    public func loadSubscribeOrUnSubcribeShow(_ data: [String:Any]?) {
        SVProgressHUD.dismiss()
        guard let data = data, let showId = data["showId"] as? Int,
            let isSubcribed = data["isSubcribed"] as? Bool,
            let show = self.show,
            show.id == showId else {
                
                showHeader.isSubscribed = false
                return
        }
        
        showHeader.isSubscribed = isSubcribed
    }
    
    /// Call shouldLoadRecommendedShows(_ data: [[String: Any]]?)
    public func shouldLoadRecommendedShows(_ data: [[String: Any]]?) {
        guard let data = data else {
            return
        }
        var shows = [Show]()
        for showDict in data {
            let show = Show(showDict)
            shows.append(show)
        }
        self.recommendedShows = shows
        SVProgressHUD.dismiss()
    }
}


//MARK:- VC Life Cycle
extension AHFMShowPageVC {
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        setup()
        
        sectionView.select(index: 0, sendEvent: true)
        
        AHDownloader.addDelegate(self)
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // by default, hide navbar
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.barStyle = .black
        
        manager?.viewWillAppear(self)
        
        
        
        SVProgressHUD.show()
        manager?.showPageVCShouldLoadInitialShow(self)
        
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldCheckCurrentEpisode {
            checkCurrentEpisode()
        }else{
            shouldCheckCurrentEpisode = true
        }
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.presentedViewController != nil {
            // there's a vc presented by this vc
            // it could be a episodelistVC from bottomPlayer, or a introVC from this VC.
            shouldCheckCurrentEpisode = false
        }else{
            navBar.setBackgroundImage(nil, for: .default)
            navBar.shadowImage = nil
            navBar.barStyle = .default
        }
        
        manager?.viewWillDisappear(self)
        
        
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

//MARK:- AHDownloaderDelegate
extension AHFMShowPageVC: AHDownloaderDelegate {
    public func downloaderDidStartDownload(url:String){
        updateDownloadState(forUrl: url)
    }
    public func downloaderDidFinishDownload(url:String, localFilePath: String){
        updateDownloadState(forUrl: url)
    }
    public func downloaderDidPaused(url: String){
        updateDownloadState(forUrl: url)
    }
    public func downloaderDidPausedAll(){
        guard let eps = self.episodes else {
            return
        }
        for ep in eps {
            updateDownloadState(forUrl: ep.remoteURL ?? "")
        }
    }
    public func downloaderDidResumedAll(){
        guard let eps = self.episodes else {
            return
        }
        for ep in eps {
            updateDownloadState(forUrl: ep.remoteURL ?? "")
        }
    }
    public func downloaderDidResume(url:String){
        updateDownloadState(forUrl: url)
    }
    public func downloaderCancelAll(){
        guard let eps = self.episodes else {
            return
        }
        for ep in eps {
            updateDownloadState(forUrl: ep.remoteURL ?? "")
        }
    }
    public func downloaderDidCancel(url:String){
        updateDownloadState(forUrl: url)
    }
}

//MARK:- TableView Delegate
extension AHFMShowPageVC: UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard navBar != nil else {
            return
        }
        
        if scrollView === currentTableView {
            handleEpisodeShowHeader(scrollView)
            handleEpisodeSectionView(scrollView)
        }else{
            handleRecommendShowHeader(scrollView)
            handleRecommendSectionView(scrollView)
        }
        
        
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if playingMode {
            if scrollView.contentOffset.y < playingModeOffsetY {
                playingModeOffsetY = scrollView.contentOffset.y
            }
            
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? AHFMShowPageCell else {
            return
        }
        guard let eps = self.episodes else {
            return
        }
        let ep = eps[indexPath.row]
        
        let state = ep.downloadState
        switch state {
        case .notStarted:
            cell.normal()
        case .pausing:
            cell.pause()
        case .downloading:
            cell.downloading()
        case .succeeded:
            cell.downloaded()
        case .failed:
            cell.normal()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === self.currentTableView, let cell = tableView.cellForRow(at: indexPath) as? AHFMShowPageCell {
            guard let show = self.show else {
                return
            }
            if let ep = cell.episode {
                manager?.showPageVCDidSelectEpisode(self, show: show.id, currentEpisode: ep.id)
                
            }
            
        }else if tableView === self.recommendedTableView, let cell = tableView.cellForRow(at: indexPath) as? AHFMShowRecommendCell{
            
            guard let show = cell.show else {
                print("cell.show is nil ????")
                return
            }
            
            manager?.showPageVCDidSelectRecommendedShow(self, recommendedShow: show.id)
            
        }
    }
}

//MARK:- Control Events
extension AHFMShowPageVC {
    /// Adjust tableviews when switching.
    private func adjustment(_ tableView: UITableView) {
        tableView.contentInset.top = sectionView.frame.maxY
        tableView.contentOffset.y = -sectionView.frame.maxY
        self.view.insertSubview(tableView, belowSubview: showHeader)
        tableView.contentInset.top = Y_Inset
    }
    
    func sectionBtnsTapped(_ button: UIButton) {
        if button == epSectionleft {
            // epBtn left
            recommendedTableView.removeFromSuperview()
            adjustment(currentTableView)
            
        }else{
            // epBtn right
            playingMode = false
            currentTableView.removeFromSuperview()
            adjustment(recommendedTableView)
            
            
            // check if there's data,
            // if recommendedShows.count > 0 means the related shows are already being retrived.
            if let recommendedShows = self.recommendedShows, recommendedShows.count > 0{
                recommendedTableView.reloadData()
            }else{
                // Retrive related eps based current playing episode if any
                // or pick the first ep of the show for it.
                
                guard let show = show else {
                    return
                }
                SVProgressHUD.show()
                manager?.showPageVC(self, shouldLoadRecommendedShowsForShow: show.id)
            }
            
            
            
        }
    }
    
    func backBtnTapped(_ sender: UIBarButtonItem) {
        if self.navigationController == nil {
            self.dismiss(animated: true, completion: nil)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
}


//MARK:- Recommend TableView Scrolling
extension AHFMShowPageVC {
    func handleRecommendShowHeader(_ scrollView: UIScrollView) {
        let toolView = showHeader.toolBar
        if scrollView.contentOffset.y >= -Y_Inset {
            // Position Y
            // yOffset is negative within Y_Inset!!
            // following tableView scrolling up
            // delta is the distance tableView scrolling up, is positive
            let delta = (Y_Inset + scrollView.contentOffset.y)
            showHeader.frame.origin.y = ShowHeaderOriginY - delta
            
            let toolDelta = showHeader.frame.maxY - navBar.frame.maxY
            let toolTotal = ShowHeaderOriginY + ShowHeaderHeight
            //######
            var alpha = toolDelta / toolTotal
            // A quick fix for toolView?.alpha remaining at 0.748, but reaching 1.
            var fixMe: Any?
            if alpha > 0.74 {
                alpha = 1.0
            }
            toolView?.alpha = alpha
            //######
            if showHeader.frame.maxY <= NavBarHeight  {
                showHeader.frame.origin.y = -ShowHeaderHeight + NavBarHeight
            }
            
        }else{
            toolView?.alpha = 1.0
            // Scrolling too far, stick to its originY
            showHeader.frame.origin.y = ShowHeaderOriginY
        }
    }
    
    func handleRecommendSectionView(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= -Y_Inset {
            // Position Y
            // yOffset is negative within Y_Inset!!
            // following tableView scrolling up
            // delta is the distance tableView scrolling up, is positive
            let delta = (Y_Inset + scrollView.contentOffset.y)
            sectionView.frame.origin.y = SectionOriginY - delta
            
            if sectionView.frame.origin.y <= NavBarHeight {
                // sticking at 64.0
                sectionView.frame.origin.y = NavBarHeight
            }
        }else{
            // Scrolling too far, stick to its originY
            sectionView.frame.origin.y = SectionOriginY
            
        }
    }
}

//MARK:- Episode TableView Scrolling
extension AHFMShowPageVC {
    func handleEpisodeShowHeader(_ scrollView: UIScrollView) {
        
        let toolView = showHeader.toolBar
        
        var y_inset = Y_Inset
        if playingMode &&  scrollView === currentTableView {
            y_inset = playingModeOffsetY
            if scrollView.contentOffset.y > y_inset {
                // Position Y
                // yOffset is negative within Y_Inset!!
                // following tableView scrolling up
                // delta is the distance tableView scrolling up, is positive
                let delta = scrollView.contentOffset.y - y_inset
                showHeader.frame.origin.y = ShowHeaderOriginY - delta
                //                print("offsetY:\(scrollView.contentOffset.y) y_inset:\(y_inset) delta:\(delta) SectionOriginY - delta:\(SectionOriginY - delta)")
                let toolDelta = showHeader.frame.maxY - navBar.frame.maxY
                let toolTotal = ShowHeaderOriginY + ShowHeaderHeight
                
                //######
                var alpha = toolDelta / toolTotal
                // A quick fix for toolView?.alpha remaining at 0.748, but reaching 1.
                var fixMe: Any?
                if alpha > 0.74 {
                    alpha = 1.0
                }
                toolView?.alpha = alpha
                //######
                
                if showHeader.frame.maxY <= NavBarHeight  {
                    // origin.y is realdy negative since showHeader's top edge is alrady out of screen, so use -ShowHeaderHeight and then take out NavBarHeight.
                    showHeader.frame.origin.y = -ShowHeaderHeight + NavBarHeight
                    playingMode = false
                }
            }else{
                // Scrolling too far, stick to its originY
                showHeader.frame.origin.y = ShowHeaderOriginY
                toolView?.alpha = 1.0
                if scrollView.contentOffset.y <= -Y_Inset  {
                    playingMode = false
                    scrollView.contentInset.top = Y_Inset
                    
                }
            }
        }else{
            
            if scrollView.contentOffset.y >= -Y_Inset {
                // Position Y
                // yOffset is negative within Y_Inset!!
                // following tableView scrolling up
                // delta is the distance tableView scrolling up, is positive
                let delta = (Y_Inset + scrollView.contentOffset.y)
                showHeader.frame.origin.y = ShowHeaderOriginY - delta
                
                let toolDelta = showHeader.frame.maxY - navBar.frame.maxY
                let toolTotal = ShowHeaderOriginY + ShowHeaderHeight
                //######
                var alpha = toolDelta / toolTotal
                // A quick fix for toolView?.alpha remaining at 0.748, but reaching 1.
                var fixMe: Any?
                if alpha > 0.74 {
                    alpha = 1.0
                }
                toolView?.alpha = alpha
                //######
                if showHeader.frame.maxY <= NavBarHeight  {
                    showHeader.frame.origin.y = -ShowHeaderHeight + NavBarHeight
                }
                
            }else{
                toolView?.alpha = 1.0
                // Scrolling too far, stick to its originY
                showHeader.frame.origin.y = ShowHeaderOriginY
            }
            
        }
        
    }
    
    func handleEpisodeSectionView(_ scrollView: UIScrollView) {
        var y_inset = Y_Inset
        if playingMode &&  scrollView === currentTableView {
            y_inset = playingModeOffsetY
            if scrollView.contentOffset.y > y_inset {
                // Position Y
                // yOffset is negative within Y_Inset!!
                // following tableView scrolling up
                // delta is the distance tableView scrolling up, is positive
                let delta = scrollView.contentOffset.y - y_inset
                sectionView.frame.origin.y = SectionOriginY - delta
                //                print("offsetY:\(scrollView.contentOffset.y) y_inset:\(y_inset) delta:\(delta) SectionOriginY - delta:\(SectionOriginY - delta)")
                if sectionView.frame.origin.y <= NavBarHeight {
                    // sticking at 64.0
                    sectionView.frame.origin.y = NavBarHeight
                    playingMode = false
                }
            }else{
                // Scrolling too far, stick to its originY
                sectionView.frame.origin.y = SectionOriginY
                if scrollView.contentOffset.y <= -Y_Inset  {
                    playingMode = false
                    scrollView.contentInset.top = Y_Inset
                    
                }
            }
        }else{
            if scrollView.contentOffset.y >= -Y_Inset {
                // Position Y
                // yOffset is negative within Y_Inset!!
                // following tableView scrolling up
                // delta is the distance tableView scrolling up, is positive
                let delta = (Y_Inset + scrollView.contentOffset.y)
                sectionView.frame.origin.y = SectionOriginY - delta
                
                if sectionView.frame.origin.y <= NavBarHeight {
                    // sticking at 64.0
                    sectionView.frame.origin.y = NavBarHeight
                }
            }else{
                // Scrolling too far, stick to its originY
                sectionView.frame.origin.y = SectionOriginY
                
            }
        }
        
        
    }
}

//MARK:- AHFMShowHeaderDelegate
extension AHFMShowPageVC: AHFMShowHeaderDelegate {
    public func showHeaderLikeBtnTapped(_ header: AHFMShowHeader) {
        guard let show = self.show else {
            return
        }
        if header.isSubscribed {
            self.manager?.showPageVC(self, shouldSubscribeOrUnSubcribeShow: show.id, shouldSubscribed: false)
            
        }else{
            SVProgressHUD.show()
            // fake networking delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.manager?.showPageVC(self, shouldSubscribeOrUnSubcribeShow: show.id, shouldSubscribed: true)
            }
            
        }
        
        
    }
    
    
    public func showHeaderShareBtnTapped(_ header: AHFMShowHeader){
        print("showHeaderShareBtnTapped")
    }
    public func showHeaderDownloadBtnTapped(_ header: AHFMShowHeader){
        guard let show = self.show else {
            return
        }
        manager?.showPageVCDidTappDownloadBtnTapped(self, forshow: show.id)
    }
    public func showHeaderIntroTapped(_ header: AHFMShowHeader){
        let vc = AHFMShowIntroVC()
        vc.show = show
        vc.dismissBlock = {
            self.manager?.showPageVCWillDismissIntroVC(self)
        }
        manager?.showPageVCWillPresentIntroVC(self)
        present(vc, animated: false, completion: nil)
    }
}

//MARK:- Helpers
extension AHFMShowPageVC {
    fileprivate func urlToIndexPath(url: String) -> IndexPath? {
        guard let eps = self.episodes else {
            return nil
        }
        let filteredEps = eps.filter { (ep) -> Bool in
            return ep.remoteURL == url
        }
        guard filteredEps.count > 0, let targetEp = filteredEps.first else {
            return nil
        }
        
        let index = eps.index { (ep) -> Bool in
            return ep.id == targetEp.id
        }
        guard index != nil else {
            return nil
        }
        
        let indexPath = IndexPath(row: index!, section: 0)
        return indexPath
    }
    fileprivate func updateDownloadState(forUrl url: String) {
        guard let indexPath = urlToIndexPath(url: url) else {
            return
        }
        let state = AHDownloader.getState(url)
        self.episodes?[indexPath.row].downloadState = state
        
        updateEpisodeCell(for: indexPath, state: state)
        
    }
    
    
    fileprivate func updateEpisodeCell(for indexPath: IndexPath, state: AHDataTaskState) {
        guard let cell = currentTableView.cellForRow(at: indexPath) as? AHFMShowPageCell else {
            return
        }
        
        
        switch state {
        case .notStarted:
            cell.normal()
        case .pausing:
            cell.pause()
        case .downloading:
            cell.downloading()
        case .succeeded:
            cell.downloaded()
        case .failed:
            cell.normal()
        }
        
        
        
    }
    
    
    
    /// The gateway for 'playingMoe'.
    /// Check if there's any episode that audioPlayer is playing and scroll to that playing episode and other sticky header related operations.
    fileprivate func checkCurrentEpisode() {
        guard let episodes = self.episodes else {
            return
        }
        if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId {
            
            var index: Int? = nil
            for i in 0..<episodes.count {
                let ep = episodes[i]
                if ep.id == playingTrackId {
                    index = i
                }
            }
            
            if index != nil {
                adjustForPlayingMode(forEpisodeAtIndex: index!)
            }
            
        }
    }
    
    
    
    func adjustForPlayingMode(forEpisodeAtIndex index: Int) {
        let playingIndexPath = IndexPath(row: index, section: 0)
        // you have scroll it first in order to get the cell
        self.currentTableView.scrollToRow(at: playingIndexPath, at: .top, animated: false)
        if let cell = self.currentTableView.cellForRow(at: playingIndexPath) {
            // positioning the cell right below sectionView + 20.0
            var offsetY = cell.frame.origin.y - Y_Inset - 20.0
            if offsetY < 0 {
                offsetY = -Y_Inset
            }
                
                // check if the add-up offsetY + one screen height is larger than contentSize.height
            else if offsetY + ScreenSize.height > self.currentTableView.contentSize.height {
                // assign the last screen to offsetY
                //TODO: figure out how/why that extra 1.0 prevent the header flip the top when the currentEpisdoe the in last screen. Take it off and assign the last ep, and see what happen. Then do research here.
                offsetY = self.currentTableView.contentSize.height - ScreenSize.height - 1.0
            }
                // check if it will be too far down below the inset for first several cells which already in display.
            else if offsetY < -Y_Inset{
                offsetY = -Y_Inset
            }
            playingModeOffsetY = offsetY
            playingMode = true
            self.currentTableView.contentOffset.y = offsetY
        }
    }
}

//MARK:- Setups
extension AHFMShowPageVC {
    fileprivate func setup() {
        // All sizes and frames are based on ScreenSize and they are fixed.
        
        // TableView, on the bottom of the view hierarchy
        let tableViewRect = CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height)
        let tableView = UITableView(frame: tableViewRect, style: .plain)
        tableView.delegate = self
        tableView.dataSource = showPageCellDataSource
        tableView.backgroundColor = UIColor.white
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 50.0
        tableView.contentInset = .init(top: Y_Inset, left: 0, bottom: 49.0, right: 0)
        showPageCellDataSource.tablView = tableView
        self.currentTableView = tableView
        
        // recommendedTableView
        
        let recommendedTableView = UITableView(frame: tableViewRect, style: .plain)
        recommendedTableView.delegate = self
        recommendedTableView.dataSource = showRecommendDataSource
        recommendedTableView.backgroundColor = UIColor.white
        recommendedTableView.separatorStyle = .none
        recommendedTableView.estimatedRowHeight = 60.0
        recommendedTableView.contentInset = .init(top: Y_Inset, left: 0, bottom: 49.0, right: 0)
        showRecommendDataSource.tablView = recommendedTableView
        self.recommendedTableView = recommendedTableView
        
        // Show Header
        let showHeader = AHFMShowHeader.loadNib()
        showHeader.frame = CGRect(x: 0, y: 0.0, width: ScreenSize.width, height: ShowHeaderHeight)
        showHeader.backgroundColor = UIColor.white
        showHeader.delegate = self
        self.view.addSubview(showHeader)
        self.showHeader = showHeader
        
        
        // SectionView
        let sectionView = AHSectionView()
        sectionView.frame = CGRect(x: 0, y: SectionOriginY, width: ScreenSize.width, height: SectionViewHeight)
        sectionView.backgroundColor = UIColor.white
        self.view.addSubview(sectionView)
        self.sectionView = sectionView
        
        // add section buttons
        
        
        epSectionleft.frame = .init(x: 0, y: 0, width: sectionView.bounds.width * 0.5, height: sectionView.bounds.height)
        epSectionleft.addTarget(self, action: #selector(sectionBtnsTapped(_:)), for: .touchUpInside)
        epSectionleft.setTitle("Episodes", for: .normal)
        epSectionleft.setTitleColor(UIColor.black, for: .normal)
        sectionView.addSection(epSectionleft)
        
        
        epSectionRight.frame = .init(x: sectionView.bounds.width * 0.5, y: 0, width: sectionView.bounds.width * 0.5, height: sectionView.bounds.height)
        epSectionRight.addTarget(self, action: #selector(sectionBtnsTapped(_:)), for: .touchUpInside)
        epSectionRight.setTitle("Recoomended", for: .normal)
        epSectionRight.setTitleColor(UIColor.black, for: .normal)
        sectionView.addSection(epSectionRight)
        
        
        // NavBar, on the top of the view hierarchy
        let navBar = self.navigationController!.navigationBar
        //        navBar.setBackgroundImage(UIImage(), for: .default)
        //        navBar.shadowImage = UIImage()
        //        navBar.isTranslucent = true
        
        let backImage = UIImage(name: "back", user: self)?.withRenderingMode(.alwaysOriginal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backBtnTapped(_:)))
        
        
        titleLabel.frame.size = CGSize(width: 200, height: 64)
        titleLabel.text = "Title Undefined"
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17.0)
        
        self.navigationItem.titleView = titleLabel
        
        self.navBar = navBar
    }
}


struct Episode {
    var id: Int
    var remoteURL: String?
    var title: String?
    var createdAt: String?
    var duration: TimeInterval?
    var downloadedProgress: Double?
    var downloadState: AHDataTaskState = .notStarted
    
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.remoteURL = dict["remoteURL"] as? String
        self.title = dict["title"] as? String
        self.duration = dict["duration"] as? TimeInterval
        self.createdAt = dict["createdAt"] as? String
        self.downloadedProgress = dict["downloadedProgress"] as? Double
        
        if let remoteURL = self.remoteURL{
            if let isDownloaded = dict["isDownloaded"] as? Bool, isDownloaded == true {
                self.downloadState = .succeeded
            }else if let progress = self.downloadedProgress, progress > 0, AHDownloader.getState(remoteURL) == .notStarted{
                // the task is not started yet there's a downloaded progress -- this is an archived task.
                self.downloadState = .pausing
            }else{
                self.downloadState = AHDownloader.getState(remoteURL)
            }
        }else{
            self.downloadState = .failed
        }
        
        
        
    }
    
}

struct Show: Equatable {
    var id: Int
    var title: String
    var detail: String
    var fullCover: String
    var thumbCover: String
    var isSubscribed: Bool
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.title = dict["title"] as! String
        self.fullCover = dict["fullCover"] as! String
        self.thumbCover = dict["thumbCover"] as! String
        self.detail = dict["detail"] as! String
        self.isSubscribed = dict["isSubscribed"] as! Bool
    }
    
    public static func ==(lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}
