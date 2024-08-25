//
//  ViewController.swift
//  ShareRun
//
//  Created by 김시종 on 8/23/24.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation
import SnapKit

class RunningViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = RunningViewModel()
    private let locationManager = CLLocationManager()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let startStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [distanceLabel, timeLabel, startStopButton])
        stackView.axis = .vertical // 수직 방향으로 변경
        stackView.spacing = 20
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings() // Binding 설정 추가
        setupLocationManager() // 위치 업데이트를 위해 추가
    }

    private func setupUI() {
        view.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        startStopButton.rx.tap
            .bind(to: viewModel.startStopTrigger)
            .disposed(by: disposeBag)
        
        viewModel.distance
            .drive(distanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.duration
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.buttonTitle
            .drive(startStopButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.isRunning
            .drive(onNext: { [weak self] isRunning in
                if isRunning {
                    self?.startUpdatingLocation()
                } else {
                    self?.locationManager.stopUpdatingLocation()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
}

extension RunningViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        viewModel.locationUpdate.accept(location)
    }
}
