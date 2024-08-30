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

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(data: generateMonthlyData())
    }
}

// Helper function to generate sample monthly data
func generateMonthlyData() -> [ChartData] {
    let allDays = (1...30).map { day in
        Calendar.current.date(byAdding: .day, value: day - 1, to: Date())!
    }
    
    return allDays.map { date in
        // Simulating data with some random entries
        let value = Bool.random() ? Double.random(in: 0...10) : 0
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        let label = formatter.string(from: date)
        
        return ChartData(value: value, label: label)
    }
}
