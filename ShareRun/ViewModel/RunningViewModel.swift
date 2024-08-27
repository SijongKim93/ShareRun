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

enum SessionState {
    case stopped
    case running
    case paused
}

class RunningViewModel {
    private let disposeBag = DisposeBag()
    private let runningManager: RunningManager
    
    
    // Input
    let startStopTrigger = PublishRelay<Void>()
    let pauseResumeTrigger = PublishRelay<Void>()
    let locationUpdate = PublishRelay<CLLocation>()
    
    // Output
    let distance: Driver<String>
    lazy var duration: Driver<String> = {
        return Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { _ in
                let minutes = Int(self.durationTime) / 60
                let seconds = Int(self.durationTime) % 60
                return String(format: "%02d분 %02d초", minutes, seconds)
            }
            .asDriver(onErrorJustReturn: "00분 00초")
    }()
    let sessionState: Driver<SessionState>
    let startStopButtonTitle: Driver<String>
    let pauseResumeButtonTitle: Driver<String>
    let isPauseResumeButtonHidden: Driver<Bool>
    let isStopButtonHidden: Driver<Bool>
    
    private let sessionStateRelay = BehaviorRelay<SessionState>(value: .stopped)
    private var timer: Timer?
    private var durationTime: TimeInterval = 0
    
    init(runningManager: RunningManager = .shared) {
        self.runningManager = runningManager
        
        sessionState = sessionStateRelay.asDriver()
        
        distance = runningManager.currentSession
            .compactMap { $0?.distance }
            .flatMap { $0.asObservable() }
            .map { String(format: "%.2f", $0) }
            .asDriver(onErrorJustReturn: "0.00")
            .startWith("0.00")
        
        startStopButtonTitle = sessionStateRelay.map { state in
            state == .stopped ? "Start" : "Stop"
        }.asDriver(onErrorJustReturn: "Start")
        
        pauseResumeButtonTitle = sessionStateRelay.map { state in
            state == .paused ? "Resume" : "Pause"
        }.asDriver(onErrorJustReturn: "Pause")
        
        isPauseResumeButtonHidden = sessionStateRelay.map { $0 == .stopped }
            .asDriver(onErrorJustReturn: true)
        
        isStopButtonHidden = sessionStateRelay.map { $0 == .stopped }
            .asDriver(onErrorJustReturn: true)
        
        setupBindings()
    }
    
    private func setupBindings() {
        startStopTrigger
            .withLatestFrom(sessionStateRelay)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                if state == .stopped {
                    self.startSession()
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
}
