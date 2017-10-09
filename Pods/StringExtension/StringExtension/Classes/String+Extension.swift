//
//  String+Extension.swift
//  Pods
//
//  Created by Andy Tong on 7/22/17.
//
//

import Foundation
public extension String {
    /// Turn bytes into a string MegaBytes
    public static func bytesToMegaBytes(_ bytes: UInt64) -> String {
        let str = String(format: "%.01f", (Double(bytes) / 1024.0 / 1024.0))
        return str
    }
    
    /// Turn seconds into a time string, e.g. 01:04, 32:01
    public static func secondToTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else {
            return "-00:00"
        }
        let min = Int(seconds.rounded()) / 60
        let sec = Int(seconds.rounded()) % 60
        return String(format: "%02ld:%02ld", min,sec)
    }
    
    /// Which bound is CGFloat.GreatedtFiniteMagnitude, is the one you need to figure out.
    public func stringSize(boundWdith: CGFloat, boundHeight: CGFloat, font: UIFont) -> CGSize {
        let boundSize: CGSize =  CGSize(width: boundWdith, height: boundHeight)
        
        let size = (self as NSString).boundingRect(with: boundSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size
        return size
    }
}
