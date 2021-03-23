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
    
    var today = Date()
    var todayStepCnt = 0
    var stepCnt = 0
    
    var isUpdating:Bool = false
    
    override init() {
        super.init()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.dateChanged(_:)), name: .NSCalendarDayChanged, object: nil)
        
    }
    
    // 권한 요청
    func requestAuth(success: @escaping(_ status: CMAuthorizationStatus)-> Void) {
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined:
            print("아직 정하지 못함")
            //
            if CMMotionActivityManager.isActivityAvailable() {
//                self.activityManager.startActivityUpdates(to: .main) { _ in
//                    if self.isUpdating == false {
//                        self.startCountingSteps()
//                    }
//                }
                self.activityManager.startActivityUpdates(to: .main) { (activity) in
                    
                }
                success(.authorized)
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
        switch CMPedometer.authorizationStatus() {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    func queryCountingSteps(startDay:Date, lastDay:Date, success:@escaping (_ step:Double) -> Void) {
        print("from : \(startDay) ~ to : \(lastDay))")
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
//        print("startCountingSteps")
        if isUpdating == false {
            self.todayStepCnt = 0
            self.pedometer.startUpdates(from: Date()) { (data, error) in
                guard let data = data else {
                    return
                }
                let value = data.numberOfSteps.intValue - self.stepCnt
//                print("data.numberOfSteps.intValue : \(data.numberOfSteps.intValue)")
//                print("self.stepCnt : \(self.stepCnt)")
                self.addStep(value: value)
                self.stepCnt = data.numberOfSteps.intValue
            }
            self.isUpdating = true
        }
    }
    
    func startCountingSteps( completion: @escaping (Double) -> Void) {
        self.pedometer.startUpdates(from: Date()) { (data, error) in
            guard let data = data else {
                return
            }
            completion(data.numberOfSteps.doubleValue)
        }
    }
    
    func stopCountingSteps() {
//        print("stopCountingSteps")
        if isUpdating {
            self.pedometer.stopUpdates()
            self.isUpdating = false
            
            self.stepCnt = 0
        }
    }
    
    func addStep(value:Int) {
        if isUpdating == true {
            self.todayStepCnt += value
            NotificationCenter.default.post(name: NSNotification.Name("Help"), object: nil, userInfo: [:])
        }else {
            
        }
    }
    
    @objc func dateChanged(_ notification:NSNotification) {
        self.todayStepCnt = 0
        self.today = Date()
        self.addStep(value: 0)
    }
    
}
