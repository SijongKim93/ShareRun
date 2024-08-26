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

class RunningViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = RunningViewModel()
    private let locationManager = CLLocationManager()
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routePolyline: MKPolyline?
    private var previousLocation: CLLocation?
    
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .medium)
        label.textColor = .black
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
        stackView.spacing = 30
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
    
    private func setupUI() {
        view.addSubview(mapView)
        view.addSubview(gradientView)
        view.addSubview(stackView)
        
        mapView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(view.frame.height / 2)
        }
        
        gradientView.snp.makeConstraints {
            $0.edges.equalTo(mapView)
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        addGradientLayer()
        
        
    }
    
    private func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = mapView.bounds
        gradientLayer.colors = [UIColor.clear.cgColor, view.backgroundColor?.cgColor ?? UIColor.white.cgColor]
        gradientLayer.locations = [0.7, 1.0]
        gradientView.layer.addSublayer(gradientLayer)
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
    
    private func setupMapView() {
        mapView.delegate = self
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
