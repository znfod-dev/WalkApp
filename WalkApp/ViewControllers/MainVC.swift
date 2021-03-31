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
    @IBOutlet weak var stepCntLbl: NumericAnimatedLabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataSource: UICollectionViewDiffableDataSource<MonthItem, DataItem>!
    
    // MARK: Model objects
    var months = Array<MonthItem>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.initNoti()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func initUI() {
        self.dateLbl.text = Date().toString(format: .custom("yyyy년 MM월 dd일 : "))
        self.stepCntLbl.text = "0"
        self.initCollectionView()
        
    }
    
    func initNoti() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.todayStepChanged(_:)), name: .TodayStepChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.motionAuthChanged(_:)), name: .MotionAuthChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.healthkitAuthChanged(_:)), name: .HealthkitAuthChanged, object: nil)
    }
    
    @objc func todayStepChanged(_ notification:Notification) {
        DispatchQueue.main.async {
            self.stepCntLbl.updateCurrentValue(value: Int(SingletonManager.shared.todayStep))
        }
    }
    
    
    @objc func motionAuthChanged(_ notification:Notification) {
        let auth = SingletonManager.shared.motionAuth
        
        if auth() {
            MotionManager.shared.startCountingSteps()
        }else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "걸음 데이터에 접근이 거부되었습니다", message: "정확한 데이터 추적을 위해 접근을 허용해주세요\n확인을 누르시면 '설정'으로 이동합니다", preferredStyle: .alert)
                let action = UIAlertAction(title: "확인", style: .default) { (action) in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func healthkitAuthChanged(_ notification:Notification) {
        print("healthkitAuthChanged")
        let auth = SingletonManager.shared.healthkitAuth
        if auth() {
            HealthKitManager.shared.getTodayStepCount { (step) in
                SingletonManager.shared.todayStep = step
            }
            HealthKitManager.shared.readAllStepCount(last: 365) { (list) in
                self.months = self.sortByMonth(dayList: list)
                self.reloadCollectionView()
            }
        }else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "걸음 데이터에 접근이 거부되었습니다", message: "정확한 데이터 추적을 위해 접근을 허용해주세요\n확인을 누르시면 '건강'앱으로 이동합니다", preferredStyle: .alert)
                let action = UIAlertAction(title: "확인", style: .default) { (action) in
                    UIApplication.shared.open(URL(string: "x-apple-health://")!)
                }
                let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        }
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
        self.reloadCollectionView()
    }
    
    func reloadCollectionView() {
        DispatchQueue.main.async {
            self.applySnapshot()
            self.collectionView.reloadData()
        }
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
