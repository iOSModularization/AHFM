//
//  AHFMBottomPlayer.swift
//  Pods
//
//  Created by Andy Tong on 8/15/17.
//
//

import UIKit
import AHAudioPlayer
import UIImageExtension
import AHFloatingTextView

@objc public protocol AHFMBottomPlayerDelegate: class {
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController, didTapListBarForShow showId:Int)
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController,didTapHistoryBtnForShow showId:Int)
    func bottomPlayer(_ vc: UIViewController, parentVC: UIViewController,didTapInsideWithForShow showId:Int, episodeID: Int)
    
    /// Call loadShow(_:)
    /// parameter = [String:Any]
    func bottomPlayerLoadShow(_ vc: UIViewController, parentVC: UIViewController, showId: Int)
    
    /// Call loadEpisode(_:)
    /// parameter = [String:Any]
    func bottomPlayerLoadEpisode(_ vc: UIViewController, parentVC: UIViewController, episodeId: Int)
    
    /// Call loadLastPlayedEpisode(_:), pass both episode and its show within a dict parameter.
    /// parameter = ["episode": [String:Any], "show": [String:Any]]
    func bottomPlayerLoadLastPlayedEpisode(_ vc: UIViewController, parentVC: UIViewController)
}


private let PlayerHeight: CGFloat = 49.0



public class AHFMBottomPlayer: UIViewController {
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var historyBtn: UIButton!
    @IBOutlet weak var listBarBtn: UIButton!
    
    
    public static let shared = AHFMBottomPlayer()
    public var manager: AHFMBottomPlayerDelegate?
    public weak var parentVC: UIViewController?
    public var shouldShowPlayer = false {
        didSet {
            self.displayPlayer(shouldShow: shouldShowPlayer)
        }
    }
    
    /// internal state that only modified by self.displayPlayer(shouldShow: shouldShowPlayer)
    fileprivate var isCurrentlyShowing = false
    
    fileprivate var show: Show? {
        didSet {
            if let show = show {
                showTitleLabel.text = show.title
            }
        }
    }
    
    fileprivate var episode: Episode? {
        didSet {
            if let episode = episode {
                floatingTitleView.text = episode.title
            }
        }
    }
    
    fileprivate var notificationHandlers = [NSObjectProtocol]()
    fileprivate var timer: Timer?
    fileprivate var shouldUpdateTimer = false
    
    @IBOutlet weak var progressWidth: NSLayoutConstraint!
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var floatingTitleView: AHFloatingTextView!
    
    
    
    ///########## VC Class Related
    public init() { // programatic initializer
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "\(type(of: self))", bundle: bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) { // storyboard initializer
        /*
         if override this method like:
         let bundle = Bundle(for: AHFMPlayerView.self)
         super.init(nibName: "AHFMPlayerView", bundle: bundle)
         then the navigation bar is not shown.
         not a good override
         */
        super.init(coder: aDecoder)
        let bundle = Bundle(for: type(of: self))
        let xibView = bundle.loadNibNamed("\(type(of: self))", owner: self, options: nil)!.first as! UIView
        self.view = xibView
    }
    
    ///########## End VC Class Related
    
    
    deinit {
        for handler in notificationHandlers{
            NotificationCenter.default.removeObserver(handler)
        }
    }
    
}

extension AHFMBottomPlayer {
    func displayPlayer(shouldShow: Bool) {
        guard let parentVC = self.parentVC else {
            return
        }
        
        // if current state is matched to the demending one, return
        guard shouldShow != self.isCurrentlyShowing else {
            return
        }
        
        if shouldShow == false {
            self.isCurrentlyShowing = false
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        }else{
            guard let delegate = UIApplication.shared.delegate else {
                print("Can not find delegate??")
                return
            }
            
            guard let keyWindow = delegate.window as? UIWindow else {
                print("Can not find keyWindow??")
                return
            }
            
            self.isCurrentlyShowing = true
            self.willMove(toParentViewController: parentVC)
            self.didMove(toParentViewController: parentVC)
            
            self.view.willMove(toSuperview: keyWindow)
            keyWindow.addSubview(self.view)
            self.view.didMoveToSuperview()
        }
    }
}


