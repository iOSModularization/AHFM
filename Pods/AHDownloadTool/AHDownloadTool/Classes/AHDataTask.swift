//
//  AHDataTask.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 6/22/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import Foundation

private let AHDataTaskDownloadQueueName = "AHDownloadTool-DownloadTask-QueueName"


public struct AHHttpHeader {
    static let contentLength = "Content-Length"
    
    // for Google Firebase Storage, it use "content-range" for range
    static let contentRange = "Content-Range"
}

public enum AHDataTaskState {
    case notStarted
    case pausing
    case downloading
    case succeeded
    case failed
}


public class AHDataTask: NSObject {
    public static var maxConcurrentTasks: Int = 1
    
    
    fileprivate var session: URLSession?
    fileprivate weak var task: URLSessionDataTask?
    

    fileprivate static var delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = AHDataTaskDownloadQueueName
        queue.maxConcurrentOperationCount = maxConcurrentTasks
        return queue
    }()
    
    // Default is main queue.
    fileprivate static var callBackQueue: DispatchQueue?
    
    public var tempDir: String?
    public var cacheDir: String?
    public var fileName: String?
    public var fileTempPath: String? {
        if let fileName = self.fileName {
            return getTempPath(fileName: fileName)
        }else{
            return nil
        }
    }
    public var fileCachePath: String? {
        if let fileName = self.fileName {
            return getCachePath(fileName: fileName)
        }else{
            return nil
        }
    }
    public var timeout: TimeInterval = 8.0
    
    // only for the file in cache, and this size is the current size of the file
    fileprivate var offsetSize: UInt64 = 0
    
    fileprivate var totalSize: UInt64 = 0
    fileprivate var outputStream: OutputStream?
    
    // Callbacks
    fileprivate var fileSizeCallback: ((_ fileSize: UInt64) -> Void)?
    fileprivate var progressCallback: ((_ progress: Double) -> Void)?
    fileprivate var successCallback: ((_ filePath: String) -> Void)? {
        didSet {
            if successCallback == nil {
                print("successCallback == nil")
            }
        }
    }
    fileprivate var failureCallback: ((_ error: Error?) -> Void)?
    
    
    
    // It is not nil, when there's an error in the current task.
    fileprivate var currentError: Error? = nil
    
    fileprivate(set) var progress: Double = 0.0
    fileprivate(set) var state = AHDataTaskState.notStarted {
        didSet {
            var queue: DispatchQueue? = nil
            if AHDataTask.callBackQueue == nil {
                queue = DispatchQueue.main
            }
            
            switch state {
            case .succeeded:
                guard let cachePath = self.fileCachePath else {return}
                
                queue!.async {
                     self.successCallback?(cachePath)
                }
                
            case .failed:
                queue!.async {
                    self.failureCallback?(self.currentError)
                }
            default:
                break
            }
        }
    }
    
    
    
    
}

extension AHDataTask {
    public func donwload(url: String, fileSizeCallback: ((_ fileSize: UInt64) -> Void)?, progressCallback: ((_ progress: Double) -> Void)?, successCallback: ((_ filePath: String) -> Void)?, failureCallback: ((_ error: Error?) -> Void)?) {
        self.fileSizeCallback = fileSizeCallback
        self.progressCallback = progressCallback
        self.successCallback = successCallback
        self.failureCallback = failureCallback
        
        download(url: url)
    }
    
    
    fileprivate func download(url: String){
        guard state != .downloading && state != .pausing else {
            print("startDownload state is still in either downloading or pausing")
            return
        }
        guard let tempPath = self.fileTempPath, let cachePath = self.fileCachePath else {
            print("tempPath or cachePath is nil")
            return
        }
        
        state = .notStarted
        
        
        // A. file is already downloaded in cache dir
            // 1. notify outside info(localPath, fileSize)
        if AHFileTool.doesFileExist(filePath: cachePath) {
            state = .succeeded
            return
        }

        
        // B. check tempPath
        //    1. file is in tempPath, start download from fileSize
        //    2. file is not in tempPath, start download from 0
        if AHFileTool.doesFileExist(filePath: tempPath) {
            offsetSize = AHFileTool.fileSize(filePath: tempPath)
        }else{
            print("start download from 0")
            offsetSize = 0
            
        }
        
        download(url, offsetSize)
        
        // C. check current file size agaist total size
        //  * implmeneted in urlSeesion(didReceived response) since you can only get the file's real size in http response
    }
    
    public func resume() {
        guard state == .notStarted || state == .pausing else {
            print("resume state is not notStarted or pausing")
            return
        }
        
        // if it's current pausing, delegate method urlSeesion(didReceived response) won't be called and state won't be changed to downloading, so change state here
        if state == .pausing {
            state = .downloading
        }
        
        // state will be determined in delegate methods
        task?.resume()
    }
    
    public func pause() {
        guard state == .downloading else {
            print("pause state is not downloading")
            return
        }
        state = .pausing
        task?.suspend()
    }
    

