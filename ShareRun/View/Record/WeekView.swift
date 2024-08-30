//
//  WeekView.swift
//  ShareRun
//
//  Created by 김시종 on 8/29/24.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftUI

class WeekView: UIView {
    private let disposeBag = DisposeBag()
    private let collectionView: UICollectionView
    private var chartHostController: UIHostingController<ChartView>?
    
    private let viewModel = RecordViewModel()
    private let averageLabelView = RecordAverageLabelView()
    
    
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let screenWidth = UIScreen.main.bounds.width / 8
        layout.itemSize = CGSize(width: screenWidth, height: 70)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        addSubview(collectionView)
        
        collectionView.register(CalendarCollectionViewCell.self, forCellWithReuseIdentifier: CalendarCollectionViewCell.identifier)
        
        averageLabelView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(100)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(averageLabelView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(80)
        }
    }
    
    private func setupChart() {
        let chartView = ChartView(data: [])
        let chartHostController = UIHostingController(rootView: chartView)
        self.chartHostController = chartHostController
        addSubview(chartHostController.view)
        
        chartHostController.view.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(170)
        }
    }
    
    private func bindData() {
        viewModel.averageDistance
            .drive(onNext: { [weak self] distance in
                self?.averageLabelView.configure(distance: distance, pace: "05:00", time: "02:00", count: "4")
            })
            .disposed(by: disposeBag)
        
        viewModel.chartData
            .drive(onNext: { [weak self] data in
                guard let self = self else { return }
                self.chartHostController?.rootView = ChartView(data: data)
            })
            .disposed(by: disposeBag)

        let dates = Array(0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek())! }
        let runningData = [true, false, true, false, true, false, true]
        let combinedData = zip(dates, runningData).map { ($0.0, $0.1) }

        Observable.just(combinedData)
            .bind(to: collectionView.rx.items(cellIdentifier: CalendarCollectionViewCell.identifier, cellType: CalendarCollectionViewCell.self)) { index, data, cell in
                cell.configure(with: data.0, hasRunningData: data.1)
            }
            .disposed(by: disposeBag)
    }
    
    private func startOfWeek() -> Date {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return Calendar.current.date(from: components)!
    }
    
}

