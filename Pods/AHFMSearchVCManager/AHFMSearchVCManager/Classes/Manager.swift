//
//  Manager.swift
//  AHFMSearchVC_Example
//
//  Created by Andy Tong on 10/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter
import AHFMNetworking

import AHFMBottomPlayerServices
import AHFMKeywordVCServices

import SwiftyJSON

private let RecentTermKey = "RecentTermKey"

class Manager: NSObject {
    lazy var networking = AHFMNetworking()
    
    deinit {
        networking.cancelAllRequests()
    }
    
    func searchVC(_ vc: UIViewController, didSelectKeyword keyword: String, searchResultsController: UIViewController){
        let serachKeyword = keyword
        let info: [String : Any] = [AHFMKeywordVCServices.keyGetVC: searchResultsController, AHFMKeywordVCServices.keySearchKeyword: serachKeyword]
        AHServiceRouter.doTask(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskGoSearch, userInfo: info, completion: nil)
    }
    
    func searchVCGetSearchResultsController(_ vc: UIViewController) -> UIViewController?{
        let isForShows = false
        let info = [AHFMKeywordVCServices.keyIsSearchingForShows: isForShows] as [String : Any]
        guard let data = AHServiceRouter.doTask(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskCreateVC, userInfo: info, completion: nil) else {
            return nil
        }
        
        guard let vc = data[AHFMKeywordVCServices.keyGetVC] as? UIViewController else {
            return nil
        }
        return vc
    }
    
    /// Call loadTrendingTerms(_ terms: [String]?)
    func searchVCShouldLoadTrendingTerms(_ vc: UIViewController){
        networking.trending { (data, error) in
            var terms = [String]()
            if let data = data, let jsonData = JSON(data).array {
                for jsonTopic in jsonData {
                    if let term = jsonTopic["trend"].string {
                        terms.append(term)
                    }
                }
                
            }
            vc.perform(Selector(("loadTrendingTerms:")), with: terms)
        }
    }
    
    
    /// Call loadRecentTerms(_ terms: [String]?)
    func searchVCShouldLoadRecentTerms(_ vc: UIViewController){
        var terms: [String]?
        if let recentTerms = UserDefaults.standard.value(forKey: RecentTermKey) as? [String] {
            terms = recentTerms
        }
        vc.perform(Selector(("loadRecentTerms:")), with: terms)
    }
    
    func searchVC(_ vc: UIViewController, shouldSaveRecentTerm recentTerm: String){
        var recentTerms: [String]?
        if let terms = UserDefaults.standard.value(forKey: RecentTermKey) as? [String] {
            recentTerms = terms
        }
        
        if recentTerms == nil {
            // recentTerms is empty in disk
            recentTerms = [String]()
        }
        
        if let index = recentTerms?.index(of: recentTerm) {
            recentTerms?.remove(at: index)
        }
        
        recentTerms?.insert(recentTerm, at: 0)
        
        if recentTerms != nil {
            UserDefaults.standard.setValue(recentTerms!, forKey: RecentTermKey)
        }
    }
    
    func searchVCShouldClearRecentTerms(_ vc: UIViewController){
        UserDefaults.standard.setValue(nil, forKey: RecentTermKey)
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappear(_ vc: UIViewController){
        
    }
}