    public func cancel() {
        guard state == .downloading || state == .pausing else {
            print("cancel state is not in downloading or pausing")
            return
        }
        // state will be set to failed in delegate method for canceling
        task?.cancel()
        session?.invalidateAndCancel()
        session = nil
        
    }
    
}

//MARK:- Private Methods
extension AHDataTask {
    fileprivate func getTotalSize(response: HTTPURLResponse) -> UInt64? {
        
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
    
    fileprivate func download(_ url: String, _ offsetSize: UInt64) {
        guard let url = URL(string: url) else {
            print("download error url is nil")
            return
        }
        
        if session == nil {
            let config = URLSessionConfiguration.ephemeral
            session = URLSession(configuration: config, delegate: self, delegateQueue: AHDataTask.delegateQueue)
        }
        
        // use var to delare mutable tyepe, instead of using NSMutableURLRequest
        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        // if offset is 0, "Content-Range" would not appear in the response
        request.setValue("bytes=\(offsetSize)-", forHTTPHeaderField: "Range")

        task = session?.dataTask(with: request)
        
        resume()
        
    }

    
    /// This method's logic should be reconsidered!!!
    fileprivate func getName(url: String) -> String {
        if fileName == nil {
            fileName =  (url as NSString).lastPathComponent
        }
        return fileName!
    }
    
    fileprivate func getTempPath(fileName: String) -> String{
        if self.tempDir == nil {
            self.tempDir = NSTemporaryDirectory()
        }
        let temp = (self.tempDir! as NSString).appendingPathComponent(fileName)
        return temp
        
    }
    
    fileprivate func getCachePath(fileName: String) -> String {
        if self.cacheDir == nil {
            self.cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        }

        let cachePath = (self.cacheDir! as NSString).appendingPathComponent(fileName)
        return cachePath
    }
    
}



//MARK:- URLSession DataDelegate
extension AHDataTask: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        // C. file is in cache
        
        
        
        guard let response = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        // *** 1. file size(offsetSize) == real size --> This case would casuse status code: 416 which means the offsetSize is not satisfied.
        //  (Not implemented) 1.1 move file from cache to temp
        //  (Not implemented) 1.2 cancel current request
        //  (Not implemented) 1.3 notify outside info(localPath, fileSize)
        guard response.statusCode < 400 else {
            print("response.statusCode >= 400 !!!")
            completionHandler(.cancel)
            return
        }
        
        guard let totalSize = getTotalSize(response: response) else {
            completionHandler(.cancel)
            return
        }
        
        
        
        
        // 4.2 file size > real size when fail to move file from cachePath to tempPath
        //  4.2.1 remove the file and restart download
        //  4.2.2 start new download request
        
        
        // 4.3 file size < real size
        //  4.3.1 create and open OutputStream
        //  4.3.2 resume download from currentSize
        
        guard let cachePath = self.fileCachePath,
              let tempPath = self.fileTempPath else {
            print("didReceive response: no cachePath or tempPath")
            completionHandler(.cancel)
            return
        }
        
        
        if offsetSize == totalSize  { // this case is less likely to happen -- status code: 416
            AHFileTool.moveItem(atPath: tempPath, toPath: cachePath)
            completionHandler(.cancel)
        } else if offsetSize > totalSize {
            AHFileTool.remove(filePath: tempPath)
            completionHandler(.cancel)
            download(url: response.url!.absoluteString)
        }else{
            let url = URL(fileURLWithPath: tempPath)
            outputStream = OutputStream(url: url, append: true)
            outputStream?.open()
            state = .downloading
            
            if self.fileSizeCallback != nil {
                var queue: DispatchQueue? = nil
                if AHDataTask.callBackQueue == nil {
                    queue = DispatchQueue.main
                }
                queue?.async {
                    self.fileSizeCallback?(totalSize)
                }
            }
            completionHandler(.allow)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        var values = [UInt8](repeating:0, count:data.count)
        data.copyBytes(to: &values, count: data.count)
        
        outputStream?.write(values, maxLength: data.count)
        offsetSize = offsetSize + UInt64(data.count)
        
        let newProgress = Double(offsetSize) / Double(totalSize)
        let secondDigitA = Int(newProgress * 100) % 10
        let secondDigitB = Int(progress * 100) % 10

        
        progress = newProgress
        
        if self.progressCallback != nil, secondDigitA != secondDigitB {
            var queue: DispatchQueue? = nil
            if AHDataTask.callBackQueue == nil {
                queue = DispatchQueue.main
            }
            queue?.async {
                self.progressCallback?(self.progress)
            }
        }
        
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        guard let cachePath = self.fileCachePath,
            let tempPath = self.fileTempPath else {
                state = .failed
                return
        }
        if error == nil {
            AHFileTool.moveItem(atPath: tempPath, toPath: cachePath)
            state = .succeeded
        }else{
            self.currentError = error
            state = .failed
            AHFileTool.remove(filePath: tempPath)
        }
        outputStream?.close()
    }
    
}




extension UIDevice {
    static var isSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }
}





