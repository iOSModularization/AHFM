
//
//  ServiceManager.swift
//  Pods
//
//  Created by Andy Tong on 9/28/17.
//
//

import Foundation
import AHFMAudioPlayerVCServices

import AHFMModuleManager
import AHServiceRouter


//public var albumnId: Int
//public var trackId: Int
//public var audioURL: String
//public var fullCover: String?
//public var thumbCover: String?
//
//public var albumnTitle: String?
//public var trackTitle: String?
//public var duration: TimeInterval?
//
//public var lastPlayedTime: TimeInterval?


public struct AHFMAudioPlayerVCManager: AHFMModuleManager {
    
    public static func activate() {
        AHServiceRouter.registerVC(AHFMAudioPlayerVCServices.service, taskName: AHFMAudioPlayerVCServices.taskNavigation) { (userInfo) -> UIViewController? in
            guard let thisTrackId = userInfo[AHFMAudioPlayerVCServices.keyTrackId] as? Int else {
                return nil
            }
            
            let vcStr = "AHFMAudioPlayerVC.AHFMAudioPlayerVC"
            
            guard let clazz = NSClassFromString(vcStr), let vcType = clazz as? UIViewController.Type else {
                return nil
            }
            
            var vc: UIViewController? = AHServiceRouter.reuseVC({ (vc) -> Bool in
                if vc.isKind(of: clazz) {
                    return true
                }else{
                    return false
                }
            })
            
            if vc == nil {
                vc = vcType.init()
            }
            
            let manager = AHFMManagerHandler()
            manager.initialTrackId = thisTrackId
            vc?.setValue(manager, forKey: "manager")
            
            return vc
        }
        
    }
    
    
}








