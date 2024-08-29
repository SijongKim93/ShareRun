////
////  ScheduleViewController.swift
////  ShareRun
////
////  Created by 김시종 on 8/26/24.
////
//
//import UIKit
//import RxSwift
//import RxCocoa
//
//class RecordViewController: UIViewController {
//    private let viewModel: RecordViewModel
//    private let disposeBag = DisposeBag()
//    
//    private let scrollView = UIScrollView()
//    private let contentView = UIView()
//    private let segmentedControl: UISegmentedControl = {
//        let sc = UISegmentedControl(items: ["Week", "Month", "All Time"])
//        sc.selectedSegmentIndex = 0
//        return sc
//    }()
//    
//    private let weekView = UIView()
//    private let monthView = UIView()
//    private let allTimeVIew = UIView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        
//    }
//    
//    init(viewModel: RecordViewModel) {
//        self.viewModel = viewModel
//    }
//    
//    private func setupSegmentedControl() {
//        view.addSubview(segmentedControl)
//        //segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
//        segmentedControl.snp.makeConstraints {
//            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
//            $0.leading.trailing.equalToSuperview().inset(20)
//        }
//    }
//    
//    private func setupScrollView() {
//        view.addSubview(scrollView)
//    }
//
//}
