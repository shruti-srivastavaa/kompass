import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var lastLocation: CLLocation?
    @Published var lastHeading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentPlacemark: CLPlacemark?
    @Published var currentAddress: String = ""
    
    private var geocodeTimer: Timer?
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        // Throttle reverse geocoding to every 30 seconds
        if geocodeTimer == nil {
            reverseGeocode(location)
            geocodeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
                self?.geocodeTimer = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    // MARK: - Reverse Geocoding
    func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                self.currentPlacemark = placemark
                self.currentAddress = self.formatPlacemark(placemark)
            }
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            var parts: [String] = []
            if let number = placemark.subThoroughfare { parts.append(number) }
            if let street = placemark.thoroughfare { parts.append(street) }
            if let city = placemark.locality { parts.append(city) }
            if let state = placemark.administrativeArea { parts.append(state) }
            completion(parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }
    
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var parts: [String] = []
        if let street = placemark.thoroughfare { parts.append(street) }
        if let city = placemark.locality { parts.append(city) }
        return parts.isEmpty ? "Unknown Location" : parts.joined(separator: ", ")
    }
    
    func bearingTo(target: CLLocationCoordinate2D) -> Double? {
        guard let current = lastLocation else { return nil }
        
        let lat1 = current.coordinate.latitude.toRadians()
        let lon1 = current.coordinate.longitude.toRadians()
        let lat2 = target.latitude.toRadians()
        let lon2 = target.longitude.toRadians()
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2(y, x)
        return radiansBearing.toDegrees()
    }
    
    func distanceTo(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = lastLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }
    
    // MARK: - Simulation Logic
    private var simulationTimer: Timer?
    private var simulationRoute: [CLLocationCoordinate2D] = []
    private var simulationIndex = 0
    @Published var isSimulating = false
    
    func startSimulation(route: [CLLocationCoordinate2D], speedMultiplier: Double = 1.0) {
        stopSimulation()
        guard !route.isEmpty else { return }
        
        simulationRoute = route
        simulationIndex = 0
        isSimulating = true
        
        // Stop real updates to avoid conflict (optional, but cleaner)
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        
        // Timer to advance position
        // MKDirections points are usually close. 0.5s interval is okay.
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5 / speedMultiplier, repeats: true) { [weak self] _ in
            self?.nextSimulationStep()
        }
    }
    
    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        simulationRoute = []
        isSimulating = false
        
        // Resume real updates
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    private func nextSimulationStep() {
        guard simulationIndex < simulationRoute.count else {
            stopSimulation()
            return
        }
        
        let coord = simulationRoute[simulationIndex]
        let timestamp = Date()
        
        // Calculate course from current point to next point
        var course: CLLocationDirection = lastHeading?.trueHeading ?? 0
        if simulationIndex + 1 < simulationRoute.count {
            course = calculateBearing(from: coord, to: simulationRoute[simulationIndex + 1])
        } else if simulationIndex > 0 {
            // Keep previous course if at end
             course = calculateBearing(from: simulationRoute[simulationIndex - 1], to: coord)
        }
        
        let location = CLLocation(
            coordinate: coord,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: course,
            speed: 15, // ~54 km/h generic speed
            timestamp: timestamp
        )
        
        lastLocation = location
        simulationIndex += 1
    }
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude.toRadians()
        let lon1 = from.longitude.toRadians()
        let lat2 = to.latitude.toRadians()
        let lon2 = to.longitude.toRadians()
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2(y, x)
        return radiansBearing.toDegrees()
    }
}

extension Double {
    func toRadians() -> Double { return self * .pi / 180 }
    func toDegrees() -> Double { return self * 180 / .pi }
}
