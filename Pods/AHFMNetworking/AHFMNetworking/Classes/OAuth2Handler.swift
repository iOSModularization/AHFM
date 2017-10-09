//
//  OAuth2Handler.swift
//  Pods
//
//  Created by Andy Tong on 7/16/17.
//
//

import Foundation
import Alamofire

class OAuth2Handler: RequestAdapter, RequestRetrier {
    
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
    private let sessionManager: SessionManager = {
        return SessionManager.default
    }()
    
    private var didUpdateAccessTokenCallback: ((_ accessToken: String)->Void)?
    
    private let lock = NSLock()
    
    private var clientID: String
    private var baseURLString: String
    private var accessToken: String
    private var clientSecret: String
    private var authorizeUri: String
    private var tokenUri: String
    private var grantType: String
    private var scope: String
    
    
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []

    // MARK: - Initialization
    // parameter keys:
//    "base_url": Constants.OAuth.baseURL,
//    "client_id": Constants.OAuth.clientId,
//    "client_secret": Constants.OAuth.clientSecret,
//    "authorize_uri": Constants.OAuth.authorizeUri,
//    "token_uri": Constants.OAuth.tokenUri,
//    "grant_type": Constants.OAuth.grantType,
//    "scope": Constants.OAuth.scope
    
    public init(parameters: [String: String]) {
        self.clientID = parameters["client_id"]!
        self.baseURLString = parameters["base_url"]!
        self.accessToken = parameters["access_token"]!
        self.clientSecret = parameters["client_secret"]!
        self.authorizeUri = parameters["authorize_uri"]!
        self.tokenUri = parameters["token_uri"]!
        self.grantType = parameters["grant_type"]!
        self.scope = parameters["scope"]!
    }
    
    public func didUpdateAccessToken(_ completion: ((_ accessToken: String)->Void)?) {
        self.didUpdateAccessTokenCallback = completion
    }
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if let urlString = urlRequest.url?.absoluteString {
            
            if urlString.hasPrefix(baseURLString) || urlString.hasPrefix("https://www.audiosear.ch") {
                var urlRequest = urlRequest
                urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
                return urlRequest
            }
        }

        fatalError("urlRequest and baseURLString are possibly not matched!")
    }
    
    // MARK: - RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded, accessToken in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if let accessToken = accessToken {

                        strongSelf.accessToken = accessToken
                        strongSelf.didUpdateAccessTokenCallback?(accessToken)
                    }
                    
                    strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(false, 0.0)
        }
    }
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        // https://audiosear.ch/oauth/token
        let urlString = "\(baseURLString)/oauth/token"
        let parameters: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "authorize_uri": authorizeUri,
            "token_uri": tokenUri,
            "grant_type": grantType,
            "scope": scope,
            ]

        sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                if
                    let json = response.result.value as? [String: Any],
                    let accessToken = json["access_token"] as? String
                {
                    completion(true, accessToken)
                } else {
                    completion(false, nil)
                }
                
                strongSelf.isRefreshing = false
        }
    }
}
