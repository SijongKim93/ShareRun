//
//  RunningViewModel.swift
//  ShareRun
//
//  Created by 김시종 on 8/25/24.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import HealthKit
import AVFoundation


enum SessionState {
    case stopped
    case running
    case paused
}

class RunningViewModel {
    private let disposeBag = DisposeBag()
    private let runningManager: RunningManager
    private let healthStore = HKHealthStore()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Input
    let startStopTrigger = PublishRelay<Void>()
    let pauseResumeTrigger = PublishRelay<Void>()
    let locationUpdate = PublishRelay<CLLocation>()
    
    // Output
    let distance: Driver<String>
    let countdownText = BehaviorRelay<String?>(value: nil)
    let showCountdown = PublishRelay<Bool>()
    let bpm: Driver<String>
    
    lazy var pace: Driver<String> = {
        return self.runningManager.currentSession
            .compactMap { $0?.distance }
            .flatMap { $0.asObservable() }
            .map { [weak self] distance in
                guard let self = self else { return "00:00" }
                guard distance > 0 else { return "00:00" }
                let paceTime = (self.durationTime / distance) * 1000
                let minutes = Int(paceTime) / 60
                let seconds = Int(paceTime) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .startWith("00:00")
            .asDriver(onErrorJustReturn: "00:00")
    }()
    lazy var duration: Driver<String> = {
        return Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak self] _ in
                guard let self = self else { return "00:00" }
                let minutes = Int(self.durationTime) / 60
                let seconds = Int(self.durationTime) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .startWith("00:00")
            .asDriver(onErrorJustReturn: "00:00")
    }()
    let sessionState: Driver<SessionState>
    let sessionStateRelay = BehaviorRelay<SessionState>(value: .stopped)
    
    private var timer: Timer?
    private var durationTime: TimeInterval = 0
    private var heartRateQuery: HKQuery?
    private let bpmRelay = BehaviorRelay<String>(value: "---")

    init(runningManager: RunningManager = .shared) {
        self.runningManager = runningManager
        
        sessionState = sessionStateRelay.asDriver()

        distance = runningManager.currentSession
            .compactMap { $0?.distance }
            .flatMap { $0.asObservable() }
            .map { String(format: "%.2f", $0) }
            .startWith("0.00")
            .asDriver(onErrorJustReturn: "0.00")
        
        bpm = bpmRelay.asDriver(onErrorJustReturn: "---")
        
        setupBindings()
        requestHealthKitAuthorization()
    }

    private func setupBindings() {
        startStopTrigger
            .withLatestFrom(sessionStateRelay)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                if state == .stopped {
                    self.startCountdown()
                } else {
                    self.stopSession()
                }
            })
            .disposed(by: disposeBag)

        pauseResumeTrigger
            .withLatestFrom(sessionStateRelay)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                if state == .running {
                    self.pauseSession()
                } else if state == .paused {
                    self.resumeSession()
                }
            })
            .disposed(by: disposeBag)

        locationUpdate
            .withLatestFrom(sessionStateRelay) { ($0, $1) }
            .filter { _, state in state == .running }
            .map { location, _ in location }
            .subscribe(onNext: { [weak self] location in
                self?.runningManager.updateCurrentSession(newLocation: location)
            })
            .disposed(by: disposeBag)
    }
    
    private func startCountdown() {
        let countdownNumbers = ["3", "2", "1", "GO"]
        var delay: TimeInterval = 0
        
        showCountdown.accept(true)
        
        for number in countdownNumbers {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.countdownText.accept(number)
            }
            delay += 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.speak(text: "Running Start")
            self.startSession()
            self.showCountdown.accept(false)
        }
    }
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    
    private func startSession() {
        runningManager.startNewSession()
        sessionStateRelay.accept(.running)
        startTimer()
    }

    private func pauseSession() {
        sessionStateRelay.accept(.paused)
        stopTimer()
    }

    private func resumeSession() {
        sessionStateRelay.accept(.running)
        startTimer()
    }

    private func stopSession() {
        runningManager.endCurrentSession()
        sessionStateRelay.accept(.stopped)
        stopTimer()
        resetTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.durationTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
    }

    private func resetTimer() {
        durationTime = 0
    }
    
    private func requestHealthKitAuthorization() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.startHeartRateQuery()
            } else {
                print("HealthKit authorization failed.")
            }
        }
    }

    private func startHeartRateQuery() {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        self.heartRateQuery = query
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        let lastSample = samples.last
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let heartRate = lastSample?.quantity.doubleValue(for: heartRateUnit)
        
        if let heartRate = heartRate {
            bpmRelay.accept(String(format: "%.0f", heartRate))
        } else {
            bpmRelay.accept("---")
        }
    }
}
