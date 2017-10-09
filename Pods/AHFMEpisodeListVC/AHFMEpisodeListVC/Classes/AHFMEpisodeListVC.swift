//
//  AHFMEpisodeListVC.swift
//  Pods
//
//  Created by Andy Tong on 7/24/17.
//
//

import UIKit
import AHAudioPlayer
import BundleExtension
import SDWebImage

private let CellID = "AHFMEpisodeListCellID"


@objc public protocol AHFMEpisodeListVCDelegate: class {
    /// ["showId": 666]
    /// Call loadIntialShowid(_:)
    func AHFMEpisodeListVCShouldLoadInitialShowId(_ vc: UIViewController)
    
    /// Call loadShow(_:)
    func AHFMEpisodeListVC(_ vc: UIViewController, shouldLoadShow showId:Int)
    
    /// Call loadEpisode(_:episodeArr:)
    func AHFMEpisodeListVC(_ vc: UIViewController, shouldLoadEpisodes showId:Int)
}


struct Episode {
    var id: Int
    var showId: Int
    var remoteURL: String
    var title: String
    var duration: TimeInterval?
    var lastPlayedTime: TimeInterval?
    var isDownloaded: Bool?
    var localFilePath: String?
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.remoteURL = dict["remoteURL"] as! String
        self.title = dict["title"] as! String
        self.duration = dict["duration"] as? TimeInterval
        self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
        self.localFilePath = dict["localFilePath"] as? String
        self.isDownloaded = dict["isDownloaded"] as? Bool
    }
    
    public static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Show {
    var id: Int
    var title: String
    var fullCover: String?
    
    
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.title = dict["title"] as! String
        self.fullCover = dict["fullCover"] as? String
    }
    
    public static func ==(lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}


public class AHFMEpisodeListVC: UIViewController {
    public var manager: AHFMEpisodeListVCDelegate?

    weak var tableView: UITableView!
    var bgImageView: UIImageView?
    var showId: Int?
    var show: Show? {
        didSet {
            if let show = show {
                headerLabel.text = show.title
                headerLabel.textColor = UIColor.white
                headerLabel.sizeToFit()
                headerLabel.frame.size.width = 300.0
                headerLabel.textAlignment = .center
                headerLabel.center = CGPoint(x: self.headerView.bounds.width * 0.5, y: headerView.bounds.height * 0.7)
            }
        }
    }
    lazy var episodes = [Episode]()
    
    fileprivate var notificationhandlers = [NSObjectProtocol]()
    
    fileprivate var headerLabel = UILabel()
    fileprivate lazy var headerView = UIView()
    
    // key is indexPath.row, value is the episode's title height
    fileprivate var episodeTitleHeights = [CGFloat]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        setupBackground()
        setupTableView()
        setupHeader()
        
        let switchPlayHandler = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidSwitchPlay, object: nil, queue: nil) {[weak self] (_) in
            guard self != nil else {return}
            self?.tableView.reloadData()
        }
        notificationhandlers.append(switchPlayHandler)
        
    }

    deinit {
        for handler in notificationhandlers {
            NotificationCenter.default.removeObserver(handler)
        }
    }


    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.manager?.AHFMEpisodeListVCShouldLoadInitialShowId(self)
        
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}

//MARK:- Loading Methods
extension AHFMEpisodeListVC{
    public func loadIntialShowid(_ showIdDict: [String: Any]) {
        guard let showId = showIdDict["showId"] as? Int else {
            return
        }
        self.showId = showId
        self.manager?.AHFMEpisodeListVC(self, shouldLoadShow: showId)
        
    }
    
    public func loadShow(_ data: [String:Any]?) {
        guard let data = data else {
            return
        }
        self.show = Show(data)
        
        let url = URL(string: self.show!.fullCover ?? "")
        bgImageView?.sd_setImage(with: url)
        
        self.manager?.AHFMEpisodeListVC(self, shouldLoadEpisodes: self.show!.id)
        
    }
    
