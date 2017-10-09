//
//  AHFMDownloadedShowPage.swift
//  Pods
//
//  Created by Andy Tong on 8/29/17.
//
//

import UIKit
import AHDownloader
import AHAudioPlayer

private let ShowPageCellID = "SubscriptionCellID"
private let ShowPageCellHeight: CGFloat = 65.0

private let ShowPageCellMoreID = "ShowPageCellMoreID"
private let ShowPageCellMoreHeight: CGFloat = 35.0

private let ShowPageCellShowID = "ShowPageCellShowID"
private let ShowPageCellShowHeight: CGFloat = 65.0

private let gray_ish: CGFloat = 245.0/255.0
private let BackgroundColor = UIColor(red: gray_ish, green: gray_ish, blue: gray_ish, alpha: 1.0)

private let ShowPageCellHeaderHeight: CGFloat = 30.0

private let ShowPageCellShowSection = 0
private let ShowPageCellMoreSection = 1
private let ShowPageCellSection = 2

protocol AHFMDownloadedShowPageVCDelegate: class {
    /// Call loadEpisodesForShow(_:) when data is ready
    func downloadedShowPageVC(_ vc: UIViewController, shouldLoadEpisodesForShow showId: Int)
    func downloadedShowPageVC(_ vc: UIViewController, didSelectShow showId: Int)
    func downloadedShowPageVC(_ vc: UIViewController, didSelectEpisode episodeId: Int, showId: Int)
    func downloadedShowPageVC(_ vc: UIViewController, didSelectDownloadMoreForShow showId: Int)
    func downloadedShowPageVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    
    /// You should delete the info in the DB, AND their local actual files
    func downloadedShowPageVC(_ vc: UIViewController, shouldDeleteEpisodes episodeIDs: [Int], forShow showId: Int)
}

class AHFMDownloadedShowPageVC: UIViewController {
    public weak var delegate: AHFMDownloadedShowPageVCDelegate?
    var show: Show?
    
    public var downloadedEpisodes = [Episode]()
    public var selectedIndexPaths = [IndexPath]()
    
    weak var editToolView: UIView!
    weak var pickBtn: UIButton!
    weak var deleteBtn: UIButton!
    weak var tableView: UITableView!
    weak var navEditBtn: UIButton!
    
    
    func loadEpisodesForShow(_ showId: Int, eps: [Episode]) {
        guard let show = self.show else {
            return
        }
//        guard show.id == showId else {
//            return
//        }
        self.downloadedEpisodes.removeAll()
        self.downloadedEpisodes.append(contentsOf: eps)
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.navigationItem.title = show?.title ?? "Downloaded Show"
        
        
        
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
        
        
        
        let cellNib = UINib(nibName: "\(AHFMDownloadedShowPageCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(cellNib, forCellReuseIdentifier: ShowPageCellID)
        
        let showNib = UINib(nibName: "\(AHFMDownloadedShowPageShowCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(showNib, forCellReuseIdentifier: ShowPageCellShowID)
        
        let moreNib = UINib(nibName: "\(AHFMDownloadedShowPageMoreCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(moreNib, forCellReuseIdentifier: ShowPageCellMoreID)
        
        setupEditToolView()
        
    }

}

//MARK:- Editing Stuff
extension AHFMDownloadedShowPageVC {
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
        delegate?.downloadedShowPageVC(self, editingModeDidChange: self.isEditing)
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
        guard let show = self.show else {
            return
        }
        btn.isEnabled = false
        var deletedSize = 0
        let selectedEpisodes = self.selectedIndexPaths.map { (indexPath) -> Episode in
            let ep = self.downloadedEpisodes[indexPath.row]
            deletedSize += ep.fileSize ?? 0
            return ep
        }
        
        if let playingId = AHAudioPlayerManager.shared.playingTrackId {
            for ep in selectedEpisodes {
                if ep.id == playingId {
                    AHAudioPlayerManager.shared.stop()
                    break
                }
            }
            
        }
        
        let remainEpisodes = self.downloadedEpisodes.filter { (ep) -> Bool in
            let contains = selectedEpisodes.contains(where: { (selected) -> Bool in
                return ep.id == selected.id
            })
            return !contains
        }

        
        self.downloadedEpisodes = remainEpisodes
        
        self.show?.totalDownloadedSize -= deletedSize
        self.tableView.deleteRows(at: self.selectedIndexPaths, with: UITableViewRowAnimation.fade)
        let indexSet = IndexSet(integer: ShowPageCellSection)
        self.tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
        
        self.updateEditToolView(numberOfItemsSelected: 0)
        self.navEditBtnTapped(self.navEditBtn)
        
        let deletes = selectedEpisodes.map { (ep) -> Int in
            return ep.id
        }
        delegate?.downloadedShowPageVC(self, shouldDeleteEpisodes: deletes, forShow: show.id)
        delegate?.downloadedShowPageVC(self, editingModeDidChange: self.isEditing)
        
        
        
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
        let numberOfRows = tableView.numberOfRows(inSection: ShowPageCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: ShowPageCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func deselectAllCells() {
        let numberOfRows = tableView.numberOfRows(inSection: ShowPageCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: ShowPageCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willDeselectRowAt: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        }
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.downloadedEpisodes.removeAll()
        
        guard let show = self.show else {
            return
        }
        self.delegate?.downloadedShowPageVC(self, shouldLoadEpisodesForShow: show.id)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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

extension AHFMDownloadedShowPageVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == ShowPageCellShowSection {
            return 1
        }else if section == ShowPageCellMoreSection {
            return 1
        }else if section == ShowPageCellSection {
            return self.downloadedEpisodes.count
        }else{
            return 0
        }
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == ShowPageCellShowSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShowPageCellShowID, for: indexPath) as! AHFMDownloadedShowPageShowCell
            cell.show = self.show
            return cell
            
        }else if indexPath.section == ShowPageCellMoreSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShowPageCellMoreID, for: indexPath) as! AHFMDownloadedShowPageMoreCell
            return cell
        }else if indexPath.section == ShowPageCellSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: ShowPageCellID, for: indexPath) as! AHFMDownloadedShowPageCell
            
