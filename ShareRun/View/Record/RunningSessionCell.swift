//
//  RunningSessionCell.swift
//  ShareRun
//
//  Created by 김시종 on 9/3/24.
//

import UIKit

struct RunningSessionData {
    let distance: String
    let pace: String
    let time: String
}


class RunningSessionCell: UICollectionViewCell {
    
    static let identifier = "RunningSessionCell"
    
    private let distanceLabel = UILabel()
    private let paceLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        let stackView = UIStackView(arrangedSubviews: [distanceLabel, paceLabel, timeLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(10)
        }
        
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray.cgColor
    }
    
    func configure(with data: RunningSessionData) {
        distanceLabel.text = data.distance
        paceLabel.text = data.pace
        timeLabel.text = data.time
    }
    
}
