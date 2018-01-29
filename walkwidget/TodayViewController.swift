//
//  TodayViewController.swift
//  walkwidget
//
//  Created by Evan Brooks on 1/27/18.
//  Copyright © 2018 Evan Brooks. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreMotion


extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension BinaryInteger {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}

extension FloatingPoint {
    var toRadians: Self { return self * .pi / 180 }
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    var stepCount: EFCountingLabel!
    var fill: UIView!
    var pedometer: CMPedometer?
    var divider: UIView!
    var labelCenter: NSLayoutConstraint!
    var dividerCenter: NSLayoutConstraint!
    
    let shapeFill = CAShapeLayer()
    let shapeHighlight = CAShapeLayer()
    let shapeTrack = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
//        view.backgroundColor = UIColor.white.withAlphaComponent(0.28)
//        view.backgroundColor = .black
        
        fill = UIView(frame: view.bounds)
//        fill.backgroundColor = UIColor.black.withAlphaComponent(0.08)
//        view.addSubview(fill)
        
        shapeTrack.path = makePath().cgPath
        shapeTrack.strokeColor = UIColor.black.withAlphaComponent(0.08).cgColor
        shapeTrack.lineWidth = 1
        shapeTrack.fillColor = nil
        shapeTrack.lineCap = kCALineCapRound
        view.layer.addSublayer(shapeTrack)

        shapeFill.path = makePath().cgPath
        shapeFill.strokeColor = UIColor.darkText.cgColor
        shapeFill.lineWidth = 3
        shapeFill.fillColor = nil
        shapeFill.strokeEnd = 0.1
        shapeFill.lineCap = kCALineCapRound
        view.layer.addSublayer(shapeFill)
        
        shapeHighlight.path = makePath().cgPath
        shapeHighlight.strokeColor = UIColor.white.cgColor
        shapeHighlight.lineWidth = 4
        shapeHighlight.fillColor = nil
        shapeHighlight.strokeEnd = 0.1
        shapeHighlight.lineCap = kCALineCapRound
        view.layer.addSublayer(shapeHighlight)

//        divider = UIView(frame: view.bounds)
//        divider.frame.size.width = 1
//        divider.translatesAutoresizingMaskIntoConstraints = false
//
//        let topHalf = UIView(frame: divider.bounds)
//        topHalf.translatesAutoresizingMaskIntoConstraints = false
//        topHalf.backgroundColor = .black
//
//        let bottomHalf = UIView(frame: divider.bounds)
//        bottomHalf.translatesAutoresizingMaskIntoConstraints = false
//        bottomHalf.backgroundColor = .black
//
//        divider.addSubview(topHalf)
//        divider.addSubview(bottomHalf)
//        view.addSubview(divider)

