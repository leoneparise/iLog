//
//  CloseButton.swift
//  Pods
//
//  Created by Leone Parise Vieira da Silva on 09/05/17.
//
//

import UIKit

@IBDesignable
class CloseButton: UIButton {
    @IBInspectable var padding:CGFloat = 0
    @IBInspectable var lineWidth:CGFloat = 0
    
    override func draw(_ rect: CGRect) {
        var bounds = rect.insetBy(dx: padding, dy: padding)
        let minSize = min(bounds.width, bounds.height)
        bounds = bounds.insetBy(dx: (bounds.width - minSize) / 2, dy: (bounds.height - minSize) / 2)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        drawLine(ctx, from: CGPoint(x: bounds.minX, y: bounds.minY),
                 to: CGPoint(x: bounds.maxX, y: bounds.maxY),
                 lineWidth: lineWidth,
                 color: self.tintColor)
        
        drawLine(ctx,
                 from: CGPoint(x: bounds.maxX, y: bounds.minY),
                 to: CGPoint(x: bounds.minX, y: bounds.maxY),
                 lineWidth: lineWidth,
                 color: self.tintColor)
    }
}
