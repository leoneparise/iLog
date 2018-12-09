//
//  FilterButton.swift
//  iLog
//
//  Created by Leone Parise on 08/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import UIKit

@IBDesignable
class FilterButton: UIButton {
    @IBInspectable var padding:CGFloat = 0
    @IBInspectable var lineWidth:CGFloat = 0
    @IBInspectable var spacing:CGFloat = 3
    
    override func draw(_ rect: CGRect) {
        var bounds = rect.insetBy(dx: padding, dy: padding)
        let minSize = min(bounds.width, bounds.height)
        bounds = bounds.insetBy(dx: (bounds.width - minSize) / 2, dy: (bounds.height - minSize) / 2)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let x = bounds.minX
        let y = bounds.midY
        let w = bounds.width
        
        drawHLine(ctx: ctx, x: x, y: y, length: w)
        
        drawHLine(ctx: ctx, x: x, y: y - (spacing + lineWidth), length: w)
        
        drawHLine(ctx: ctx, x: x, y: y + (spacing + lineWidth), length: w)
    }
    
    private func drawHLine(ctx: CGContext, x: CGFloat, y: CGFloat, length: CGFloat) {
        drawLine(ctx, from: CGPoint(x: x, y: y),
                 to: CGPoint(x: x + length , y: y),
                 lineWidth: lineWidth,
                 color: self.tintColor)
    }
}
