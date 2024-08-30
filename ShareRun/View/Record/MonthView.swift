//
//  MonthView.swift
//  ShareRun
//
//  Created by 김시종 on 8/30/24.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SwiftUI

class MonthView: UIView {
    private let disposeBag = DisposeBag()
    private var chartHostController: UIHostingController<ChartView>?
    
    private let viewModel = RecordViewModel()
    private let averageLabelView = RecordAverageLabelView()
    private let calendarView = UICalendarView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        setupChart()
        bindData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(averageLabelView)
        addSubview(calendarView)
        
        averageLabelView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(100)
        }
        
        calendarView.snp.makeConstraints {
            $0.top.equalTo(averageLabelView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(400) 
        }
    }
    
    private func setupChart() {
        let chartView = ChartView(data: [])
        let chartHostController = UIHostingController(rootView: chartView)
        self.chartHostController = chartHostController
        addSubview(chartHostController.view)
        
        chartHostController.view.snp.makeConstraints {
            $0.top.equalTo(calendarView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(170)
        }
    }
    
    private func bindData() {
        
        viewModel.averageDistance
            .drive(onNext: { [weak self] distance in
                self?.averageLabelView.configure(distance: distance, pace: "05:00", time: "02:00", count: "20")
            })
            .disposed(by: disposeBag)
        
        viewModel.chartData
            .drive(onNext: { [weak self] data in
                guard let self = self else { return }
                self.chartHostController?.rootView = ChartView(data: data)
            })
            .disposed(by: disposeBag)
        
        calendarView.delegate = self
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
    }
}

extension MonthView: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        
    }
    
    func calendarView(_ calendarView: UICalendarView, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        
        // 여기서 선택된 날짜와 관련된 데이터를 처리할 수 있습니다.
        print("Selected date: \(date)")
    }
}
