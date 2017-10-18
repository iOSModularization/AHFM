# AHServiceRouter
A lightweight non-invasive router for doing tasks and navigating VCs, plus a recylcing feature.


## Content
- [Overview](#overview)
	- [Navigation](#navigation)
	- [Do Tasks](#do-tasks)
	- [Fallback Delegate](#fallback-delegate)
	- [A Few Words About Routing](#a-few-words-about-routing)
	  - [No URL Scheme Interpreter](#no-url-scheme-interpreter)
- [Examples](#examples)
	- [Recycle View Controller](#recycle-view-controller)
    - [Scenario When Infinite Navigations Occur](#scenario-when-infinite-navigations-occur)
	  - [Put Them In Codes](#put-them-in-codes)
		  - [Partial Recycling](#partial-recycling)
		  - [Complete Recycling](#complete-recycling)
	- [Login System](#login-system)
- [Installation](#installation)

## Overview
AHServiceRouter is basically consist of two parts: navigating VCs and doing tasks.  
The way to distinguish different navigation requests and tasks is use a service and a task.  
A 'service name' represents a namespace, or a category, and a 'task name' represents a specific task. 
One service can have mutiple tasks as long as those tasks' names are unique.  
Of course, the service name should be unique too globally.  


### Navigation
Two steps:  
1. registerVC(for the service provider)  
2. navigateVC(for the service user)  
```Swift
/// We define an independent struct here as a key manager, it's not necessary but recommended. 
struct SettingPageService {
    static let service = "SettingPageService"
    static let taskNavigateToVC = "taskNavigateToVC"
    static let taskCreateVC = "taskCreateVC"

    static let keyGetVC = "keyGetVC"
    
    /// You must include a value for this key!
    static let keyShouldRefresh = "keyShouldRefresh"
}

/// This should be somewhere in your delegate object or a manager, NOT a view controller!!
/// Use registerVC to register anything related to navigation as well as presentation.
/// We register with the key 'taskNavigateToVC'.
/// Parameter 'userInfo' is a [String: Any] passed by the service user when they use the 'navigateVC' method.
AHServiceRouter.registerVC(SettingPageService.service, taskName: SettingPageService.taskNavigateToVC) { (userInfo) -> UIViewController? in
    /// We first check if the userInfo includes the key, if not, we return nil, assuming the value of 'keyShouldRefresh' is something that SettingPage must need to operate, otherwise it can't be used.
    guard let shouldRefresh = userInfo[SettingPageService.keyShouldRefresh] as? Bool else{
        return nil
    }
    let vc = SettingPage()
    vc.shouldRefresh = shouldRefresh
    return vc
}


/// For service users
import AHServiceRouter
import SettingPageService

/// Let's pretend we are in the mainPage now:)
/// And the following class is mainPageVC's delegate object.
/// NOTE: we use a class here, it could be a struct as well. 
/// But class is the preferred choice for VC delegates.  
class MainPageDelegateObject: MainPageDelegate {
	func mainPageDidTapSettingButton(_ vc: MainPage) {
		guard let navVC = vc.navigationController else {
            return
    }
    /// The completion closure here is called after completing the navgation by the router. It's not related to the service provider!
    AHServiceRouter.navigateVC(SettingPageService.service, taskName: SettingPageService.taskNavigateToVC, userInfo: [SettingPageService.keyShouldRefresh: true], type: .push(navVC: navVC), completion: nil)
	}
}

```
As you can see, the userInfo parameter can be used to pass values from the user to the service provider.  
In this case, it's the 'true' value for the key 'keyShouldRefresh'.  

There are three navigation types:
```Swift
public enum AHServiceNavigationType{
    case present(currentVC: UIViewController)
    /// Will wrap a navVC to the target vc, presenting by currentVC
    case presentWithNavVC(currentVC: UIViewController)
    case push(navVC: UINavigationController)
}

/// You can do this if you support both presenting and navigating
var type: AHServiceNavigationType
if vc.navigationController != nil {
	type = .push(navVC: vc.navigationController!)
}else{
	type = .present(currentVC: vc)
}


```
You as a service provider, should always document what kinds of navigation types you support by providing a key, such as 'taskNavigateToVC' or 'taskPresentVC'(though should use 'registerVC' method to register and use 'navigateVC' method to present).  
Because navigating to a VC and presenting a VC require different UI settings sometimes.


### Do Tasks
Let's create a VC by using a task, instead of using the built-in navigateVC method to navigate.
```Swift
/// Register first!
/// We register with the key 'taskCreateVC' this time.
/// Parameter 'completon' is an optional completion closure from the user in order to notify them when you finish, along with a flag and a dict. 'completion?(Bool, [String: Any])'.
/// If your task is needed to be done asynchronously, use the 'completion' to pass the results when finish, otherwise return the results directly.
/// In this case, we return the newly created vc directly in a [String : Any] -- the difference part from 'registerVC'.
AHServiceRouter.registerTask(SettingPageService.service, taskName: SettingPageService.taskCreateVC) { (userInfo, completion) -> [String : Any]? in
    guard let shouldRefresh = userInfo[SettingPageService.keyShouldRefresh] as? Bool else{
        completion?(false, nil)
        return nil
    }
    
    let vc = SettingPage()
    vc.shouldRefresh = shouldRefresh
    completion(true, nil)
    return [SettingPageService.keyGetVC: vc]
}


/// Now we use it
/// This method is in mainPage's delegate object
func mainPageGetSettingController(_ vc: MainPage) -> UIViewController? {
  /// use the return data from the 'doTask' method. The data is '[SettingPageService.keyGetVC: vc]' shown in above code snippet.
	guard let data = AHServiceRouter.doTask(SettingPageService.service, taskName: SettingPageService.taskCreateVC, userInfo: [SettingPageService.keyShouldRefresh: false], completion: nil) else {
    return
	}
	guard let vc = data[SettingPageService.keyGetVC] as? UIViewController else {
    return
	}
	return vc
}

/// In mainPage VC
func settingButtonDidTap(_ sender: UIButton) {
	guard let settingVC = self.delegate?.mainPageGetSettingController(self) else{
		return
	}
	/// You can ask the SettingPage guy to register a service/task to provide additional data for the animation, if you can't handle the animation yourself within your MainPage module.
	  vc.transitioningDelegate = someAnimator
    vc.modalPresentationStyle = .custom
    self.present(vc, animated: true, completion: nil)
}

```
This is AHServiceRouter way of doing transition animation -- all we're doing here is for isolating UI layer from your bussiness logics -- for the greater good of maintainability and scalability!
As all we know, it's hard to reuse bussiness logics but it's possible to reuse UI logics and components.
So if you structure your application this way -- the MVCs only do the UI stuff and they will ask their delegates for extra informations.
Then your UI logics can be reused for sure. More importantly, it's a super weak coupling here to the bussiness logics. 


### Fallback Delegate
Two delegate methods.
It's basically the same as register a service/task, but only called when AHServiceRouter couldn't find a service or a task.
```Swift
public protocol AHServiceRouterDelegate {
    /// Do NOT do navigation yourself! Just return the fallback VC.
    func fallbackVC(for service: String, task: String, userInfo: [String: Any]) -> UIViewController?
    
    /// If your task is needed to be done asynchronously, use the 'completion' to pass the results when finish, otherwise return the results directly.
    func fallbackTask(for service: String, task: String, userInfo: [String: Any], completion: AHServiceCompletion?) -> [String: Any]?
}
```
NOTE: AHServiceCompletion is a typealias for '(_ finished: Bool,_ userInfo: [String: Any]?) -> Void'



### A Few Words About Routing
AHServiceRouter should to be used as a basic routing system that glues all independent modules and services together to become a maintainable, scalable iOS applicaton.  
You should NEVER EVER put routing logics into a view controller or even the whole UI layer in your application.  
You should always delegate those routing logics to another object or manager or another layer.  

#### No URL Scheme Interpreter
You might ask, what about URL schemes like other routers provide?  
AHServiceRouter doesn't provide any URL scheme related functionality.  
You should come out your own URL scheme interpreter module.
For example, you can use 'Inter-app' as a service name and 'OAuth' as a task name.
Every time your app is being called by some other app for OAuth login, you first ask your URL scheme interpreter to break down the URL into a service name and a task name, then use AHServiceRouter.  
So the responsibility for how to define your URL scheme is on you.
The only thing AHServiceRouter has, are a service name and a task name!

BTW, the "module" here is meant to be Cocoapod's pod modules using "pod lib create <ModuleName>".  
For more info about pods, checkout ![Using Pod Lib Create](https://guides.cocoapods.org/making/using-pod-lib-create.html)


## Examples

### Recycle View Controller
NOTE: You can skip the following product design related section, and go straight to the codes to learn recycling view controllers.

#### Scenario When Infinite Navigations Occur
Let's assume we have a navigation stack as following:
"mainPage -> showPage -> audioPlayer -> showPage -> showPage -> audioPlayer"

And the each 'showPage' has a 'recommended shows' section.
Then basically, this navigation stack could go infinitely.

The solution for preventing this kind of infinite navigations is to reuse some of the VCs strategically.  
Q: Why don't we put a 'close' button right after the back button '<' on the top left corner of the navigation bar, to pop to the root view controller?
A: Yes we can!

So the strategy is:  
we partially reuse 'showPage' when the next show is already shown in the stack, we pop to that 'showPage', instead of keeping pushing(creating) 'showPage' VCs. 
The reasons are 1) we don't fully reuse it. Because if the current VC is 'showPage', and you want to checkout another recommended show from here, then the 'recommended showPage' should be pushed into the stack, instead of reusing current 'showPage'. 2) Popping to the already shown 'showPage' only when there's one, reminds the user "oh I just checked this show before" and it also shorten the stack if not completely.

And we reuse the audioPlayer completely.
The reason is that 'audioPlayer' acts like a destination in an audio app after a long searching and scrolling in the 'recommended shows' section.

#### Put Them In Codes
Core method:
```Swift
/// If you pass a navVC then AHServiceRouter will iterate its childViewControllers and ask you if the childViewController is the one you wnat to reuse(or recycle). 
/// If you don't pass a navVC or pass a nil, AHServiceRouter will find the first UINavigationController under the keyWindow then iterate through its childViewControllers.
static func reuseVC(navigationVC: UINavigationController? = nil,_ shouldBeReused: (_ currentVC: UIViewController) -> Bool) -> UIViewController?
```

##### Partial Recycling

The following is for recycling a 'showPage' with the same showId.
```Swift
/// Recycling policy is only defined in the service provider side when registering. The service user doesn't know anything about recycling a viewController.
AHServiceRouter.registerVC(ShowPageServices.service, taskName: ShowPageServices.taskNavigation) { (userInfo) -> UIViewController? in
	/// Check if the user includes a showId which will be used in the 'reuseVC' method
    guard let showId = userInfo[AHFMShowPageServices.keyShowId] as? Int else {
        print("You must pass a showId into userInfo")
        return nil
    }
    
    /// Here we don't pass a navVC into 'reuseVC' method.
    /// So the default navVC is used and the method will iterate through the navVC's childViewControllers.
    /// The default navVC is the first UINavigationController under the keyWindow.
    var vc: ShowPage? = AHServiceRouter.reuseVC({ (vc) -> Bool in
    	/// Check if the vc is the same kind
        guard vc.isKind(of: ShowPage.self), let showPage = vc as! ShowPage else {
            return false
        }
        /// Returning true tells the method this is the one we want to reuse.
        return showPage.showId == showId
    })
    
    if vc == nil {
    	/// There's no reusable 'showPage' in the stack
        vc = ShowPage()
    }
    /// do the assigning showId again just in case there's a 'didSet' listener in the 'showPage' VC.
    vc?.showId = showId
    return vc
}

```

#### Complete Recycling
The following is for recycling an 'audioPlayer' if there's one already in the stack.
```Swift
AHServiceRouter.registerVC(AudioPlayerVCServices.service, taskName: AudioPlayerVCServices.taskNavigation) { (userInfo) -> UIViewController? in
    guard let trackId = userInfo[AudioPlayerVCServices.keyTrackId] as? Int else {
        return nil
    }
    
    var vc: AudioPlayerVC? = AHServiceRouter.reuseVC({ (vc) -> Bool in
    	/// Check if the vc is the same kind, if it is, return true, no further checking needed.
        if vc.isKind(of: AudioPlayerVC.self) else {
            return true
        }else{
        	return false
        }
    })
    
    if vc == nil {
        vc = AudioPlayerVC()
    }

    vc?.trackId = trackId
    
    return vc
}
```


### Login System
Suppose we have pageA, pageB.  
And pageA will only route to pageB if the user is loged in.  
If not loged in, present loginVC first.
When the user finishes logging in, pageA has some data needed to pass to pageB  
If the user is logged in already, pageA can just route to pageB directly with a userInfo.

The difficult part of this problem is that pageA doesn't when the user will finish loggin in, since login is related to networking.

The key of solving this problem is to pass loginVC a completion closure then later loginVC will invoke it when finish.
Note: You have to document your service structs so that your teammates know how to use it.
```Swift
/// Define services and classes

struct PageBServices{
	static let service = "\(Self.self)"
	static let taskNavigateToVC = "taskNavigateToVC"
	/// Int
	static let keyOrderNumber = "keyOrderNumber"
	/// Double
	static let keyPrice = "keyPrice"
}

class PageB: UIViewController {
	var orderNumber:Int?
	var price: Double?
}

struct LoginVCServices{
	static let service = "\(Self.self)"

	/// use .presentWithNavVC to present
	static let taskPresentVC = "taskPresentVC"

	/// the value should be a closure of form '(_ succeeded: Bool)->Void'
	/// this key-value is optional!
	static let keyCompletionClosure = "keyCompletionClosure"
}

class LoginVC: UIViewController {
	var completion: ((_ succeeded: Bool)->Void)?
	
	func dismissButtonTapped(_ sender: UIButton) {
		/// invoke the completion closure when dismiss, with a failed login status
		completion?(false)
	}

	/// Called when finish authentication
	func handleClosure(_ isSucceeded: Bool) {
		completion?(isSucceeded)
	}
}

/// Register first!!

/// Register PageBServices
AHServiceRouter.registerVC(PageBServices.service, taskName: PageBServices.taskNavigation) { (userInfo) -> UIViewController? in
  guard let orderNumber = userInfo[PageBServices.keyOrderNumber] as? Int,
		let price = userInfo[PageBServices.keyPrice] as? Double else {
    return nil
  }
  let vc = PageB()
  vc.orderNumber = orderNumber
  vc.price = price
  return vc
}

/// Register LoginVCServices
AHServiceRouter.registerVC(LoginVCServices.service, taskName: LoginVCServices.taskNavigation) { (userInfo) -> UIViewController? in

	let vc = LoginVC()
	/// the completion closure is optional parameter.
  if let comletion = userInfo[LoginVCServices.keyCompletionClosure] as? ((_ succeeded: Bool)->Void) else {
  	vc.comletion = comletion
  }
    
  return vc
}



/// Now let's pretend we are in pageA's delegate class.

import AHServiceRouter
import PageBServices
/// You have to import the actual module, not just the service module.
import PageB
import LoginVCServices
/// You have to import the actual module, not just the service module.
import LoginVC

class PageADelegateObject: NSObject, PageADelegate {
	func comfirmButtonDidTap(_ vc: PageB, orderNumber: Int, price: Double) {
		guard let navVC = vc.navigationController else {return}

		if checkLogin() {
			/// route to pageB directly with a infoDict required by its services.
			navigateToPageB(orderNumber, price)
		}else{
			/// user not loggd in !!!
			let completion: (_ succeeded: Bool)->Void = { (succeeded) in
				if succeeded {
					self.navigateToPageB(orderNumber, price)
				}else{
					// error handling here, it might be a network error
				}
			}

			let closureDict = [LoginVCServices.keyCompletionClosure: completion]
			AHServiceRouter.navigateVC(LoginVCServices.service, taskName: LoginVCServices.taskPresentVC, userInfo: closureDict, type: .presentWithNavVC(currentVC: vc), completion: nil)
		}
	}

	func navigateToPageB(_ orderNumber: Int, _ price: Double) {
		/// Make sure the infoDict has the correct info for routing to pageB
		let infoDict = [PageBServices.keyOrderNumber: orderNumber, PageBServices.keyPrice: price]
		AHServiceRouter.navigateVC(PageBServices.service, taskName: PageBServices.taskNavigateToVC, userInfo: infoDict, type: .push(navVC: navVC), completion: nil)
	}

	func checkLogin() -> Bool {
		/// .... logics to decide if the current user is logged in or not .... it could be another service provided by the LoginVCServices.
	}
}
```

Q: There's a completion in 'registerTask'. Could this completion be used when registering the LoginVC??
```Swift
/// Register this way
AHServiceRouter.registerTask(LoginVCServices.service, taskName: LoginVCServices.taskCreateVC) { (userInfo, completion) -> [String : Any]? in
	let vc = LoginVC()
	/// instead of invoking the comletion here, assigning it to the vc.
	vc.completion = completion
	/// You need to return a dict when regisgter tasks!
	return [LoginVCServices.keyGetVC: vc]
}

/// Use it
func navigateToPageB(_ pageA: PageA) {
	let completionClosure: ((_ succeeded: Bool, info: [String : Any]?)) = { (succeeded,info) in
		if succeeded {
			// navigate to pageB here
		}
	}
	/// pass 'completionClosure' to 'doTask' method
	guard let data = AHServiceRouter.doTask(LoginVCServices.service, taskName: LoginVCServices.taskCreateVC, userInfo: [:], completion: completionClosure) else {
    return
	}
	guard let vc = data[LoginVCServices.keyGetVC] as? UIViewController else {
    return
	}
	
	// present vc here
}

```
A: YES, You got it! You have to document it and let people know that when that completion is called.  
When you have a asynchronous task and you can't return the result immediately, you can keep the completion and invoke it later.
But when you can make things clear, which appearently it's the first way, then make them clear!

## Example Project
The example project is empty. 

## Installation

AHServiceRouter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AHServiceRouter"
```

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHServiceRouter is available under the MIT license. See the LICENSE file for more info.
