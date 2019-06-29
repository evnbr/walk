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

let kLastStepCount = "CACHED_STEP_COUNT"

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

class TodayViewController: UIViewController, NCWidgetProviding {
    
    var stepCount: EFCountingLabel!
    var pedometer: CMPedometer?
    
    var isFirstLoad = true


    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstLoad = true
//        view.backgroundColor = .black

        stepCount = EFCountingLabel()
        stepCount.method = .easeInOut
        stepCount.animationDuration = 0.1
        stepCount.format = "%d"
        stepCount.formatBlock = { num in
            return Int(num).formattedWithSeparator
        }
        stepCount.translatesAutoresizingMaskIntoConstraints = false
        if let lastCount = UserDefaults.standard.object(forKey: kLastStepCount) as? Int {
            stepCount.countFrom(
                CGFloat(lastCount),
                to: CGFloat(lastCount),
                withDuration: 0
            )
        } else {
            stepCount.text = "0"
        }

        stepCount.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .medium)
        stepCount.textColor = UIColor.label
        stepCount.alpha = 0.5
        stepCount.sizeToFit()
        view.addSubview(stepCount)
        
        stepCount.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16).isActive = true
        stepCount.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        
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
        guard var thisMorning: Date = Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            return
        }
        if thisMorning > now { thisMorning = thisMorning - day }

        pedometer?.startUpdates(from: thisMorning, withHandler: { (data, error) in
            DispatchQueue.main.async {
                self.updateDisplay(data, error)
            }
        })
    }
    
    func constrain(_ value: CGFloat, from minVal: CGFloat, to maxVal: CGFloat) -> CGFloat {
        return max(minVal, min(maxVal, value))
    }
    
    func updateDisplay(_ data: CMPedometerData?, _ error: Error?) {
        if (error != nil) {
            self.stepCount.text = "???"
        }
        if let data = data {
            let newVal = data.numberOfSteps.intValue
            UserDefaults.standard.set(newVal, forKey: kLastStepCount)
            
            stepCount.alpha = 1
            self.stepCount.countFromCurrentValueTo(CGFloat(newVal))

            isFirstLoad = false
        }
    }
    
    func loadStepCount(completionHandler: @escaping (Bool) -> Void = { _ in } ) {
        
        let now : Date = Date()
        guard var thisMorning : Date = Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            return
        }
        if thisMorning > now {
            // it's between midnight and 5am, show yesterday
            thisMorning = thisMorning - day
        }
        
        pedometer?.queryPedometerData(from: thisMorning, to: now, withHandler: { (data, error) in
            DispatchQueue.main.async {
                self.updateDisplay(data, error)
                completionHandler((data != nil))
            }
        })
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
}
