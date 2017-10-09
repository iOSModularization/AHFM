//
//  AHFMNetworking.swift
//  Pods
//
//  Created by Andy Tong on 7/16/17.
//
//

import Foundation
import Alamofire

public class AHFMNetworking: NSObject {
    fileprivate var requests = [DataRequest]()
    
    
    private var parameters: [String: String] = [
        "base_url": Constants.OAuth.baseURL,
        "client_id": Constants.OAuth.clientId,
        "client_secret": Constants.OAuth.clientSecret,
        "authorize_uri": Constants.OAuth.authorizeUri,
        "token_uri": Constants.OAuth.tokenUri,
        "access_token": "",
        "grant_type": Constants.OAuth.grantType,
        "scope": Constants.OAuth.scope,
        ]

    private lazy var sessionManager: SessionManager = {
        // accessToken, send request anyway since sessionManager will retry and get a new token
        let accessToken = AHKeychain.getAccessToken() ?? ""
        self.parameters["access_token"] = accessToken
        let oauthHandler = OAuth2Handler(parameters: self.parameters)
        // in case accessToken is invalid, save this newly obtained one
        oauthHandler.didUpdateAccessToken({ (accessToken) in
            AHKeychain.saveAcessToken(token: accessToken)
        })
        
        
        let sessionManager = SessionManager()
        
        // 'Authorization' header won't be passed through!!
        sessionManager.delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
            var redirectedRequest = request
            
            if let
                originalRequest = task.originalRequest,
                let headers = originalRequest.allHTTPHeaderFields,
                let authorizationHeaderValue = headers["Authorization"]
            {
                var mutableRequest = request
                mutableRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
                redirectedRequest = mutableRequest
            }
            
            return redirectedRequest
        }
        
        
        sessionManager.adapter = oauthHandler
        sessionManager.retrier = oauthHandler
        return sessionManager
    }()
    
    public func cancelAllRequests() {
        requests.forEach { (request) in
            request.cancel()
        }
        requests.removeAll()
    }
    
    public func cancelLastRequest() {
        let request = requests.popLast()
        request?.cancel()
    }
    
    public func cancelRequest(url: URL) {
        let requests = self.requests.filter { (request) -> Bool in
            return request.request?.url == url
        }
        requests.forEach { (request) in
            request.cancel()
            if let index = self.requests.index(of: request) {
                self.requests.remove(at: index)
            }
        }
        
    }
    
    @discardableResult
    public func trending(_ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let baseURLString = Constants.BaseURL.trending
        
        let urlString = "\(baseURLString)"
        
        return request(urlStr: urlString, completion)
    }
    
    @discardableResult
    public func show(byShowId showId:Int, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let baseURLString = Constants.BaseURL.showById
        
        let urlString = "\(baseURLString)/\(showId)"
        
        return request(urlStr: urlString, completion)
        
    }

    @discardableResult
    public func episode(byEpisodeId episodeId:Int, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let baseURLString = Constants.BaseURL.episodeById
        let urlStr = "\(baseURLString)/\(episodeId)"
        
        return request(urlStr: urlStr, completion)
        
    }
    
    @discardableResult
    public func episodes(byShowID showID:Int, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let baseURLString = Constants.BaseURL.episodesByShowID
        let urlStr = "\(baseURLString)/\(showID)/episodes"
        
        return request(urlStr: urlStr, completion)
        
    }
    
    @discardableResult
    public func shows(byRelatedShowId id:Int, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let baseURLString = Constants.BaseURL.relatedShowsById
        let urlStr = "\(baseURLString)/\(id)/related"
        
        return request(urlStr: urlStr, completion)
        
    }
    
    @discardableResult
    public func showsChartDaily(amount: Int,_ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        //https://www.audiosear.ch/api/chart_daily?limit=50&country=us
        let urlStr = "https://www.audiosear.ch/api/chart_daily?limit=\(amount)&country=us"
        
        return request(urlStr: urlStr, completion)
    }
    
    @discardableResult
    public func showsByCategory(_ categoryName: String,  _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        let url = "https://audiosear.ch/api/search/shows/*?filters[categories.name]=\(categoryName.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)"
        return request(urlStr: url, completion)
    }
    
    @discardableResult
    public func episodesByKeyword(_ keyword: String, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void)  -> DataRequest{
        // You have to add 'www' !!
        // https://www.audiosear.ch/api/search/episodes/women?size=20&from=0
        let url = "https://www.audiosear.ch/api/search/episodes/\(keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)?size=20&from=0"
        return request(urlStr: url, completion)
    }
    
    @discardableResult
    fileprivate func request(urlStr: String, _ completion: @escaping (_ data: Any?, _ error: Error?)->Void) -> DataRequest {
        
        let request = sessionManager.request(urlStr).validate().responseJSON { response in
            
            DispatchQueue.main.async {
                if let url = response.request?.url {
                    self.cancelRequest(url: url)
                }
                
            }
            
            switch response.result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
            
        }
        
        requests.append(request)
        return request
    }
    
}


extension DataRequest: Equatable {
    public static func ==(lhs: DataRequest, rhs: DataRequest) -> Bool{
        return lhs.request == rhs.request
    }
}









