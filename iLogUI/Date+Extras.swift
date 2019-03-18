//
//  Date+Extras.swift
//  iLog
//
//  Created by Leone Parise on 11/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import UIKit

extension Date {
    func start(of dateComponent : Calendar.Component) -> Date {
        var startOfComponent = self
        var timeInterval: TimeInterval = 0.0
        if Calendar.current.dateInterval(of: dateComponent, start: &startOfComponent, interval: &timeInterval, for: self) {
            return startOfComponent
        } else {
            return self
        }
    }
}
