//
//  ScheduleViewController.swift
//  ShareRun
//
//  Created by 김시종 on 8/26/24.
//

import UIKit
import RxSwift
import RxCocoa

class RecordViewController: UIViewController {
    private let viewModel = RecordViewModel()
    private let disposeBag = DisposeBag()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Week", "Month", "All Time"])
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let weekView = WeekView()
    private let monthView = UIView()
    private let allTimeView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupSegmentedControl()
        setupScrollView()
        bindSegmentedControl()
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        contentView.addSubview(weekView)
        contentView.addSubview(monthView)
        contentView.addSubview(allTimeView)
        
        weekView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
        }
        
        monthView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
        }
        
        allTimeView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
        }
    }
    
    private func bindSegmentedControl() {
        segmentedControl.rx.selectedSegmentIndex
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                self.updateView(for: index)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateView(for index: Int) {
        weekView.isHidden = index != 0
        monthView.isHidden = index != 1
        allTimeView.isHidden = index != 2
    }
    
    @objc private func segmentChanged() {
        updateView(for: segmentedControl.selectedSegmentIndex)
    }

}
