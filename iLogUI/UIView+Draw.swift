//
//  UIView+Draw.swift
//  Pods
//
//  Created by Leone Parise Vieira da Silva on 09/05/17.
//
//

import UIKit

extension UIView {
    func drawLine(_ ctx:CGContext,
                  from: CGPoint,
                  to:CGPoint,
                  lineWidth:CGFloat = 1.0,
                  color:UIColor = UIColor.black) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.move(to: CGPoint(x: from.x, y: from.y))
        ctx.addLine(to: CGPoint(x: to.x, y: to.y))
        ctx.strokePath()
    }
    
    func drawCircle(_ ctx: CGContext,
                    center:CGPoint,
                    size:CGSize,
                    borderWidth: CGFloat = 1.0,
                    fillColor:UIColor = UIColor.black,
                    borderColor:UIColor = UIColor.black) {
        let rect = CGRect(x: center.x - size.width / 2,
                          y: center.y - size.height / 2,
                          width: size.width,
                          height: size.height)
        
        // Add circle
        ctx.setFillColor(fillColor.cgColor)
        ctx.addEllipse(in: rect)
        ctx.fillPath()
        
        // Add circle border
        ctx.setStrokeColor(borderColor.cgColor)
        ctx.setLineWidth(borderWidth)
        ctx.addEllipse(in: rect)
        ctx.strokePath()
    }
}
