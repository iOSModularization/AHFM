//
//  AHFMBottomPlayerManager.swift
//  AHFMBottomPlayer
//
//  Created by Andy Tong on 10/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AHServiceRouter
import AHFMModuleManager
import AHFMBottomPlayerServices


public struct AHFMBottomPlayerManager: AHFMModuleManager {
    public static func activate() {
        let vcStr = "AHFMBottomPlayer.AHFMBottomPlayer"
        
        guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
            print("\(vcStr) doesn't exist")
            return
        }
        
        let manager = Manager.shared
        if let vc = vcType.value(forKey: "shared") as? UIViewController {
            vc.setValue(manager, forKey: "manager")
        }else{
            print("bottomPlayer doesn't exist")
        }
        
        
        AHServiceRouter.registerTask(AHFMBottomPlayerServices.service, taskName: AHFMBottomPlayerServices.taskDisplayPlayer) { (userInfo, completion) -> [String : Any]? in
            
            guard let parentVC = userInfo[AHFMBottomPlayerServices.keyParentVC] as? UIViewController else {
                assert(false, "You have to include a VC as a parentVC.")
                completion?(false, nil)
                return nil
            }
            
            guard let shouldShowPlayer = userInfo[AHFMBottomPlayerServices.keyShowPlayer] as? Bool else{
                assert(false, "You have to include 'shouldShowPlayer' to indicate if you need the bottomPlayer to show up or not.")
                completion?(false, nil)
                return nil
            }
            
            let vcStr = "AHFMBottomPlayer.AHFMBottomPlayer"
            
            guard let vcType = NSClassFromString(vcStr) as? UIViewController.Type else {
                assert(false, "Could find bottomPlayer, you need to include the dependency.")
                completion?(false, nil)
                return nil
            }
            
            
            if let vc = vcType.value(forKey: "shared") as? UIViewController {
                vc.setValue(parentVC, forKey: "parentVC")
                vc.setValue(shouldShowPlayer, forKey: "shouldShowPlayer")
                completion?(true, nil)
            }else{
                completion?(false, nil)
                
            }
            return nil
        }
    }
}





