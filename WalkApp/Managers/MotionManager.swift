//
//  MotionManager.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/12.
//

import UIKit
import CoreMotion
import HealthKit
import UIKit

protocol MotionManagerDelegate {
    func walkCount(type:String,walk:String)
}


class MotionManager: NSObject {
    
    static let shared = MotionManager()
    
    private let activityManager = CMMotionActivityManager()
    
    private let pedometer = CMPedometer()
    
    var motionQueue = DispatchQueue.init(label: "Motion")
    
    var isStepCountingAvailable : Bool{
        get{
            return CMPedometer.isStepCountingAvailable()
        }
    }
    var isUpdating:Bool = false
    
    override init() {
        super.init()
        
    }
    
    // 권한 요청
    func requestAuth(success: @escaping(_ status: CMAuthorizationStatus)-> Void) {
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined:
            print("아직 정하지 못함")
            //
            if CMMotionActivityManager.isActivityAvailable() {
                self.activityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { (list, error) in
                    switch CMMotionActivityManager.authorizationStatus() {
                    case .authorized:
                        print("권한 확인됨")
                        success(.authorized)
                        break
                    default:
                        success(CMMotionActivityManager.authorizationStatus())
                        break
                    }
                }
                
            }
            
            break
        case .restricted:
            print("잠김")
            success(.restricted)
            break
        case .authorized:
            print("권한 확인됨")
            if CMMotionActivityManager.isActivityAvailable() {
                self.activityManager.startActivityUpdates(to: .main) { _ in
                }
                success(.authorized)
            }
            break
        case .denied:
            print("거절")
            success(.denied)
            break
        default:
            break
        }
    }
    
    func getAuthorizationStatus() -> Bool{
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    func queryCountingSteps(startDay:Date, lastDay:Date, success:@escaping (_ step:Double) -> Void) {
        let from = startDay
        let to = lastDay
        self.pedometer.queryPedometerData(from: from, to: to) { (value, error) in
            if let pedData = value{
                let step = pedData.numberOfSteps.doubleValue
                success(step)
            } else {
                success(0)
            }
        }
    }
    
    func startCountingSteps() {
        self.startCountingSteps { (step) in
            SingletonManager.shared.addStep = step
        }
    }
    
    private func startCountingSteps( completion: @escaping (Double) -> Void) {
        self.pedometer.startUpdates(from: Date()) { (data, error) in
            guard let data = data else {
                return
            }
            let step = data.numberOfSteps.doubleValue
            SingletonManager.shared.addStep = step
            completion(step)
        }
    }
    
    func stopCountingSteps() {
        self.pedometer.stopUpdates()
    }
    
    
}
