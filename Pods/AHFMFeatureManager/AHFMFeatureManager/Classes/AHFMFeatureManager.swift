//
//  AHFMFeatureManager.swift
//  AHFMFeature
//
//  Created by Andy Tong on 10/7/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMModuleManager

import AHServiceRouter
import AHFMFeatureServices


public struct AHFMFeatureManager: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerTask(AHFMFeatureServices.service, taskName: AHFMFeatureServices.taskCreateVC) { (_, _) -> [String : Any]? in

            let vcStr = "AHFMFeature.AHFMFeatureVC"
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                return nil
            }
            
            let vc = vcType.init()
            let manager = Manager()
            vc.setValue(manager, forKey: "manager")
            return [AHFMFeatureServices.keyGetVC: vc]
            
        }
    }
}
