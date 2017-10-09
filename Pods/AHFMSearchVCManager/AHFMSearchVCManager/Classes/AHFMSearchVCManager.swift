//
//  AHFMSearchVCManager.swift
//  AHFMSearchVC_Example
//
//  Created by Andy Tong on 10/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMModuleManager
import AHFMSearchVCService

public struct AHFMSearchVCManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerTask(AHFMSearchVCService.service, taskName: AHFMSearchVCService.taskCreateVC) { (_, _) -> [String : Any]? in
            let vcStr = "AHFMSearchVC.AHFMSearchVC"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let manager = Manager()
            let vc = vcType.init()
            vc.setValue(manager, forKey: "manager")
            return [AHFMSearchVCService.keyGetVC: vc]
        }
    }
}
