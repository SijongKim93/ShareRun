//
//  RecordAverageLabelView.swift
//  ShareRun
//
//  Created by 김시종 on 8/30/24.
//

import UIKit


class RecordAverageLabelView: UIView {
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 60, weight: .bold)
        label.textAlignment = .center
        label.text = "0.00"
        return label
    }()
    
    private let distanceSubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .left
        label.text = "km"
        return label
    }()
    
    private let paceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .left
        label.text = "PACE  00:00 min/km"
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .left
        label.text = "TIME  00:00"
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .left
        label.text = "DAY : 0"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        let leftStackView = UIStackView(arrangedSubviews: [distanceLabel, distanceSubLabel])
        leftStackView.axis = .horizontal
        leftStackView.alignment = .bottom
        
        let rightStackView = UIStackView(arrangedSubviews: [paceLabel, timeLabel, countLabel])
        rightStackView.axis = .vertical
        rightStackView.alignment = .leading
        rightStackView.spacing = 10
        
        addSubview(leftStackView)
        addSubview(rightStackView)
        
        leftStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(0.55)
            $0.centerY.equalToSuperview()
        }
        
        distanceSubLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-7)
        }
        
        rightStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(1.5)
            $0.centerY.equalToSuperview()
        }
    }
    
    func configure(distance: String, pace: String, time: String, count: String) {
        distanceLabel.text = "\(distance)"
        paceLabel.text = "PACE \(pace)"
        timeLabel.text = "TIME \(time)"
        countLabel.text = "DAY \(count)"
    }
}
