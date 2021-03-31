//
//  NSNotification.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/30.
//

import Foundation

public extension NSNotification.Name {
    
    static let TodayStepChanged: NSNotification.Name = NSNotification.Name("TodayStepChanged")
    static let MotionAuthChanged: NSNotification.Name = NSNotification.Name("MotionAuthChanged")
    static let HealthkitAuthChanged: NSNotification.Name = NSNotification.Name("HealthkitAuthChanged")
    
    
}
