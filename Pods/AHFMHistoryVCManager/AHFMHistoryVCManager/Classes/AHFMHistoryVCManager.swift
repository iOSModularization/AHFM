//
//  AHFMHistoryVCManager.swift
//  AHFMHistoryVC
//
//  Created by Andy Tong on 10/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMModuleManager
import AHServiceRouter
import AHFMHistoryVCServices

public struct AHFMHistoryVCManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerVC(AHFMHistoryVCServices.service, taskName: AHFMHistoryVCServices.taskNavigation) { (_) -> UIViewController? in
            let vcStr = "AHFMHistoryVC.AHFMHistoryVC"
            
            guard let clazz = NSClassFromString(vcStr), let vcType = clazz as? UIViewController.Type else {
                return nil
            }
            
            var vc: UIViewController? = AHServiceRouter.reuseVC({ (vc) -> Bool in
                return vc.isKind(of: clazz)
            })
            
            if vc == nil {
                vc = vcType.init()
            }
            
            let manager = Manager()
            vc!.setValue(manager, forKey: "manager")
            return vc
            
        }
    }
}
