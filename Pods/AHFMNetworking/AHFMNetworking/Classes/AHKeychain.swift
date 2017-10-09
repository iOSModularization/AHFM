//
//  AHKeychain.swift
//  Pods
//
//  Created by Andy Tong on 7/16/17.
//
//

import Foundation
import KeychainAccess

final class AHKeychain {
    static let keychain = Keychain(service: Constants.Keychain.service)
    
    static func getAccessToken() -> String? {
        return keychain[Constants.Keychain.accessTokenKey]
    }
    
    static func saveAcessToken(token: String) {
        keychain[Constants.Keychain.accessTokenKey] = token
    }
}
