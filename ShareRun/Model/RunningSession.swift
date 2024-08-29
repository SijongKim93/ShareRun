//
//  RunningSession.swift
//  ShareRun
//
//  Created by 김시종 on 8/23/24.
//

import Foundation
import CoreLocation
import RxCocoa

struct RunningSession {
    let id: UUID
    let date: Date
    let distance: BehaviorRelay<Double>
    let duration: BehaviorRelay<TimeInterval>
    let locations: BehaviorRelay<[CLLocation]>
    
    init(id: UUID = UUID (), date: Date = Date(), distance: Double = 0.0, duration: TimeInterval = 0.0, locations: [CLLocation] = []) {
        self.id = id
        self.date = date
        self.distance = BehaviorRelay<Double>(value: 0.0)
        self.duration = BehaviorRelay<TimeInterval>(value: 0.0)
        self.locations = BehaviorRelay<[CLLocation]>(value: [])
    }
}
