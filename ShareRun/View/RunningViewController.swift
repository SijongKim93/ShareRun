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
import MapKit
import AVFoundation

class RunningViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = RunningViewModel()
    private let locationManager = CLLocationManager()
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routePolyline: MKPolyline?
    private var previousLocation: CLLocation?

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }()

    private let gradientView: UIView = {
        let view = UIView()
        return view
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 100, weight: .bold)
        label.textColor = .systemIndigo
        label.textAlignment = .center
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        return label
    }()

    private let distanceLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 35, weight: .bold, textColor: .black, textAlignment: .center)
    }()

    private let distanceSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 28, weight: .semibold, textColor: .gray, textAlignment: .center, title: "KM")
    }()

    private let timeLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 35, weight: .bold, textColor: .black, textAlignment: .center)
    }()

    private let timeSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 28, weight: .semibold, textColor: .gray, textAlignment: .center, title: "TIME")
    }()

    private let paceLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 35, weight: .bold, textColor: .black, textAlignment: .center)
    }()

    private let paceSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 28, weight: .semibold, textColor: .gray, textAlignment: .center, title: "PACE")
    }()

    private let bpmLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 35, weight: .bold, textColor: .black, textAlignment: .center)
    }()

    private let bpmSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 28, weight: .semibold, textColor: .gray, textAlignment: .center, title: "BPM")
    }()
    
    private let finishWarningLabel: UILabel = {
        let label = UILabel()
        label.text = "정지 버튼을 길게 눌러야 런닝이 종료 됩니다."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        button.setImage(UIImage(systemName: "figure.run", withConfiguration: config), for: .normal)
        button.backgroundColor = .systemIndigo
        button.tintColor = .white
        button.layer.cornerRadius = 40
        return button
    }()

    private let stopButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        button.setImage(UIImage(systemName: "stop.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 40
        button.isHidden = true
        return button
    }()

    private let pauseResumeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        button.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemYellow
        button.layer.cornerRadius = 40
        button.isHidden = true
        return button
    }()

    private lazy var distanceStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [distanceLabel, distanceSubLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    private lazy var timeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [timeLabel, timeSubLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    private lazy var paceStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [paceLabel, paceSubLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    private lazy var bpmStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [bpmLabel, bpmSubLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupUI()
        setupMapView()
        setupBindings()
        setupLocationManager()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradientLayer()
    }
    
    private func setupUI() {
        view.addSubview(mapView)
        view.addSubview(gradientView)
        view.addSubview(countdownLabel)
        view.addSubview(distanceStackView)
        view.addSubview(timeStackView)
        view.addSubview(paceStackView)
        view.addSubview(bpmStackView)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(pauseResumeButton)
        view.addSubview(finishWarningLabel)
        
        mapView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(view.frame.height / 2)
        }
        
        gradientView.snp.makeConstraints {
            $0.edges.equalTo(mapView)
        }
        
        countdownLabel.snp.makeConstraints {
            $0.center.equalTo(mapView)
        }
        
        distanceStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(0.5)
            $0.centerY.equalToSuperview().multipliedBy(1.15)
        }
        
        timeStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(1.5)
            $0.centerY.equalToSuperview().multipliedBy(1.15)
        }
        
        paceStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(0.5)
            $0.centerY.equalToSuperview().multipliedBy(1.40)
        }
        
        bpmStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(1.5)
            $0.centerY.equalToSuperview().multipliedBy(1.40)
        }
        
        startButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            $0.width.equalTo(80)
            $0.height.equalTo(80)
        }
        
        stopButton.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(0.5)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            $0.width.equalTo(80)
            $0.height.equalTo(80)
        }
        
        pauseResumeButton.snp.makeConstraints {
            $0.centerX.equalToSuperview().multipliedBy(1.5)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            $0.width.equalTo(80)
            $0.height.equalTo(80)
        }
        
        finishWarningLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(startButton.snp.bottom).offset(16)
        }
        
        addGradientLayer()
    }
    
    private func addGradientLayer() {
        gradientView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        
        gradientView.layer.addSublayer(gradientLayer)
    }
    
    private func setupBindings() {
        startButton.rx.tap
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
        
        viewModel.pace
            .drive(paceLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.bpm
            .drive(bpmLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.sessionState
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
                
                switch state {
                case .running:
                    self.startButton.isHidden = true
                    self.stopButton.isHidden = false
                    self.pauseResumeButton.isHidden = false
                    self.pauseResumeButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
                    self.startUpdatingLocation()
                    
                case .paused:
                    self.startButton.isHidden = true
                    self.stopButton.isHidden = false
                    self.pauseResumeButton.isHidden = false
                    self.pauseResumeButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
                    self.locationManager.stopUpdatingLocation()
                    
                case .stopped:
                    self.startButton.isHidden = false
                    self.stopButton.isHidden = true
                    self.pauseResumeButton.isHidden = true
                    self.locationManager.stopUpdatingLocation()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.countdownText
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] text in
                self?.showCountdownLabel(with: text)
            })
            .disposed(by: disposeBag)
        
        viewModel.showCountdown
            .filter { !$0 }
            .subscribe(onNext: { [weak self] _ in
                self?.countdownLabel.text = nil
            })
            .disposed(by: disposeBag)
        
        viewModel.showFinishWarning
            .map { !$0 }
            .bind(to: finishWarningLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        stopButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.finishWarningLabel.isHidden = false
            })
            .disposed(by: disposeBag)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 2.0
        stopButton.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            viewModel.showFinishWarning.accept(true)
        case .ended:
            viewModel.showFinishWarning.accept(false)
            viewModel.stopButtonLongPressTrigger.accept(())
        case .cancelled:
            viewModel.showFinishWarning.accept(false)
        default:
            break
        }
    }
    
    private func setupMapView() {
        mapView.delegate = self
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private func centerMapIn3D(on location: CLLocation) {
        let distance: CLLocationDistance = 500
        let pitch: CGFloat = 45
        let heading = 0.0
        
        let camera = MKMapCamera(lookingAtCenter: location.coordinate,
                                 fromDistance: distance,
                                 pitch: pitch,
                                 heading: heading)
        
        mapView.camera = camera
    }
    
    private func updateRouteLine(to location: CLLocation) {
        guard let previousLocation = previousLocation else {
            self.previousLocation = location
            return
        }
        
        let coordinates = [previousLocation.coordinate, location.coordinate]
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        self.previousLocation = location
    }
    
    private func showCountdownLabel(with text: String) {
        countdownLabel.text = text
        countdownLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        countdownLabel.alpha = 0
        
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut],
                       animations: {
            self.countdownLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.countdownLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.4, animations: {
                self.countdownLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.countdownLabel.alpha = 0
            })
        }
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
        centerMap(on: location)
        updateRouteLine(to: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let defaultLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        centerMap(on: defaultLocation)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    private func centerMap(on location: CLLocation) {
        centerMapIn3D(on: location)
    }
}

extension RunningViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemIndigo
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
