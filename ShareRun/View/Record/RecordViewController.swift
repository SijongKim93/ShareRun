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
    
    private let containerView = UIView()
    private let weekView = WeekView()
    private let monthView = MonthView()
    private let allTimeView = UIView()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 170)
        layout.minimumLineSpacing = 10
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupSegmentedControl()
        setupScrollView()
        setupContainerView()
        setupCollectionView()
        bindSegmentedControl()
    }
    
    private func setupContainerView() {
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
        }
        
        containerView.addSubview(weekView)
        containerView.addSubview(monthView)
        containerView.addSubview(allTimeView)
        
        weekView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        monthView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        allTimeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        updateView(for: 0)
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func setupCollectionView() {
        contentView.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.register(RunningSessionCell.self, forCellWithReuseIdentifier: RunningSessionCell.identifier)
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(containerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        
        let dummyData = [
            RunningSessionData(distance: "5.0 km", pace: "5:00 min/km", time: "00:25:00"),
            RunningSessionData(distance: "6.2 km", pace: "4:50 min/km", time: "00:30:00"),
            RunningSessionData(distance: "4.3 km", pace: "5:10 min/km", time: "00:22:00")
        ]
        
        Observable.just(dummyData)
            .bind(to: collectionView.rx.items(cellIdentifier: RunningSessionCell.identifier, cellType: RunningSessionCell.self)) { index, data, cell in
                cell.configure(with: data)
            }
            .disposed(by: disposeBag)
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
            $0.height.equalTo(1300)
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
        
        // 선택된 뷰의 높이에 따라 컨테이너 뷰의 높이를 조정
        let height: CGFloat
        switch index {
        case 0:
            height = 500
        case 1:
            height = 1300
        case 2:
            height = 500
        default:
            height = 500
        }
        
        containerView.snp.updateConstraints {
            $0.height.equalTo(height)
        }
    }
    
    @objc private func segmentChanged() {
        updateView(for: segmentedControl.selectedSegmentIndex)
    }
    
}
