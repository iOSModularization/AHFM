//
//  AHFMCategoryVCManager.swift
//  AHFMCategoryVC_Example
//
//  Created by Andy Tong on 10/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMModuleManager
import AHFMCategoryVCServices

public struct AHFMCategoryVCManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerTask(AHFMCategoryVCServices.service, taskName: AHFMCategoryVCServices.taskCreateVC) { (_, _) -> [String : Any]? in
            
            let vcStr = "AHFMCategoryVC.AHFMCategoryVC"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let vc = vcType.init()
            let manager = Manager()
            vc.setValue(manager, forKey: "manager")
            return [AHFMCategoryVCServices.keyGetVC: vc]
        }
    }
}
