//
//  AHFMDownloadCenterManager.swift
//  AHFMDownloadCenter
//
//  Created by Andy Tong on 10/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMModuleManager
import AHFMDownloadCenterServices

public struct AHFMDownloadCenterManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerVC(AHFMDownloadCenterServices.service, taskName: AHFMDownloadCenterServices.taskNavigation) { (_) -> UIViewController? in
            
            let vcStr = "AHFMDownloadCenter.AHFMDownloadCenter"
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            
            let vc = vcType.init()
            let manager = Manager()
            vc.setValue(manager, forKey: "manager")
            return vc
            
        }
    }
}
