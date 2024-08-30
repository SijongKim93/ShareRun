//
//  CalendarCollectionViewCell.swift
//  ShareRun
//
//  Created by 김시종 on 8/29/24.
//

import UIKit

class CalendarCollectionViewCell: UICollectionViewCell {
    static let identifier = "CalendarCollectionViewCell"
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("컬렉션 뷰 오류")
    }
    
    private func setupView() {
        addSubview(dateLabel)
        addSubview(separatorView)
        addSubview(emojiLabel)
        
        dateLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(6)
            $0.height.equalTo(20)
        }
        
        separatorView.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        emojiLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    func configure(with date: Date, hasRunningData: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateLabel.text = dateFormatter.string(from: date)
        emojiLabel.text = hasRunningData ? "🏃‍♂️" : ""
        
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            self.dateLabel.textColor = .red
        } else {
            self .dateLabel.textColor = .black
        }
    }
}
