//
//  UIColor_Hex.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

/// MARK: - Hex extensions
extension UIColor {
    convenience init(hexRed: UInt8, hexGreen: UInt8, hexBlue: UInt8, alpha: CGFloat) {
        let divider: CGFloat = 255.0
        self.init(red: CGFloat(hexRed) / divider,
                  green: CGFloat(hexGreen) / divider,
                  blue: CGFloat(hexBlue) / divider,
                  alpha: alpha)
    }
    
    convenience init(hex:UInt32) {
        self.init(hex:hex, alpha: 1.0)
    }
    
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(hexRed: UInt8((hex >> 16) & 0xff),
                  hexGreen: UInt8((hex >> 8) & 0xff),
                  hexBlue: UInt8(hex & 0xff),
                  alpha: alpha)
    }
}
