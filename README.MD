[Switch to English](https://github.com/iOSModularization/AHFM/tree/EN)
# AHFM
AHFM是一个精简版的[蜻蜓FM](https://itunes.apple.com/us/app/id506685538?mt=8)克隆  
### Overview(这个动图有点大 会有点卡，请耐心等待几秒 让它下载完成)
![](https://gitee.com/Andy_Tong/AHFM/blob/master/demo_gifs/overview.gif)


### Dependencies
AHFM只有了3个第三方开源库：
1. Alamofire(只用于JSON数据请求和OAuth验证).  
2. SwiftJSON  
3. SDWebImage     
NOTE: 下载部分用的是自己做的[AHDownloader](https://github.com/ivsall2012/AHDownloader)   

除了上面提到的3个第三方库外，其他的各种UI和功能都是自己做的。

自己画的资源文件(Sketch文件):  
https://github.com/iOSModularization/AHFM/blob/master/AHFM.sketch  



## 目录
- [简介](#简介)
- [功能特点](#功能特点)
- [测试项目](#测试项目)
- [关于组件化](#关于组件化)
- [功能模块展示](#功能模块展示)
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
- [相关Frameworks](#相关Frameworks)


## 简介
AHFM是一个中等中等复杂的Swift项目。它使用了[高度组件化方案](https://github.com/iOSModularization/AHFM#featuring-a-distributed-architecture)（正在制作中文版的，过几天就上）。  
它由10个不同的业务组件组成。项目一共有超过50个的pod。[所有的pod在这里](https://github.com/iOSModularization)。  
因为使用了组件化，这让在团队开发的情况下，每个工程师都能聚焦自己的业务组件而几乎不受整个项目的配置环境影响。每个业务组件就像一个个独立的插件，调试起来非常方便。[了解更多](https://github.com/iOSModularization/AHFM#featuring-a-distributed-architecture)


## 功能特点
AHFM使用了[AHDataModel](https://github.com/ivsall2012/AHDataModel)来做本地持久化库。
- **缓存正在播放音频的进度**  
音频的播放进度会被缓存起来，就算进入后台播放，也会缓存。当下次再播放到这个音频的时候，会自动播放上次的进度。

- **缓存下载进度**  
使用自己做的下载器[AHDownloader](https://github.com/ivsall2012/AHDownloader)。支持断点续传。自动暂停和缓存进度，当应用进入后台或者被用户终结掉。

- **后台播放模式**  
使用自己做的音频播放器[AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer),通过代理实现了后台播放、暂停、上一首/下一首、专辑画面等功能。 

- **音频文件大小探测**   
因为服务器数据原本就是不带音频文件大小的, 所有自己做了个文件大小探测器。探测器在[AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)里面的AHFileSizeProbe。

- **Manage Local Albums and episodes**
可以管理已经下载好的专辑和单个音频。

- **Play History**  
可以记录和显示播放历史、播放进度。

- **A Simple Subscribe/unsubscribe system**  
一个本地的 假的订阅系统。

## 测试项目
#### Requirements
iOS 9.0+(less than 11.0)  
Xcode 8.0+  
NOTE: 在iOS11上运行，UITablView的inset会不正确。但小于iOS11的版本都OK。  
NOTE: **因为我用的数据是在美国的免费电台数据提供商。刚收到邮件，他们要在11月28日关闭这个免费的REST服务了:(( 我会尽快修复的，找其他免费的或者自己搞个爬虫。但这个项目所展示的技术和思想是不变的。只有2个地方要改 1）数据请求地址 2）数据的transformer. 其他的逻辑都不用改。**

#### 步骤
1. [安装Cocoapods](https://guides.cocoapods.org/using/getting-started.html)  
2. 打开你Macbook的terminal，然后添加[AHFMSpecs](https://github.com/iOSModularization/AHFMSpecs)进你的CocoaPods. 运行下面命令：  
```ruby
pod repo add AHFMSpecs https://github.com/iOSModularization/AHFMSpecs.git
```

3. 克隆[AHFM](https://github.com/iOSModularization/AHFM)项目   
```ruby
git clone https://github.com/iOSModularization/AHFM.git
```

4. update一下  
```ruby
pod update
```

5. 打开AHFM.xcworkspace  
6. 选择一个iPhone模拟器或者用真机测试。 


### 关于组件化  
在[iOS高度组件化](https://github.com/iOSModularization/AHFM#featuring-a-distributed-architecture)中，我给出了一个相对主流方案更优化的组件化方案[The Service Router Architecture](https://github.com/ivsall2012/A-Highly-Distributed-Architecture-for-Large-scale-Collaborations/blob/master/SRA.md)。  
每一个功能模块都是一个SRA单元。  
我看了很多主流的组件化方案，他们都不错，就是都是用Objective-C的，然后他们都在类的load方法进行注册或配置操作。但在Swift里，那个方法将要过期。而且Swift更加提倡懒加载, 不像Objective-C, Swift不会一下子把所有的类在启动时加载一遍。  
简单地来说，这个方案，或者说是一种Architecture，使用[AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter)负责组件间通讯，然后每个组件或者功能模块就是一个SRA单元，它们都包含3个子模块(pod):

1. **Main**  
这个pod模块是一个足够小但不是太小的颗粒化**UI功能**。比如说一个登录界面但不包含网络、本地存储和其他验证功能。再比如说，一个订单界面，一个用户中心。它们只是一个UI界面，它自身只会通过代理向外界要数据或者传递数据，通过public方法来触发事件，仅此而已。  
因为这个模块是delegate驱动的，所以它可以说是独立于你的项目，你可以把它想象成一个UITablView或者UICollectionView -- 他们根本不关心网络和数据处理，只关心展示UI控件。这个模块可以有自己的数据模型，但绝不公开，外界传数据进来的时候，数据必需是基本数据类型，比如字典，必需保证数据一定正确以便能一拿数据，就可以创建模型了。  
这样使用私有的数据模型是为了不被各种公有数据模型入侵到项目的各个角落。  

2. **Service**  
这其实是一纯字符串的类，也是一个pod。 这些字符串都被用在[AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter)里。它们有3类：1）此服务的服务名称 2）在此服务下的各种任务名 3）某个任务下的参数名称以及这些参数是否可选。  
因为[AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter)会用到这3类字符串名称来进行路由。  

3. **Manager**  
这是一个强业务逻辑pod模块。因为到此为止，我们只有一个UI界面模块和一个字符串名称模块。我们还需要对外提供注册服务。对外提供包括网络数据请求、"Main"模块delegate方法实现、主动触发"Main"模块事件（类似UITableView的reload方法）、页面跳转和持久化。  
如果你仔细一点，你会发现上面的所有这些都是强业务相关的 -- 每个模块，每个项目都有不同的要求，可移植性很差。  
所以现在是业务界面是独立的，但业务逻辑只在这个Manager模块中实现。  
如果想了解更多，请移步到[iOS高度组件化方案](https://github.com/ivsall2012/A-Highly-Distributed-Architecture-for-Large-scale-Collaborations)。（正在制作中文版的，过几天就上）

## 功能模块展示
以下的每一个功能都是一个SRA组件单元。  
### Bottom Player
1. [AHFMBottomPlayer](https://github.com/iOSModularization/AHFMBottomPlayer)  
2. [AHFMBottomPlayerServices](https://github.com/iOSModularization/AHFMBottomPlayerServices)  
3. [AHFMBottomPlayerManager](https://github.com/iOSModularization/AHFMBottomPlayerManager)  

Bottom player就是在屏幕底部的迷你播放器：  
你可以按:  
- 左边的list bar跳转到[Episode List](#episode-list)页面.    
- 中间文字部分跳转到[Audio Player](#audio-player).    
- 右边播放或者暂停按钮  
- 最右边的按钮跳转到[Play History](#play-history)  

这个底部迷你播放器也可以显示之前的播放进度 

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/bottomPlayer.gif)  

相关framework:
[AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  


### Show Page
* [AHFMShowPage](https://github.com/iOSModularization/AHFMShowPage)  
* [AHFMShowPageServices](https://github.com/iOSModularization/AHFMShowPageServices)  
* [AHFMShowPageManager](https://github.com/iOSModularization/AHFMShowPageManger)  

#### Overview
这是专辑首页。显示一些简介和它的音频节目。如果当前播放的音频是本专辑其中的一个音频，那么左边就会有个红色条提示用户。跟QQ音乐的差不多。    
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_overview.gif)  

#### Header
头部有一个蛮不错的、可拉伸的动画效果。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_header.gif)  

#### Download
每个音频的右边都会有下载状态的图标，当然也可以直接点下载。    
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_download.gif)  

#### 控制器重用  
[AHServiceRouter](https://github.com/ivsall2012/AHServiceRouter)支持控制器重用 -- 可以拿到之前的有相同数据模型的控制器，以此来避免太深的导航层级。  
下面的这张Gif展示了 显示在"FT Alphachat"主页, 然后跳到另外一个页面，然后因为选了"FT Alphachat"，所有又跳回来了。    
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/showPage_recycling.gif)  

相关Framewrks:
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider)  
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  


### Audio Player
1. [AHFMAudioPlayerVC](https://github.com/iOSModularization/AHFMAudioPlayerVC)  
2. [AHFMShowPageServices](https://github.com/iOSModularization/AHFMAudioPlayerVCServices)  
3. [AHFMAudioPlayerVCManager](https://github.com/iOSModularization/AHFMAudioPlayerVCManager)  

一个标准的音频播放器: 下一个/上一个音频, 快进/快退10秒, 语速1.0/1.25/1.5/1.75/2.0。  
右边的list bar会跳到[Episode List](#episode-list)。如果你点击中间的专辑图片会跳到专辑的[Show Page](#show-page)。   
这个播放器会自动播放上一下的进度。还有可以播放本地下载好的文件，如果有的话。

#### 演示和控制器重用
动图所展示的播放器都是被pop出来的，也就是重用之前的播放器。   
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/audioPlayer.gif)  

NOTE: 动图里的拖拽有点迟钝，但现在已经修复了。  
相关frameworks:
* [AHBannerView](https://github.com/ivsall2012/AHBannerView) -- 中间的专辑View  
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider) -- 播放器带下载进度条  
* [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView) -- 顶部专辑浮动文字  
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  

### Download List
1. [AHFMDownloadList](https://github.com/iOSModularization/AHFMDownloadList)  
2. [AHFMDownloadListServices](https://github.com/iOSModularization/AHFMDownloadListServices)  
3. [AHFMDownloadListManager](https://github.com/iOSModularization/AHFMDownloadListManager)  

这个下载页面首先会去获取音频文件的大小，然后用户可以选择下载哪个，或者下载所有。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadList.gif)  

Related Frameworks:  
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool) -- 探测音频文件用  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  

### Download Center
1. [AHFMDownloadCenter](https://github.com/iOSModularization/AHFMDownloadCener)  
2. [AHFMDownloadCenterServices](https://github.com/iOSModularization/AHFMDownloadCenterServices)  
3. [AHFMDownloadCenterManager](https://github.com/iOSModularization/AHFMDownloadCenterManager)  

下载中心有2个部分可以切换: 1) 左边已下载控制器 2) 右边正在下载控制器   

这2个控制器页面是用[AHCategoryView](https://github.com/ivsall2012/AHCategoryView)实现的。  
  
支持断点下载。就算应用被用户关闭了，也还是可以暂停然后缓存进度。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadCenter_overview.gif)  

#### 直接删除整张专辑或者删除单个音频   

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/downloadCenter_deletion.gif)  

Related framework:  
* [AHCategoryView](https://github.com/ivsall2012/AHCategoryView)   
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  


### Search Page
1. [AHFMSearchVC](https://github.com/iOSModularization/AHFMSearchVC)  
2. [AHFMSearchVCServices](https://github.com/iOSModularization/AHFMSearchVCServices)  
3. [AHFMSearchVCManager](https://github.com/iOSModularization/AHFMSearchVCManager)  

搜索页面，先是会加载热门关键字。每次搜索都会缓存到数据库。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/searchPage.gif)  


### Category Page
1. [AHFMCategoryVC](https://github.com/iOSModularization/AHFMCategoryVC)  
2. [AHFMCategoryVCServices](https://github.com/iOSModularization/AHFMCategoryVCServices)  
3. [AHFMCategoryVCManager](https://github.com/iOSModularization/AHFMCategoryVCManager)  

主题分类页面，用UICollectionView和手势实现的一个自定义layout。

![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/category.gif)  

### Play History
1. [AHFMHistoryVC](https://github.com/iOSModularization/AHFMHistoryVC)  
2. [AHFMHistoryVCServices](https://github.com/iOSModularization/AHFMHistoryVCServices)  
3. [AHFMHistoryVCManager](https://github.com/iOSModularization/AHFMHistoryVCManager)  

播放历史页面会从本地数据库读取最近的15条播放历史。那么谁记录的这些历史呢？ 答案是[AHFMAudioPlayerManager](https://github.com/iOSModularization/AHFMAudioPlayerManager)记录的。它是和[AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)一起用的。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/history.gif)  


### User Center
1. [AHFMUserCenter](https://github.com/iOSModularization/AHFMUserCenter)  
2. [AHFMUserCenterServices](https://github.com/iOSModularization/AHFMUserCenterServices)  
3. [AHFMUserCenterManager](https://github.com/iOSModularization/AHFMUserCenterManager)  

用户中心页面只展示下载、播放历史和订阅页面。   
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/userCenter.gif)  

### Episode List
1. [AHFMEpisodeListVC](https://github.com/iOSModularization/AHFMEpisodeListVC)  
2. [AHFMEpisodeListVCServices](https://github.com/iOSModularization/AHFMEpisodeListVCServices)  
3. [AHFMEpisodeListVCManager](https://github.com/iOSModularization/AHFMEpisodeListVCManager)  

一个简单的音频清单页面。  
![](https://github.com/iOSModularization/AHFM/blob/master/demo_gifs/episodeList.gif) 


## 相关Frameworks
以下的8个frameworks，全部都只使用了iOS自带的库，没有使用任何第三方依赖。  
* [AHDataModel](https://github.com/ivsall2012/AHDataModel) for all persistence layers  
* [AHCategoryView](https://github.com/ivsall2012/AHCategoryView)  
* [AHBannerView](https://github.com/ivsall2012/AHBannerView)  
* [AHDownloadTool](https://github.com/ivsall2012/AHDownloadTool)  
* [AHDownloader](https://github.com/ivsall2012/AHDownloader)  
* [AHAudioPlayer](https://github.com/ivsall2012/AHAudioPlayer)  
* [AHFloatingTextView](https://github.com/ivsall2012/AHFloatingTextView)  
* [AHProgressSlider](https://github.com/ivsall2012/AHProgressSlider)  

## Author
童杰
ivsall@qq.com

## License

AHBannerView is available under the MIT license. See the LICENSE file for more info.



