

import Foundation
import AHDownloader
import AHFMModuleManager

public struct AHFMDownloaderManager: AHFMModuleManager {
    public static func activate() {
        let manager = Manager.shared
        AHDownloader.addDelegate(manager)
    }
}
