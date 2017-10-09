//
//  AHFMHistoryVC.swift
//  Pods
//
//  Created by Andy Tong on 8/27/17.
//
//

import UIKit
import UIImageExtension
import BundleExtension

private let HistoryCellID = "SubscriptionCellID"
private let HistoryCellHeight: CGFloat = 85.0

private let gray_ish: CGFloat = 245.0/255.0
private let BackgroundColor = UIColor(red: gray_ish, green: gray_ish, blue: gray_ish, alpha: 1.0)


// The section number for subscribe cells
private let HistoryCellSection = 0



@objc public protocol AHFMHistoryVCDelegate: class {
    /// Call loadHistoryEpisodes(_:)
    func hisotryVCShouldLoadHistoryEpisodes(_ vc: UIViewController)
    func hisotryVC(_ vc: UIViewController, didSelectHisotryEpisode episodeID: Int, showId: Int)
    func hisotryVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    func hisotryVC(_ vc: UIViewController, shouldDeleteEpisodes episodes: [Int])
    
    func viewWillAppear(_ vc: UIViewController)
    func viewWillDisappear(_ vc: UIViewController)
}


public class AHFMHistoryVC: UIViewController {
    public var manager: AHFMHistoryVCDelegate?
    
    
    var historyEpisode = [Episode]()
    var selectedIndexPaths = [IndexPath]()
    
    weak var editToolView: UIView!
    weak var pickBtn: UIButton!
    weak var deleteBtn: UIButton!
    weak var tableView: UITableView!
    weak var navEditBtn: UIButton!

    
    
}

//MARK:- VC Life Cycle
extension AHFMHistoryVC {
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.historyEpisode.removeAll()
        
        self.manager?.hisotryVCShouldLoadHistoryEpisodes(self)
        
        self.manager?.viewWillAppear(self)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.manager?.viewWillDisappear(self)
    }
}


//MARK:- Loading Methods
extension AHFMHistoryVC {
    public func loadHistoryEpisodes(_ epArrDict: [[String:Any]]?) {
        guard let epArrDict = epArrDict else {
            return
        }
        guard epArrDict.count > 0 else {
            return
        }
        
        var eps = [Episode]()
        
        for epDict in epArrDict {
            let ep = Episode(epDict)
            eps.append(ep)
        }
        
        self.historyEpisode.append(contentsOf: eps)
        self.tableView.reloadData()

    }
}


//MARK:- Editing Stuff
extension AHFMHistoryVC {
    func navEditBtnTapped(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        
        self.isEditing = btn.isSelected
        tableView.setEditing(btn.isSelected, animated: true)
        
        if !btn.isSelected {
            selectedIndexPaths.removeAll()
            updateEditToolView(numberOfItemsSelected: 0)
            editToolView.isHidden = true
        }else{
            editToolView.isHidden = false
        }
        
        self.manager?.hisotryVC(self, editingModeDidChange: self.isEditing)
        
    }
    
