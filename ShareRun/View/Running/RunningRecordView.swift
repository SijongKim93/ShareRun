//
//  RunningRecordView.swift
//  ShareRun
//
//  Created by 김시종 on 8/29/24.
//

import UIKit
import RxSwift
import RxCocoa

class RunningRecordView: UIView {
    private let disposeBag = DisposeBag()

    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let bpmLabel = UILabel()
    private let paceLabel = UILabel()

    var onOkButtonTapped: (() -> Void)?

    init(viewModel: RunningViewModel) {
        super.init(frame: .zero)
        setupUI()
        bindData(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = "Running Record 🏃‍♀️"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center

        let distanceStackView = createLabelStack(title: "Distance", label: distanceLabel)
        let durationStackView = createLabelStack(title: "Time", label: durationLabel)
        let bpmStackView = createLabelStack(title: "BPM", label: bpmLabel)
        let paceStackView = createLabelStack(title: "Pace", label: paceLabel)

        let topStackView = UIStackView(arrangedSubviews: [distanceStackView, durationStackView])
        topStackView.axis = .horizontal
        topStackView.alignment = .fill
        topStackView.distribution = .fillEqually
        topStackView.spacing = 20

        let bottomStackView = UIStackView(arrangedSubviews: [bpmStackView, paceStackView])
        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .fill
        bottomStackView.distribution = .fillEqually
        bottomStackView.spacing = 20

        let contentStackView = UIStackView(arrangedSubviews: [topStackView, bottomStackView])
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 20

        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.tintColor = .black
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let okButton = UIButton(type: .system)
        okButton.setTitle("OK", for: .normal)
        okButton.tintColor = .black
        okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside)

        let buttonStackView = UIStackView(arrangedSubviews: [shareButton, okButton])
        buttonStackView.axis = .horizontal
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 100

        self.addSubview(titleLabel)
        self.addSubview(contentStackView)
        self.addSubview(buttonStackView)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(20)
        }
        
        contentStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.center.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(20)
            $0.centerX.equalToSuperview()
        }
    }

    private func createLabelStack(title: String, label: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        titleLabel.textAlignment = .center

        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }

    private func bindData(viewModel: RunningViewModel) {
        viewModel.distance
            .drive(distanceLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.duration
            .drive(durationLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.bpm
            .drive(bpmLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.pace
            .drive(paceLabel.rx.text)
            .disposed(by: disposeBag)
    }

    @objc private func shareTapped() {
        // 공유 기능 구현
    }

    @objc private func okTapped() {
        onOkButtonTapped?()
    }
}
