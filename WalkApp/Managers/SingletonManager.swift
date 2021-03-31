//
//  SingletonManager.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/25.
//

import UIKit

class SingletonManager: NSObject {
    
    lazy var motionAuth = {
        return MotionManager.shared.getAuthorizationStatus()
    }
    lazy var healthkitAuth = {
        return HealthKitManager.shared.getAuthorizationStatus()
    }
    
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
    func checkAuthorization() {
        MotionManager.shared.requestAuth { (status) in
            print("MotionManager : \(status)")
            NotificationCenter.default.post(name: .MotionAuthChanged, object: nil)
            switch status {
            case .authorized:
                print("authorized")
                break
            case .denied:
                print("denied")
                break
            case .notDetermined:
                print("notDetermined")
                break
            case .restricted:
                print("restricted")
                break
            default:
                break
            }
        }
        HealthKitManager.shared.requestAuthorization { (bool) in
            print("HealthKitManager : \(bool)")
            NotificationCenter.default.post(name: .HealthkitAuthChanged, object: nil)
            if bool {
                
            }else {
                
            }
        }
    }
    
    func startCountingStep() {
        HealthKitManager.shared.getTodayStepCount { (step) in
            self.todayStep = step
            MotionManager.shared.startCountingSteps { (step) in
                print("step : \(step)")
                self.addStep = step
            }
        }
    }
    
}
