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

class TimelineTableViewCell: UITableViewCell, TimelineTableViewCellType {
    @IBOutlet weak var bulletView:TimelineBulletView!
    @IBOutlet weak var levelLabel:LogLevelLabel!
    @IBOutlet weak var fileLabel:UILabel!
    @IBOutlet weak var lineLabel:UILabel!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    @IBOutlet weak var functionLabel:UILabel!
            
    var expanded:Bool = false {
        didSet {
            messageLabel.numberOfLines = expanded ? 0 : 2
            functionLabel.isHidden = !expanded
        }
    }
    
    var line:UInt? {
        didSet { lineLabel.text = line != nil ? "\(line!)" : "" }
    }
    
    var message:String? {
        didSet { messageLabel.text = message }
    }
    
    var file:String? {
        didSet { fileLabel.text = file != nil ? "\(file!):" : "" }
    }
    
    var level:LogLevel = .debug {
        didSet {
            levelLabel.level = level
        }
    }
    
    var createdAt:Date = Date() {
        didSet { dateLabel.text = String(format: "%02d", createdAt.second) }
    }
    
    var function:String? {
        didSet { functionLabel.text = function }
    }
    
    var isLast:Bool = false {
        didSet { bulletView.isLast = isLast }
    }
}
