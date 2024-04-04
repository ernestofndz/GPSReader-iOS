//
//  GPSReaderViewModel.swift
//  GPS Reader
//
//  Created by Ernesto Fernandez on 4/4/24.
//

import Combine
import CoreLocation
import AVFoundation

final class GPSReaderViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    private struct Constants {

        static let secondsToDetermineNoSignal = 8.0
        static let accuracyFull = 10.0
        static let accuracyGood = 70.0
        static let accuracyAverage = 200.0

    }

    @Published private(set) var isLocationPermissionEnabled = false
    @Published private(set) var signalStrength = SignalStrength.notDetermined

    private var cancellables = Set<AnyCancellable>()
    private let locationManager: CLLocationManager
    private var lastUpdate: Date?
    private var noSignalTimer: Timer?
    private var audioPlayer: AVAudioPlayer?

    private(set) var status: LocationServiceStatus = .notDetermined {
        didSet {
            isLocationPermissionEnabled = status == .authorized
            startUpdatingLocationIfPossible()
        }
    }

    private var isInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // MARK: - Initialization

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        observe()
    }

    // MARK: - Public methods

    func onAppear() {
        locationManager.delegate = self
        prepareAudioPlayer()
        requestLocationAuthorization()
    }

    // MARK: - CLLocationManagerDelegate methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastUpdate = .init()
        signalStrength = determineSignalStrength(from: locations)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined: status = .notDetermined
        case .restricted, .denied: status = .denied
        case .authorizedWhenInUse, .authorizedAlways: status = .authorized
        @unknown default: fatalError("Location services: status unhandled")
        }
    }

    // MARK: - Private methods

    private func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func startUpdatingLocationIfPossible() {
        guard status == .authorized else { return }
        locationManager.startUpdatingLocation()
        checkForNoSignal()
    }

    private func determineSignalStrength(from locations: [CLLocation]) -> SignalStrength {
        guard let location = locations.last else { return .notDetermined }
        let accuracy = location.horizontalAccuracy
        if accuracy < 0 {
            return .none
        } else if accuracy < Constants.accuracyFull {
            return .full
        } else if accuracy < Constants.accuracyGood {
            return .good
        } else if accuracy < Constants.accuracyAverage {
            return .average
        } else {
            return .poor
        }
    }

    private func checkForNoSignal() {
        noSignalTimer?.invalidate()
        noSignalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let lastUpdate = self?.lastUpdate else { return }
            let diff = Date().timeIntervalSince1970 - lastUpdate.timeIntervalSince1970
            if diff > Constants.secondsToDetermineNoSignal {
                self?.signalStrength = .none
            }
        }
    }

    private func prepareAudioPlayer() {
        let path = Bundle.main.path(forResource: "sound.wav", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
    }

    private func playNoSignalAudioIfNeeded(_ strength: SignalStrength) {
        guard !isInPreview else { return }
        let isPlaying = audioPlayer?.isPlaying ?? false
        if strength == .none {
            if !isPlaying {
                audioPlayer?.play()
            }
        } else {
            if isPlaying {
                audioPlayer?.stop()
            }
        }
    }

    // MARK: - Private methods

    private func observe() {
        observeSignalStrength()
    }

    private func observeSignalStrength() {
        $signalStrength
            .sink { [weak self] in self?.playNoSignalAudioIfNeeded($0) }
            .store(in: &cancellables)
    }

}
