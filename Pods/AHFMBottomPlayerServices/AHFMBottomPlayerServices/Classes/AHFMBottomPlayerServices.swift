//
//  AHFMBottomPlayerServices.swift
//  AHFMBottomPlayer
//
//  Created by Andy Tong on 10/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMServices

public struct AHFMBottomPlayerServices: AHFMServices {
    /// use AHServiceRouter.doTask(...)
    public static let taskDisplayPlayer = "taskDisplayPlayer"
    
    /// You should pass your current VC as a parentVC for bottomPlayer
    public static let keyParentVC = "keyParentVC"
    
    /// Boolean value to determine if the bottomPlayer should show up or not.
    public static let keyShowPlayer = "keyShowPlayer"
}
