//
//  RunningManager.swift
//  ShareRun
//
//  Created by 김시종 on 8/23/24.
//

import Foundation
import RxCocoa
import CoreLocation


class RunningManager {
    static let shared = RunningManager()
    
    private init() {}
    
    let currentSession = BehaviorRelay<RunningSession?>(value: nil)
    let isRunning = BehaviorRelay<Bool>(value: false)
    
    func startNewSession() {
        let newSession = RunningSession()
        currentSession.accept(newSession)
        isRunning.accept(true)
    }
    
    func endCurrentSession() {
        currentSession.accept(nil)
        isRunning.accept(false)
    }
    
    func updateCurrentSession(newLocation: CLLocation) {
        guard var session = currentSession.value else { return }
        
        //update location
        var locations = session.locations.value
        locations.append(newLocation)
        session.locations.accept(locations)
        
        //update distance
        if let lastLocation = locations.dropLast().last {
            let newDistance = lastLocation.distance(from: newLocation) / 1000.0
            let currentDistance = session.distance.value
            session.distance.accept(currentDistance + newDistance)
        }
        
        //update duration
        let newDuration = Date().timeIntervalSince(session.date)
        session.duration.accept(newDuration)
        
        currentSession.accept(session)
    }
}
