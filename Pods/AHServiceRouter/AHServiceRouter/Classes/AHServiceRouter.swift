//
//  AHService.swift
//  Pods
//
//  Created by Andy Tong on 7/18/17.
//
//

import Foundation

public typealias AHServiceCompletion = (_ finished: Bool,_ userInfo: [String: Any]?) -> Void

/// If your task is needed to be done asynchronously, use the 'completion' to pass the results, otherwise return the results directly in the closure.
public typealias AHServiceWorker = (_ userInfo: [String: Any], _ completion: AHServiceCompletion?) -> [String: Any]?


public typealias AHServiceVCWorker = (_ userInfo: [String: Any]) -> UIViewController?


public enum AHServiceNavigationType{
    case present(currentVC: UIViewController)
    /// Will wrap a navVC to the target vc, presenting by this currentVC
    case presentWithNavVC(currentVC: UIViewController)
    case push(navVC: UINavigationController)
}

public protocol AHServiceRouterDelegate {
    /// Do NOT do navigation yourself! Just return the fallback VC.
    func fallbackVC(for service: String, task: String, userInfo: [String: Any]) -> UIViewController?
    
    /// If your task is needed to be done asynchronously, use the 'completion' to pass the results, otherwise return the results directly.
    func fallbackTask(for service: String, task: String, userInfo: [String: Any], completion: AHServiceCompletion?) -> [String: Any]?
}




private struct AHServer: CustomStringConvertible, Equatable {
    var service: String
    private var tasks = [String : AHTask]()
    
    init(service: String) {
        self.service = service
    }
    
    mutating func add(task: AHTask) {
        tasks[task.taskName] = task
    }
    func getTask(taskName: String) -> AHTask? {
        if let task = tasks[taskName] {
            return task
        }
        return nil
    }
    func taskExists(taskName: String) -> Bool {
        if let _ = tasks[taskName] {
            return true
        }
        return false
    }
    mutating func remove(taskName: String) {
        tasks.removeValue(forKey: taskName)
    }
    
    var description: String {
        let tasksString = tasks.flatMap({$0.key}).joined(separator: ",")
        return "service:\(service) tasks:{\(tasksString)}"
    }
    
    public static func ==(lhs: AHServer, rhs: AHServer) -> Bool {
        return lhs.service == rhs.service && lhs.tasks == rhs.tasks
    }
}

private enum AHServiceWorkerType {
    /// For non VC related, data processing
    case service(AHServiceWorker)
    
    /// For navigating VCs
    case navigateVC(AHServiceVCWorker)
}

private struct AHTask: CustomStringConvertible, Equatable {
    var taskName: String
    var workerType: AHServiceWorkerType
    var description: String {
        return "\(taskName)"
    }
    
    public static func ==(lhs: AHTask, rhs: AHTask) -> Bool {
        return lhs.taskName == rhs.taskName
    }
}

public final class AHServiceRouter {
    /// Your delegate is kept strongly here!!!
    public static var delegate: AHServiceRouterDelegate?
    
    // ['serviceName': AHServer]
    fileprivate static var services = [String : AHServer]()
    
    
    /// If your task is needed to be done asynchronously, use the 'completion' to pass the results, otherwise return the results directly in the closure.
    /// AHServiceRouter does not keep the provided object or does any modification.
    /// - Parameters:
    ///   - service: The service name. This should be unique globally.
    ///   - taskName: The name of the task. This should be unique under the service.
    ///   - worker: A closure callback that provides more info for the service provider to process later when the service is being used.
    public static func registerTask(_ service: String, taskName: String, worker: @escaping AHServiceWorker) {
        
        let task = AHTask(taskName: taskName, workerType: AHServiceWorkerType.service(worker))
        register(service: service, task: task)
    }
    

    /// Use this method to provide services/tasks for navigating VCs.
    /// - Parameters:
    ///   - service: The service name. This should be unique globally.
    ///   - taskName: The name of the task. This should be unique under the service.
    ///   - worker: A closure callback that notify the provider later to give a VC to present or push.
    public static func registerVC(_ service: String, taskName: String, worker: @escaping AHServiceVCWorker) {
        
        let task = AHTask(taskName: taskName, workerType: AHServiceWorkerType.navigateVC(worker))
        register(service: service, task: task)
        
        
    }
    
