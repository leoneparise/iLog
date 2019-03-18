//
//  LogManagerTests.swift
//  iLogTests
//
//  Created by Leone Parise on 12/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import XCTest
import Quick
import Nimble
import SQLite
@testable import iLog


class LogManagerTests: QuickSpec {
    override func spec() {
        describe("Log manager") {
            var driver:SqlLogDriver!
            beforeEach {
                driver = SqlLogDriver(level: .debug, inMemory: true)
                LogManager.setup(driver!)
            }
            
            it("should log to mainDriver") {
                log(.debug, "some info")
                
                var count:Int64?
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.7) {
                    expect{ count = try driver.db.scalar("SELECT COUNT(*) FROM logs") as? Int64 }.toNot(throwError())
                }
                
                expect(count).toEventually(equal(1), timeout: 2)
            }
            
            it("should fire log notification") {
                var entry:LogEntry?
                NotificationCenter.default.addObserver(forName: Notification.Name.LogManagerDidLog, object: nil, queue: .main) { (notification) in
                    entry = notification.object as? LogEntry
                }
                
                log(.debug, "some info")
                expect(entry).toEventuallyNot(beNil())
                expect(entry?.level).toEventually(equal(.debug))
                expect(entry?.message).toEventually(contain("some info"))
            }
        }
    }
}
