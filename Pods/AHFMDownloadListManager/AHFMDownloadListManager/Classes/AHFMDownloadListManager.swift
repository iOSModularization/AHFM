//
//  AHFMDownloadListManager.swift
//  AHFMDownloadList
//
//  Created by Andy Tong on 10/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMDownloadListServices
import AHFMModuleManager
import AHServiceRouter

public struct AHFMDownloadListManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerVC(AHFMDownloadListService.service, taskName: AHFMDownloadListService.taskNavigation) { (userInfo) -> UIViewController? in
            
            let vcStr = "AHFMDownloadList.AHFMDownloadListVC"
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            guard let showId = userInfo[AHFMDownloadListService.keyShowId] as? Int else {
                return nil
            }
            
            let vc = vcType.init()
            let manager = Manager()
            if let showCenter = userInfo[AHFMDownloadListService.keyShouldShowRightNavBarButton] as? Bool {
                vc.setValue(showCenter, forKey: "shouldShowRightNavBarButton")
            }
            manager.showId = showId
            vc.setValue(manager, forKey: "manager")
            return vc
            
        }
    }
}
