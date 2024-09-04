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
        fetchStepData()
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
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        
        var interval = DateComponents()
        interval.day = 1
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startDate, intervalComponents: interval)
        
        query.initialResultsHandler = { [weak self] _, results, error in
            guard let self = self, let results = results else {
                print("Error fetching steps: \(String(describing: error))")
                return
            }
            
            var stepsData: [String] = []
            
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: statistics.startDate)
                    stepsData.append("\(dateString): \(steps) 걸음")
                }
            }
            self.stepsSubject.accept(stepsData)
        }
        healthStore.execute(query)
    }
}
