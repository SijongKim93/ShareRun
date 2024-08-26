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
    let duration: Driver<String>
    let sessionState: Driver<SessionState>
    let startStopButtonTitle: Driver<String>
    let pauseResumeButtonTitle: Driver<String>
    let isPauseResumeButtonHidden: Driver<Bool>
    let isStopButtonHidden: Driver<Bool>
    
    private let sessionStateRelay = BehaviorRelay<SessionState>(value: .stopped)
    
    init(runningManager: RunningManager = .shared) {
        self.runningManager = runningManager
        
        sessionState = sessionStateRelay.asDriver()
        
        distance = runningManager.currentSession
            .compactMap { $0?.distance }
            .flatMap { $0.asObservable() }
            .map { String(format: "%.2f km", $0) }
            .asDriver(onErrorJustReturn: "0.00 km")
        
        duration = runningManager.currentSession
            .compactMap { $0?.duration }
            .flatMap { $0.asObservable() }
            .map { duration in
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                return String(format: "%02d분 %02d초", minutes, seconds)
            }
            .asDriver(onErrorJustReturn: "00분 00초")
        
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
    }
    
    private func pauseSession() {
        sessionStateRelay.accept(.paused)
    }
    
    private func resumeSession() {
        sessionStateRelay.accept(.running)
    }
    
    private func stopSession() {
        runningManager.endCurrentSession()
        sessionStateRelay.accept(.stopped)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
