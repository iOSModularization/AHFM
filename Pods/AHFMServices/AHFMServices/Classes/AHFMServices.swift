import Foundation

public protocol AHFMServices {
    
}
public extension AHFMServices {
    /// The service name
    public static var service: String {
        return "\(Self.self)"
    }
    
    /// To navigate to a VC
    public static var taskNavigation: String {
        return "taskNavigation"
    }
    
    /// To create a VC and return it to the caller
    public static var taskCreateVC: String {
        return "taskCreateVC"
    }
    
    /// The key to extract the VC from a userInfo dictionary
    public static var keyGetVC: String {
        return "keyGetVC"
    }
}
