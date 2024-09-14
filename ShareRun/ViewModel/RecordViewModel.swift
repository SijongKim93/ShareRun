//
//  RecordViewModel.swift
//  ShareRun
//
//  Created by 김시종 on 8/29/24.
//

import Foundation
import RxSwift
import RxCocoa

class RecordViewModel {
    
    let selectedSegment = BehaviorRelay<Int>(value: 0)
    
    lazy var averageDistance: Driver<String> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<Double> in
                guard let self = self else { return .just(0.0) }
                return self.calculateAverageDistance(for: segment)
            }
            .map { "\($0)" }
            .asDriver(onErrorJustReturn: "0.00")
    }()
    
    lazy var averageDuration: Driver<String> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<TimeInterval> in
                guard let self = self else { return .just(0.0) }
                return self.calculateAverageDuration(for: segment)
            }
            .map { timeInterval in
                let minutes = Int(timeInterval) / 60
                let seconds = Int(timeInterval) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .asDriver(onErrorJustReturn: "00:00")
    }()
    
    lazy var averagePace: Driver<String> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<Double> in
                guard let self = self else { return .just(0.0) }
                return self.calculateAveragePace(for: segment)
            }
            .map { pace in
                let minutes = Int(pace) / 60
                let seconds = Int(pace) % 60
                return String(format: "%02d:%02d min/km", minutes, seconds)
            }
            .asDriver(onErrorJustReturn: "00:00 min/km")
    }()
    
    lazy var averageBPM: Driver<String> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<Int> in
                guard let self = self else { return .just(0) }
                return self.calculateAverageBPM(for: segment)
            }
            .map { "\($0) BPM" }
            .asDriver(onErrorJustReturn: "--- BPM")
    }()
    
    lazy var chartData: Driver<[ChartData]> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<[ChartData]> in
                guard let self = self else { return .just([]) }
                return self.calculateChartData(for: segment)
            }
            .asDriver(onErrorJustReturn: [])
    }()
    
    private let runningSessions: [RunningSession]
    private let disposeBag = DisposeBag()
    
    init() {
        // Week에 해당하는 더미 데이터 설정
        let session1 = RunningSession(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                                      distance: 5.0, duration: 1800)
        let session2 = RunningSession(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                                      distance: 7.2, duration: 2400)
        let session3 = RunningSession(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                                      distance: 0.0, duration: 0.0)
        
        self.runningSessions = [session1, session2, session3]
    }
    
    private func calculateAverageDistance(for segment: Int) -> Observable<Double> {
        let filteredSessions = filterSessions(for: segment)
        let totalDistance = filteredSessions.reduce(0) { $0 + $1.distance.value }
        return Observable.just(filteredSessions.isEmpty ? 0.0 : totalDistance / Double(filteredSessions.count))
    }
    
    private func calculateAverageDuration(for segment: Int) -> Observable<TimeInterval> {
        let filteredSessions = filterSessions(for: segment)
        let totalDuration = filteredSessions.reduce(0.0) { $0 + TimeInterval($1.duration.value) }
        return Observable.just(filteredSessions.isEmpty ? 0.0 : totalDuration / Double(filteredSessions.count))
    }
    
    private func calculateAveragePace(for segment: Int) -> Observable<Double> {
        let filteredSessions = filterSessions(for: segment)
        let totalDistance = filteredSessions.reduce(0) { $0 + $1.distance.value }
        let totalDuration = filteredSessions.reduce(0) { $0 + $1.duration.value }
        return Observable.just(totalDistance > 0 ? totalDuration / totalDistance : 0.0)
    }
    
    private func calculateAverageBPM(for segment: Int) -> Observable<Int> {
        return Observable.just(120)
    }
    
    private func calculateChartData(for segment: Int) -> Observable<[ChartData]> {
        var groupedData: [String: Double] = [:]
        
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        
        
        for weekday in weekdaySymbols {
            groupedData[weekday] = 0.0
        }
        
        let filteredSessions = filterSessions(for: segment)
        
        for session in filteredSessions {
            let weekday = calendar.component(.weekday, from: session.date) - 1
            let key = weekdaySymbols[weekday]
            groupedData[key, default: 0.0] += session.distance.value
        }
        
        let chartData = weekdaySymbols.map { ChartData(value: groupedData[$0] ?? 0.0, label: $0) }
        return Observable.just(chartData)
    }
    
    
    private func filterSessions(for segment: Int) -> [RunningSession] {
        let calendar = Calendar.current
        let now = Date()
        
        switch segment {
        case 0: // 주별
            return runningSessions.filter { session in
                calendar.isDate(session.date, equalTo: now, toGranularity: .weekOfYear)
            }
        case 1: // 월별
            return runningSessions.filter { session in
                calendar.isDate(session.date, equalTo: now, toGranularity: .month)
            }
        case 2:
            return runningSessions
        default:
            return []
        }
    }
}
