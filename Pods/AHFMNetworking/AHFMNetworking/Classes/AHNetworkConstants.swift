//
//  AHNetworkConstants.swift
//  Pods
//
//  Created by Andy Tong on 7/16/17.
//
//

import Foundation

struct Constants{
    struct OAuth {
        static var clientId = "ed7696c1660f15f214cc2de145bb25accf02d415eb396c50920538fe9205633f"
        static var clientSecret = "cdb3bf0a6d6b9eb9f1f77215a7a77d6f482bf63f2dfcf9dcd2586e429a60cc71"
        static var authorizeUri = "https://audiosear.ch/oauth/authorize"
        static var tokenUri = "https://audiosear.ch/oauth/token"
        static var baseURL = "https://audiosear.ch"
        static var grantType = "client_credentials"
        static var scope = ""
        
    }
    
    struct Keychain {
        static var service = "com.andyhurricane.ios"
        static var accessTokenKey = "Keychain.accessTokenKey"
    }
    
    struct BaseURL {
        // not last '/' and no 'www' attached!!
        static var showById = "https://audiosear.ch/api/shows"
        static var episodeById = "https://audiosear.ch/api/episodes"
        
        // Get related shows based a show's id
        // https://www.audiosear.ch/api/shows/2964/related
        static var relatedShowsById = "https://audiosear.ch/api/shows"
        
        // https://www.audiosear.ch/api/shows/2149/episodes
        static var episodesByShowID = "https://audiosear.ch/api/shows"
        
        static var trending = "https://audiosear.ch/api/trending"
    }
}
