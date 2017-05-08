//
//  ViewController.swift
//  iLogExample
//
//  Created by Leone Parise Vieira da Silva on 08/05/17.
//  Copyright © 2017 com.leoneparise. All rights reserved.
//

import UIKit
import iLog

class ViewController: UIViewController {
    private var timer:Timer?
    
    @IBAction func debugAction() {
        log(.debug, "Some debug message. Active only when #DEBUG is true")
    }
    
    @IBAction func infoAction() {
        log(.info, "A info message. Let's try some multiline\nmessage to see\nwhat whe can do...\nsome\nmore\nlines...\n1)\n2)\n3)")
    }
    
    @IBAction func warnAction() {
        log(.warn, "This is a warning message. Something is wrong...")
    }
    
    @IBAction func errorAction() {
        log(.error, "This is a fail message. Something is really bad right now...")
    }
    
    @IBAction func viewLogAction() {
        self.present(LogViewerViewController(), animated: true)
    }
    
    @IBAction func startLogChanged(sender:UISwitch) {
        if sender.isOn {
            timer = Timer.scheduledTimer(timeInterval: 2,
                                         target: self,
                                         selector: #selector(debugAction),
                                         userInfo: nil,
                                         repeats: true)
        } else {
            timer?.invalidate()
        }
    }
}

