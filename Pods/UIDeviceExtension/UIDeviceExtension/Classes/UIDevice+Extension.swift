//
//  File.swift
//  Pods
//
//  Created by Andy Tong on 8/18/17.
//
//

import Foundation

public extension UIDevice {
    public static var totalDiskSpaceInBytes: UInt64{
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                if let space = systemAttributes[FileAttributeKey.systemSize] as?UInt64 {
                    return space
                    
                }else{
                    return 0
                }
            } catch {
                return 0
            }
        }
    }
    
    public static var freeDiskSpaceInBytes: UInt64{
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                if let freeSpace = systemAttributes[FileAttributeKey.systemFreeSize] as? UInt64 {
                    return freeSpace
                }else{
                    return 0
                }
                
            } catch {
                return 0
            }
        }
    }
    
    public static var usedDiskSpaceInBytes:UInt64 {
        get {
            let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
            return usedSpace
        }
    }
    public static var totalDiskSpaceStr: String{
        return bytesToMegaBytes(UIDevice.totalDiskSpaceInBytes)
    }
    
    public static var freeDiskSpaceStr: String{
        return bytesToMegaBytes(UIDevice.freeDiskSpaceInBytes)
    }
    
    public static var usedDiskSpaceStr: String{
        get {
            return bytesToMegaBytes(UIDevice.usedDiskSpaceInBytes)
        }
    }
    
    public static var isSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }
    
    private static func bytesToMegaBytes(_ bytes: UInt64) -> String {
        let str = String(format: "%.01f", (Double(bytes) / 1024.0 / 1024.0))
        return str
    }
}



