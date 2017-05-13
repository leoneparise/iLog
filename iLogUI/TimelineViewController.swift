//
//  TimelineViewController.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

class TimelineViewController: UITableViewController {
    var dataSource:TimelineDatasource!
    private var logManager:LogManager!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Log Viewer"
        
        // Configure log manager
        logManager = LogManager.shared
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(didLog(notification:)),
                         name: Notification.Name.LogManagerDidLog,
                         object: nil)
        
        // Configure datasource
        if dataSource == nil {
            dataSource = TimelineDatasource()
        }
        
        dataSource.configureCell = { cell, entry, isLast in
            guard let entryCell = cell as? TimelineTableViewCell else { return }
            entryCell.level = entry.level
            entryCell.file = entry.file
            entryCell.line = entry.line
            entryCell.message = entry.message
            entryCell.createdAt = entry.createdAt
            entryCell.function = entry.function
            entryCell.isLast = isLast
        }
        
        dataSource.didSet = { [unowned self] _ in
            self.tableView.reloadData()
        }
        
        dataSource.didAppend = { [unowned self] changes in
            self.tableView.reloadData()
        }
        
        dataSource.didInsert = { [unowned self] changes in
            let addChanges = changes.filter{ $0.type == .add }
            let updateChanges = changes.filter{ $0.type == .sectionUpdate }
            
            self.apply(changes: addChanges, withAddAnimation: .top)
            self.apply(changes: updateChanges)
        }
        
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.tableFooterView = UIView()
        // Register cell
        let bundle = Bundle(for: TimelineViewController.self)
        let cellNib = UINib(nibName: "TimelineTableViewCell", bundle: bundle)
        tableView.register(cellNib, forCellReuseIdentifier: TimelineDatasource.cellIdentifier)
        
        // Configure navigation bar
        let closeButton = CloseButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        closeButton.padding = 5
        closeButton.lineWidth = 2
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                                 target: self,
                                                                 action: #selector(clear))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let logs = logManager.all() else { return }
        self.dataSource.set(entries: logs)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = TimelineTableViewHeader.fromNib()
        view.isFirst = section == 0
        view.date = dataSource.getGroup(forSection: section).timestamp
        return view
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let (section, row) = (indexPath.section, indexPath.row)
        let rowCount = dataSource.count(forSection: section)
        
        if section >= max(0, (2 / 3) * dataSource.count)
            && row >= max(0, (2 / 3) * rowCount),
           let logs = logManager.all(offset: dataSource.offset) {
            dataSource.append(entries: logs)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        self.tableView.beginUpdates()
        
        guard
            let cell = tableView.cellForRow(at: indexPath) as? TimelineTableViewCellType
        else { return }
        
        cell.expanded = !cell.expanded
        
        self.tableView.endUpdates()
    }
    
    // MARK: - Selectors
    @objc private func close() {
        if let nav = self.navigationController {
            nav.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func clear() {
        logManager.clear()
        
        guard let entries = logManager.all() else { return }
        dataSource.set(entries: entries)
    }
    
    @objc private func didLog(notification:Notification) {
        guard let entry = notification.object as? LogEntry else { return }
        self.dataSource.prepend(entries: [entry])
    }
    
    private func apply(changes:[Change], withAddAnimation addAnimation: UITableViewRowAnimation = .top) {
        self.tableView.beginUpdates()
        for change in changes {
            if change.createSection {
                self.tableView.insertSections([change.indexPath.section], with: addAnimation)
            }
            
            switch change.type {
            case .add: self.tableView.insertRows(at: [change.indexPath], with: addAnimation)
            case .update: self.tableView.reloadRows(at: [change.indexPath], with: .none)
            case .sectionUpdate: self.tableView.reloadSections([change.indexPath.section], with: .none)
            }
        }
        self.tableView.endUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
