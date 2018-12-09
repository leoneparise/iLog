//
//  String+Extras.swift
//  iLog
//
//  Created by Leone Parise on 09/12/18.
//  Copyright © 2018 com.leoneparise. All rights reserved.
//

import Foundation

extension String {
    func replacingPattern(of pattern:String, with template:String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSMakeRange(0, self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
        } catch {
            return self
        }
    }
}
