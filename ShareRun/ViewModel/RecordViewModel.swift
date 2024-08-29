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
    
    // Input
    let selectedSegment = BehaviorRelay<Int>(value: 0)
    
    // Output
    lazy var averageDistance: Driver<String> = {
        return self.selectedSegment
            .flatMapLatest { [weak self] segment -> Observable<Double> in
                guard let self = self else { return .just(0.0) }
                return self.calculateAverageDistance(for: segment)
            }
            .map { "\($0) KM" }
            .asDriver(onErrorJustReturn: "0.00 KM")
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
    
    init(runningSessions: [RunningSession] = []) {
        // 여기에서 초기값을 설정합니다.
        if runningSessions.isEmpty {
            let session1 = RunningSession(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, distance: 5.0, duration: 1800)
            let session2 = RunningSession(date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!, distance: 7.2, duration: 2400)
            let session3 = RunningSession(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, distance: 10.5, duration: 3600)
            
            self.runningSessions = [session1, session2, session3]
        } else {
            self.runningSessions = runningSessions
        }
    }
    
    private func calculateAverageDistance(for segment: Int) -> Observable<Double> {
        let filteredSessions = filterSessions(for: segment)
        let totalDistance = filteredSessions.reduce(0) { $0 + $1.distance.value }
        return Observable.just(filteredSessions.isEmpty ? 0.0 : totalDistance / Double(filteredSessions.count))
    }
    
    private func calculateAverageDuration(for segment: Int) -> Observable<TimeInterval> {
        let filteredSessions = filterSessions(for: segment)
        let totalDuration = filteredSessions.reduce(0) { $0 + $1.duration.value }
        return Observable.just(filteredSessions.isEmpty ? 0.0 : totalDuration / Double(filteredSessions.count))
    }
    
    private func calculateAveragePace(for segment: Int) -> Observable<Double> {
        let filteredSessions = filterSessions(for: segment)
        let totalDistance = filteredSessions.reduce(0) { $0 + $1.distance.value }
        let totalDuration = filteredSessions.reduce(0) { $0 + $1.duration.value }
        return Observable.just(totalDistance > 0 ? totalDuration / totalDistance : 0.0)
    }
    
    private func calculateAverageBPM(for segment: Int) -> Observable<Int> {
        // BPM 데이터가 RunningSession에 추가되어 있다고 가정
        return Observable.just(120) // 예시로 120 BPM 반환
    }
    
    private func calculateChartData(for segment: Int) -> Observable<[ChartData]> {
        let filteredSessions = filterSessions(for: segment)
        var groupedData: [String: Double] = [:]
        
        let calendar = Calendar.current
        for session in filteredSessions {
            let key: String
            switch segment {
            case 0:
                key = calendar.weekdaySymbols[calendar.component(.weekday, from: session.date) - 1]
            case 1:
                key = String(calendar.component(.day, from: session.date    ))
            case 2:
                key = calendar.monthSymbols[calendar.component(.month, from: session.date) - 1]
            default:
                key = ""
            }
            
            groupedData[key, default: 0.0] += session.distance.value
        }
        
        let chartData = groupedData.map { ChartData(value: $0.value, label: $0.key) }
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
        case 2: // 전체
            return runningSessions
        default:
            return []
        }
    }
}
