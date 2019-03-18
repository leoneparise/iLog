//
//  Logger.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import Foundation
import UIKit

/**
 Global log function. You should provide only `level` and `message` parameters. Leave the rest with it's default values
 
 - parameter file: file where this log was fired.
 - parameter line: line where this log was fired.
 - parameter function: function where this log was fired.
 - parameter level: this log level
 - parameter message: this log message
 */
public func log(file:String = #file, line:UInt = #line, function:String = #function, _ level:LogLevel, _ message:String) {
    LogManager.shared.log(file: file, line: line, function: function, level: level, message: message)
}

public extension Notification.Name {
    /// Fired when any manager's `log` method is called
    public static let LogManagerDidLog = Notification.Name("LogManagerDidLog")
}

/// Manager
public class LogManager {
    private var storeBackgroundTask:UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    private let loggingQueue = DispatchQueue(label: "loggingQueue", qos: .background)
    private let queryQueue = DispatchQueue(label: "queryQueue", qos: .background)
    private static var sharedInstance: LogManager!
    
    // MARK: Public
    
    /// LogManager level
    public var level:LogLevel = .debug {
        didSet { didSetLevel() }
    }
    
    /// Log manager drivers
    public var drivers: [LogDriver] = []
    
    /// First driver from drivers array
    public var mainDriver: LogDriver? {
        return drivers.first
    }
    
    /// Share instance. Used by log global function
    public static var shared: LogManager {
        assert(sharedInstance != nil, "Please, call setup method before using iLog")      
        return sharedInstance
    }
    
    public static func setup(_ drivers: LogDriver...) {
        sharedInstance = LogManager(drivers: drivers)
    }
    
    /// Default initializer
    public init(drivers: [LogDriver]) {
        self.drivers = drivers        
    }
    
    /// Get log history from the main Driver
    public func filter(level levelOrNil:LogLevel? = nil, text textOrNil:String? = nil, offset:Int = 0, completion: @escaping (([LogEntry]?) -> Void)) {
        queryQueue.async { [weak self] in
            self?.mainDriver?.filter(level: levelOrNil, text: textOrNil, offset: offset, completion: completion)
        }
    }
    
    /// Log
    public func log(file: String = #file, line: UInt = #line, function: String = #function, level: LogLevel = .debug, message: String) {
        let fileName = file.components(separatedBy: "/").last?
                           .components(separatedBy: ".").first ?? ""
        
        let entry = LogEntry(createdAt: nil, order: nil, stored: nil, level: level, file: fileName, line: line, function: function, message: message)
        
        loggingQueue.async { [weak self] in
            guard let wself = self else { return }            
            for driver in wself.drivers {
                driver.log(entry: entry)
            }
        }
        
        postDidLogNotification(entry: entry)
    }
    
    /**
     Store your log entries in a backend service. This method should be callend when you application
     is going to background state. It automatially starts a background task, call your save handler,
     saves the changes in the database and finish the background task.
     
     **In uses only the mainDriver.**
     
     - parameter: appliction UIAppliction instance
     - handler: Store handler.
     */
    public func storeLogsInBackground(application: UIApplication, handler: @escaping StoreHandler) {
        // If there is a background task running, doesn't run again
        if storeBackgroundTask != UIBackgroundTaskIdentifier.invalid { return }
        
        storeBackgroundTask = application.beginBackgroundTask { [unowned self] in
            application.endBackgroundTask(self.storeBackgroundTask) // End background task after 180 seconds
        }
        
        do {
            try mainDriver?.store{ [unowned self] (entries, complete) in
                try handler(entries) { success in
                    try complete(success)                    
                    if self.storeBackgroundTask != UIBackgroundTaskIdentifier.invalid {
                        application.endBackgroundTask(self.storeBackgroundTask) // End background task after save
                    }
                }
            }
        } catch {
            if self.storeBackgroundTask != UIBackgroundTaskIdentifier.invalid {
                application.endBackgroundTask(self.storeBackgroundTask) // End background task if there is an error
            }
        }
    }
    
    /// Clear all drivers
    public func clear() {
        loggingQueue.async { [weak self] in
            guard let wself = self else { return }
            for driver in wself.drivers {
                driver.clear()
            }
        }
    }
    
    private func didSetLevel() {
        for driver in drivers {
            driver.level = self.level
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification
extension LogManager {
    fileprivate func postDidLogNotification(entry: LogEntry) {
        NotificationCenter.default.post(name: Notification.Name.LogManagerDidLog, object: entry)
    }
}
