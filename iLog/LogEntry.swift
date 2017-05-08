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
public enum LogLevel: Int64 {
    case info = 0, debug = 10, warn = 20, error = 30
    
    var stringValue:String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warn: return "warn"
        case .error: return "error"
        }
    }
}

open class LogEntry {
    public let level: LogLevel
    public let message: String
    public let file: String
    public let line: UInt
    public let function: String
    public let createdAt: Date
    public let order:Int64
    public let stored:Bool
    
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
    return left.createdAt == right.createdAt && left.order == right.order && left.level == right.level
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
