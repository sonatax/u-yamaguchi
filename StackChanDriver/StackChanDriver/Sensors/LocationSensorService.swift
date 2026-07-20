@preconcurrency import CoreLocation
import Foundation

@MainActor
protocol LocationSensorProviding: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }

    func start(
        onSample: @escaping @MainActor (LocationSensorSample) -> Void,
        onReady: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (SensorServiceError) -> Void
    ) throws
    func stop()
}

@MainActor
final class LocationSensorService: NSObject, LocationSensorProviding {
    private let locationManager: CLLocationManager
    private var onSample: (@MainActor (LocationSensorSample) -> Void)?
    private var onReady: (@MainActor () -> Void)?
    private var onError: (@MainActor (SensorServiceError) -> Void)?
    private var startRequested = false

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    override init() {
        locationManager = CLLocationManager()
        super.init()
        configureLocationManager()
    }

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        configureLocationManager()
    }

    func start(
        onSample: @escaping @MainActor (LocationSensorSample) -> Void,
        onReady: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (SensorServiceError) -> Void
    ) throws {
        guard CLLocationManager.locationServicesEnabled() else {
            throw SensorServiceError.locationUnavailable
        }

        self.onSample = onSample
        self.onReady = onReady
        self.onError = onError
        startRequested = true

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            beginLocationUpdates()
        case .denied, .restricted:
            throw SensorServiceError.locationPermissionDenied
        @unknown default:
            throw SensorServiceError.locationUnavailable
        }
    }

    func stop() {
        startRequested = false
        locationManager.stopUpdatingLocation()
        onSample = nil
        onReady = nil
        onError = nil
        print("[Sensors] Location updates stopped")
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func beginLocationUpdates() {
        guard startRequested else { return }
        locationManager.startUpdatingLocation()
        onReady?()
        print("[Sensors] Location updates started")
    }
}

extension LocationSensorService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard startRequested else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            beginLocationUpdates()
        case .denied, .restricted:
            onError?(.locationPermissionDenied)
        case .notDetermined:
            break
        @unknown default:
            onError?(.locationUnavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        onSample?(
            LocationSensorSample(
                timestamp: location.timestamp,
                speedMetersPerSecond: max(0, location.speed),
                horizontalAccuracyMeters: location.horizontalAccuracy,
                speedAccuracyMetersPerSecond: location.speedAccuracy
            )
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        let locationError = error as? CLError
        if locationError?.code == .locationUnknown {
            return
        }
        onError?(.locationUpdateFailed(error.localizedDescription))
    }
}
