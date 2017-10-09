//
//  AHFMKeywordVCManager.swift
//  AHFMKeywordVC_Example
//
//  Created by Andy Tong on 10/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMModuleManager
import AHFMKeywordVCServices

public struct AHFMKeywordVCManager: AHFMModuleManager {
    public static func activate() {
        registerForNavigation()
        registerForCreatingVC()
        registerForGoSearchTask()
    }
    fileprivate static func registerForGoSearchTask() {
        AHServiceRouter.registerTask(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskGoSearch) { (userInfo, completion) -> [String : Any]? in
            let vcStr = "AHFMKeywordVC.AHFMKeywordVC"
            
            guard let clazz = NSClassFromString(vcStr) else {
                assertionFailure("You must include the module AHFMKeywordVC")
                return nil
            }
            
            guard let vc = userInfo[AHFMKeywordVCServices.keyGetVC] as? UIViewController else {
                assert(false, "You must include an already created VC using task AHFMKeywordVCServices.taskCreateVC.")
                return nil
            }
            
            guard vc.isKind(of: clazz) else {
                assertionFailure("Incorrect VC type!")
                return nil
            }
            
            guard let keyword = userInfo[AHFMKeywordVCServices.keySearchKeyword] as? String else {
                assert(false, "You must include a value for key 'keySearchKeyword'")
                return nil
            }
            
            guard let manager = vc.value(forKey: "manager") as? Manager else {
                assertionFailure("Internal error: vc didn't get assigned with a manager!")
                return nil
            }
            manager.keyword = keyword
            manager.keywordVC(vc, shouldSearchForKeyword: keyword)
            completion?(true, nil)
            return nil
            
        }
    }
    
    fileprivate static func registerForCreatingVC() {
        AHServiceRouter.registerTask(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskCreateVC) { (userInfo, _) -> [String : Any]? in
            let keyword = userInfo[AHFMKeywordVCServices.keySearchKeyword] as? String
            
            guard let isSearchingForShows = userInfo[AHFMKeywordVCServices.keyIsSearchingForShows] as? Bool else {
                assert(false, "You must include a value for key 'keyIsSearchingForShows'")
                return nil
            }
            
            let vcStr = "AHFMKeywordVC.AHFMKeywordVC"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let manager = Manager()
            manager.keyword = keyword
            manager.isSearchingForShows = isSearchingForShows
            
            let vc = vcType.init()
            vc.setValue(manager, forKey: "manager")
            return [AHFMKeywordVCServices.keyGetVC: vc]
        }
    }
    
    fileprivate static func registerForNavigation() {
        AHServiceRouter.registerVC(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskNavigation) { (userInfo) -> UIViewController? in
            guard let keyword = userInfo[AHFMKeywordVCServices.keySearchKeyword] as? String else {
                assert(false, "You must include a value for key 'keySearchKeyword'")
                return nil
            }
            
            guard let isSearchingForShows = userInfo[AHFMKeywordVCServices.keyIsSearchingForShows] as? Bool else {
                assert(false, "You must include a value for key 'keyIsSearchingForShows'")
                return nil
            }
            
            let vcStr = "AHFMKeywordVC.AHFMKeywordVC"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            
            let manager = Manager()
            manager.keyword = keyword
            manager.isSearchingForShows = isSearchingForShows
            let vc = vcType.init()
            vc.setValue(manager, forKey: "manager")
            return vc
        }
    }
}
