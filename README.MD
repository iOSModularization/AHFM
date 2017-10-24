# AHFM
### Brief Demo(the Gif is little bit large, please wait)
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/overview.gif)


### Dependencies
AHFM only uses three third-party frameworks: 
1. Alamofire(for JSON requests and OAuth ONLY).  
2. SwiftJSON  
3. SDWebImage     
NOTE: The download parts are from [AHDownloader](https://github.com/ivsall2012/AHDownloader) which doesn't depend on Alamofire.  

Other than those three frameworks, other parts of the project, including utility tools, are all home-made!!  
There are related frameworks written down at each section in [Feature Demos By Modules](#feature-demos-by-modules) and also a summary at [Related Frameworks](#related-frameworks). 

\**AHFM clones most of its features from [蜻蜓FM](https://itunes.apple.com/us/app/id506685538?mt=8).*     


## Content
- [Overview](#overview)
- [Feature List](#feature-list)
- [Test The Project](#test-the-project)
- [Feature Demos By Modules](#feature-demos-by-modules)
  - [Bottom Player](#bottom-player)
  - [Episode List](#episode-list)
  - [Show Page](#show-page)
  - [Audio Player](#audio-player)
  - [Download List](#download-list)
  - [Download Center](#download-center)
  - [Search Page](#search-page)
  - [Category Page](#category-page)
  - [Play History](#play-history)
  - [User Center](#user-center)
- [Featuring A Distributed Architecture](#featuring-a-distributed-Architecture)
- [Related Frameworks](#related-frameworks)


## Overview
AHFM is a mid-level complex podcast iOS app that consists of [50+ modules](https://github.com/iOSModularization), including 8 utility modules and 10 marjor INDEPENDENT business modules -- all orchestrated by [AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter).  
AHFM has one particularly shining feature that other open source projects, perhaps a lot of production apps, **don't have** -- built with a **highly distributed Architecture** -- better than [Uber's](https://eng.uber.com/new-rider-app/)!  
For more info about the Architecture: [Featuring Distributed Architecture](#distributed-Architecture) and my article [A Highly Distributed Architecture for Large-scale Collaborations](https://github.com/ivsall2012/A-Highly-Distributed-Architecture-for-Large-scale-Collaborations)

NOTE: Throughout this article, a podcast show is called a show and an audio podcast track is called an episode. 
A show can contain multiple episodes.


## Feature List
AHFM caches extensively with local database using [AHDataModel](https://github.com/ivsall2012/AHDataModel).  
- **Audio Progress Caching**  
The audio player will record playing progresses every 10s and restore them every time the same episode being played, including when pausing, user kills the app, during background mode.  

- **Download Progress Caching**  
Downloading tasks will be cached when user pauses them, put the app in background and even kill the app.  
AHFM archived this download capabilities through [AHDownloader](https://github.com/ivsall2012/AHDownloader).

- **Background Playing Mode**  
The audio player, [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer), already handled background playing mode, including album image, next/previous play and of course, play/pause.

- **Audio File Size Probing**   
Since the JSON data doesn't contain file sizes originally, AHFM uses [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)'s AHFileSizeProbe for file size detecting and save them into database.

- **Manage Local Albums and episodes**
After an episode being downloaded, you can play it locally and delete the episode, or the whole album if you want. 

- **Play History**  
All played episodes will be stored in local database and shown in the history page with their played-progress.

- **A Simple Subscribe/unsubscribe system**  
This subscribing system works locally with the database. AHFM is still a demo project anyway.  
I'll describe how to make a socket [long connection](#login-and-backend-long-connection) later.

## Test The Project
#### Requirements
iOS 9.0+(less than 11.0)  
Xcode 8.0+  
NOTE: It's not fully tested on iOS11, though it's functioning well without a crash.  
But most of the problem is from the "safe area" and tablView is not adjusted properly.   
iOS 10.2 is OK.  

#### Steps
1. [Install Cocoapods](https://guides.cocoapods.org/using/getting-started.html)
2. Open your terminal and add the private specs [AHFMSpecs](https://github.com/iOSModularization/AHFMSpecs)  
```ruby
pod repo add AHFMSpecs https://github.com/iOSModularization/AHFMSpecs.git
```

3. Clone [AHFM](https://github.com/iOSModularization/AHFM)  
```ruby
git clone https://github.com/iOSModularization/AHFM.git
```

4. Go to the directory of AHFM you just cloned and update pods through terminal  
```ruby
pod update
```

5. Open AHFM.xcworkspace  
6. Choose a simulator or your real device(recommended) and do a build-and-run  


### Featuring A Distributed Architecture
AHFM uses a flat architecture and divides all services and business logics into fined-grained modules.    
All major modules are ABSOLUTE INDEPENDENT -- Not aware of the entire project and any business related logics.
And all modules are directed by [AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter) which acts like a central traffic control center.
A major(main) module usually has a service module and a manager module.  
The followings are a short description of a major module:  

1. **The Main**  
It is a small enough business UI module using MVC or MVVM Architecture.   
It usually is just one page of screen.
It is INDEPENDENT and reusable -- you can just for example "pod 'AHFMBottomPlayer'" and use it in another project without changing a line!  

2. **The Service**  
It is also an independent module and contains keys of services that the main module providing to the public so that outsiders can use [AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter) to route to it or use its services. (AHServiceRouter routes by strings of keys). It's purely for routing pages.  

3. **The Manager**  
It's a pure business logics manager which processes and handles data/events from the main module.   
It also imports other service modules and decides which page to route according to those events.  

For more info [A Highly Distributed Architecture for Large-scale Collaborations](https://github.com/ivsall2012/A-Highly-Distributed-Architecture-for-Large-scale-Collaborations)

## Feature Demos By Modules
All the major modules are consists of three parts: 1) main 2) service 3) manager.  
For more info [Featuring A Distributed Architecture](#featuring-a-distributed-Architecture).  

### Bottom Player
1. [AHFMBottomPlayer](https://github.com/iOSModularization/AHFMBottomPlayer)  
2. [AHFMBottomPlayerServices](https://github.com/iOSModularization/AHFMBottomPlayerServices)  
3. [AHFMBottomPlayerManager](https://github.com/iOSModularization/AHFMBottomPlayerManager)  

The bottom player is a mini audio control panel shown at the bottom of the app most of the time.  
Tapping on:  
- left list bar, will route to [Episode List](#episode-list) page.  
- middle area, routes to [Audio Player](#audio-player).  
- right the play button, controls audio playback  
- the far right corner button is for [Play History](#play-history)  

The player also restores last played episode and its played progress too, if any.  

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/bottomPlayer.gif)  

Related frameworks:
[AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  


### Show Page
* [AHFMShowPage](https://github.com/iOSModularization/AHFMShowPage)  
* [AHFMShowPageServices](https://github.com/iOSModularization/AHFMShowPageServices)  
* [AHFMShowPageManager](https://github.com/iOSModularization/AHFMShowPageManger)  

#### Overview
The show page displays a show's introduction and its episodes.    
If there's a playing episode that belongs the current show,  
it will scroll to that specific episode and give it a red indicator on the left.  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_overview.gif)  

#### Header
it also has a nice sticky header and it's particularly sticky when the show contains current playing episode.
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_header.gif)  

#### Download
It also correctly handles episode's download states at any given time!  
NOTE: All download related states(paused, downloading, downloaded) are handled correctly throughout the app at any given time!    
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_download.gif)  

#### Recycling View Controllers  
The show page is one of the two pages in the app(the other is Audio Player page), implemented viewController recycling.  
The following Gif shows that we started from "FT Alphachat", tapped into some other show then found "FT Alphachat" again at the "recommended" section.  
When we tapped it, the navigationController didn't push, but popped to previous show page for "FT Alphachat" entering from the left side.  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_recycling.gif)  

Related Framewrks:
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider)  
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  


### Audio Player
1. [AHFMAudioPlayerVC](https://github.com/iOSModularization/AHFMAudioPlayerVC)  
2. [AHFMShowPageServices](https://github.com/iOSModularization/AHFMAudioPlayerVCServices)  
3. [AHFMAudioPlayerVCManager](https://github.com/iOSModularization/AHFMAudioPlayerVCManager)  

The audio player has all the functionalities a standard audio player has: next/previous episode, fast-forward/backward 10s, speeds 1.0/1.25/1.5/1.75/2.0.  
It also has a [Episode List](#episode-list) at left corner list bar and a [Show Page](#show-page) by tapping the middle show cover.  
It always remembers episode's last played time history and ready to restore the progress.  

#### Overview and Recycling
In the Gif demo, pay attention that the audio player only being push at the first time and other times it's being **popped** -- entering from the left side to the right -- it's being recycled(or reused).  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/audioPlayer.gif)  

NOTE: The retarded dragging in the demo is now fixed. 
Related frameworks:
* [AHBannerView](https://github.com/ivsall2012/AHBannerView) for middle bannerView  
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider) for progress slider with loaded progress  
* [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView) for floating header at the top
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  

### Download List
1. [AHFMDownloadList](https://github.com/iOSModularization/AHFMDownloadList)  
2. [AHFMDownloadListServices](https://github.com/iOSModularization/AHFMDownloadListServices)  
3. [AHFMDownloadListManager](https://github.com/iOSModularization/AHFMDownloadListManager)  

You can get to the Download List from only one place -- a [Show Page](#show-page).    
It first probes episode's file sizes then store them into database.  
And it's a download list, of course it can initiate download tasks.  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadList.gif)  

Related Frameworks:  
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  

### Download Center
1. [AHFMDownloadCenter](https://github.com/iOSModularization/AHFMDownloadCener)  
2. [AHFMDownloadCenterServices](https://github.com/iOSModularization/AHFMDownloadCenterServices)  
3. [AHFMDownloadCenterManager](https://github.com/iOSModularization/AHFMDownloadCenterManager)  

The download Center consists of two parts: 1) left side downloaded page 2) right side downloading page  

#### Downloaded Page
The downloaded page displays shows that has more than one downloaded episodes.  

#### Downloading page
The downloading page displays all currently downloading/pausing tasks, including those didn't finish last time.  
Those two section pages are hosted by [AHCategoryView](https://github.com/ivsall2012/AHCategoryView).   

#### Caching Downloading Tasks  
The following Gif shows that at some point, there were two tasks that got paused then the app was killed, then re-launch. And that two tasks were successfully cached then restored and finished the download tasks with complete files.  
In fact, the tasks would get cached even without pausing first.  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadCenter_overview.gif)  

#### Delete Shows and Episodes  
Additionally for the downloaded page, You can delete the whole show's downloaded episodes or you tap into it and delete episodes from that page.  

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadCenter_deletion.gif)  

Related framework:  
* [AHCategoryView](https://github.com/ivsall2012/AHCategoryView) for downloaded/downloading section pages   
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  


### Search Page
1. [AHFMSearchVC](https://github.com/iOSModularization/AHFMSearchVC)  
2. [AHFMSearchVCServices](https://github.com/iOSModularization/AHFMSearchVCServices)  
3. [AHFMSearchVCManager](https://github.com/iOSModularization/AHFMSearchVCManager)  

The search page is for searching episodes. And it comes with trending terms from Twitter reportedly.  
Though it can't do auto-complete search since the server just simply doesn't support it.  
BTW, the JSON data is from www.audiosear.ch. Thank you for your free services!!  
![](https://github.com/iOSModularization/AHFM/searchPage.gif)  


### Category Page
1. [AHFMCategoryVC](https://github.com/iOSModularization/AHFMCategoryVC)  
2. [AHFMCategoryVCServices](https://github.com/iOSModularization/AHFMCategoryVCServices)  
3. [AHFMCategoryVCManager](https://github.com/iOSModularization/AHFMCategoryVCManager)  

The category page is a draggable UICollectionView and it's topic-based.   
The order of the topics is cached into disk so that it wouldn't get lost.  


![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/category.gif)  

### Play History
1. [AHFMHistoryVC](https://github.com/iOSModularization/AHFMHistoryVC)  
2. [AHFMHistoryVCServices](https://github.com/iOSModularization/AHFMHistoryVCServices)  
3. [AHFMHistoryVCManager](https://github.com/iOSModularization/AHFMHistoryVCManager)  

The history records every episode played and their played progresses.  
It only displays the most recent 15 of those episodes though.  
It can be accessed through [Bottom Player](#buttom-player) and [User Center](#user-center)  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/history.gif)  


### User Center
1. [AHFMUserCenter](https://github.com/iOSModularization/AHFMUserCenter)  
2. [AHFMUserCenterServices](https://github.com/iOSModularization/AHFMUserCenterServices)  
3. [AHFMUserCenterManager](https://github.com/iOSModularization/AHFMUserCenterManager)  

User center is a really simple page which consists of subscriptions, downloads and history.  

The following Gif show that a show will be subscribed then deleted.  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/userCenter.gif)  

### Episode List
1. [AHFMEpisodeListVC](https://github.com/iOSModularization/AHFMEpisodeListVC)  
2. [AHFMEpisodeListVCServices](https://github.com/iOSModularization/AHFMEpisodeListVCServices)  
3. [AHFMEpisodeListVCManager](https://github.com/iOSModularization/AHFMEpisodeListVCManager)  

Episode list is also a really simple page and serves as an episode picker for the Audio Player and Bottom Player.

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/episodeList.gif) 


## Related Framework
The following 8 frameworks are made with native iOS frameworks fully.  
* [AHDataModel](https://github.com/ivsall2012/AHDataModel) for all persistence layers  
* [AHCategoryView](https://github.com/ivsall2012/AHCategoryView)  
* [AHBannerView](https://github.com/ivsall2012/AHBannerView)  
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  
* [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider)  

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHBannerView is available under the MIT license. See the LICENSE file for more info.



