//
//  ChartView.swift
//  ShareRun
//
//  Created by 김시종 on 8/29/24.
//

import SwiftUI
import Charts


struct ChartView: View {
    let data: [ChartData]
    
    init(data: [ChartData]) {
        self.data = data
        print("Received ChartData: \(data)")
    }
    
    var body: some View {
        Chart {
            ForEach(data) { entry in
                BarMark(
                    x: .value("Day", entry.label),
                    y: .value("KM", entry.value)
                )
                .foregroundStyle(.indigo)
                .cornerRadius(16)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
