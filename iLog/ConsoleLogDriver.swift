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
    df.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    return df
}

public class ConsoleLogDriver: LogDriver {
    public var level: LogLevel = .debug
    public var didLog: DidLogCallback?
    public var logString:(LogEntry) -> String = { entry in
        let dateFormatter:DateFormatter = defaultDateFormatter()
        return "\(dateFormatter.string(from: entry.createdAt)) [\(entry.level.stringValue)] \(entry.file):\(entry.function):\(entry.line) \(entry.message)"
    }
    
    public init?(level: LogLevel = .debug) {
        self.level = level
    }
    
    public func log(entry: LogEntry) {
        guard entry.level.rawValue >= level.rawValue else { return }
        
        print(logString(entry))
        didLog?(entry)
    }
    
    public func all(level levelOrNil: LogLevel?, offset: Int) -> [LogEntry]? {
        return nil
    }
    
    public func store(_ handler: ([LogEntry], (Bool) -> Void) -> Void) {
        
    }
}
