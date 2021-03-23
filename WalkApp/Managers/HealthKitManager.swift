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
                    let authorizationStatus = self.healthStore.authorizationStatus(for: stepType)
                    
                    if authorizationStatus == .notDetermined {
                        print("notDetermined")
                        completion(false)
                    } else if authorizationStatus == .sharingDenied {
                        print("sharingDenied")
                        completion(false)
                    } else if authorizationStatus == .sharingAuthorized {
                        print("sharingAuthorized")
                        completion(true)
                    }else {
                        completion(false)
                    }
                }else {
                    completion(false)
                }
            }
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
        print("startDay : \(startDay) / lastDay : \(lastDay)")
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: lastDay, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                completion(0.0)
                return
            }
            
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        self.healthStore.execute(query)
    }
    
    func startUpdate(date:Date, completion: @escaping (Double) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query: HKObserverQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] (query, completionHandler, error) in
            if let err = error {
                print("error : \(err)")
                return
            }
            if let strongSelf = self {
                strongSelf.readStepCount(date: date, completion: { (step) in
                    completionHandler()
                })
            }
            
        }
        self.healthStore.execute(query)
        self.healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { (bool, error) in
            
        }
 
        
    }
    
    //    func sendNotification(title:String, body:String) {
    //        let notificationContent = UNMutableNotificationContent()
    //        notificationContent.title = title
    //        notificationContent.body = body
    //        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    //        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
    //        userNotificationCenter.add(request) { (error) in
    //            if let error = error {
    //                print("Notification Error: \(error)")
    //                return
    //            }
    //        }
    //    }
    
    
    
}
