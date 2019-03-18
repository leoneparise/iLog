//
//  iLogTests.swift
//  iLogTests
//
//  Created by Leone Parise on 11/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import XCTest
import Quick
import Nimble
import SQLite
@testable import iLog

struct StringArrayOutputStream: TextOutputStream {
    var lines:[String] = []
    mutating public func write(_ string: String) {
        if(!string.isEmpty && string != "\n") {
            lines.append(string)
        }
    }
    
    mutating public func clear() {
        lines = []
    }
}

class LogDriverTests: QuickSpec {
    override func spec() {                
        describe("Console driver") {
            var driver:PrintLogDriver<StringArrayOutputStream>!
            beforeEach {
                driver = PrintLogDriver(level: .info, output: StringArrayOutputStream())
                LogManager.setup(driver!)
            }
            
            it("should log info") {
                let entry = LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "some text")
                driver.log(entry: entry)
                
                expect(driver.output.lines.count).toEventually(equal(1))
                expect(driver.output.lines[0]).toEventually(contain("info", "some text"))
            }
            
            it("should ignore debug") {
                let entry = LogEntry(level: .debug, file: "TestFile", line: 10, function: "testFunction", message: "should be ignored")
                driver.log(entry: entry)
                
                expect(driver.output.lines.count).toEventually(equal(0))
            }
            
            it("should log in sequence") {
                let entries = [
                    LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "one"),
                    LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "two")
                ]
                
                for entry in entries {
                    driver.log(entry: entry)
                }
                
                expect(driver.output.lines.count).toEventually(equal(2))
                expect(driver.output.lines[0]).toEventually(contain("one"))
                expect(driver.output.lines[0]).toEventuallyNot(contain("two"))
                expect(driver.output.lines[1]).toEventually(contain("two"))
                expect(driver.output.lines[1]).toEventuallyNot(contain("one"))
            }
            
            it("should return nil in filter") {
                let entry = LogEntry(level: .debug, file: "TestFile", line: 10, function: "testFunction", message: "should be ignored")
                driver.log(entry: entry)
                
                var filterEntries:[LogEntry]?
                driver.filter { (entries) in
                    filterEntries = entries
                }
                
                expect(filterEntries).to(beNil())
            }
            
            it("should throw an error in store") {
                let entry = LogEntry(level: .debug, file: "TestFile", line: 10, function: "testFunction", message: "should be ignored")
                driver.log(entry: entry)
                
                expect{
                    try driver.store{ (entries, complete) in try complete(true) }
                }.to(throwError(iLogError.notSupported))
            }
            
            it("should fire didLog") {
                var entry:LogEntry?
                
                driver.didLog = { log in
                    entry = log
                }
                
                log(.info, "didLog fired")
                expect(entry).toEventuallyNot(beNil())
                expect(entry?.message).toEventually(contain("didLog fired"))
            }
        }
        
        describe("SQL driver") {
            var driver:SqlLogDriver!
            beforeEach {
                driver = SqlLogDriver(level: .info, inMemory: true)
                LogManager.setup(driver!)
            }
            
            it("should log info") {
                let entry = LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "some message")
                driver.log(entry: entry)
                
                var count:Int64 = 0
                expect{ count = try driver.db.scalar("SELECT COUNT(*) FROM logs") as! Int64 }.toNot(throwError())
                expect(count).to(equal(1))
            }
            
            it("should ignore debug") {
                let entry = LogEntry(level: .debug, file: "TestFile", line: 10, function: "testFunction", message: "should be ignored")
                driver.log(entry: entry)
                
                var count:Int64 = 0
                expect{ count = try driver.db.scalar("SELECT COUNT(*) FROM logs") as! Int64 }.toNot(throwError())
                expect(count).to(equal(0))
            }
            
            it("should log in sequence") {
                let entries = [
                    LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "one"),
                    LogEntry(level: .info, file: "TestFile", line: 10, function: "testFunction", message: "two"),
                    LogEntry(level: .debug, file: "TestFile", line: 10, function: "testFunction", message: "three")
                ]
                
                for entry in entries {
                    driver.log(entry: entry)
                }
                
                // Check if database has 2 entries
                var count:Int64 = 0
                expect{ count = try driver.db.scalar("SELECT COUNT(*) FROM logs") as! Int64 }.toNot(throwError())
                expect(count).to(equal(2))
                
                // Check if entries were stored in sequence
                var stmt:Statement!
                expect{ stmt = try driver.db.prepare("SELECT message FROM logs") }.toNot(throwError())
                for (index, row) in stmt.enumerated() {
                    let message:String = row[0] as! String
                    expect(message).to(equal(entries[index].message))
                }
            }
            
            it("should fire didLog") {
                var entry:LogEntry?
                
                driver.didLog = { log in
                    entry = log
                }
                
                log(.info, "didLog fired")
                expect(entry).toEventuallyNot(beNil())
                expect(entry?.message).toEventually(contain("didLog fired"))
            }
        }
    }
}
