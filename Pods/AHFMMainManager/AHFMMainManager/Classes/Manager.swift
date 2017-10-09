//
//  Manager.swift
//  AHFMMain_Example
//
//  Created by Andy Tong on 10/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHServiceRouter
import AHFMUserCenterServices
import AHFMFeatureServices
import AHFMCategoryVCServices
import AHFMSearchVCService

class Manager: NSObject {
    func AHFMMainVCGetUserCenterVC(_ vc: UIViewController)  -> UIViewController?{
        guard let info = AHServiceRouter.doTask(AHFMUserCenterServices.service, taskName: AHFMUserCenterServices.taskCreateVC, userInfo: [:], completion: nil) else {
            return nil
        }
        
        guard let vc = info[AHFMUserCenterServices.keyGetVC] as? UIViewController else {
            return nil
        }
        return vc
    }
    
    func AHFMMainVCGetFeatureVC(_ vc: UIViewController) -> UIViewController?{
        guard let info = AHServiceRouter.doTask(AHFMFeatureServices.service, taskName: AHFMFeatureServices.taskCreateVC, userInfo: [:], completion: nil) else {
            return nil
        }
        
        guard let vc = info[AHFMFeatureServices.keyGetVC] as? UIViewController else {
            return nil
        }
        return vc
    }
    
    func AHFMMainVCGetCategoryVC(_ vc: UIViewController) -> UIViewController?{
        guard let info = AHServiceRouter.doTask(AHFMCategoryVCServices.service, taskName: AHFMCategoryVCServices.taskCreateVC, userInfo: [:], completion: nil) else {
            return nil
        }
        
        guard let vc = info[AHFMCategoryVCServices.keyGetVC] as? UIViewController else {
            return nil
        }
        return vc
    }
    
    func AHFMMainVCGetSearchVC(_ vc: UIViewController) -> UIViewController?{
        guard let info = AHServiceRouter.doTask(AHFMSearchVCService.service, taskName: AHFMSearchVCService.taskCreateVC, userInfo: [:], completion: nil) else {
            return nil
        }
        
        guard let vc = info[AHFMSearchVCService.keyGetVC] as? UIViewController else {
            return nil
        }
        return vc
    }
}
