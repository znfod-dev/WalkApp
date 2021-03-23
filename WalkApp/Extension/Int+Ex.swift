//
//  Int+Ex.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/12.
//

import Foundation

extension Int {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}
