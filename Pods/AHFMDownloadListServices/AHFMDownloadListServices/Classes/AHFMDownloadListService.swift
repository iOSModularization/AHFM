//
//  AHFMDownloadListService.swift
//  AHFMDownloadList
//
//  Created by Andy Tong on 10/1/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMServices

public struct AHFMDownloadListService: AHFMServices {
    
    /// Should show downloadCenter on the right side of the navBar, or not.
    /// If not passed, its default is true.
    public static let keyShouldShowRightNavBarButton = "keyShouldShowRightNavBarButton"
    
    /// The showId you want downloadListVC to display
    public static let keyShowId = "keyShowId"
}
