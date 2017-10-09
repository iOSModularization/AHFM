//
//  AHFMSearchVC.swift
//  Pods
//
//  Created by Andy Tong on 9/6/17.
//
//

import Foundation
import BundleExtension
import StringExtension

private let CellID = "CellId"
private let TermWordHeight: CGFloat = 24.0
private let TermPadding: CGFloat = 8.0
private let HeaderReuseID = "HeaderReuseID"
private let HotTermSectionNumber = 1
private let RecentTermSectionNumber = 0



@objc public protocol AHFMSearchVCDelegate: class {
    func searchVC(_ vc: UIViewController, didSelectKeyword keyword: String, searchResultsController: UIViewController)
    
    func searchVCGetSearchResultsController(_ vc: UIViewController) -> UIViewController?
    
    /// Call loadTrendingTerms(_ terms: [String]?)
    func searchVCShouldLoadTrendingTerms(_ vc: UIViewController)
    
    
    /// Call loadRecentTerms(_ terms: [String]?)
    func searchVCShouldLoadRecentTerms(_ vc: UIViewController)
    
    func searchVC(_ vc: UIViewController, shouldSaveRecentTerm recentTerm: String)
    
    func searchVCShouldClearRecentTerms(_ vc: UIViewController)
    
    func viewWillAppear(_ vc: UIViewController)
    
    func viewWillDisappear(_ vc: UIViewController)
}

public class AHFMSearchVC: UIViewController {
    public var manager: AHFMSearchVCDelegate?
    
    
    var collectionView: UICollectionView!
    
    var resultVC: UIViewController!
    
    lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.frame = CGRect(x: 0, y: 0, width: 292.0, height: 28.0)
        return bar
    }()
    
    var hotTerms: [String]?
    var recentTerms: [String]?
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        setupCollectionView()
        setupNavigationBar()
        setupResultVC()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.manager?.viewWillAppear(self)
        self.manager?.searchVCShouldLoadRecentTerms(self)
        self.manager?.searchVCShouldLoadTrendingTerms(self)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.manager?.viewWillDisappear(self)
    }
    
}

//MARK:- Loading Methods
extension AHFMSearchVC {
    public func loadTrendingTerms(_ terms: [String]?) {
        guard let terms = terms else {
            return
        }
        self.hotTerms = terms
        let indexSet = IndexSet(integer: HotTermSectionNumber)
        self.collectionView.reloadSections(indexSet)
    }
    
    public func loadRecentTerms(_ terms: [String]?) {
        guard let terms = terms else {
            return
        }
        self.recentTerms = terms
        let indexSet = IndexSet(integer: RecentTermSectionNumber)
        self.collectionView.reloadSections(indexSet)
    }
}

//MARK:- Events
extension AHFMSearchVC {
    func collectionViewTapGestureTapped(_ gesture: UIGestureRecognizer) {
        self.searchBar.resignFirstResponder()
    }
    
    public func cancelButtonTapped(_ btn: UIButton) {
        self.searchBar.resignFirstResponder()
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func switchToCollectionView() {
        self.resultVC.view.removeFromSuperview()
        self.collectionView.willMove(toSuperview: self.view)
        self.view.addSubview(self.collectionView)
        self.collectionView.didMoveToSuperview()
    }
    
    func switchToSearchReaultVC() {
        self.searchBar.resignFirstResponder()
        self.collectionView.removeFromSuperview()
        self.resultVC.view.willMove(toSuperview: self.view)
        self.view.addSubview(self.resultVC.view)
        self.resultVC.view.didMoveToSuperview()
    }
}

//MARK:- CollectionView Delegate/DataSource
extension AHFMSearchVC: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == RecentTermSectionNumber {
            return self.recentTerms?.count ?? 0
        }else if section == HotTermSectionNumber {
            return self.hotTerms?.count ?? 0
        }else {
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath) as! AHFMSeachKeywordCell
        
        if indexPath.section == RecentTermSectionNumber {
            cell.termLabel.text = self.recentTerms![indexPath.row]
        }else if indexPath.section == HotTermSectionNumber {
            cell.termLabel.text = self.hotTerms![indexPath.row]
        }
        
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var term: String?
        
        if indexPath.section == RecentTermSectionNumber {
            term = self.recentTerms![indexPath.row]
        }else if indexPath.section == HotTermSectionNumber {
            term = self.hotTerms![indexPath.row]
        }
        
