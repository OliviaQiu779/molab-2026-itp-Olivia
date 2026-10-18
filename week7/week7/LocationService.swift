import CoreLocation
import SwiftUI
import Combine

/// One-shot location lookup that gives us "Tokyo, Japan" + the local time zone for the photo stamp.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var placeName: String?
    @Published var timeZone: TimeZone?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break   // denied: the stamp falls back to the device time zone
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let p = placemarks?.first else { return }
            let parts = [p.locality ?? p.administrativeArea, p.country].compactMap { $0 }
            DispatchQueue.main.async {
                self?.placeName = parts.joined(separator: ", ")
                self?.timeZone = p.timeZone ?? .current
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep whatever we had; the UI falls back to "Somewhere" + device time zone.
    }
}