//MARK:- Loading Methods
extension AHFMBottomPlayer {
    // parameter = [String:Any]
    public func loadShow(_ data: [String:Any]?) {
        guard let data = data else {
            return
        }
        
        self.show = Show(data)
        self.shouldUpdateTimer = false
        updateProgress()
        
        if AHAudioPlayerManager.shared.state == .playing {
            fireTimer()
        }
    }
    
    // parameter = [String:Any]
    public func loadEpisode(_ data: [String:Any]?) {
        guard let data = data else {
            return
        }
        guard let parentVC = self.parentVC else {
            return
        }
        
        self.episode = Episode(data)
        self.manager?.bottomPlayerLoadShow(self, parentVC: parentVC, showId: self.episode!.showId)
    }
    
    /// parameter = ["episode": [String:Any], "show": [String:Any]]
    public func loadLastPlayedEpisode(_ data: [String: Any]?) {
        guard let data = data else {
            return
        }
        guard let epDict = data["episode"] as? [String:Any] else {
            return
        }
        guard let showDict = data["show"] as? [String:Any] else {
            return
        }
        self.show = Show(showDict)
        self.episode = Episode(epDict)
        self.shouldUpdateTimer = false
        updateProgress()
        
        if AHAudioPlayerManager.shared.state == .playing {
            self.playBtn.isSelected = true
            fireTimer()
        }else{
            self.playBtn.isSelected = false
        }
        
    }
}

//MARK:- VC Life Cycle
extension AHFMBottomPlayer {
    override public func viewDidLoad() {
        super.viewDidLoad()
        let mainBounds = UIScreen.main.bounds
        self.view.frame.size.height = PlayerHeight
        self.view.frame.size.width = mainBounds.width
        self.view.frame.origin = CGPoint(x: 0.0, y: mainBounds.height - PlayerHeight)
        
        setupUI()

        setupNotifications()
        
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        guard let parentVC = self.parentVC else {
            return
        }
        
        if AHAudioPlayerManager.shared.state != .paused {
            self.playBtn.isSelected = true
        }else{
            self.playBtn.isSelected = false
        }

        
        if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId {
            // there's a track playing or pausing in the audioPlayer
            // fetch it now.
            self.manager?.bottomPlayerLoadEpisode(self, parentVC: parentVC, episodeId: playingTrackId)
        }else{
            // audioPlayer is not playing anything or has anything paused.
            // fetch last played episode and its show now.
            self.manager?.bottomPlayerLoadLastPlayedEpisode(self, parentVC: parentVC)
        }
        
    }
    
    
    
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.shouldUpdateTimer = false
        timer?.invalidate()
        timer = nil
    }
    
}

//MARK:- Control Events
extension AHFMBottomPlayer {
    
    @IBAction func listBarBtnTapped(_ sender: Any) {
        guard let show = self.show else {
            return
        }
        guard let parentVC = self.parentVC else {
            return
        }
        
        manager?.bottomPlayer(self, parentVC: parentVC, didTapListBarForShow: show.id)
    }
    
