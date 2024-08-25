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

class RunningViewModel {
    private let disposeBag = DisposeBag()
    private let runningManager: RunningManager
    
    // Input
    let startStopTrigger = PublishRelay<Void>()
    let locationUpdate = PublishRelay<CLLocation>()
    
    // Output
    let distance: Driver<String>
    let duration: Driver<String>
    let isRunning: Driver<Bool>
    let buttonTitle: Driver<String>
    
    init(runningManager: RunningManager = .shared) {
        self.runningManager = runningManager
        
        isRunning = runningManager.isRunning.asDriver()
        
        distance = runningManager.currentSession
            .compactMap { $0?.distance }
            .flatMap { $0.asObservable() }
            .map { String(format: "%.2f km", $0) }
            .asDriver(onErrorJustReturn: "0.00 km")
        
        duration = runningManager.currentSession
            .compactMap { $0?.duration }
            .flatMap { $0.asObservable() }
            .map { self.formatDuration($0) }
            .asDriver(onErrorJustReturn: "00:00:00")
        
        buttonTitle = isRunning.map { $0 ? "Stop" : "Start" }
        
        setupBindings()
    }
    
    private func setupBindings() {
        startStopTrigger
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if self.runningManager.isRunning.value {
                    self.runningManager.endCurrentSession()
                } else {
                    self.runningManager.startNewSession()
                }
            })
            .disposed(by: disposeBag)
        
        locationUpdate
            .subscribe(onNext: { [weak self] location in
                self?.runningManager.updateCurrentSession(newLocation: location)
            })
            .disposed(by: disposeBag)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
