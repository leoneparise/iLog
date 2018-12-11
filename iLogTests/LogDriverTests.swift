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
        describe("console driver") {
            var driver:PrintLogDriver<StringArrayOutputStream>!
            beforeEach {
                driver = PrintLogDriver(level: .info, output: StringArrayOutputStream())
                LogManager.setup(driver!)
            }
            
            it("should log info") {
                log(.info, "some text")
                expect(driver.output.lines.count).toEventually(equal(1))
                expect(driver.output.lines[0]).toEventually(contain("info", "some text"))
            }
            
            it("should ignore debug") {
                log(.debug, "should be ignored")
                expect(driver.output.lines.count).toEventually(equal(0))
            }
            
            it("should log in sequence") {
                log(.info, "one")
                log(.info, "two")
                expect(driver.output.lines.count).toEventually(equal(2))
                expect(driver.output.lines[0]).toEventually(contain("one"))
                expect(driver.output.lines[0]).toEventuallyNot(contain("two"))
                expect(driver.output.lines[1]).toEventually(contain("two"))
                expect(driver.output.lines[1]).toEventuallyNot(contain("one"))
            }
            
            it("should fire didLog") {
                var entry:LogEntry?
                LogManager.shared.didLog = { e in
                    entry = e
                }
                
                log(.info, "did log")
                
                expect(entry).toEventuallyNot(beNil())
                expect(entry?.message).toEventually(contain("did log"))
            }
        }
    }
}
