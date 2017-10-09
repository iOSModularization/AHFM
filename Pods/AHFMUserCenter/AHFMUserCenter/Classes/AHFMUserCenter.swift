

private let AHFMUserCellID = "AHFMUserCellID"
private let AHFMUserCellHeight: CGFloat = 80.0

private let AHFMUserItemCellID = "AHFMUserItemCellID"
private let AHFMUserItemCellHeight: CGFloat = 60.0

private let AHFMNormalcellID = "AHFMNormalcellID"
private let AHFMNormalcellHeight: CGFloat = 40.0

private let gray_ish: CGFloat = 245.0/255.0
private let BackgroundColor = UIColor(red: gray_ish, green: gray_ish, blue: gray_ish, alpha: 1.0)

import BundleExtension
import UIImageExtension


@objc public protocol AHFMUserCenterDelegate: class {
    /// Call loadNumberOfSubscriptions(_ data: ["number": Any])
    func userCenterLoadNumberOfSubscriptions(_ vc: UIViewController)
    
    /// Call loadNumbberOfDownloads(_ data: ["number": Any])
    func userCenterLoadNumberOfDownloadedEpisodes(_ vc: UIViewController)
    
    /// Call loadLastPlayedEpisode(_ data: [String: Any]?)
    func userCenterLoadLastPlayedEpisode(_ vc: UIViewController)
    
    func userCenterDidSelectDownloadSection(_ vc: UIViewController)
    
    func userCenterDidSelectHistorySection(_ vc: UIViewController)
    
    func userCenter(_ vc: UIViewController, didSelectSubscribedShow showId: Int)
    
    func subscriptionVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    
    /// Call loadSubcribedShows(_ data: [[String: Any]]?)
    func subscriptionVCShouldLoadSubcribedShows(_ vc: UIViewController)
    
    func subscriptionVC(_ vc: UIViewController, shouldUnsubcribedShows showIDs: [Int])
    
    func subscriptionVCWillAppear(_ vc: UIViewController)
    
    func subscriptionVCWillDisappear(_ vc: UIViewController)
    
    func viewWillAppear(_ vc: UIViewController)
    
    func viewWillDisappear(_ vc: UIViewController)
    
}


public class AHFMUserCenter: UITableViewController {
    public var manager: AHFMUserCenterDelegate?
    
    
    fileprivate var numberOfSubcriptions: Int = 0
    fileprivate var numberOfDownloads: Int = 0
    fileprivate var lastPlayedEpisode: Episode?
    
    /// When it gets to 3, that means all numbers and lastPlayedEpisode are ready to use.
    fileprivate var loadingCount = 0
    
    fileprivate var subcriptionVC: AHFMSubscriptionVC?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTablView()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingCount = 0
        manager?.viewWillAppear(self)

        manager?.userCenterLoadNumberOfSubscriptions(self)
        manager?.userCenterLoadNumberOfDownloadedEpisodes(self)
        manager?.userCenterLoadLastPlayedEpisode(self)
        
        
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

}

//MARK:- Loading Methods
extension AHFMUserCenter {
    /// Call loadNumberOfSubscriptions(_ data: ["number": Any])
    public func loadNumberOfSubscriptions(_ data: [String: Any]){
        loadingCount += 1
        if let number = data["number"] as? Int {
            self.numberOfSubcriptions = number
        }
        
        if loadingCount == 3 {
            self.tableView.reloadData()
        }
        
    }
    
    /// Call loadNumbberOfDownloads(_ data: ["number": Any])
    public func loadNumbberOfDownloads(_ data: [String: Any]){
        loadingCount += 1
        if let number = data["number"] as? Int {
            self.numberOfDownloads = number
        }
        
        if loadingCount == 3 {
            self.tableView.reloadData()
        }
        
    }
    
    /// Call loadLastPlayedEpisode(_ data: [String: Any]?)
    public func loadLastPlayedEpisode(_ data: [String: Any]?){
        loadingCount += 1
        if let data = data {
            let ep = Episode(data)
            self.lastPlayedEpisode = ep
        }
        
        if loadingCount == 3 {
            self.tableView.reloadData()
        }
        
    }
    
    public func loadSubcribedShows(_ data: [[String: Any]]?) {
        guard let data = data else {
            return
        }
        var shows = [Show]()
        for showDict in data {
            let show = Show(showDict)
            shows.append(show)
        }
        self.subcriptionVC?.loadSubscribedShows(shows)
    }
}


