//
//  TimelineViewController.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 05/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

open class TimelineViewController: UITableViewController {
    public var dataSource:TimelineDatasource!
    private var searchController:UISearchController!
    private var logManager:LogManager!
    
    fileprivate var logLevel = LogLevel.debug {
        didSet { refresh() }
    }
    
    fileprivate var searchText:String? = nil {
        didSet { refresh() }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        title = "Log Viewer"
        
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 50
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        
        // Register cell
        let bundle = Bundle(for: TimelineViewController.self)
        let cellNib = UINib(nibName: "TimelineTableViewCell", bundle: bundle)
        tableView.register(cellNib, forCellReuseIdentifier: TimelineDatasource.cellIdentifier)
        
        // Configure navigation bar
        let closeButton = CloseButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        closeButton.padding = 6
        closeButton.lineWidth = 2
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        let filterButton = FilterButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        filterButton.padding = 5
        filterButton.lineWidth = 2
        filterButton.spacing = 5
        filterButton.addTarget(self, action: #selector(showActions), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: filterButton)
        
        // Configure the search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search logs"
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        navigationItem.titleView = searchController.searchBar
        
        // Sets this view controller as presenting view controller for the search interface
        definesPresentationContext = true
        
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logManager.filter(level: logLevel, text: searchText) { entries in
            self.dataSource.set(entries: entries ?? [])
        }
    }
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = TimelineTableViewHeader.fromNib()
        view.isFirst = section == 0
        view.date = dataSource.getGroup(forSection: section).timestamp
        return view
    }
    
    override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let (section, row) = (indexPath.section, indexPath.row)
        let rowCount = dataSource.count(forSection: section)
        
        if section >= max(0, (2 / 3) * dataSource.count)
            && row >= max(0, (2 / 3) * rowCount) {
            logManager.filter(level: logLevel, text: searchText, offset: dataSource.offset) { [weak self] entries in
                self?.dataSource.append(entries: entries ?? [])
            }
        }
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard
            let cell = tableView.cellForRow(at: indexPath) as? TimelineTableViewCellType
            else { return }
        
        self.tableView.beginUpdates()
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
        refresh()
    }
    
    @objc private func didLog(notification:Notification) {
        guard let entry = notification.object as? LogEntry else { return }
        
        // We shouldn't add new logs if there is a search happening
        if entry.level >= logLevel && (searchText?.isEmpty ?? true) && !searchController.isActive {
            self.dataSource.prepend(entries: [entry])
        }
    }
    
    private func apply(changes:[Change], withAddAnimation addAnimation: UITableView.RowAnimation = .top) {
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
    
    fileprivate func refresh() {
        logManager.filter(level: logLevel, text: searchText) { [weak self] entries in
            self?.dataSource.set(entries: entries ?? [])
        }
    }
    
    @objc private func showActions() {
        func createAction(level:LogLevel) -> UIAlertAction {
            let isSelected = logLevel == level
            let title = isSelected ? "- \(level.stringValue) -" : level.stringValue
            let action = UIAlertAction(title: title, style: .default) { [unowned self] _ in
                self.logLevel = level
            }
            action.isEnabled = !isSelected
            
            return action
        }
        
        let alert = UIAlertController(title: nil,  message: "Log level", preferredStyle: .actionSheet)
        alert.addAction(createAction(level: .debug))
        alert.addAction(createAction(level: .info))
        alert.addAction(createAction(level: .warn))
        alert.addAction(createAction(level: .error))
        
        alert.addAction(UIAlertAction(title: "Clear logs", style: .destructive, handler: { (_) in
            self.clear()
        }))
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension TimelineViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        performTrottled(label: "search", delay: 0.5) { [weak self] in
            guard let text = searchController.searchBar.text, !text.isEmpty else {
                self?.searchText = nil
                return
            }
            
            self?.searchText = text
        }
    }
}
