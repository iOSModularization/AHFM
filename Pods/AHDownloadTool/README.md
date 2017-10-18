# AHDownloadTool
## Usage
### 1. Download
```Swift
AHDataTaskManager.donwload(fileName: "testURL4.mp3", url: testURL4, fileSizeCallback: { (fileSize) in
/// store the file size if needed
}, progressCallback: { (progress) in
/// the progress will only be updated when the percent whole number changes,
/// e.g. from %33 to %34, not for those from %33.33 to %33.99.
/// Otherwise the main thread is going to be filled up with those progress updates.
}, successCallback: { (filePath) in
print("testURL4 ok, path:\(filePath)")
}) { (error) in
print("testURL4 failed error:\(String(describing: error))")
}
```
#### Paths and file name
The default temporary and cache direatory is NSTemporaryDirectory() and cachesDirectory from NSSearchPathForDirectoriesInDomains.
The default filename is the last path component of thr download url.

You can always specify those three attributes, by using another overloaded download method(It's too long to put it on here, Xcode's autocomplete will tell you which one).

#### Download controls and States
A. AHDataTaskManager provides download controls, such as pauseAll(), resumeAll(), or pause(url: String) for specific task based on its url string.

B. Other APIs provided by AHDataTaskManager:
```Swift
public static func getCurrentTaskURLs() -> [String]
public static func getState(_ urlStr: String) -> AHDataTaskState
public static func getTaskTempFilePath(_ urlStr: String) -> String?
public static func getTaskCacheFilePath(_ urlStr: String) -> String?
```

### 2. File size probe. Support download url redirections.
A: Probe a single url
```Swift
AHFileSizeProbe.probe(urlStr: testURL4) { (size) in
print("single size:\(size)")
}
```

B: Probe a batch of urls
```Swift
let fileUrls = [testURL1,testURL2,testURL3,testURL4]
AHFileSizeProbe.probeBatch(urlStrs: [testURL1,testURL2,testURL3,testURL4]) { (sizeDict) in
/// NOTE: the sizeDict is a map from the ORIGINAL download url you passed in, to its file size.
for (offset: i, element: (key: url, value: fileSize)) in sizeDict.enumerated() {
print("url:\(value) fileSize:\(fileSize)")
}
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AHDownloadTool is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AHDownloadTool"
```

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHDownloadTool is available under the MIT license. See the LICENSE file for more info.

