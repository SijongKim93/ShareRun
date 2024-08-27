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
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let distanceLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 40, weight: .bold, textColor: .black, textAlignment: .center)
    }()
    
    private let distanceSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 30, weight: .semibold, textColor: .gray, textAlignment: .center, title: "KM")
    }()
    
    private let timeLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 40, weight: .bold, textColor: .black, textAlignment: .center)
    }()
    
    private let timeSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 30, weight: .semibold, textColor: .gray, textAlignment: .center, title: "TIME")
    }()
    
    private let paceLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 40, weight: .bold, textColor: .black, textAlignment: .center)
    }()
    
    private let paceSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 30, weight: .semibold, textColor: .gray, textAlignment: .center, title: "PACE")
    }()
    
    private let bpmLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 40, weight: .bold, textColor: .black, textAlignment: .center)
    }()
    
    private let bpmSubLabel: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 30, weight: .semibold, textColor: .gray, textAlignment: .center, title: "BPM")
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
        
        
        mapView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(view.frame.height / 2)
        }
        
        gradientView.snp.makeConstraints {
            $0.edges.equalTo(mapView)
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
        locationManager.distanceFilter = kCLDistanceFilterNone
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