    func setupEditToolView() {
        let editToolView = UIView()
        editToolView.frame = CGRect(x: 0, y: self.view.frame.height - 49.0, width: self.view.frame.width, height: 49.0)
        editToolView.backgroundColor = UIColor.white
        self.view.addSubview(editToolView)
        self.editToolView = editToolView
        let width: CGFloat = editToolView.bounds.width * 0.5 - 8.0 * 2.0
        let height: CGFloat = editToolView.bounds.height - 8.0 * 2
        let borderColor = UIColor.black.cgColor
        let titleColor = UIColor.black
        let borderWidth: CGFloat = 0.5
        let cornerRadius: CGFloat = 5.0
        
        let pickBtn = UIButton(type: .custom)
        pickBtn.frame = CGRect(x: 8.0, y: 8.0, width: width, height: height)
        pickBtn.layer.masksToBounds = true
        pickBtn.layer.cornerRadius = cornerRadius
        pickBtn.layer.borderColor = borderColor
        pickBtn.layer.borderWidth = borderWidth
        pickBtn.setTitle("Select All", for: .normal)
        pickBtn.setTitle("Deselect All", for: .selected)
        pickBtn.setTitleColor(titleColor, for: .normal)
        pickBtn.addTarget(self, action: #selector(pickBtnTapped(_:)), for: .touchUpInside)
        self.pickBtn = pickBtn
        
        let deleteBtn = UIButton(type: .custom)
        deleteBtn.frame = CGRect(x: pickBtn.frame.maxX + 8.0, y: 8.0, width: width, height: height)
        deleteBtn.layer.masksToBounds = true
        deleteBtn.layer.cornerRadius = cornerRadius
        deleteBtn.layer.borderWidth = borderWidth
        deleteBtn.addTarget(self, action: #selector(deleteBtnTapped(_:)), for: .touchUpInside)
        
        self.deleteBtn = deleteBtn
        
        editToolView.addSubview(pickBtn)
        editToolView.addSubview(deleteBtn)
        editToolView.isHidden = true
        
        updateEditToolView(numberOfItemsSelected: 0)
    }
    
    func updateEditToolView(numberOfItemsSelected items: Int) {
        if items == 0{
            deleteBtn.layer.borderColor = UIColor.lightGray.cgColor
            deleteBtn.setTitle("Delete", for: .normal)
            deleteBtn.setTitleColor(UIColor.lightGray, for: .normal)
            deleteBtn.isEnabled = false
            
            pickBtn.isSelected = false
            
        }else{
            deleteBtn.layer.borderColor = UIColor.red.cgColor
            deleteBtn.setTitle("Delete(\(items))", for: .normal)
            deleteBtn.setTitleColor(UIColor.red, for: .normal)
            deleteBtn.isEnabled = true
            
            pickBtn.isSelected = true
        }
    }
    
    func deleteBtnTapped(_ btn: UIButton) {
        guard self.isEditing else {
            return
        }
        btn.isEnabled = false
        
        let episodeIDs = self.selectedIndexPaths.map { (indexPath) -> Int in
            let ep = self.historyEpisode[indexPath.row]
            return ep.id
        }
        
        
        let newHistoryEpisodes = self.historyEpisode.filter { (episode) -> Bool in
            let isContained = episodeIDs.contains(where: { (epId) -> Bool in
                return epId == episode.id
            })
            return !isContained
        }
        
        self.historyEpisode = newHistoryEpisodes
        
        self.tableView.deleteRows(at: self.selectedIndexPaths, with: UITableViewRowAnimation.fade)
        
        self.updateEditToolView(numberOfItemsSelected: 0)
        self.navEditBtnTapped(self.navEditBtn)
        
        self.manager?.hisotryVC(self, shouldDeleteEpisodes: episodeIDs)
        
    }
    
    func pickBtnTapped(_ btn: UIButton) {
        guard self.isEditing else {
            return
        }
        
        btn.isSelected = !btn.isSelected
        
        if btn.isSelected {
            selectAllCells()
        }else{
            deselectAllCells()
        }
    }
    
    func selectAllCells() {
        let numberOfRows = tableView.numberOfRows(inSection: HistoryCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: HistoryCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func deselectAllCells() {
        let numberOfRows = tableView.numberOfRows(inSection: HistoryCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: HistoryCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willDeselectRowAt: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        }
    }
    
    
    
    func backBtnTapped(_ button: UIButton) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
}

//MARK:- TableView Delegate/DataSource
extension AHFMHistoryVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.historyEpisode.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCellID, for: indexPath) as! AHFMHisotryCell
        
        let ep = self.historyEpisode[indexPath.row]
        cell.isEditingMode = self.isEditing
        cell.episode = ep
        
        return cell
    }
    
    
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return HistoryCellHeight
    }
    
    //### Editing Related
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isEditing {
            selectedIndexPaths.append(indexPath)
        }
        updateEditToolView(numberOfItemsSelected: selectedIndexPaths.count)
        return indexPath
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard self.isEditing == false else {
            return
        }
        let ep = self.historyEpisode[indexPath.row]
        self.manager?.hisotryVC(self, didSelectHisotryEpisode: ep.id, showId: ep.showId)
        
    }
    
    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isEditing {
            if let index = selectedIndexPaths.index(of: indexPath) {
                selectedIndexPaths.remove(at: index)
            }
        }
        updateEditToolView(numberOfItemsSelected: selectedIndexPaths.count)
        return indexPath
    }
    
    
}

//MARK:- Setup UI
extension AHFMHistoryVC {
    fileprivate func setupUI() {
        self.automaticallyAdjustsScrollViewInsets = false
        // setup navBar
        let backBtn = UIButton()
        let backImg = UIImage(name: "back-black", user: self)
        backBtn.setImage(backImg, for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnTapped(_:)), for: .touchUpInside)
        backBtn.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        // setup navEditBtn
        let navEditBtn = UIButton(type: .custom)
        navEditBtn.setTitle("Edit", for: .normal)
        navEditBtn.setTitle("Cancel", for: .selected)
        navEditBtn.setTitleColor(UIColor.black, for: .normal)
        navEditBtn.frame.size = CGSize(width: 60.0, height: 20.0)
        navEditBtn.titleLabel?.textAlignment = .right
        navEditBtn.addTarget(self, action: #selector(navEditBtnTapped(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navEditBtn)
        self.navEditBtn = navEditBtn
        self.navigationItem.title = "History"
        
        
        
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.separatorColor = BackgroundColor
        tableView.backgroundColor = BackgroundColor
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.contentInset.top = 64.0
        tableView.contentInset.bottom = 49.0
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        
        
        let nib = UINib(nibName: "\(AHFMHisotryCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(nib, forCellReuseIdentifier: HistoryCellID)
        
        setupEditToolView()
    }
}

struct Episode {
    var id: Int
    var showId: Int
    var title: String
    var showTitle: String?
    var duration: TimeInterval?
    var lastPlayedTime: TimeInterval?
    var showThumbCover: String?
    init(_ dict: [String: Any]) {
        self.id = dict["id"] as! Int
        self.showId = dict["showId"] as! Int
        self.title = dict["title"] as! String
        self.showTitle = dict["showTitle"] as? String
        self.duration = dict["duration"] as? TimeInterval
        self.lastPlayedTime = dict["lastPlayedTime"] as? TimeInterval
        self.showThumbCover = dict["showThumbCover"] as? String
    }
    
    public static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.id == rhs.id
    }
}
