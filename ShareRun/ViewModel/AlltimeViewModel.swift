//
//  AlltimeViewModel.swift
//  ShareRun
//
//  Created by 김시종 on 9/4/24.
//

import Foundation
import RxSwift
import RxCocoa
import HealthKit

class AlltimeViewModel {
    private let healthStore = HKHealthStore()
    let stepsSubject = BehaviorRelay<[String]>(value: [])
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let readDataTypes: Set = [stepType]
        
        healthStore.requestAuthorization(toShare: [], read: readDataTypes) { [weak self] success, error in
            if success {
                print("HealthKit authorization granted.")
                self?.fetchStepData()
            } else {
                print("HealthKit authorization failed with error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    private func fetchStepData() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let self = self, let result = result, let sum = result.sumQuantity() else {
                print("No data found")
                return
            }
            let steps = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                self.stepsSubject.accept(["총 걸음 수 : \(Int(steps))"]) // 데이터 전달
            }
        }
        healthStore.execute(query)
    }
}
