//
//  LogLevel+Color.swift
//  iLog
//
//  Created by Leone Parise on 12/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
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
