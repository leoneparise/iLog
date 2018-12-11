//
//  SqlManager.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit
import SQLite

/// Default SQL log driver
public class SqlLogDriver: LogDriver {
    // MARK - Public Properties
    public var level: LogLevel = .debug
    public var didLog: DidLogCallback?
    fileprivate var db:Connection
    
    // MARK: - Data Definition
    fileprivate let tbl_logs = Table("logs")
    fileprivate let col_id = Expression<Int64>("id")
    fileprivate let col_level = Expression<Int64>("level")
    fileprivate let col_message = Expression<String>("message")
    fileprivate let col_file = Expression<String>("file")
    fileprivate let col_line = Expression<Int64>("line")
    fileprivate let col_function = Expression<String>("function")
    fileprivate let col_createdAt = Expression<Int64>("created_at")
    fileprivate let col_stored = Expression<Bool>("stored")
    fileprivate let col_order = Expression<Int64>("order_seq")
    
    fileprivate let vtbl_logs = VirtualTable("vlogs")
    /**
     Create a SqlLogDriver instance.
     
     - parameter level: minimum log level
     - parameter logFile: log file name. All logs are atored in user's document directory
     - parameter inMemory: use in memory database. **In memory databases doesn't have a shared state**
    */
    public init?(level:LogLevel = .debug, logFile:String = "logs.sqlite3", inMemory:Bool = false) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let logFileUrl = documentDirectory.appendingPathComponent(logFile)
        
        do {
            if inMemory {
                db = try Connection(.inMemory)
            } else {
                db = try Connection(logFileUrl.absoluteString)
            }            
            try createDatabase()
        } catch {
            print("iLog >> Can't create database \(error)")
            return nil
        }
    }
    
    private func createDatabase() throws {
        try db.run(tbl_logs.create(ifNotExists: true) { t in
            t.column(col_level)
            t.column(col_message)
            t.column(col_file)
            t.column(col_line)
            t.column(col_function)
            t.column(col_createdAt)
            t.column(col_order)
            t.column(col_stored)
            t.primaryKey(col_createdAt, col_order)
        })
        
        try db.run(tbl_logs.createIndex(col_level, col_createdAt, col_order, ifNotExists: true))
        try db.run(tbl_logs.createIndex(col_createdAt, col_order, ifNotExists: true))
        try db.run(tbl_logs.createIndex(col_stored, ifNotExists: true))
        
        let config = FTS4Config()
            .column(col_message)
            .column(col_file)
            .column(col_function)
            .column(col_createdAt, [.unindexed])
            .column(col_order, [.unindexed])
            .tokenizer(Tokenizer.Unicode61())
        
        try db.run(vtbl_logs.create(.FTS4(config), ifNotExists: true))
    }
    
    // MARK: - Public Functions
    public func log(entry:LogEntry) {
        guard entry.level.rawValue >= level.rawValue else { return }
        
        do {
            try db.transaction { [weak self] in
                guard let wself = self else { return }
                try wself.db.run(wself.tbl_logs.insert(
                    wself.col_level <- entry.level.rawValue,
                    wself.col_message <- entry.message,
                    wself.col_file <- entry.file,
                    wself.col_line <- Int64(entry.line),
                    wself.col_function <- entry.function,
                    wself.col_createdAt <- Int64(entry.createdAt.timeIntervalSince1970),
                    wself.col_order <- entry.order,
                    wself.col_stored <- entry.stored))
                
                try wself.db.run(wself.vtbl_logs.insert(
                    wself.col_function <- entry.function,
                    wself.col_file <- entry.file,
                    wself.col_message <- entry.message,
                    wself.col_createdAt <- Int64(entry.createdAt.timeIntervalSince1970),
                    wself.col_order <- entry.order
                ))
            }
        } catch {
            print("iLog >> Can't insert entry \(error)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.didLog?(entry)
        }
    }
    
    public func filter(level levelOrNil:LogLevel? = nil, text textOrNil:String? = nil, offset:Int = 0, completion: @escaping (([LogEntry]?) -> Void)) {
        let query:Table
        if let text = textOrNil, !text.isEmpty {
            query = fullTextQuery(level: levelOrNil ?? .debug,
                                        text: text,
                                        limit: 50,
                                        offset: offset)
        } else {
            query = simpleQuery(level: levelOrNil ?? .debug,
                                      limit: 50,
                                      offset: offset)
        }
        
        let entries = getEntries(query: query)
        
        DispatchQueue.main.async {
            completion(entries)
        }
    }
    
    public func store(_ handler: ([LogEntry], (Bool) -> Void) -> Void) {
        let query = tbl_logs.filter(col_stored == false)
                            .order(col_createdAt.asc, col_order.asc)
        
        let entries = getEntries(query: query)
        handler(entries) { success in
            if success {
                for entry in entries {
                    update(entry: entry)
                }
            }
        }
    }
    
    public func clear() {
        do {
            try db.transaction { [weak self] in
                guard let wself = self else { return }
                
                try wself.db.run(wself.tbl_logs.delete())
                try wself.db.run(wself.vtbl_logs.delete())
            }
        } catch {
            print("iLog >> Can't clear log \(error)")
        }
    }
}

// MARK
fileprivate extension SqlLogDriver {
    func getEntries(query:Table) -> [LogEntry] {
        var entries:[LogEntry] = []
        
        do {
            for log in try db.prepare(query) {
                let entry = LogEntry(
                    createdAt: Date(timeIntervalSince1970: TimeInterval(log[col_createdAt])),
                    order: log[col_order],
                    stored: log[col_stored],
                    level: LogLevel(rawValue: log[col_level])!,
                    file: log[col_file],
                    line: UInt(log[col_line]),
                    function: log[col_function],
                    message: log[col_message]
                )
                
                entries.append(entry)
            }
        } catch {
            print("iLog >> Can't fetch logs: \(error)")
        }
        
        return entries
    }
    
    func update(entry:LogEntry) {
        let log = tbl_logs.filter(col_createdAt == Int64(entry.createdAt.timeIntervalSince1970)
                               && col_order == entry.order)
        do {
            if try db.run(log.update(col_stored <- true)) == 0 {
                print("iLog >> Log not found")
            }
        } catch {
            print("iLog >> Can't update log \(error)")
        }
    }
    
    func fullTextQuery(level: LogLevel, text: String, limit:Int, offset: Int) -> Table {
        let words = text.trimmingCharacters(in: .whitespaces)
            .replacingPattern(of: "\\s+", with: " ")
            .split(separator: " ")
            .map{ "\($0)*" }
            .joined(separator: " ")
        
        let query = tbl_logs.select(tbl_logs[*]).join(vtbl_logs, on:
            vtbl_logs[col_createdAt] == tbl_logs[col_createdAt] &&
            vtbl_logs[col_order] == tbl_logs[col_order]
        )
        .filter(vtbl_logs.match(words) && col_level >= level.rawValue)
        .order(tbl_logs[col_createdAt].desc, tbl_logs[col_order].desc)
        .limit(limit, offset: offset)
        
        return query
    }
    
    func simpleQuery(level: LogLevel, limit:Int, offset: Int) -> Table {
        return tbl_logs.filter(col_level >= level.rawValue)
            .order(col_createdAt.desc, col_order.desc)
            .limit(limit, offset: offset)
    }
}
