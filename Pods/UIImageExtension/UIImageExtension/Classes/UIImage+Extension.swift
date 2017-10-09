//
//  UIImage+Extension.swift
//  Pods
//
//  Created by Andy Tong on 7/22/17.
//
//

import Foundation

public extension UIImage {
    /// ONLY for cocoapods frameworks!!!
    /// Load the named images(all sizes) from the bundle that the class(the user object) is included
    public convenience init?(name: String, user : AnyObject) {
        let resourceBundle = Bundle.resourceBundle(user)
        self.init(named: name, in: resourceBundle, compatibleWith: nil)
    }
}

extension Bundle {
    
    /// The resource bundle lives within a pod framework
    static func resourceBundle(_ user: AnyObject) -> Bundle? {
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
