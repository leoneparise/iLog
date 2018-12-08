//
//  LogDriver.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import Foundation

/// Callback used to notify that a log was send
public typealias DidLogCallback = ((LogEntry) -> Void)

/// Callback used to know if the store was completed
public typealias StoredLogCallback = ((Bool) -> Void)

/// Store handler
public typealias StoreHandler = (([LogEntry], StoredLogCallback) -> Void)

public protocol LogDriver:class {
    /// Function called when a log is send by this driver
    var didLog: DidLogCallback? { get set }
    
    /// Minimum level to log **debug < info < warn < error**
    var level:LogLevel { get set }
    
    /**
     Logs a LogEntry. This is the main function of this driver
     
     - parameter entry: log entry
     */
    func log(entry:LogEntry)
    
    /**
     Get all logs stored by this driver. **Some drivers doesn't offer log history** (eg: ConsoleLogDriver) returning `nil`.
     
     - parameter level: log level to filter
     - parameter offset: offset to the history
     - returns: Array of `LogEntry` if history is supported or `nil` otherwise
     */
    func all(level levelOrNil:LogLevel?, offset:Int, completion: @escaping (([LogEntry]?) -> Void))
    
    /**
     Store logs in another service. The handler function must call the callback to tell this driver 
     the the storing was completed with success. The driver must handle what should be stored or not.
     
     **Some drivers doesn't suppor store (eg: ConsoleLogDriver)**
     
     - parameter: handler Store function handler
     */
    func store(_ handler: StoreHandler)
    
    /// Clear logs. **Some drivers doesn't support clear**
    func clear()
}
