# AHFM
AHFM is a mid-level complex podcast iOS app that consists of [50+ modules](https://github.com/iOSModularization), including 8 utility modules and 10 marjor INDEPENDENT business modules -- all orchestrated by [AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter).  
AHFM has one particularly shining feature that other open source projects, perhaps a lot of production apps, don't have -- built with a highly distributed archeteture -- better than [Uber's](https://eng.uber.com/new-rider-app/)!  
For more info about the archeteture: [Featuring Distributed Archeteture](#distributed-archeteture) and my paper [iOS: A Highly Distributed Archeteture for Large-scale Collaborations]()

AHFM only uses three third-party frameworks: 
1. Alamofire(for JSON reuqests and OAuth ONLY).  
2. SwiftJSON  
3. SDWebImage    
NOTE: The download parts use [AHDownloader](https://github.com/ivsall2012/AHDownloader) which doesn't depend on Alamofire.  

Other than those three frameworks, other parts of the project, including utility tools, are all home-made!!

\**AHFM copys most of its features from [蜻蜓FM](https://itunes.apple.com/us/app/id506685538?mt=8).*   

## Content
- [Overview](#overview)
  - [Brief Demo](#brief-demo)
  - [Feature List](#feature-list)
  - [Test The Project](#test-the-project)
    - [Error Handling](#error-handling)
  - [Featuring Distributed Archeteture](#featuring-distributed-archeteture)
- [What Is Not Implemented](#what-is-not-implemented)
  - [Offline Detection](#offline-detection)
  - [Login And Backend Long Connection](#login-and-backend-long-connection)
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


## Overview
Throughout this article, a podcast show is called a show and an audio podcast track is called an episode.  
A show contains mutiple episodes.


### Brief Demo

### Feature List
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
After a episode being downloaded, you can play it locally and delete the episode, or the whole album if you want. 

- **Play History**  
All played episodes will be stored in local database and shown in the history page with their played-progress.

- **A Simple Subscribe/unscribe system**  
This suscribing system works locally with the database. AHFM is still a demo project anyway.  
I'll describe how to make a socket [long connection](#login-and-backend-long-connection) later.

### Test The Project

#### Build From Xcode

#### Download The Binary

#### Error Handling
libc++abi.dylib`__cxa_throw:

### Featuring Distributed Archeteture
What doesn that even mean, a "distributed archeteture"?  
Well, usually we develop an iOS app, we will create a one project hosted on Github(or other sites), then we started develop on our own. Once a developer finishes his part, he would 

The following modules are AHFM's major business modules. 
1. **The main module** is a small enough business UI module using MVC or MVVM archeteture.   
It ususally is just one page of screen.
It is INDEPENDENT and resuable -- you can just for example "pod 'AHFMBottomPlayer'" and use it in another project without changing a line!
And each of them has two companion modules -- services module and a manager module.  

2. **The service module**, e.g. AHFMBottomPlayerServices, is an independent module and contains keys of services that the main module providing to the public so that the ousiders can use [AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter) to route to it or use its services. (AHServiceRouter routes by strings of keys). It's purely for routing pages.

3. ** The manager**, e.g. AHFMBottomPlayerManager, is a pure business logics manager which process and handles data and events from the main module. It also imports other service modules and decides which page to route according to those events.



## What Is Not Implemented

### Offline Detection

### Login And Backend Long Connection

## Feature Demos By Modules

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

![bottomPlayer](https://github.com/iOSModularization/AHFM/bottomPlayer.gif)  

Related frameworks:
a. floating header at top: [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  


### Show Page
1. [AHFMShowPage](https://github.com/iOSModularization/AHFMShowPage)  
2. [AHFMShowPageServices](https://github.com/iOSModularization/AHFMShowPageServices)  
3. [AHFMShowPageManager](https://github.com/iOSModularization/AHFMShowPageManger)  


The show page displays a show's introduction and its episodes.    
If there's a playing episode that belongs the current show,  
it will scroll to that specific episode and give it a red indicator on the left.  
![overview](https://github.com/iOSModularization/AHFM/showPage_overview.gif)  

it also has a nice sticky header and it's particularly sticky when the show contains current playing episode.
![header](https://github.com/iOSModularization/AHFM/showPage_header.gif)  

It also correctly handles episode's download states at any given time!  
NOTE: All download related states(paused, downloading, downlaoded) are handled correctly throughout the app at any given time!  
![download](https://github.com/iOSModularization/AHFM/showPage_download.gif)  

The show page is one of the two pages in the app(the otehr is Audio Player page), implemented viewController recycling.  
The following gif shows that we started from "FT Alphachat", tapped into some other show then found "FT Alphachat" again at the "recommended" section.  
When we tapped it, the navigationController didn't push, but popped to previous show page for "FT Alphachat" entering from the left side.  
![recycling](https://github.com/iOSModularization/AHFM/showPage_recycling.gif)  



### Audio Player
1. [AHFMAudioPlayerVC](https://github.com/iOSModularization/AHFMAudioPlayerVC)  
2. [AHFMShowPageServices](https://github.com/iOSModularization/AHFMAudioPlayerVCServices)  
3. [AHFMAudioPlayerVCManager](https://github.com/iOSModularization/AHFMAudioPlayerVCManager)  

The audio player has all the functionalities a standard audio player has: next/previous episode, fast-forward/backward 10s, speeds 1.0/1.25/1.5/1.75/2.0.  
It also has a [Episode List](#episode-list) at left corner list bar and a [Show Page](#show-page) by tapping the middle show cover.  
It always remembers episode's last played time history and ready to restore the progress.  

In the gif demo, pay attention that the audio player only being push at the first time and other times it's being **popped**, entering from the left side -- it's being recycled(or reused).  
![audio player demo](https://github.com/iOSModularization/AHFM/audioPlayer.gif)  

Related frameworks:
a. middle bannerView: [AHBannerView](https://github.com/ivsall2012/AHBannerView)  
b. progress slider with loaded progress: [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider)  
c. floating header at top: [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  

### Download List
1. [AHFMDownloadList](https://github.com/iOSModularization/AHFMDownloadList)  
2. [AHFMDownloadListServices](https://github.com/iOSModularization/AHFMDownloadListServices)  
3. [AHFMDownloadListManager](https://github.com/iOSModularization/AHFMDownloadListManager)  

You can get to Download List from only one place -- the show page.  
It first probes episode's file sizes then store them into database.  
And it's a download list, of course it can initiate download tasks.  
![DownadList Demo](https://github.com/iOSModularization/AHFM/downloadList.gif)  

### Download Center
1. [AHFMDownloadCenter](https://github.com/iOSModularization/AHFMDownloadCener)  
2. [AHFMDownloadCenterServices](https://github.com/iOSModularization/AHFMDownloadCenterServices)  
3. [AHFMDownloadCenterManager](https://github.com/iOSModularization/AHFMDownloadCenterManager)  

The download Center consists of two parts: 1) left side downloaded page 2) right side downloading page  
The downloaded page displays shows that has more than one downloaded episodes.  

The downloading page displays all currently downloading/pasuing tasks, including those didn't finish last time.
Those two pages are hosted by [AHCategoryView](https://github.com/ivsall2012/AHCategoryView).   

The following gif shows that at some point, there were two tasks that got paused then the app was killed, then re-launch. And that two tasks were successfully cached then restored and finished the downloadings with complete files.  
In fact, the tasks would get cached even without pausing first.  
![DownloadCenter Overview](https://github.com/iOSModularization/AHFM/downloadCenter_overview.gif)  


Additinally for the downloaded page, You can delete the whole show's downloaded episodes or you tap into it and delete episodes from that page.  

![DownloadCenter Deletion](https://github.com/iOSModularization/AHFM/downloadCenter_deletion.gif)  

Related framework:  
a. downloaded/downloading pages hosted by [AHCategoryView](https://github.com/ivsall2012/AHCategoryView).  

### Search Page
1. [AHFMSearchVC](https://github.com/iOSModularization/AHFMSearchVC)  
2. [AHFMSearchVCServices](https://github.com/iOSModularization/AHFMSearchVCServices)  
3. [AHFMSearchVCManager](https://github.com/iOSModularization/AHFMSearchVCManager)  

The search page is for searching episodes. And it comes with trending terms from Twitter reportedly.  
Though it can't do auto-complete search since the server just simplely doesn't support it.  
BTW, the JSON data is from www.audiosear.ch. Thank you for your free services!!  
![Search Page](https://github.com/iOSModularization/AHFM/searchPage.gif)  


### Category Page
1. [AHFMCategoryVC](https://github.com/iOSModularization/AHFMCategoryVC)  
2. [AHFMCategoryVCServices](https://github.com/iOSModularization/AHFMCategoryVCServices)  
3. [AHFMCategoryVCManager](https://github.com/iOSModularization/AHFMCategoryVCManager)  

The category page is a draggable UICollectionView and it's topic-based.   
The order of the topics is cached into disk so that it wouldn't be lost.  


![Category Page](https://github.com/iOSModularization/AHFM/category.gif)  

### Play History
1. [AHFMHistoryVC](https://github.com/iOSModularization/AHFMHistoryVC)  
2. [AHFMHistoryVCServices](https://github.com/iOSModularization/AHFMHistoryVCServices)  
3. [AHFMHistoryVCManager](https://github.com/iOSModularization/AHFMHistoryVCManager)  

The history records every episode played and their played progresses.  
It only displays the most recent 15 of those episodes though.  
It can be accessed through [Bottom Player](#buttom-player) and [User Center](#user-center)  
![History Page](https://github.com/iOSModularization/AHFM/history.gif)  


### User Center
1. [AHFMUserCenter](https://github.com/iOSModularization/AHFMUserCenter)  
2. [AHFMUserCenterServices](https://github.com/iOSModularization/AHFMUserCenterServices)  
3. [AHFMUserCenterManager](https://github.com/iOSModularization/AHFMUserCenterManager)  

User center is a really simple page which consists of subscriptions, downloads and history.  

The following gif show that a show will be subscribed then deleted.  
![User Center](https://github.com/iOSModularization/AHFM/userCenter.gif)  

### Episode List
1. [AHFMEpisodeListVC](https://github.com/iOSModularization/AHFMEpisodeListVC)  
2. [AHFMEpisodeListVCServices](https://github.com/iOSModularization/AHFMEpisodeListVCServices)  
3. [AHFMEpisodeListVCManager](https://github.com/iOSModularization/AHFMEpisodeListVCManager)  

Episode list is also a really simple page and serves as an episodes picker for the Audio Player and Bottom Player.

![Episode List](https://github.com/iOSModularization/AHFM/episodeList.gif) 


## Author

Andy Tong, ivsall2012@gmail.com

## License

AHBannerView is available under the MIT license. See the LICENSE file for more info.



