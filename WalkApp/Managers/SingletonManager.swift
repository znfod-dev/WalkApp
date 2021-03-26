//
//  SingletonManager.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/25.
//

import UIKit

class SingletonManager: NSObject {

    static let shared = SingletonManager()
    
    var todayStep:Double = 0.0
    
    var addStep: Double = 0 {
        willSet(newVal) {
            self.todayStep -= addStep
            self.todayStep += newVal
        }
    }
    
    override init() {
        super.init()
    
    }
    
    
}
