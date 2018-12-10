//
//  NSObject+Trottled.swift
//  iLog
//
//  Created by Leone Parise on 09/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import UIKit

extension NSObject {
    func performTrottled(label:String, delay: TimeInterval, function: @escaping (() -> Void)) {
        let object = LabeledFunction(label: label, function: function)
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performCosure), object: object)
        self.perform(#selector(performCosure), with: object, afterDelay: delay)
    }
}

fileprivate extension NSObject {
    @objc func performCosure(_ closure: LabeledFunction) {
        closure.function()
    }
}

fileprivate class LabeledFunction: NSObject {
    let function: (() -> Void)
    let label: String
    
    init(label:String, function: @escaping (() -> Void)) {
        self.function = function
        self.label = label
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let right = object as? LabeledFunction else { return false }
        return self.label == right.label
    }
}
