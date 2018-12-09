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
    private var storeBackgroundTask:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // MARK: Public
    
    /// LogManager level
    public var level:LogLevel = .debug {
        didSet { didSetLevel() }
    }
    
    /// Callback used to notify a log event. This callback is called on ANY log event from ANY LogManager.
    public var didLog: DidLogCallback?
    
    /// Log manager drivers
    public var drivers: [LogDriver] = [] {
        didSet { didSetDrivers() }
    }
    
    /// First driver from drivers array
    public var mainDriver: LogDriver? {
        return drivers.first
    }
    
    /// Share instance. Used by log global function
    public static var shared: LogManager = {
        let drivers:[LogDriver?] = [SqlLogDriver(), ConsoleLogDriver()]
        return LogManager(drivers: drivers.flatMap{ $0 })
    }()
    
    /// Default initializer
    public init(drivers: [LogDriver]) {
        self.drivers = drivers
        didSetDrivers()
        
        
        // Configure observers
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(onLogNotification(notification:)),
                         name: Notification.Name.LogManagerDidLog,
                         object: nil)
    }
    
    /// Get log history from the main Driver
    public func filter(level levelOrNil:LogLevel? = nil, text textOrNil:String? = nil, offset:Int = 0, completion: @escaping (([LogEntry]?) -> Void)) {
        self.mainDriver?.filter(level: levelOrNil, text: textOrNil, offset: offset, completion: completion)
    }
    
    /// Log
    public func log(file: String = #file, line: UInt = #line, function: String = #function, level: LogLevel = .debug, message: String) {
        let fileName = file.components(separatedBy: "/").last?
                           .components(separatedBy: ".").first ?? ""
        
        let entry = LogEntry(createdAt: nil, order: nil, stored: nil, level: level, file: fileName, line: line, function: function, message: message)
        
        for driver in drivers {
            driver.log(entry: entry)
        }
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
        if storeBackgroundTask != UIBackgroundTaskInvalid { return }
        storeBackgroundTask = application.beginBackgroundTask(withName: "iLogStoreLogs") {
            application.endBackgroundTask(self.storeBackgroundTask)
        }
        
        mainDriver?.store{ [unowned self] (entries, callback) in
            handler(entries) { success in
                callback(success)
                if self.storeBackgroundTask != UIBackgroundTaskInvalid {
                    application.endBackgroundTask(self.storeBackgroundTask)
                }
            }
        }
    }
    
    /// Clear all drivers
    public func clear() {
        for driver in drivers {
            driver.clear()
        }
    }
    
    // MARK: Private
    private func didSetDrivers() {
        if let driver = self.mainDriver {
            driver.didLog = {[weak self] entry in
                self?.postDidLogNotification(entry: entry)
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
    @objc fileprivate func onLogNotification(notification: Notification) {
        guard let entry = notification.object as? LogEntry else { return }
        self.didLog?(entry)
    }
    
    fileprivate func postDidLogNotification(entry: LogEntry) {
        NotificationCenter.default.post(name: Notification.Name.LogManagerDidLog, object: entry)
    }
}
