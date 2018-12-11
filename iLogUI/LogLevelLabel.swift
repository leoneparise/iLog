//
//  LogTypeLabel.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

extension LogLevel {
    var color:UIColor {
        switch self {
        case .debug: return UIColor(hex: 0x3cb371)
        case .info: return UIColor(hex: 0x0099cc)
        case .warn: return UIColor(hex: 0xff9933)
        case .error: return UIColor(hex: 0xdc143c)
        }
    }
}

@IBDesignable
public class LogLevelLabel: UILabel {
    public var level:LogLevel? {
        didSet {
            self.text = level?.stringValue.uppercased()
            self.backgroundColor = level?.color
            setNeedsLayout()
        }
    }
    
    public convenience init(level:LogLevel) {
        self.init(frame: CGRect.zero)
        self.level = level
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 3
        self.font = UIFont.systemFont(ofSize: 9, weight: UIFont.Weight(rawValue: 500))
        self.textColor = .white
        self.backgroundColor = .darkGray
        self.textAlignment = .center
    }
        
    public override func prepareForInterfaceBuilder() {
        commonInit()
        self.level = .info
    }
}
