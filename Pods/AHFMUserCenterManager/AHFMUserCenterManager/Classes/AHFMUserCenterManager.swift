//
//  AHFMUserCenterManager.swift
//  AHFMUserCenter_Example
//
//  Created by Andy Tong on 10/7/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMModuleManager
import AHServiceRouter
import AHFMUserCenterServices

public struct AHFMUserCenterManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerTask(AHFMUserCenterServices.service, taskName: AHFMUserCenterServices.taskCreateVC) { (_, _) -> [String : Any]? in
            
            let vcStr = "AHFMUserCenter.AHFMUserCenter"
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let vc = vcType.init()
            let manager = Manager()
            vc.setValue(manager, forKey: "manager")
            return [AHFMUserCenterServices.keyGetVC: vc]
        }
    }
}