        stepCount = EFCountingLabel()
        stepCount.method = .easeInOut
        stepCount.animationDuration = 0.4
        stepCount.format = "%d"
        stepCount.translatesAutoresizingMaskIntoConstraints = false
        stepCount.text = "..."
        stepCount.font = UIFont.systemFont(ofSize: 40, weight: .semibold)
        stepCount.textColor = UIColor.darkText
        stepCount.sizeToFit()
//        view.addSubview(stepCount)
        
//        divider.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        divider.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
//        dividerCenter = divider.centerXAnchor.constraint(equalTo: view.leftAnchor, constant: 0)
//        dividerCenter.isActive = true
//
//        topHalf.topAnchor.constraint(equalTo: divider.topAnchor).isActive = true
//        topHalf.leftAnchor.constraint(equalTo: divider.leftAnchor).isActive = true
//        topHalf.rightAnchor.constraint(equalTo: divider.rightAnchor).isActive = true
//        topHalf.bottomAnchor.constraint(equalTo: stepCount.topAnchor, constant: -8).isActive = true
//
//        bottomHalf.bottomAnchor.constraint(equalTo: divider.bottomAnchor).isActive = true
//        bottomHalf.leftAnchor.constraint(equalTo: divider.leftAnchor).isActive = true
//        bottomHalf.rightAnchor.constraint(equalTo: divider.rightAnchor).isActive = true
//        bottomHalf.topAnchor.constraint(equalTo: stepCount.bottomAnchor, constant: 8).isActive = true
        
//        stepCount.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -2).isActive = true
//        stepCount.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -28).isActive = true
//        labelCenter = stepCount.centerXAnchor.constraint(equalTo: view.leftAnchor, constant: 0)
//        labelCenter.isActive = true
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer = CMPedometer()
            loadStepCount()
            startUpdates()
        }
        else {
            stepCount.text = "Unavailable"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startUpdates() {
        let now : Date = Date()
        guard var thisMorning : Date = Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            return
        }
        if thisMorning > now { thisMorning = thisMorning - day }

        pedometer?.startUpdates(from: thisMorning, withHandler: { (data, error) in
            self.updateDisplay(data, error)
        })
    }
    
    func constrain(_ value: CGFloat, from minVal: CGFloat, to maxVal: CGFloat) -> CGFloat {
        return max(minVal, min(maxVal, value))
    }
    
    func updateDisplay(_ data: CMPedometerData?, _ error: Error?) {
        DispatchQueue.main.async {
            if (error != nil) {
                self.stepCount.text = "???"
            }
            if let data = data {
                let goal : Float = data.numberOfSteps.floatValue > 10000 ? 15000 : 10000
                let pct : CGFloat = CGFloat(data.numberOfSteps.floatValue / goal)
                let newVal = CGFloat(10000 - data.numberOfSteps.intValue)
                
                if (self.stepCount.currentValue().isZero) {
                    self.stepCount.countFrom(newVal, to: newVal)
                    self.updatePosition(percentComplete: pct)
                }
                else {
                    self.stepCount.countFromCurrentValueTo(newVal)
                    UIView.animate(withDuration: 0.5, animations: {
                        self.updatePosition(percentComplete: pct)
                    })
                }
            }
        }
    }
    
    func updatePosition(percentComplete: CGFloat) {
        let posX = 12 + (percentComplete * (self.view.bounds.width - 24))
//        let minX = self.stepCount.bounds.width / 2
//        let maxX = self.view.bounds.width - minX
//        self.labelCenter.constant = self.constrain(posX, from: minX, to: maxX)
//        self.dividerCenter.constant = posX
//        self.view.layoutIfNeeded()
        shapeFill.strokeEnd = percentComplete
        shapeHighlight.strokeEnd = percentComplete
        shapeHighlight.strokeStart = percentComplete - 0.0001

        fill.frame.size.width = posX
    }
    
    func loadStepCount(completionHandler: @escaping (Bool) -> Void = { _ in } ) {
        
        let now : Date = Date()
        guard var thisMorning : Date = Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            return
        }
        if thisMorning > now { thisMorning = thisMorning - day }
        
        pedometer?.queryPedometerData(from: thisMorning, to: now, withHandler: { (data, error) in
            self.updateDisplay(data, error)
            completionHandler((data != nil))
        })
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        loadStepCount() { done in
            completionHandler(done
                ? NCUpdateResult.newData
                : NCUpdateResult.failed
            )
        }
    }
    
    let pathH : CGFloat = 78
    let radius : CGFloat = 3
    func makePath() -> UIBezierPath {
        let path = UIBezierPath()
        
        let topLeft = CGPoint(x: 12, y: 13)
        path.move(to: topLeft)
        
        var loopPoint = topLeft
        loopPoint.y += radius - 1
        path.addLine(to: loopPoint)
        
        for _ in 0..<28 {
            var down = path.currentPoint
            down.y += pathH
            path.addLine(to: down)
            
            var bottomCenter = down
            bottomCenter.x += radius
            bottomCenter.y += radius

            path.addArc(withCenter: bottomCenter, radius: radius, startAngle: CGFloat(180).toRadians, endAngle: 0, clockwise: false)

            var up = path.currentPoint
            up.y -= pathH
            path.addLine(to: up)

            var topCenter = up
            topCenter.x += radius
            topCenter.y -= radius

            path.addArc(withCenter: topCenter, radius: radius, startAngle: CGFloat(180).toRadians, endAngle: 0, clockwise: true)
        }
        
        var endPoint = path.currentPoint
        endPoint.y += pathH + radius - 1
        path.addLine(to: endPoint)

        
        return path
    }
    
}
