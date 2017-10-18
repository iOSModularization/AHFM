# AHDownloader
The feature of this downloader is its muti-delegate-based monitor mechanism.
Instead of using blocks which will casue potential retain cycles, crashes and much higher maintain costs.
A muti-delegate monitor is like regular delegate -- clear and easy to maintain.
All you need to do is to add your delegate to AHDownloader.
You delegate will be kept weakly -- don't need to remove your delegate like when using a notificaiton.
## Usage
### Basic APIs
```Swift
/// The url string acts like a UUID for the download task.
AHDownloader.download(url: String)

/// Get the downoad state for a specific download task
AHDownloader.getState(urlStr: String)

/// Cancel and delete currently downloading tasks and their temporary files.
AHDownloader.deleteUnfinishedTasks(_ urls: [String], _ completion:(()->Void)? )
```
### Monitoring
```Swift
/// Your url string is like a ID for the task. And you differentiate each tasks by their url strings.
/// AHDownloader will remove your delete internally if your delegate gets destoryed.
/// Your delegate is kept weakly inside AHDownloader.
AHDownloader.addDelegate(_ delegate: AHDownloaderDelegate)

/// The Delegate Methods
public func downloaderWillStartDownload(url: String)

public func downloaderDidStartDownload(url: String)

public func downloaderDidUpdate(url: String, progress: Double)

public func downloaderDidUpdate(url: String, fileSize: Int)

/// The path used to store downloading data -- a temporary file path which will be removed when the task finished.
public func downloaderDidUpdate(url: String, unfinishedLocalPath: String)

public func downloaderDidFinishDownload(url: String, localFilePath: String)

public func downloaderDidPaused(url: String)

public func downloaderDidPausedAll()

public func downloaderDidResumedAll()

public func downloaderDidResume(url: String)

public func downloaderCancelAll()

public func downloaderDidCancel(url: String)

/// The downloader already handled removing unfinished files for you.
/// This is just a notification. You should delete unfinishedFilePath for your data models.
public func downloaderDeletedUnfinishedTaskFiles(urls: [String])

/// Will use first delegate that returns a non-nil string
public func downloaderForFileName(url: String) -> String?
```


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AHDownloader is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AHDownloader'
```

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHDownloader is available under the MIT license. See the LICENSE file for more info.

