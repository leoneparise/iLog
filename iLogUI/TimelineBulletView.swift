//
//  TimelineView.swift
//  StumpExample
//
//  Created by Leone Parise Vieira da Silva on 06/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit

@IBDesignable
class TimelineBulletView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.contentMode = .center
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    // MARK: State
    @IBInspectable var isFirst:Bool = true {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var showBullet:Bool = true {
        didSet { setNeedsDisplay() }
    }
    
    // Mark: Config
    @IBInspectable var lineColor:UIColor = .darkGray {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var bulletColor:UIColor = .white {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var bulletSize:CGSize = CGSize(width: 10, height: 10) {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var lineWidth:CGFloat = 1.0 {
        didSet { setNeedsDisplay() }
    }
    
    // MARK: Draw
    override func draw(_ rect: CGRect) {
        let (w, h) = (rect.width, rect.height)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        if isFirst {
            drawLine(ctx,
                     from: CGPoint(x: w/2, y: h/2),
                     to: CGPoint(x: w/2, y:h),
                     lineWidth: lineWidth,
                     color: lineColor)
        } else {
            drawLine(ctx,
                     from: CGPoint(x: w/2, y: 0),
                     to: CGPoint(x: w/2, y:h),
                     lineWidth: lineWidth,
                     color: lineColor)
        }
        if showBullet {
            drawCircle(ctx,
                       center: CGPoint(x: w/2, y: h/2),
                       size:bulletSize,
                       borderWidth: 1.0,
                       fillColor: bulletColor,
                       borderColor: bulletColor)
        }
    }
}
