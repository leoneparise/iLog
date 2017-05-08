//
//  SqlManager.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit
import SQLite

public class SqlLogDriver: LogDriver {
    // MARK - Public Properties
    public var level: LogLevel = .debug
    public var didLog: DidLogCallback?
    fileprivate var db:Connection
    
    // MARK: - Data Definition
    fileprivate let tbl_logs = Table("logs")
    fileprivate let col_level = Expression<Int64>("level")
    fileprivate let col_message = Expression<String>("message")
    fileprivate let col_file = Expression<String>("file")
    fileprivate let col_line = Expression<Int64>("line")
    fileprivate let col_function = Expression<String>("function")
    fileprivate let col_createdAt = Expression<Int64>("created_at")
    fileprivate let col_stored = Expression<Bool>("stored")
    fileprivate let col_order = Expression<Int64>("order_seq")
            
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
        
        try db.run(tbl_logs.createIndex([col_level, col_createdAt, col_stored], ifNotExists: true))
    }
    
    // MARK: - Public Functions
    public func log(entry:LogEntry) {
        do {
            try db.run(tbl_logs.insert(
                            col_level <- entry.level.rawValue,
                            col_message <- entry.message,
                            col_file <- entry.file,
                            col_line <- Int64(entry.line),
                            col_function <- entry.function,
                            col_createdAt <- Int64(entry.createdAt.timeIntervalSince1970),
                            col_order <- entry.order,
                            col_stored <- entry.stored))
        } catch {
            print("iLog >> Can't insert entry")
            return
        }
        
        didLog?(entry)
    }
    
    public func all(level levelOrNil:LogLevel? = nil, offset:Int = 0) -> [LogEntry]? {
        let query = tbl_logs.filter(col_level >= (levelOrNil?.rawValue ?? 0))
                            .order(col_createdAt.desc, col_order.desc)
                            .limit(50, offset: offset)
        
        return self.getEntries(query: query)
    }
    
    public func store(_ handler: ([LogEntry], (Bool) -> Void) -> Void) {
        let query = tbl_logs.filter(col_stored == false)
                            .order(col_createdAt.asc, col_order.asc)
        
        let entries = getEntries(query: query)
        handler(entries) { success in
            if success {
                for entry in entries {
                    self.update(entry: entry)
                }
            }
        }
    }
}

// MARK
extension SqlLogDriver {
    fileprivate func getEntries(query:Table) -> [LogEntry] {
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
            print("iLog >> Can't fetch logs")
        }
        
        return entries
    }
    
    fileprivate func update(entry:LogEntry) {
        let log = tbl_logs.filter(col_createdAt == Int64(entry.createdAt.timeIntervalSince1970)
                               && col_order == entry.order)
        do {
            if try db.run(log.update(col_stored <- true)) == 0 {
                print("iLog >> Log not found")
            }
        } catch {
            print("iLog >> Can't update log")
        }
    }
}
