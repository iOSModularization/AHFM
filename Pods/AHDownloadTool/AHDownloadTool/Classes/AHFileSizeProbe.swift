//
//  AHFileSizeProbe.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 8/4/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import Foundation

public typealias AHFileSizeProbeCompletionSingle = (_ fileSize: UInt64)->Void
public typealias AHFileSizeProbeCompletionBatch = (_ sizeDict: [String : UInt64])->Void

private struct AHFileProbeTask: Equatable {
    var task: URLSessionDataTask?
    var completion: AHFileSizeProbeCompletionSingle?
    
    public static func ==(lhs: AHFileProbeTask, rhs: AHFileProbeTask) -> Bool {
        if lhs.task == nil || lhs.completion == nil {
            // not a complete task!
            return false
        }
        if rhs.task == nil || rhs.completion == nil {
            // not a complete task!
            return false
        }
        
        // now both task/completion are not nil, on both sides.
        // unwrap first!
        return lhs.task! === rhs.task!
    }
}

public class AHFileSizeProbe: NSObject {
    public var timeout: TimeInterval = 8.0
    
    fileprivate static var probes = [AHFileSizeProbe]()
    
    fileprivate var session: URLSession?
    fileprivate var taskDict = [String: AHFileProbeTask]()
    
    // [redirectedURL: originalURL]
    fileprivate var taskRedirectDict = [String: String]()
    
    public static func probe(urlStr: String, _ completion: @escaping AHFileSizeProbeCompletionSingle) {
        // One probe object with only one probe task
        self.probeFile(urlStr: urlStr, completion)
    }
    
    private static func probeFile(urlStr: String, probe: AHFileSizeProbe? = nil, _ completion: @escaping AHFileSizeProbeCompletionSingle) {
        var probe = probe
        
        // If this method is called by the probeBatch method, we don't remove probe, leave it to that method to manage. 
        // If the call is from the sinle probe method, we do the removal.
        var shouldRemoveProbe = false
        if probe == nil {
            probe = AHFileSizeProbe()
            shouldRemoveProbe = true
        }
        probes.append(probe!)
        
        guard let task = probe!.getDataTask(urlStr) else { return }
        
        let wraperCompletion:AHFileSizeProbeCompletionSingle = {(fileSize: UInt64) -> Void in
            completion(fileSize)
            
            guard let probe = probe else { return }
            if shouldRemoveProbe {
                if let index = probes.index(of: probe){
                    self.probes.remove(at: index)
                }
                
            }else{
                // the method caller is from probeBatch(), let that method to manage the probe.
            }
            
        }
        
        let probeTask = AHFileProbeTask(task: task, completion: wraperCompletion)
        probe!.taskDict[urlStr] = probeTask
        task.resume()
    
    }
    
    
    // return file sizes in the order of the urlStrs array.
    // This method will remove currently probing tasks, if you called this method before and it's still probing now. And this method won't affect the shared probe!
    public static func probeBatch(urlStrs: [String], _ completion: @escaping AHFileSizeProbeCompletionBatch) {
        // One probe object with many probe tasks
        guard urlStrs.count > 0 else {
            return
        }
        let probe = AHFileSizeProbe()
        self.probes.append(probe)
        
        var sizeDict = [String : UInt64]()
        let group = DispatchGroup()
        
        for urlStr in urlStrs{
            group.enter()
            self.probeFile(urlStr: urlStr, probe: probe, { (size) in
                sizeDict[urlStr] = size
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.main, work: .init(block: {
            completion(sizeDict)
            if let index = probes.index(of: probe){
                self.probes.remove(at: index)
            }
        }))
        
    }
    
    private func getDataTask(_ urlStr: String) -> URLSessionDataTask? {
        guard let url = URL(string: urlStr) else {
            print("download error url is nil")
            return nil
        }
        
        if let _  = taskDict[urlStr] {
            print("repeated!")
            return nil
        }
        
        if session == nil {
            let config = URLSessionConfiguration.ephemeral
            session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        }
        
        // use var to delare mutable tyepe, instead of using NSMutableURLRequest
        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        // if offset is 0, "Content-Range" would not appear in the response
        request.setValue("bytes=0-", forHTTPHeaderField: "Range")
        
        guard let task = session?.dataTask(with: request) else {
            print("task failed")
            return nil
        }
       return task
    }
    
    
}

// The delegate is 'URLSessionDataDelegate' not 'URLSessionDelegate'!!!
extension AHFileSizeProbe: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        if let origin = task.currentRequest?.url?.absoluteString, let new = request.url?.absoluteString {
            
            if let originFurther = self.taskRedirectDict[origin] {
                self.taskRedirectDict[new] = originFurther
            }else{
                self.taskRedirectDict[new] = origin
            }
        }
        
        
        completionHandler(request)
    }
    
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        guard let request = dataTask.currentRequest else {
            return
        }
        guard let url = request.url else {
            return
        }
        
        var probeTaskTemp: AHFileProbeTask? = nil
        
        if let originalURL = taskRedirectDict[url.absoluteString], let task = taskDict[originalURL] {
            probeTaskTemp = task
        }
        
        if let task = taskDict[url.absoluteString] {
            // no redrection, use the url directly
            probeTaskTemp = task
        }
        
        guard let probeTask = probeTaskTemp else {
            print("No such probeTask with url:\(url.absoluteString)")
            return
        }
        
        guard let response = response as? HTTPURLResponse else {
            taskDict.removeValue(forKey: url.absoluteString)
            probeTask.completion?(0)
            completionHandler(.cancel)
            return
        }
        
        guard response.statusCode < 400 else {
            print("response.statusCode >= 400 !!!")
            taskDict.removeValue(forKey: url.absoluteString)
            probeTask.completion?(0)
            completionHandler(.cancel)
            return
        }
        
        guard let totalSize = getTotalSize(response: response) else {
            taskDict.removeValue(forKey: url.absoluteString)
            probeTask.completion?(0)
            completionHandler(.cancel)
            return
        }
        
        
        taskDict.removeValue(forKey: url.absoluteString)
        probeTask.completion?(totalSize)
        completionHandler(.cancel)
    }
    
    fileprivate func getTotalSize(response: HTTPURLResponse) -> UInt64? {
        var totalSize: UInt64 = 0
        let allFields = response.allHeaderFields
        
        guard let contentLengthStr = allFields[AHHttpHeader.contentLength] as? String else {
            print("no contentLength, something wrong, STOP!!")
            return nil
        }
        // Content-Length is guaranteed to exist
        guard let contentLength = UInt64(contentLengthStr) else {
            print("contentLengthStr transform failed, STOP!!")
            return nil
        }
        
        totalSize = contentLength
        
        // if content-range(lowercase) exists, take this over Content-Length
        if let contentRange = allFields[AHHttpHeader.contentRange] as? String {
            // "Content-Range" = "bytes 100-4880328/4880329"
            if let sizeStr = contentRange.components(separatedBy: "/").last,
                let size = UInt64(sizeStr) {
                totalSize = size
            }else{
                // can't extract total size from contentRange, STOP!
                return nil
            }
        }
        
        return totalSize
    }
}









