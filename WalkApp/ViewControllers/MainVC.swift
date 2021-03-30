//
//  MainVC.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/12.
//

import UIKit
import HealthKit
import CoreMotion

class MainVC: UIViewController {
    
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var stepCntLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataSource: UICollectionViewDiffableDataSource<MonthItem, DataItem>!
    
    // MARK: Model objects
    var months = Array<MonthItem>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        
        self.getData()
    }
    
    func initUI() {
        self.dateLbl.text = Date().toString(format: .custom("yyyy년 MM월 dd일 : "))
        self.stepCntLbl.text = "0"
        self.initCollectionView()
    
    }
    
    func initNoti() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.dateChanged(_:)), name: .NSCalendarDayChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.todayStepChanged(_:)), name: .TodayStepChanged, object: nil)
    }
    
    func getData() {
        SingletonManager.shared.checkAuthorization()
        NotificationCenter.default.addObserver(self, selector: #selector(self.motionAuthChanged(_:)), name: .MotionAuthChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.healthkitAuthChanged(_:)), name: .HealthkitAuthChanged, object: nil)
        
//        HealthKitManager.shared.requestAuthorization { (success) in
//            if success {
//                HealthKitManager.shared.readAllStepCount(last: 365) { (list) in
//                    self.months = self.sortByMonth(dayList: list)
//                    DispatchQueue.main.async {
//                        self.applySnapshot()
//                        self.collectionView.reloadData()
//                    }
//                }
//            }else {
//
//            }
//        }
    }
    
    @objc func dateChanged(_ notification:Notification) {
        MotionManager.shared.stopCountingSteps()
        
    }
    
    @objc func todayStepChanged(_ notification:Notification) {
        
        DispatchQueue.main.async {
            self.stepCntLbl.text = Int(SingletonManager.shared.todayStep).withCommas()
        }
    }
    
    
    @objc func motionAuthChanged(_ notification:Notification) {
        
    }
    @objc func healthkitAuthChanged(_ notification:Notification) {
        
    }
    
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
    
    @IBAction func addData(_ sender:UIButton) {
        self.applySnapshot()
        self.collectionView.reloadData()
    }
    
}

// MARK: - UICollectionView
extension MainVC {
    func initCollectionView() {
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        // MARK: Create list layout
        var layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        layoutConfig.headerMode = .firstItemInSection
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        
        // MARK: Configure collection view
        collectionView.collectionViewLayout = listLayout
        collectionView.allowsSelection = false
        
        // MARK: Cell registration
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MonthItem> {
            (cell, indexPath, month) in
            
            // Set parent's title to header cell
            var content = cell.defaultContentConfiguration()
            content.text = "\(month.date.toString(format: .custom("yyyy년 MM월")))"
            cell.contentConfiguration = content
            
            let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
        }
        
        let childCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DayItem> {
            (cell, indexPath, child) in
            
            // Set child title to cell
            var content = cell.defaultContentConfiguration()
            content.text = "\(child.date.toString(format: .custom("yyyy.MM.dd"))) : \(child.step)"
            cell.contentConfiguration = content
        }
        
        // MARK: Initialize data source
        dataSource = UICollectionViewDiffableDataSource<MonthItem, DataItem>(collectionView: collectionView) {
            (collectionView, indexPath, listItem) -> UICollectionViewCell? in
            switch listItem {
            case .month(let parent):
                // Dequeue header cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                        for: indexPath,
                                                                        item: parent)
                return cell
                
            case .day(let child):
                // Dequeue cell
                let cell = collectionView.dequeueConfiguredReusableCell(using: childCellRegistration,
                                                                        for: indexPath,
                                                                        item: child)
                return cell
            }
        }
        self.applySnapshot()
        
    }
    func applySnapshot(animationDifferences: Bool = true) {
        // Loop through each parent items to create a section snapshots.
        for parent in months {
            
            // Create a section snapshot
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<DataItem>()
            
            // Create a parent DataItem & append as parent
            let parentDataItem = DataItem.month(parent)
            sectionSnapshot.append([parentDataItem])
            
            // Create an array of child items & append as children of parentDataItem
            let childDataItemArray = parent.days.map { DataItem.day($0) }
            sectionSnapshot.append(childDataItemArray, to: parentDataItem)
            
            // Expand this section by default
            sectionSnapshot.expand([parentDataItem])
            
            // Apply section snapshot to the respective collection view section
            dataSource.apply(sectionSnapshot, to: parent, animatingDifferences: animationDifferences)
        }
        
    }
}
