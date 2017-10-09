//
//  AHFMShowReformer.swift
//  Pods
//
//  Created by Andy Tong on 9/28/17.
//
//

import Foundation
import SwiftyJSON


public struct AHFMShowTransform {
    /*
     public var id = 0
     public var title = ""
     public var detail = ""
     public var thumbCover = ""
     public var fullCover = ""
     public var buzzScore: Double = 0.0
     */
    
    /// Transform json data into AHFMShow from Category request
    public static func transformJsonShows(_ jsonArray : [JSON]) -> [[String: Any]] {
        var shows = [[String: Any]]()
        for jsonShow in jsonArray {
            let show = jsonToShow(jsonShow)
            shows.append(show)
        }
        return shows
    }
    
    public static func jsonToShow(_ jsonShow: JSON) -> [String: Any] {
        var show = [String: Any]()
        show["id"] = jsonShow[AHJsonShowPaths.id].intValue
        show["title"] = jsonShow[AHJsonShowPaths.title].string ?? ""
        show["detail"] = jsonShow[AHJsonShowPaths.detail].string ?? ""
        
        
        // go through all posible paths
        for jsonPath in AHJsonShowPaths.thumbCoverPaths {
            if let thumbCover = jsonShow[jsonPath].string {
                show["thumbCover"] = thumbCover
                break
            }
        }
        
        for jsonPath in AHJsonShowPaths.fullCoverPaths {
            if let fullCover = jsonShow[jsonPath].string {
                show["fullCover"] = fullCover
                break
            }
        }
        
        
        show["buzzScore"] = jsonShow[AHJsonShowPaths.buzzScore].double ?? 0.0
        if let jsonCategories = jsonShow[AHJsonShowPaths.categories].array {
            var categoryArr = [String]()
            for jsonCategory in jsonCategories {
                if let category = jsonCategory[AHJsonShowPaths.categoryName].string {
                    categoryArr.append(category)
                }
            }
            show["categoryStr"] = categoryArr.joined(separator: ",")
        }
        
        return show
    }
}



private struct AHJsonShowPaths {
    static let id: [JSONSubscriptType] = ["id"]
    static let title: [JSONSubscriptType] = ["title"]
    static let detail: [JSONSubscriptType] = ["description"]
    
    // the following two, are for shows requested by category/relatedShows REST API
    static let thumbCover: [JSONSubscriptType] = ["image_files", 0, "file","thumb", "url"]
    static let fullCover: [JSONSubscriptType] = ["image_files", 0, "file", "url"]
    
    // the following two, are for shows requested by showId REST API
    static let thumbCover2: [JSONSubscriptType] = ["image_files", 0, "url","thumb"]
    static let fullCover2: [JSONSubscriptType] = ["image_files", 0, "url","full"]
    
    static let thumbCover3: [JSONSubscriptType] = ["image_urls", "thumb"]
    static let fullCover3: [JSONSubscriptType] = ["image_urls", "full"]
    
    static let thumbCoverPaths:[[JSONSubscriptType]] = { () -> [[JSONSubscriptType]] in
        return [thumbCover, thumbCover2, thumbCover3]
    }()
    
    static let fullCoverPaths:[[JSONSubscriptType]] = { () -> [[JSONSubscriptType]] in
        return [fullCover, fullCover2, fullCover3]
    }()
    
    static let buzzScore: [JSONSubscriptType] = ["buzz_score"]
    
    // the value is an array of category dict, and categoryName is under that dict.
    static let categories: [JSONSubscriptType] = ["categories"]
    static let categoryName: [JSONSubscriptType] = ["name"]
    
}
