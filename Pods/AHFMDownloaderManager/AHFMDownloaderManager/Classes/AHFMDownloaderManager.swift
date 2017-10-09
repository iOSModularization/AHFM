

import Foundation
import AHDownloader
import AHFMModuleManager

public struct AHFMDownloaderManager: AHFMModuleManager {
    public static func activate() {
        let manager = Manager.shared
        var changeDownloadPaths: Any?
        
        let tempDir = "/Users/Hurricane/Go/Swift/AHFM_v2/Audios/temp"
        let cacehDir = "/Users/Hurricane/Go/Swift/AHFM_v2/Audios/cache"
        
        AHDownloader.tempDir = tempDir
        AHDownloader.cacheDir = cacehDir
        AHDownloader.addDelegate(manager)
    }
}