    private static func register(service: String, task: AHTask) {
        if var server = services[service]{
            // check duplicate
            if server.taskExists(taskName: task.taskName) {
                assert(false,"\(service).\(task.taskName) is already register.")
                return
            }
            server.add(task: task)
            services[service] = server
        }else{
            var server = AHServer(service: service)
            server.add(task: task)
            services[service] = server
        }
    }
    
    
    /// Do a regular task, NOT a navigationVC task!!
    @discardableResult
    public static func doTask(_ service: String, taskName: String, userInfo: [String: Any], completion: AHServiceCompletion?) -> [String: Any]? {

        guard let server = services[service] else {
            print("AHService: service:\(service) not registered")
            return self.delegate?.fallbackTask(for: service, task: taskName, userInfo: userInfo, completion: completion)
        }
        
        guard let task = server.getTask(taskName: taskName) else {
            print("AHService: \(service).\(taskName) not found")
            return self.delegate?.fallbackTask(for: service, task: taskName, userInfo: userInfo, completion: completion)
        }
        
        guard case let AHServiceWorkerType.service(worker) = task.workerType else {
            assert(false, "Your task might be a 'navigateVC' task??")
            return nil
        }
        
        return worker(userInfo, completion)
        
    }
    
    /// The completion closure here is called after completing the navgation by the router. It's not related to the service provider!
    public static func navigateVC(_ service: String, taskName: String, userInfo: [String: Any], type: AHServiceNavigationType, completion: AHServiceCompletion?) {
        
        guard let server = services[service] else {
            print("AHService: service:\(service) not registered")
            if let vc = self.delegate?.fallbackVC(for: service, task: taskName, userInfo: userInfo) {
                self.navigateVC(vc, type, completion)
                completion?(true, nil)
            }
            return
        }
        
        guard let task = server.getTask(taskName: taskName) else {
            print("AHService: \(service).\(taskName) not found")
            if let vc = self.delegate?.fallbackVC(for: service, task: taskName, userInfo: userInfo) {
                self.navigateVC(vc, type, completion)
                completion?(true, nil)
            }
            return
        }
        
        guard case let AHServiceWorkerType.navigateVC(worker) = task.workerType else {
            assert(false, "Your task might be a normal task not a navigationVC task??")
            return
        }
        
        
        if let vc = worker(userInfo) {
            self.navigateVC(vc, type, completion)
        }else{
            completion?(false, nil)
        }
        
        
    }
    
    private static func navigateVC(_ vc: UIViewController, _ type: AHServiceNavigationType, _ completion: AHServiceCompletion?) {
        switch type {
        case let .present(currentVC):
            currentVC.present(vc, animated: true, completion: nil)
        case let .presentWithNavVC(currentVC):
            let navVC = UINavigationController(rootViewController: vc)
            currentVC.present(navVC, animated: true, completion: nil)
        case let .push(navVC):
            pushVC(targetVC: vc, navVC: navVC)
        }
        completion?(true, nil)
    }
    
    
    /// Reuse a VC from a navigationVC, default is the first navigationVC under the application's rootVC, or just the rootVC if it is a navigationVC already.
    public static func reuseVC(navigationVC: UINavigationController? = nil,_ shouldBeReused: (_ currentVC: UIViewController) -> Bool) -> UIViewController? {
        

        if navigationVC == nil {
            guard let delegate = UIApplication.shared.delegate,
                let window = delegate.window,
                let rootVC = window?.rootViewController as? UINavigationController else {
                    assert(false, "application delegate or window is nil???")
                    return nil
            }
            var firstNavVC: UINavigationController?
            firstNavVC = rootVC.isKind(of: UINavigationController.self) ? rootVC : nil
            
            if firstNavVC == nil {
                for vc in rootVC.viewControllers {
                    if vc.isKind(of: UINavigationController.self) {
                        firstNavVC = vc as? UINavigationController
                        break
                    }
                }
            }
            
            guard let navVC = firstNavVC else {
                return nil
            }
            
            let reversedVCs = navVC.viewControllers.reversed()
            var newVC: UIViewController?
            for vc in reversedVCs {
                if shouldBeReused(vc) {
                    newVC = vc
                    break
                }
            }
            
            
            return newVC
            
        }else{
            let reversedVCs = navigationVC!.viewControllers.reversed()
            var newVC: UIViewController?
            for vc in reversedVCs {
                if shouldBeReused(vc) {
                    newVC = vc
                    break
                }
            }
            
            
            return newVC
        }
        
        
        
    }

    
    private static func pushVC(targetVC: UIViewController, navVC: UINavigationController) {
        // there's this vc in the stack already, then pop to it
        var newVC: UIViewController?
        for childVC in navVC.viewControllers {
            if childVC === targetVC {
                newVC = childVC
                break
            }
        }
        
        if newVC == nil {
            navVC.pushViewController(targetVC, animated: true)
        }else{
            navVC.popToViewController(newVC!, animated: true)
        }
    }
    
    public static func allServices() -> [String] {
        let servers = services.values
        return servers.flatMap({$0.description})
        
    }
    
    public static func remove(service: String) {
        services.removeValue(forKey: service)
    }
}