//MARK:- TableView Delegate/DataSource
extension AHFMUserCenter {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // AHFMUserCell
            return 1
        }else if section == 1 {
            // AHFMUserItemCell
            return 3
        }else if section == 2 {
            // AHFMNormalcell
            return 2
        }else{
            return 0
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // AHFMUserCell
            let cell = tableView.dequeueReusableCell(withIdentifier: AHFMUserCellID, for: indexPath) as! AHFMUserCell
            cell.userIcon.image = UIImage(name: "test-user-icon-2", user: self)
            cell.userNameLabel.text = "test-user"
            return cell
        }else if indexPath.section == 1 {
            // AHFMUserItemCell
            let cell = createCellForUserItem(tableView, cellForRowAt: indexPath)
            return cell
        }else if indexPath.section == 2 {
            // AHFMNormalcell
            let cell = createCellForNormal(tableView, cellForRowAt: indexPath)
            return cell
        }else{
            // won't get here if the numnberOfSection is correct
            return UITableViewCell()
        }
    }
    
    func createCellForUserItem(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> AHFMUserItemCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMUserItemCellID, for: indexPath) as! AHFMUserItemCell
        let index = indexPath.row
        if index == 0 {
            // My Subscription
            cell.itemIcon.image = UIImage(name: "love-selected", user: self)
            cell.itemTitle.text = "My Subcriptions"
            cell.itemAmount.text = "\(self.numberOfSubcriptions)"
        }else if index == 1 {
            // My Dwonloads
            cell.itemIcon.image = UIImage(name: "download-green", user: self)
            cell.itemTitle.text = "My Downloads"
            cell.itemAmount.text = "\(self.numberOfDownloads)"
        }else if index == 2 {
            // My Hisotry
            cell.itemIcon.image = UIImage(name: "history-blue", user: self)
            cell.itemTitle.text = "My History"
            cell.itemAmount.text = self.lastPlayedEpisode?.title ?? ""
        }
        
        return cell
    }
    func createCellForNormal(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> AHFMNormalcell{
        let cell = tableView.dequeueReusableCell(withIdentifier: AHFMNormalcellID, for: indexPath) as! AHFMNormalcell
        let index = indexPath.row
        if index == 0 {
            // My Subscription
            cell.iconImageView.image = UIImage(name: "message-icon", user: self)
            cell.titleLabel.text = "Messages"
        }else if index == 1 {
            // My Dwonloads
            cell.iconImageView.image = UIImage(name: "setting-icon", user: self)
            cell.titleLabel.text = "Settings"
        }
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            // AHFMUserCell
            return AHFMUserCellHeight
        }else if indexPath.section == 1 {
            // AHFMUserItemCell
            return AHFMUserItemCellHeight
        }else if indexPath.section == 2 {
            // AHFMNormalcell
            return AHFMNormalcellHeight
        }else{
            return 0
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = BackgroundColor
        return view
    }
    
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // AHFMUserCell
            return
        }else if indexPath.section == 1 {
            // AHFMUserItemCell
            
            if indexPath.row == 0 {
                // subscriptionVC
                self.subcriptionVC = AHFMSubscriptionVC()
                self.subcriptionVC?.delegate = self
                if self.navigationController != nil {
                    self.navigationController?.pushViewController(self.subcriptionVC!, animated: true)
                }
                
            }else if indexPath.row == 1 {
                // download
                manager?.userCenterDidSelectDownloadSection(self)
                
            }else if indexPath.row == 2 {
                //  history
                manager?.userCenterDidSelectHistorySection(self)
                
            }else{
                print("indexPath out of bound")
            }
            
            
        }else if indexPath.section == 2 {
            // AHFMNormalcell
            return
        }else{
            return
        }
    }
}

//MARK:- AHFMSubscriptionVCDelegate
extension AHFMUserCenter: AHFMSubscriptionVCDelegate {
    /// Call loadSubscribedShows(_ data: [Show])
    func subscriptionVCShouldLoadSubcribedShows(_ vc: UIViewController) {
        manager?.subscriptionVCShouldLoadSubcribedShows(self)
    }
    
    func subscriptionVC(_ vc: UIViewController, shouldUnsubcribedShows showIDs: [Int]) {
        manager?.subscriptionVC(self, shouldUnsubcribedShows: showIDs)
    }
    
    func subscriptionVC(_ vc: AHFMSubscriptionVC, didSelectShow showId: Int) {
        manager?.userCenter(self, didSelectSubscribedShow: showId)
    }
    
    func subscriptionVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool){
        manager?.subscriptionVC(vc, editingModeDidChange: isEditing)
    }
    
    func subscriptionVCWillAppear(_ vc: UIViewController){
        manager?.subscriptionVCWillAppear(vc)
    }
    
    func subscriptionVCWillDisappear(_ vc: UIViewController){
        manager?.subscriptionVCWillDisappear(vc)
    }
    
}

//MARK:- Setups
extension AHFMUserCenter {
    func setupNavBar() {
        let backBtn = UIButton()
        let backImg = UIImage(name: "back-black", user: self)
        backBtn.setImage(backImg, for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnTapped(_:)), for: .touchUpInside)
        backBtn.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        self.navigationItem.title = "User Center"
    }
    func setupTablView() {
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = BackgroundColor
        let userNib = UINib(nibName: "\(AHFMUserCell.self)", bundle: Bundle.currentBundle(self))
        let userItemNib = UINib(nibName: "\(AHFMUserItemCell.self)", bundle: Bundle.currentBundle(self))
        let normalBin = UINib(nibName: "\(AHFMNormalcell.self)", bundle: Bundle.currentBundle(self))
        
        tableView.register(userNib, forCellReuseIdentifier: AHFMUserCellID)
        tableView.register(userItemNib, forCellReuseIdentifier: AHFMUserItemCellID)
        tableView.register(normalBin, forCellReuseIdentifier: AHFMNormalcellID)
    }
}

struct Show: Equatable {
    var id: Int
    var title: String?
    var detail: String?
    var thumbCover: String?
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.title = dict["title"] as? String
        self.detail = dict["detail"] as? String
        self.thumbCover = dict["thumbCover"] as? String
    }
    
    public static func ==(lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Episode: Equatable {
    var id: Int
    var showId: Int
    var title: String?
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.title = dict["title"] as? String
    }
    
    public static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }
}




