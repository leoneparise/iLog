//
//  LogEntryDatasource.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit
import SwiftDate

struct Change {
    enum ChangeType { case add, update, sectionUpdate }
    
    let indexPath:IndexPath
    let createSection:Bool
    let type:ChangeType
    
    init(indexPath: IndexPath, type: ChangeType = .add, createSection: Bool = false) {
        self.indexPath = indexPath
        self.createSection = createSection
        self.type = type
    }
}

class TimelineDatasource:NSObject {
    static let cellIdentifier = "TimelineCell"
    
    fileprivate var groups: [LogEntryGroup] = []
    private(set) var offset:Int = 0
    
    var didSet: (([LogEntry]) -> Void)?
    var didInsert: (([Change]) -> Void)?
    var didAppend: (([LogEntry]) -> Void)?
    
    var configureCell: ((UITableViewCell, LogEntry, Bool) -> Void)?
    var configureHeader: ((UIView, LogEntryGroup) -> Void)?
    
    func prepend(entries:[LogEntry]) {
        guard entries.count > 0 else { return }
        offset += entries.count
        let changes = entries.flatMap(self.prepend)
        didInsert?(changes)
    }
    
    func append(entries:[LogEntry]) {
        guard entries.count > 0 else { return }
        offset += entries.count
        let _ = entries.flatMap(self.append)
        didAppend?(entries)
    }
    
    func set(entries:[LogEntry]) {
        groups = []
        offset = entries.count
        let _ = append(entries: entries)
        didSet?(entries)
    }
    
    func getEntry(for indexPath:IndexPath) -> LogEntry {
        return groups[indexPath.section].entries[indexPath.row]
    }
    
    func getGroup(forSection section:Int) -> LogEntryGroup {
        return groups[section]
    }
    
    func count(forSection section:Int) -> Int {
        return groups[section].count
    }
    
    var count: Int {
        return groups.count
    }
    
    // MARK: - Private
    private func append(entry:LogEntry) -> [Change] {
        if let section = groups.index(of: LogEntryGroup(entry: entry)) {
            groups[section].append(entry)
            let indexPath = IndexPath(row: groups[section].count - 1, section: section)
            
            return [
                Change(indexPath: indexPath),
                Change(indexPath: lastIndexPath(from: indexPath), type: .update)
            ]
        } else {
            groups.append(LogEntryGroup(entry: entry))
            let indexPath = IndexPath(row: 0, section: groups.count - 1)
            
            return [
                Change(indexPath: indexPath, createSection: true),
                Change(indexPath: lastIndexPath(from: indexPath), type: .update)
            ]
        }
    }
    
    private func prepend(entry:LogEntry) -> [Change] {
        if let section = groups.index(of: LogEntryGroup(entry: entry)) {
            groups[section].insert(entry, at: 0)
            let indexPath = IndexPath(row: 0, section: section)
            return [
                Change(indexPath: indexPath)
            ]
        } else {
            groups.insert(LogEntryGroup(entry: entry), at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            return [
                Change(indexPath: indexPath, createSection: true),
                Change(indexPath: nextIndexPath(from: indexPath), type: .sectionUpdate),
            ]
        }
    }
    
    private func insert(entry:LogEntry) -> Change? {
        let newGroup = LogEntryGroup(entry: entry)
        var indexPath:IndexPath?
        var createSession = false
        
        func wasInserted() -> Bool { return indexPath != nil }
        
        // Check if log entry belongs to a group
        if let section = groups.index(of: newGroup) {
            var group = groups[section]
            
            // Check where the entry should fit inside the group
            for row in 0..<group.count {
                // Doesn't insert if entry was inserted before
                if entry == group.entries[row] {
                    break
                }
                // Check if entry is newer
                if entry > group.entries[row] {
                    group.insert(entry, at: row)
                    indexPath = IndexPath(row: row, section: section)
                    break
                }
            }
            // If the entry was not inserted and append to the end
            if !wasInserted() {
                group.append(entry)
                indexPath = IndexPath(row: group.count - 1, section: section)
            }
        }
        // If it doesn't, create a new group and insert
        else {
            // Check where the group should be inserted
            for section in 0..<groups.count {
                if newGroup.timestamp > groups[section].timestamp {
                    groups.insert(newGroup, at: section)
                    indexPath = IndexPath(row: 0, section: section)
                    break
                }
            }
            
            // If the group wast not inserted, append to the end
            if !wasInserted() {
                groups.append(newGroup)
                indexPath = IndexPath(row: 0, section: groups.count - 1)
            }
            
            createSession = true
        }
        
        return wasInserted() ? Change(indexPath: indexPath!, createSection: createSession) : nil
    }
    
    private func lastIndexPath(from indexPath:IndexPath) -> IndexPath {
        let (row, section) = (indexPath.row, indexPath.section)
        let lastSection = row == 0 && section > 0 ? section - 1 : section
        let lastRow = row > 0 ? row - 1 : count(forSection: lastSection) - 1
        
        return IndexPath(row: lastRow, section: lastSection)
    }
    
    private func nextIndexPath(from indexPath:IndexPath) -> IndexPath {
        let (row, section) = (indexPath.row, indexPath.section)
        let nextRow = row < count(forSection: section) - 1 ? row + 1 : 0
        let nextSection = section < count - 1 && nextRow == 0 ? section + 1 : section
        
        return IndexPath(row: nextRow, section: nextSection)
    }
}

extension TimelineDatasource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.count(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimelineDatasource.cellIdentifier,
                                                 for: indexPath)
        let isLast = (indexPath.section == count - 1) &&
                     (indexPath.row == count(forSection: indexPath.section) - 1)
        self.configureCell?(cell, getEntry(for: indexPath), isLast)
        return cell
    }
}
