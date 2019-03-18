//
//  TimelineTableViewCell.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

public protocol TimelineTableViewCellType:class {
    var expanded:Bool { get set }
}

public class TimelineTableViewCell: UITableViewCell, TimelineTableViewCellType {
    public struct ViewModel {
        private let entry:LogEntry
        let isLast:Bool
        
        init(entry:LogEntry, isLast:Bool = false) {
            self.entry = entry
            self.isLast = isLast
        }
        
        var message:String {
            return entry.message
        }
        
        var file:String {
            return "\(entry.file):"
        }
        
        var line:String {
            return "\(entry.line)"
        }
        
        var function:String {
            return entry.function
        }
        
        var levelText:String {
            return entry.level.stringValue.uppercased()
        }
        
        var levelColor:UIColor {
            return entry.level.color
        }
        
        var createdAt:String {
            return String(format: "%02d", Calendar.current.component(.second, from: entry.createdAt))
        }
    }
        
    @IBOutlet weak var bulletView:TimelineBulletView!
    @IBOutlet weak var levelLabel:LogLevelLabel!
    @IBOutlet weak var fileLabel:UILabel!
    @IBOutlet weak var lineLabel:UILabel!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    @IBOutlet weak var functionLabel:UILabel!
            
    public var expanded:Bool = false {
        didSet {
            messageLabel.numberOfLines = expanded ? 0 : 2
            functionLabel.isHidden = !expanded
        }
    }
    
    func configure(_ model:ViewModel) {
        lineLabel.text = model.line
        messageLabel.text = model.message
        fileLabel.text = model.file
        functionLabel.text = model.function
        levelLabel.text = model.levelText
        levelLabel.backgroundColor = model.levelColor
        dateLabel.text = model.createdAt
        bulletView.isLast = model.isLast
    }
}
