//
//  AHFMMainManager.swift
//  AHFMMain_Example
//
//  Created by Andy Tong on 10/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMModuleManager

import AHFMDownloaderManager
import AHFMAudioPlayerManager

//######### Main VCs Starts #########
//### AHFMUserCenter
import AHFMUserCenterManager

//### AHFMFeature
import AHFMFeatureManager

//### AHFMCategoryVC
import AHFMCategoryVCManager

//### AHFMSearchVC
import AHFMSearchVCManager

//######### Main VCs End #########


//### AHFMBottomPlayer
import AHFMBottomPlayerManager

//### AHFMEpisodeListVC
import AHFMEpisodeListVCManager

//### AHFMHistoryVC
import AHFMHistoryVCManager

//### AHFMAudioPlayerVC
import AHFMAudioPlayerVCManager

//### AHFMDownloadList
import AHFMDownloadListManager

//### AHFMDownloadCenter
import AHFMDownloadCenterManager

//### AHFMShowPage
import AHFMShowPageManger

//### AHFMKeywordVC
import AHFMKeywordVCManager

import AHFMMainServices

public struct AHFMMainManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerTask(AHFMMainServices.service, taskName: AHFMMainServices.taskCreateVC) { (_, _) -> [String : Any]? in
            let vcStr = "AHFMMain.AHFMMainVC"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let manager = Manager()
            let vc = vcType.init()
            vc.setValue(manager, forKey: "manager")
            return [AHFMMainServices.keyGetVC: vc]
        }
        
        activateAll()
    }
    fileprivate static func activateAll() {
        AHFMDownloaderManager.activate()
        AHFMAudioPlayerManager.activate()
        
        //######### Main VCs Starts #########
        //### AHFMUserCenter
        AHFMUserCenterManager.activate()
        
        //### AHFMFeature
        AHFMFeatureManager.activate()
        
        //### AHFMCategoryVC
        AHFMCategoryVCManager.activate()
        
        //### AHFMSearchVC
        AHFMSearchVCManager.activate()
        
        //######### Main VCs End #########
        
        
        //### AHFMBottomPlayer
        AHFMBottomPlayerManager.activate()
        
        //### AHFMEpisodeListVC
        AHFMEpisodeListVCManager.activate()
        
        //### AHFMHistoryVC
        AHFMHistoryVCManager.activate()
        
        //### AHFMAudioPlayerVC
        AHFMAudioPlayerVCManager.activate()
        
        //### AHFMDownloadList
        AHFMDownloadListManager.activate()
        
        //### AHFMDownloadCenter
        AHFMDownloadCenterManager.activate()
        
        //### AHFMShowPage
        AHFMShowPageManger.activate()
        
        //### AHFMKeywordVC
        AHFMKeywordVCManager.activate()
    }
}