    /// showIdDict = ["showId": 666]
    public func loadEpisodes(_ showIdDict: [String: Int], episodeArr: [[String:Any]]?) {
        guard let episodeArr = episodeArr else {
            return
        }
        guard episodeArr.count > 0 else {
            return
        }
        self.episodes.removeAll()
        for epDict in episodeArr {
            let ep = Episode(epDict)
            self.episodes.append(ep)
        }
        self.tableView.reloadData()
    }
}

//MARK:- Setups
extension AHFMEpisodeListVC {
    func setupBackground() {
        bgImageView = UIImageView()
        bgImageView?.frame = self.view.bounds
        self.view.addSubview(bgImageView!)
        
        let blue = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: blue)
        effectView.frame = self.view.bounds
        self.view.addSubview(effectView)
    }
    func setupTableView() {
        let tableView = UITableView()
        tableView.frame = self.view.bounds
        tableView.frame.origin.y = 64.0
        tableView.contentInset.bottom = 64.0
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        // this line is to prevent extra separators in the bottom
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 100.0
        
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        let bundle = Bundle.currentBundle(self)
        let nib = UINib(nibName: "\(AHFMEpisodeListCell.self)", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: CellID)
    }
    func setupHeader() {
        // create headerView
        headerView.frame.origin.x = 0.0
        headerView.frame.origin.y = 0.0
        headerView.frame.size.width = self.view.bounds.width
        headerView.frame.size.height = 64.0
        headerView.backgroundColor = UIColor.clear
        self.view.addSubview(headerView)
        // add title label
        
        headerView.addSubview(headerLabel)
        
        
        // add header bottom white separator
        let separator = UIView()
        separator.frame = CGRect(x: 0, y: headerView.bounds.height - 1, width: headerView.bounds.width, height: 1)
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        headerView.addSubview(separator)
        
        
        // add right dismiss button
        let btn = UIButton(type: .custom)
        let img = UIImage(name: "dismiss-white", user: self)
        btn.setImage(img, for: .normal)
        btn.sizeToFit()
        btn.frame.origin.x = headerView.bounds.width - btn.frame.size.width - 8 - 8.0
        btn.center.y = headerView.bounds.height * 0.7
        btn.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        headerView.addSubview(btn)
    }
    
    func dismiss(_ button: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK:- TableView Delegate/DataSource
extension AHFMEpisodeListVC: UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return show == nil ? 0 : 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath) as! AHFMEpisodeListCell
        let episode = self.episodes[indexPath.row]
        cell.episode = episode
        cell.isPurchasedImg.isHidden = indexPath.row % 2 == 0
        return cell
    }
    
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard self.episodes.count > 0 else {
            print("episodes.count == 0")
            return
        }
        
        let ep = self.episodes[indexPath.row]
        
        if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId,ep.id == playingTrackId {
            if self.navigationController == nil {
                self.dismiss(animated: true)
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }else{
            AHAudioPlayerManager.shared.stop()
           
            var url: URL?
            
            if ep.localFilePath != nil {
                url = URL(fileURLWithPath: ep.localFilePath!)
            }else{
                url = URL(string: ep.remoteURL)
            }
            
            var toTime: TimeInterval? = nil
            if let lastPlayedTime = ep.lastPlayedTime,
                let duration = ep.duration,
                lastPlayedTime > 0.0, duration > 0.0{
                toTime = lastPlayedTime
                
            }
            
            
            
            if self.navigationController == nil {
                self.dismiss(animated: true) {
                    AHAudioPlayerManager.shared.play(trackId: ep.id, trackURL: url!, toTime: toTime)
                }
            }else{
                self.navigationController?.popViewController(animated: true)
                AHAudioPlayerManager.shared.play(trackId: ep.id, trackURL: url!, toTime: toTime)
            }
        }
        
        
        
    }

    
}










