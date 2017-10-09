//
//  Manager.swift
//  AHFMCategoryVC_Example
//
//  Created by Andy Tong on 10/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter
import AHFMKeywordVCServices
import AHFMBottomPlayerServices


class Manager: NSObject {
    func categoryVC(_ vc: UIViewController, didSelectCategory category: String){
        guard let navVC = vc.navigationController else {
            return
        }
        let type: AHServiceNavigationType = .push(navVC: navVC)
        let serachKeyword = category
        let isForShows = true
        let info = [AHFMKeywordVCServices.keySearchKeyword: serachKeyword, AHFMKeywordVCServices.keyIsSearchingForShows: isForShows] as [String : Any]
        
        AHServiceRouter.navigateVC(AHFMKeywordVCServices.service, taskName: AHFMKeywordVCServices.taskNavigation, userInfo: info, type: type, completion: nil)
    }
    
    func viewWillAppear(_ vc: UIViewController){
        let dict: [String: Any] = [AHFMBottomPlayerServices.keyShowPlayer: true, AHFMBottomPlayerServices.keyParentVC: vc]
        AHServiceRouter.doTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer, userInfo: dict, completion: nil)
    }
    
    func viewWillDisappesar(_ vc: UIViewController){
        
    }
}
