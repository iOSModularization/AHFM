//
//  AHFMShowPageManger.swift
//  AHFMShowPage
//
//  Created by Andy Tong on 10/6/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMModuleManager
import AHServiceRouter
import AHFMShowPageServices


public struct AHFMShowPageManger: AHFMModuleManager {
    public static func activate() {
        AHServiceRouter.registerVC(AHFMShowPageServices.service, taskName: AHFMShowPageServices.taskNavigation) { (userInfo) -> UIViewController? in
            guard let showId = userInfo[AHFMShowPageServices.keyShowId] as? Int else {
                assert(false, "You must pass a showId into userInfo")
                return nil
            }
            
            let vcStr = "AHFMShowPage.AHFMShowPageVC"
            
            guard let clazz = NSClassFromString(vcStr), let vcType = clazz as? UIViewController.Type else {
                return nil
            }
            
            var vc: UIViewController? = AHServiceRouter.reuseVC({ (vc) -> Bool in
                guard vc.isKind(of: clazz) else {
                    return false
                }
                
                guard let manager = vc.value(forKey: "manager") as? Manager else {
                    return false
                }
                
                return manager.showId == showId
            })
            
            if vc == nil {
                vc = vcType.init()
            }
            let manager = Manager()
            manager.showId = showId
            vc?.setValue(manager, forKey: "manager")
            return vc
        }
    }
}
