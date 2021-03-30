//
//  HealthKitManager.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/22.
//

import UIKit
import HealthKit


// MARK: Identifier Types
struct MonthItem: Hashable {
    let date: Date
    let days: [DayItem]
}

struct DayItem: Hashable {
    let date: Date
    let step: Int
}

enum DataItem: Hashable {
    case month(MonthItem)
    case day(DayItem)
}


class HealthKitManager: NSObject {
    
    static let shared = HealthKitManager()
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    let healthStore = HKHealthStore()
    
    let healthKitTypes:Set = [ HKObjectType.quantityType(forIdentifier: .stepCount)! ]
    
    var authorizationStatus:HKAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        self.healthStore.requestAuthorization(toShare: self.healthKitTypes, read: self.healthKitTypes) { (bool, error) in
            if let e = error {
                print("oops something went wrong during authorization \(e.localizedDescription)")
                completion(false)
            }else {
                print("User has completed the authorization flow")
                if HKHealthStore.isHealthDataAvailable() {
                    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                    self.authorizationStatus = self.healthStore.authorizationStatus(for: stepType)
                    switch self.authorizationStatus {
                    case .notDetermined:
                        print("notDetermined")
                        completion(false)
                    case .sharingDenied:
                        print("sharingDenied")
                        completion(false)
                    case .sharingAuthorized:
                        print("sharingAuthorized")
                        completion(true)
                        break
                     default:
                        print("default")
                        completion(false)
                        break
                    }
                }else {
                    completion(false)
                }
            }
        }
    }
    
    func getAuthorizationStatus() -> Bool{
        switch self.authorizationStatus {
        case .sharingAuthorized:
            return true
        default:
            return false
        }
    }
    
    func readStepCount(last:Int, completion: @escaping ([MonthItem]) -> Void) {
        self.readAllStepCount(last: 365) { (list) in
            completion(self.sortByMonth(dayList: list))
        }
    }
    
    func readAllStepCount(last:Int, completion: @escaping ([DayItem]) -> Void) {
        var list = [DayItem]()
        for i in 0..<last {
            let timeInterval:TimeInterval = (-1 * 60 * 60 * 24) * Double(i)
            let date = Date().addingTimeInterval(timeInterval)
            self.readStepCount(date:date) { (step) in
                list.append(DayItem(date: date, step: Int(step)))
                if list.count == last {
                    completion(list)
                }
            }
        }
    }
    
    /*
     월별로 Sorting
     */
    func sortByMonth(dayList:[DayItem]) -> [MonthItem]{
        let months = dayList.compactMap { Calendar.current.dateComponents([.month, .year], from: $0.date) }
        let monthsSet:Set = Set(months)
        var monthResult = [MonthItem]()
        for month in monthsSet {
            var dayResult = [DayItem]()
            for dayItem in dayList {
                if Calendar.current.dateComponents([.month, .year], from: dayItem.date) == month {
                    dayResult.append(dayItem)
                }
            }
            dayResult = dayResult.sorted(by: { $0.date > $1.date })
            monthResult.append(MonthItem(date: dayResult.first!.date, days: dayResult))
        }
        monthResult = monthResult.sorted(by: { $0.date > $1.date })
        return monthResult
    }
    
    func readStepCount(date:Date, completion: @escaping (Double) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startDay = Calendar.current.startOfDay(for: date)
        let lastDay = Date(timeInterval: (60 * 60 * 24)-1, since: startDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: lastDay, options: [.strictStartDate, .strictEndDate])
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: [.mostRecent, .cumulativeSum, .duration]) { (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                completion(0.0)
                return
            }
            
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        self.healthStore.execute(query)
    }
    
    func getTodayStepCount(completion: @escaping (Double) -> Void) {
        self.readStepCount(date: Date()) { (step) in
            SingletonManager.shared.todayStep = 0.0
            completion(step)
        }
    }
    
    
}