        return getCellSize(term: term!)
    }
    
    private func getCellSize(term: String) -> CGSize {
        let size = term.stringSize(boundWdith: CGFloat.greatestFiniteMagnitude, boundHeight: TermWordHeight, font: UIFont.systemFont(ofSize: 17.0))
        return CGSize(width: size.width + TermPadding * 2.5, height: size.height + TermPadding * 2)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == RecentTermSectionNumber {
            
            if let count = self.recentTerms?.count, count > 0 {
                return CGSize.init(width: 0.0, height: 50.0)
            }else{
                return CGSize.zero
            }
            
        }else if section == HotTermSectionNumber {
            return CGSize.init(width: 0.0, height: 50.0)
        }else{
            return CGSize.zero
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == RecentTermSectionNumber {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderReuseID, for: indexPath) as! AHFMSectionSupplementaryCell
                if let count = self.recentTerms?.count, count > 0 {
                    header.titleLabel.text = "Recent⏱"
                    header.hideClearBtn = false
                    header.delegate = self
                }else{
                    header.titleLabel.text = ""
                }
                
                return header
                
            }else if indexPath.section == HotTermSectionNumber {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderReuseID, for: indexPath) as! AHFMSectionSupplementaryCell
                if let count = self.hotTerms?.count, count > 0 {
                    header.titleLabel.text = "Hot🔥"
                }else{
                    header.titleLabel.text = ""
                }
                
                return header
                
            }else{
                return UICollectionReusableView()
            }
            
        }else{
            return UICollectionReusableView()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var term: String?

        if indexPath.section == RecentTermSectionNumber {
            guard let recentTerms = self.recentTerms else {
                return
            }
            term = recentTerms[indexPath.row]
            
        }else if indexPath.section == HotTermSectionNumber{
            guard let hotTerms = self.hotTerms else {
                return
            }
            
            term = hotTerms[indexPath.row]
        }
        
        self.searchBar.text = term!
        self.searchBarSearchButtonClicked(self.searchBar)
    }
    
}

//MARK:- AHFMSectionSupplementaryCellDelegate
extension AHFMSearchVC: AHFMSectionSupplementaryCellDelegate {
    func clearBtnTapped(_ cell: AHFMSectionSupplementaryCell) {
        if let count = self.recentTerms?.count, count > 0 {
            self.manager?.searchVCShouldClearRecentTerms(self)
            self.recentTerms = nil
            let indexSet = IndexSet(integer: RecentTermSectionNumber)
            self.collectionView.reloadSections(indexSet)
        }
    }
}

//MARK:- UISearchBarDelegate
extension AHFMSearchVC: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count == 0 {
            self.switchToCollectionView()
            self.manager?.searchVCShouldLoadRecentTerms(self)
        }
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let term = searchBar.text, term.characters.count > 0 else {return }
        
        self.manager?.searchVC(self, shouldSaveRecentTerm: term)
        
        self.switchToSearchReaultVC()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.manager?.searchVC(self, didSelectKeyword: term, searchResultsController: self.resultVC)
        }

    }
    
}

//MARK:- UISearchResultsUpdating
extension AHFMSearchVC: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        if let term = searchController.searchBar.text, term.characters.count == 0 {
            self.manager?.searchVCShouldClearRecentTerms(self)
        }
    }
}

//MARK:- Setu[ UI
extension AHFMSearchVC {
    func setupResultVC() {
        var resultVC: UIViewController?
        resultVC =  self.manager?.searchVCGetSearchResultsController(self)
        
        guard resultVC != nil else {
            return
        }
        self.automaticallyAdjustsScrollViewInsets = false
        resultVC?.willMove(toParentViewController: self)
        self.addChildViewController(resultVC!)
        self.resultVC = resultVC
    }
    
    func setupNavigationBar() {
        let cancelBtn = UIButton(type: .custom)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(UIColor.black, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        cancelBtn.addTarget(self, action: #selector(self.cancelButtonTapped(_:)), for: .touchUpInside)
        cancelBtn.sizeToFit()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelBtn)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView())
        
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor.blue
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.becomeFirstResponder()
        self.navigationItem.titleView = self.searchBar
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16.0
        layout.minimumInteritemSpacing = 16.0
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = .init(top: 64.0, left: 16.0, bottom: 49.0, right: 16.0)
        
        let nib = UINib(nibName: "\(AHFMSeachKeywordCell.self)", bundle: Bundle.currentBundle(self))
        collectionView.register(nib, forCellWithReuseIdentifier: CellID)
        
        let headerNib = UINib(nibName: "\(AHFMSectionSupplementaryCell.self)", bundle: Bundle.currentBundle(self))
        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderReuseID)
        self.view.addSubview(collectionView)
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.collectionViewTapGestureTapped(_:)))
        self.collectionView.addGestureRecognizer(panGesture)
    }
}


