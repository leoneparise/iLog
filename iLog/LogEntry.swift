//
//  LogEntry.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import Foundation

// MARK: - Global Counter
fileprivate var counter: Int64 = 0
fileprivate func next() -> Int64 {
    counter = counter + 1
    return counter
}

// MARK: - Model

/// Log level
public enum LogLevel: Int64 {
    case debug = 0, info = 10, warn = 20, error = 30
    
    var stringValue:String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warn: return "warn"
        case .error: return "error"
        }
    }
}

/* 
 Represents a log into iLog. This struct can be stored, transmited to an external service of printed
 on console.
 */
open class LogEntry {
    /// Log level
    public let level: LogLevel
    /// Log message
    public let message: String
    /// File that logged this entry
    public let file: String
    /// Line in the file that logged this entry
    public let line: UInt
    /// Function in the file that logged this entry
    public let function: String
    /// When this log was created
    public let createdAt: Date
    /// Log order. This information is used only when we have two logs at the same time.
    public let order:Int64
    /// Check if this log was stored in a external service or not
    public let stored:Bool
    
    /// Default initializer
    public init(createdAt: Date?, order:Int64?, stored:Bool?, level:LogLevel, file:String, line:UInt, function:String, message:String) {
        self.level = level
        self.message = message
        self.file = file
        self.line = line
        self.function = function
        self.createdAt = createdAt ?? Date()
        self.order = order != nil ? order! : next()
        self.stored = stored ?? false
    }
    
    /**
     Get the JSON structure of this log. **Can be overriden**
     
     - returns: JSON Dictionary of this log entry
    */
    open func toJson() -> [AnyHashable : Any] {
        return [
            "level": self.level.stringValue,
            "createdAt": self.createdAt,
            "order": self.order,
            "file": self.file,
            "line": self.line,
            "function": self.function,
            "message": self.message
        ]
    }
}

// MARK: - Equatable
extension LogEntry: Equatable { }
public func == (left:LogEntry, right:LogEntry) -> Bool {
    return left.createdAt == right.createdAt && left.order == right.order
}

// MARK: - Comparable
extension LogEntry: Comparable { }
public func < (left:LogEntry, right:LogEntry) -> Bool {
    return (left.createdAt < right.createdAt) ||
           (left.createdAt == right.createdAt && left.order < right.order)
    
}

public func <= (left:LogEntry, right:LogEntry) -> Bool {
    return (left.createdAt < right.createdAt) ||
           (left.createdAt == right.createdAt && left.order <= right.order)
}

public func > (left:LogEntry, right:LogEntry) -> Bool {
    return (left.createdAt > right.createdAt) ||
           (left.createdAt == right.createdAt && left.order > right.order)
    
}

public func >= (left:LogEntry, right:LogEntry) -> Bool {
    return (left.createdAt > right.createdAt) ||
           (left.createdAt == right.createdAt && left.order >= right.order)
    
}

extension LogLevel: Comparable { }
public func < (left:LogLevel, right:LogLevel) -> Bool {
    return left.rawValue < right.rawValue
    
}

public func <= (left:LogLevel, right:LogLevel) -> Bool {
    return left.rawValue <= right.rawValue
}

public func > (left:LogLevel, right:LogLevel) -> Bool {
    return left.rawValue > right.rawValue
    
}

public func >= (left:LogLevel, right:LogLevel) -> Bool {
    return left.rawValue >= right.rawValue
    
}
