//
//  AHFMAudioPlayerServices.swift
//  Pods
//
//  Created by Andy Tong on 9/28/17.
//
//

import Foundation
import AHFMModuleManager
import AHAudioPlayer

public struct AHFMAudioPlayerManager: AHFMModuleManager {
    public static func activate() {
        let manager = Manager.shared
        AHAudioPlayerManager.shared.delegate = manager
    }
    
}
