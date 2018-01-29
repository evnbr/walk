//
//  ViewController.swift
//  walk
//
//  Created by Evan Brooks on 1/27/18.
//  Copyright © 2018 Evan Brooks. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    var stepCount: EFCountingLabel!
    var pedometer: CMPedometer?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = .black
        
        stepCount = EFCountingLabel()
        stepCount.method = .easeInOut
        stepCount.animationDuration = 0.4
        stepCount.format = "%d"
        stepCount.translatesAutoresizingMaskIntoConstraints = false
        stepCount.text = "..."
        stepCount.font = UIFont.systemFont(ofSize: 48, weight: .light)
        stepCount.textColor = .white
        stepCount.sizeToFit()

        view.addSubview(stepCount)
        stepCount.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stepCount.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16).isActive = true
        
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
    
    func updateDisplay(_ data: CMPedometerData?, _ error: Error?) {
        DispatchQueue.main.async {
            if (error != nil) {
                self.stepCount.text = "Couldn't access"
            }
            if let data = data {
                //                let pct = data.numberOfSteps.floatValue / 10000
                //                    self.stepCount.text = "\(Int(pct * 100))%"
                //                self.stepCount.text = "\((10000 - data.numberOfSteps.intValue).formattedWithSeparator)"
                //                self.stepCount.text = "\(data.numberOfSteps.intValue.formattedWithSeparator)"
                
                let newVal = CGFloat(10000 - data.numberOfSteps.intValue)
                if (self.stepCount.currentValue().isZero) {
                    self.stepCount.countFrom(newVal, to: newVal)
                }
                else {
                    self.stepCount.countFromCurrentValueTo(newVal)
                }
            }
        }
    }
    
    func loadStepCount(completionHandler: @escaping (Bool) -> Void = { _ in } ) {
        
        let now : Date = Date()
        guard let thisMorning : Date = Calendar.current.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            self.stepCount.text = "Couldn't set morning"
            return
        }
        
        stepCount.text = "Loading..."
        pedometer?.queryPedometerData(from: thisMorning, to: now, withHandler: { (data, error) in
            self.updateDisplay(data, error)
            completionHandler((data != nil))
        })
    }

}

