import Foundation
import SwiftyJSON


public struct AHFMEpisodeTransform {
    
    
    
    /*
     public var id = 0
     public var showId = 0
     public var duration:Int = 0
     public var createdAt: String = ""
     public var showTitle:String = ""
     public var title: String = ""
     public var detail: String = ""
     public var audioURL: String = ""
     public var buzzScore: Double = 0.0
     public var showFullCover: String = ""
     public var showThumbCover: String = ""
     
     
     */
    public static func transformJsonEpisodes(_ jsonArray : [JSON]) -> [[String: Any]] {
        var episodes = [[String: Any]]()
        for jsonEp in jsonArray {
            if let ep = jsonToEpisode(jsonEp) {
                episodes.append(ep)
            }
        }
        return episodes
        
    }
    
    public static func jsonToEpisode(_ jsonEpisode: JSON) -> [String: Any]? {
        guard let audioURL = jsonEpisode[AHJsonEpisodePaths.audioURL].string else {
            return nil
        }
        
        var ep = [String: Any]()
        ep["audioURL"] = audioURL
        ep["id"] = jsonEpisode[AHJsonEpisodePaths.id].intValue
        ep["showId"] = jsonEpisode[AHJsonEpisodePaths.showId].intValue
        ep["duration"] = jsonEpisode[AHJsonEpisodePaths.duration].double ?? 0
        // the raw data score is a string!!
        if let scoreStr = jsonEpisode[AHJsonEpisodePaths.buzzScore].string,
            let score = Double(scoreStr){
            
            ep["buzzScore"] = score
        }else{
            ep["buzzScore"] = 0.0
        }
        ep["showTitle"] = jsonEpisode[AHJsonEpisodePaths.showTitle].string ?? ""
        ep["title"] = jsonEpisode[AHJsonEpisodePaths.title].string ?? ""
        ep["detail"] = jsonEpisode[AHJsonEpisodePaths.detail].string ?? ""
        ep["createdAt"] = jsonEpisode[AHJsonEpisodePaths.createdAt].string ?? ""
        ep["showFullCover"] = jsonEpisode[AHJsonEpisodePaths.showFullCover].string ?? ""
        ep["showThumbCover"] = jsonEpisode[AHJsonEpisodePaths.showThumbCover].string ?? ""
        
        return ep
    }
}


private struct AHJsonEpisodePaths {
    static let id: [JSONSubscriptType] = ["id"]
    static let showId: [JSONSubscriptType] = ["show_id"]
    static let duration: [JSONSubscriptType] = ["duration"]
    static let createdAt: [JSONSubscriptType] = ["date_created"]
    static let showTitle: [JSONSubscriptType] = ["show_title"]
    static let title: [JSONSubscriptType] = ["title"]
    static let detail: [JSONSubscriptType] = ["description"]
    static let audioURL: [JSONSubscriptType] = ["audio_files", 0, "mp3"]
    static let buzzScore: [JSONSubscriptType] = ["buzz_score"]
    static let showFullCover: [JSONSubscriptType] = ["image_urls", "full"]
    static let showThumbCover: [JSONSubscriptType] = ["image_urls", "thumb"]
}
