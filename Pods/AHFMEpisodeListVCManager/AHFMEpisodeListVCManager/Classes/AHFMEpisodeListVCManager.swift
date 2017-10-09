//
//  AHFMEpisodeListVCManager.swift
//  AHFMEpisodeListVC
//
//  Created by Andy Tong on 10/4/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMEpisodeListVCServices
import AHFMModuleManager
import AHServiceRouter

public struct AHFMEpisodeListVCManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerVC(AHFMEpisodeListVCServices.service, taskName: AHFMEpisodeListVCServices.taskNavigation) { (userInfo) -> UIViewController? in
            guard let showId = userInfo[AHFMEpisodeListVCServices.keyShowId] as? Int else{
                return nil
            }
            
            let vcStr = "AHFMEpisodeListVC.AHFMEpisodeListVC"
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            
            let vc = vcType.init()
            let manager = Manager()
            manager.showId = showId
            vc.setValue(manager, forKey: "manager")
            return vc
            
        }
    }
}
