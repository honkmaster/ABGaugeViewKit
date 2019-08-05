//
//  ABGaugeView.swift
//  ABGaugeViewKit
//
//  Created by Ajay Bhanushali on 02/03/18.
//  Copyright © 2018 Aimpact. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class ABGaugeView: UIView {
    
    // MARK:- @IBInspectable
    @IBInspectable public var colorCodes: String = "929918,C8CC86,66581A,3A4A73,185D99"
    @IBInspectable public var startAngles: String = "0,20,40,60,80"
    @IBInspectable public var arcAngle: CGFloat = 260
    
    @IBInspectable public var needleColor: UIColor
    @IBInspectable public var circleColor: UIColor

    @IBInspectable public var needleValue: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable public var isRoundCap: Bool = true {
        didSet {
            capStyle = isRoundCap ? .round : .butt
        }
    }
   
    
    var currentRadians: CGFloat? = nil
    var capStyle: CGLineCap = .round
    
    var circleLayer: CAShapeLayer? = nil
    var needleLayer: CAShapeLayer? = nil
    
    
    // MARK:- UIView Draw method
    override public func draw(_ rect: CGRect) {
        drawGauge()
    }
    
    public override init(frame: CGRect) {
        if #available(iOS 13.0, *) {
            needleColor = .secondaryLabel
            circleColor = .label
        } else {
            needleColor = .black
            circleColor = .black
        }
        
        super.init(frame: frame)
        drawGauge()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        if #available(iOS 13.0, *) {
            needleColor = .secondaryLabel
            circleColor = .label
        } else {
            needleColor = .black
            circleColor = .black
        }
        
        super.init(coder: aDecoder)
        drawGauge()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        drawGauge()
    }
    
    // MARK:- Custom Methods
    func drawGauge() {
        drawSmartArc()
        drawNeedle()
        drawNeedleCircle()
    }
    
    func drawSmartArc() {
        let angles = getAllAngles()
        let arcColors = colorCodes.components(separatedBy: ",")
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        var arcs = [ArcModel]()
        for index in 0..<arcColors.count {
            let arc = ArcModel(startAngle: angles[index], endAngle: angles[index+1], strokeColor: UIColor(hex: arcColors[index]), arcCap: CGLineCap.butt, center: center)
            arcs.append(arc)
        }
        arcs.rearrange(from: arcs.count-1, to: 1)
        arcs[0].arcCap = capStyle
        arcs[1].arcCap = capStyle
        for i in 0..<arcs.count {
            createArcWith(startAngle: arcs[i].startAngle, endAngle: arcs[i].endAngle, arcCap: arcs[i].arcCap, strokeColor: arcs[i].strokeColor, center: arcs[i].center)
        }
    }
    
    func radian(for percentOfArc: CGFloat, offset: CGFloat = 0.0) -> CGFloat {
        let startAngle:CGFloat = offset + abs(arcAngle-360.0) / 2.0
        let degrees = arcAngle * (percentOfArc / 100.0)
        return (startAngle + degrees) * .pi/180
    }
    
    func getAllAngles() -> [CGFloat] {
        var angles = [CGFloat]()
        for angle in startAngles.components(separatedBy: ",") {
            guard let number = NumberFormatter().number(from: angle) else { continue }
            angles.append(radian(for: CGFloat(truncating: number), offset: 90.0))
        }
        angles.append(radian(for: 100, offset: 90.0))
        return angles
    }
    
    func createArcWith(startAngle: CGFloat, endAngle: CGFloat, arcCap: CGLineCap, strokeColor: UIColor, center:CGPoint) {
        let center = center
        let radius: CGFloat = max(bounds.width, bounds.height)/2 - frame.width/20
        let lineWidth: CGFloat = frame.width/10
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        path.lineWidth = lineWidth
        path.lineCapStyle = arcCap
        strokeColor.setStroke()
        path.stroke()
    }
    
    func drawNeedleCircle() {
        if circleLayer == nil {
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: bounds.width/20, startAngle: 0.0, endAngle: CGFloat(2 * Double.pi), clockwise: false)
            
            circleLayer = CAShapeLayer()
            circleLayer!.path = circlePath.cgPath
            
            layer.addSublayer(circleLayer!)
        }
        circleLayer!.fillColor = circleColor.cgColor
    }
    
    func drawNeedle() {
        if needleLayer == nil {
            let needlePath = UIBezierPath()
            needlePath.move(to: CGPoint(x: bounds.width/2, y: bounds.width * 0.95))
            needlePath.addLine(to: CGPoint(x: bounds.width * 0.47, y: bounds.width * 0.42))
            needlePath.addLine(to: CGPoint(x: bounds.width * 0.53, y: bounds.width * 0.42))
            needlePath.close()

            needleLayer = CAShapeLayer()
            needleLayer!.frame = bounds
            needleLayer!.path = needlePath.cgPath

            layer.addSublayer(needleLayer!)
        }
        needleLayer!.fillColor = needleColor.cgColor
        needleLayer!.strokeColor = needleColor.cgColor
        
        if currentRadians == nil {
            let startAngle:CGFloat = abs(arcAngle-360.0) / 2.0
            currentRadians = startAngle * .pi/180
        }
        let radians = radian(for: needleValue)
        
        let timeInterval: CFTimeInterval = (currentRadians! != radians) ? 0.6 : 0
        animate(triangleLayer: needleLayer!, fromValue: currentRadians!, toValue: radians, duration: timeInterval, callBack: {
            self.currentRadians = radians
        })
    }
    
    func animate(triangleLayer: CAShapeLayer, fromValue: CGFloat, toValue:CGFloat, duration: CFTimeInterval, callBack:@escaping ()->Void) {
        CATransaction.begin()
        let spinAnimation1 = CABasicAnimation(keyPath: "transform.rotation.z")
        spinAnimation1.fromValue = fromValue
        spinAnimation1.toValue = toValue
        spinAnimation1.duration = duration
        spinAnimation1.fillMode = CAMediaTimingFillMode.forwards
        spinAnimation1.isRemovedOnCompletion = false
        
        CATransaction.setCompletionBlock {
            callBack()
        }
        
        triangleLayer.add(spinAnimation1, forKey: "indeterminateAnimation")
        CATransaction.commit()
    }
}
