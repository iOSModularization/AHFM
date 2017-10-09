//
//  AHFMKeywordVCServices.swift
//  AHFMKeywordVC_Example
//
//  Created by Andy Tong on 10/8/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import AHFMServices


public struct AHFMKeywordVCServices: AHFMServices {
    /// For task 'taskNavigation', key 'keySearchKeyword' and 'keyIsSearchingForShows' are mandatory.
    /// The VC will search with the keyword when viewWillAppear.
    public static let taskNavigation = "taskNavigation"
    
    /// For task 'taskCreateVC', this key 'keySearchKeyword' is optional.
    /// Key 'keyIsSearchingForShows' is mandatory.
    /// You can use the returned VC to perform 'taskGoSearch' and include a keyword overthere, anytime later, to do the search.
    public static let taskCreateVC = "taskCreateVC"
    
    /// You must pass an already created VC for 'keyGetVC' and a keyword for 'keySearchKeyword' in order to do the search.
    /// Note: make sure the VC's view is already in display.
    public static let taskGoSearch = "taskGoSearch"
    
    
    public static let keySearchKeyword = "keySearchKeyword"

    /// To specify if this search VC is going to search, using the keyword, for shows or episodes.
    public static let keyIsSearchingForShows = "keyIsSearchingForShows"

}
