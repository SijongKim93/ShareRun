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
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        return button
    }()
    
    private let pauseResumeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [distanceLabel, timeLabel, startStopButton, pauseResumeButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupUI()
        setupBindings()
        setupLocationManager()
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
        
        pauseResumeButton.rx.tap
            .bind(to: viewModel.pauseResumeTrigger)
            .disposed(by: disposeBag)
        
        viewModel.distance
            .drive(distanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.duration
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.startStopButtonTitle
            .drive(startStopButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.pauseResumeButtonTitle
            .drive(pauseResumeButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.isPauseResumeButtonHidden
            .drive(pauseResumeButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.sessionState
            .drive(onNext: { [weak self] state in
                if state == .running {
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
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            promptForLocationService()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func promptForLocationService() {
        let alert = UIAlertController(title: "Location Permission Required",
                                      message: "Please enable location services in the settings.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension RunningViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        viewModel.locationUpdate.accept(location)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
