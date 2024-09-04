//
//  AlltimeView.swift
//  ShareRun
//
//  Created by 김시종 on 9/4/24.
//

import UIKit
import HealthKit
import RxSwift

class AlltimeView: UIView {
    private let disposeBag = DisposeBag()
    private let tableView = UITableView()
    private let viewModel = AlltimeViewModel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTableView()
        bindTableView()
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTableView() {
        addSubview(tableView)
        tableView.register(AlltimeTableViewCell.self, forCellReuseIdentifier: AlltimeTableViewCell.identifier)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func bindTableView() {
        viewModel.stepsSubject
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: AlltimeTableViewCell.identifier, cellType: AlltimeTableViewCell.self)) { index, data, cell in
                cell.textLabel?.text = data
            }
            .disposed(by: disposeBag)
    }
}
