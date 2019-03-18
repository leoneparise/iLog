//
//  ConsoleLogDriver.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import Foundation

fileprivate func defaultDateFormatter() -> DateFormatter {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return df
}

/// Default console output stream
public struct ConsoleOutputStream: TextOutputStream {
    public init() {
        
    }
    
    mutating public func write(_ string: String) {
        print(string, terminator: "")
    }
}

/// Default console log driver
public class PrintLogDriver<Target : TextOutputStream>: LogDriver {
    public var level: LogLevel = .debug
    public var didLog: DidLogCallback?
    private(set) var output: Target
    
    /// Entry format function
    public var logString:(LogEntry) -> String = { entry in
        let dateFormatter:DateFormatter = defaultDateFormatter()
        return "\(dateFormatter.string(from: entry.createdAt)) [\(entry.level.stringValue)] \(entry.file):\(entry.function):\(entry.line) \(entry.message)"
    }
    
    /// Default initializer
    public init?(level: LogLevel = .debug, output: Target) {
        self.level = level
        self.output = output
    }
    
    public func log(entry: LogEntry) {
        guard entry.level.rawValue >= level.rawValue else { return }
        
        print(logString(entry), to: &output)
        
        DispatchQueue.main.async { [weak self] in
            self?.didLog?(entry)
        }
    }
    
    public func filter(level levelOrNil:LogLevel? = nil, text textOrNil:String? = nil, offset:Int = 0, completion: @escaping (([LogEntry]?) -> Void)) {
        return completion(nil)
    }
    
    /// Not supported
    public func store(_ handler: StoreHandler) throws {
        throw iLogError.notSupported
    }
    
    /// Not supported
    public func clear() {
        
    }
}