            let ep = self.downloadedEpisodes[indexPath.row]
            cell.isEditingMode = self.isEditing
            cell.episode = ep
            
            return cell
        }else{
            return UITableViewCell()
        }
        
        
    }
    
    
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == ShowPageCellShowSection {
            return ShowPageCellShowHeight
        }else if indexPath.section == ShowPageCellMoreSection {
            return ShowPageCellMoreHeight
        }else if indexPath.section == ShowPageCellSection {
            return ShowPageCellHeight
        }else{
            return 0
        }
        
    }

    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = BackgroundColor
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == ShowPageCellSection {
            let view = UIView()
            view.backgroundColor = UIColor.white
            let label = UILabel()
            
            var totalSizeStr: String?
            if let totalSize = self.show?.totalDownloadedSize {
                totalSizeStr = String.bytesToMegaBytes(UInt64(totalSize))
            }else{
                totalSizeStr = "Unknown"
            }
            
            label.text = "\(self.downloadedEpisodes.count) episodes   \(totalSizeStr!)MB"
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.textColor = UIColor.gray.withAlphaComponent(0.7)
            label.sizeToFit()
            label.center.y = ShowPageCellHeaderHeight * 0.5
            label.frame.origin.x = 16.0
            view.addSubview(label)
            
            let separator = UIView()
            separator.backgroundColor = BackgroundColor
            separator.frame.size.height = 0.5
//            separator.frame.size.width = 300.0
            separator.frame.origin = CGPoint(x: 0, y: ShowPageCellHeaderHeight - separator.frame.size.height)
            separator.autoresizingMask = [.flexibleWidth]
            view.addSubview(separator)
            return view
        }else{
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == ShowPageCellSection {
            return ShowPageCellHeaderHeight
        }else{
            return 0.0
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard self.isEditing == false else {
            return
        }
        
        let section = indexPath.section
        if section == ShowPageCellShowSection {
            if let show = self.show {
                self.delegate?.downloadedShowPageVC(self, didSelectShow: show.id)
            }
        }else if section == ShowPageCellMoreSection {
            if let show = self.show {
               self.delegate?.downloadedShowPageVC(self, didSelectDownloadMoreForShow: show.id)
            }
            
        }else if section == ShowPageCellSection {
            if let show = self.show {
                let episode = self.downloadedEpisodes[indexPath.row]
                self.delegate?.downloadedShowPageVC(self, didSelectEpisode: episode.id, showId: show.id)
            }
            
        }
        
        
    }
    
    
    //### Editing Related
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isEditing && indexPath.section == ShowPageCellSection {
            selectedIndexPaths.append(indexPath)
            updateEditToolView(numberOfItemsSelected: selectedIndexPaths.count)
        }
        return indexPath
    }
    
    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isEditing && indexPath.section == ShowPageCellSection{
            if let index = selectedIndexPaths.index(of: indexPath) {
                selectedIndexPaths.remove(at: index)
                updateEditToolView(numberOfItemsSelected: selectedIndexPaths.count)
            }
        }
        
        return indexPath
    }
    
    
}
