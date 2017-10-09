//
//  Bundle+Extension.swift
//  Pods
//
//  Created by Andy Tong on 7/24/17.
//
//

import Foundation


public extension Bundle {
    /// The current root bundle including the whole app/framework
    public static func currentBundle(_ user: AnyObject) -> Bundle {
        let podBundle = Bundle(for: type(of: user))
        return podBundle
    }
    
    /// The resource bundle lives within a pod framework
    public static func resourceBundle(_ user: AnyObject) -> Bundle? {
        let podBundle = Bundle(for: type(of: user))
        
        // resource bundle it's within podBundle, its name is yourFramework.bundle
        let path = podBundle.bundlePath
        let bundePath = (path as NSString).lastPathComponent
        let bundleName = bundePath.components(separatedBy: ".").first
        
        guard let url = podBundle.url(forResource: bundleName, withExtension: "bundle") else {
//            fatalError("Can not find bundle:\(type(of: user)).bundle")
            return Bundle.main
        }
        return Bundle(url: url)
    }
}
