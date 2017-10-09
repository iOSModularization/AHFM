//
//  AHFMSubscriptionVC.swift
//  Pods
//
//  Created by Andy Tong on 8/27/17.
//
//

import UIKit

private let SubscriptionCellID = "SubscriptionCellID"
private let SubscriptionCellHeight: CGFloat = 70.0

private let gray_ish: CGFloat = 245.0/255.0
private let BackgroundColor = UIColor(red: gray_ish, green: gray_ish, blue: gray_ish, alpha: 1.0)


// The section number for subscribe cells
private let SubscribeCellSection = 0


protocol AHFMSubscriptionVCDelegate: class {
    func subscriptionVC(_ vc: AHFMSubscriptionVC, didSelectShow showId: Int)
    func subscriptionVC(_ vc: UIViewController, editingModeDidChange isEditing: Bool)
    /// Call loadSubscribedShows(_ data: [Show])
    func subscriptionVCShouldLoadSubcribedShows(_ vc: UIViewController)
    
    func subscriptionVC(_ vc: UIViewController, shouldUnsubcribedShows showIDs: [Int])
    
    func subscriptionVCWillAppear(_ vc: UIViewController)
    func subscriptionVCWillDisappear(_ vc: UIViewController)
}

public class AHFMSubscriptionVC: UIViewController {
    weak var delegate: AHFMSubscriptionVCDelegate?
    
    var subscribedShows: [Show]?
    var selectedIndexPaths = [IndexPath]()
    
    weak var editToolView: UIView!
    weak var pickBtn: UIButton!
    weak var deleteBtn: UIButton!
    weak var tableView: UITableView!
    weak var navEditBtn: UIButton!
    
    
    func loadSubscribedShows(_ data: [Show]) {
        guard data.count > 0 else {
            return
        }
        self.subscribedShows = data
        self.tableView.reloadData()
    }
    
    
    override public func viewDidLoad() {
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
        self.navigationItem.title = "My Subscriptions"
        
        
        
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = BackgroundColor
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.contentInset.top = 64.0
        tableView.contentInset.bottom = 49.0
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        
        
        let nib = UINib(nibName: "\(AHFMSubscriptionCell.self)", bundle: Bundle.currentBundle(self))
        tableView.register(nib, forCellReuseIdentifier: SubscriptionCellID)
        
        setupEditToolView()
        
    }

    
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.delegate?.subscriptionVCShouldLoadSubcribedShows(self)
        
        self.delegate?.subscriptionVCWillAppear(self)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.delegate?.subscriptionVCWillDisappear(self)
        
    }
    
    func backBtnTapped(_ button: UIButton) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }

    
}

//MARK:- Editing Related
extension AHFMSubscriptionVC {
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
        
        self.delegate?.subscriptionVC(self, editingModeDidChange: self.isEditing)
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
            deleteBtn.setTitle("Unsubscribe", for: .normal)
            deleteBtn.setTitleColor(UIColor.lightGray, for: .normal)
            deleteBtn.isEnabled = false
            
            pickBtn.isSelected = false
            
        }else{
            deleteBtn.layer.borderColor = UIColor.red.cgColor
            deleteBtn.setTitle("Unsubscribe(\(items))", for: .normal)
            deleteBtn.setTitleColor(UIColor.red, for: .normal)
            deleteBtn.isEnabled = true
            
            pickBtn.isSelected = true
        }
    }
    
    func deleteBtnTapped(_ btn: UIButton) {
        guard self.isEditing else {
            return
        }
        guard let subscribedShows = self.subscribedShows else {
            return
        }
        btn.isEnabled = false
        
        let selectedShows = self.selectedIndexPaths.map { (indexPath) -> Show in
            let show = subscribedShows[indexPath.row]
            return show
        }
        
        let newSubscribedShows = selectedShows.filter { (show) -> Bool in
            return !subscribedShows.contains(where: { (s) -> Bool in
                return s.id == show.id
            })
        }
        
        self.subscribedShows = newSubscribedShows
        let IDs = selectedShows.map { (show) -> Int in
            return show.id
        }
        self.tableView.deleteRows(at: self.selectedIndexPaths, with: UITableViewRowAnimation.fade)
        
        self.updateEditToolView(numberOfItemsSelected: 0)
        self.navEditBtnTapped(self.navEditBtn)
        self.delegate?.subscriptionVC(self, shouldUnsubcribedShows: IDs)
        
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
        let numberOfRows = tableView.numberOfRows(inSection: SubscribeCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: SubscribeCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func deselectAllCells() {
        let numberOfRows = tableView.numberOfRows(inSection: SubscribeCellSection)
        for i in 0..<numberOfRows {
            let indexPath = IndexPath(row: i, section: SubscribeCellSection)
            let _ = tableView.delegate?.tableView?(tableView, willDeselectRowAt: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        }
    }
}

extension AHFMSubscriptionVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.subscribedShows?.count ?? 0
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionCellID, for: indexPath) as! AHFMSubscriptionCell
        
        let show = self.subscribedShows![indexPath.row]
        cell.delegate = self
        cell.show = show
        
        return cell
    }
    
    
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SubscriptionCellHeight
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = BackgroundColor
        return view
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard self.isEditing == false else {
            return
        }
        guard let subscribedShows = self.subscribedShows else {
            return
        }
        let show = subscribedShows[indexPath.row]
        delegate?.subscriptionVC(self, didSelectShow: show.id)
    }
    
    
    //### Editing Related
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if self.isEditing {
            selectedIndexPaths.append(indexPath)
        }
        updateEditToolView(numberOfItemsSelected: selectedIndexPaths.count)
        return indexPath
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

extension AHFMSubscriptionVC: AHFMSubscriptionCellDelegate {
    func subscriptionCellDidTappSubscribeBtn(_ cell: UITableViewCell) {
        print("subscriptionCellDidTappSubscribeBtn")
    }
}