    @IBAction func playBtnTapped(_ sender: UIButton) {
        guard let ep = self.episode else {
            return
        }
        
        if AHAudioPlayerManager.shared.state != .playing {
            sender.isSelected = true
            if let playingTrackId = AHAudioPlayerManager.shared.playingTrackId,
                ep.id == playingTrackId {
                AHAudioPlayerManager.shared.resume()
            }else{
                // the case that bottomPlayer is the first one loading a lastPlayed track and the audioPlayer hasn't played any track yet since launch.
                
                var url: URL?
                
                if ep.localFilePath != nil {
                    url = URL(fileURLWithPath: ep.localFilePath!)
                }else{
                    url = URL(string: ep.remoteURL)
                }
                
                var toTime: TimeInterval? = nil
                if let lastPlayedTime = ep.lastPlayedTime{
                    toTime = lastPlayedTime
                }
                AHAudioPlayerManager.shared.play(trackId: ep.id, trackURL: url!, toTime: toTime)
                
            }
            
        }else if AHAudioPlayerManager.shared.state == .playing {
            sender.isSelected = false
            AHAudioPlayerManager.shared.pause()
        }else{
            sender.isSelected = false
        }
    }
    @IBAction func historyBtnTapped(_ sender: UIButton) {
        guard let show = self.show else {
            return
        }
        guard let parentVC = self.parentVC else {
            return
        }
        
        manager?.bottomPlayer(self, parentVC: parentVC, didTapHistoryBtnForShow: show.id)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let show = self.show else {
            return
        }
        guard let ep = self.episode else {
            return
        }
        guard let parentVC = self.parentVC else {
            return
        }
        
        manager?.bottomPlayer(self, parentVC: parentVC, didTapInsideWithForShow: show.id, episodeID: ep.id)
    }
    
}

//MARK:- Helpers
extension AHFMBottomPlayer {
    func updateProgress() {
        guard let ep = self.episode else {
            return
        }
        guard let lastPlayedTime = ep.lastPlayedTime, let duration = ep.duration, lastPlayedTime > 0.0, duration > 0.0 else {
            return
        }
        let progress: CGFloat = CGFloat(lastPlayedTime / duration)
        let progressWidth = self.view.frame.width * progress
        self.progressWidth.constant = progressWidth
    }
    
    func fireTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        timer = Timer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    
    func updateTimer() {
        let progressWidth = self.view.frame.width * CGFloat(AHAudioPlayerManager.shared.progress)
        self.progressWidth.constant = progressWidth
    }
}

//MARK:- Setups
extension AHFMBottomPlayer {
    func setupNotifications() {
        // add notifications for audioPlayer
        let changeStateHandler = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidChangeState, object: nil, queue: nil) { (_) in
            guard self.isCurrentlyShowing else {
                return
            }
            if AHAudioPlayerManager.shared.state == .playing {
                if self.shouldUpdateTimer == false {
                    self.shouldUpdateTimer = true
                    self.fireTimer()
                }
                self.playBtn.isSelected = true
            }else if AHAudioPlayerManager.shared.state == .paused {
                self.playBtn.isSelected = false
            }
        }
        notificationHandlers.append(changeStateHandler)
        
        
        let switchPlayHanlder = NotificationCenter.default.addObserver(forName: AHAudioPlayerDidSwitchPlay, object: nil, queue: nil) { (_) in
            guard self.isCurrentlyShowing else {
                return
            }
            
            guard let ep = self.episode else{
                return
            }
            
            guard let playingTrackId = AHAudioPlayerManager.shared.playingTrackId,
                ep.id != playingTrackId else {
                    return
            }
            guard let parentVC = self.parentVC else {
                return
            }
            
            self.manager?.bottomPlayerLoadEpisode(self, parentVC: parentVC, episodeId: playingTrackId)
            
            
        }
        notificationHandlers.append(switchPlayHanlder)
        
    }
    
    func setupUI() {
        let playImg = UIImage(name: "play-btn-large", user: self)
        self.playBtn.setImage(playImg, for: .normal)
        
        let pauseImg = UIImage(name: "pause-btn-large", user: self)
        self.playBtn.setImage(pauseImg, for: .selected)
        
        let historyImg = UIImage(name: "history", user: self)
        self.historyBtn.setImage(historyImg, for: .normal)
        
        let listBarImg = UIImage(name: "bars", user: self)
        self.listBarBtn.setImage(listBarImg, for: .normal)
        
        self.progressWidth.constant = 0.0
        self.floatingTitleView.color = UIColor.black
        
    }
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
