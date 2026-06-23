//
//  WeatherService.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Island. All rights reserved.
//

import Foundation
import CoreLocation

protocol WeatherServiceDelegateProtocol {
    func weatherServiceDidUpdateWeather(_ weatherService: WeatherService)
    func weatherServiceDidFailWithError(_ weatherService: WeatherService, error: Error)
}

class WeatherService: NSObject, CLLocationManagerDelegate, ObservableObject {

    // MARK: - Properties

    static let shared = WeatherService()
    private let locationManager = CLLocationManager()
    private let weatherTimer = Timer()

    var delegate: (any WeatherServiceDelegateProtocol)?

    /// Pending coordinates for reverse geocoding after weather fetch completes.
    private var pendingLatitude: Double?
    private var pendingLongitude: Double?

    var currentWeather: WeatherModel?
    var lastUpdated: Date?
    private var isUpdating = false

    // Default coordinates (backup when location access is denied)
    private let defaultLatitude = 51.5074
    private let defaultLongitude = -0.1278

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Public Methods

    func start() {
        updateWeather()

        // Set up periodic updates every 15 minutes
        Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.updateWeather()
        }
    }

    func stop() {
        // Timer will be invalidated automatically when deinitialized
    }

    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Public Methods

    public func updateWeather() {
        guard !isUpdating else { return }

        isUpdating = true

        if locationManager.authorizationStatus == .authorized ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            // Use default coordinates if location access is denied
            fetchWeatherForCoordinates(latitude: defaultLatitude, longitude: defaultLongitude)
        }
    }

    private func fetchWeatherForCoordinates(latitude: Double, longitude: Double) {
        pendingLatitude = latitude
        pendingLongitude = longitude

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"

        guard let url = URL(string: urlString) else {
            handleWeatherServiceError(NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.handleWeatherServiceError(error)
                return
            }

            guard let data = data else {
                let error = NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.handleWeatherServiceError(error)
                return
            }

            self.parseWeatherData(data)
        }

        task.resume()
    }

    private func parseWeatherData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let current = json["current_weather"] as? [String: Any],
               let temperature = current["temperature"] as? Double,
               let weatherCode = current["weathercode"] as? Int {

                let weather = WeatherModel(
                    temperature: temperature,
                    conditionCode: weatherCode,
                    location: "定位中…"
                )

                self.currentWeather = weather
                self.lastUpdated = Date()
                self.isUpdating = false

                DispatchQueue.main.async {
                    self.delegate?.weatherServiceDidUpdateWeather(self)
                    self.reverseGeocodeLocation()
                }
            } else {
                throw NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid weather data format"])
            }
        } catch {
            self.isUpdating = false
            handleWeatherServiceError(error)
        }
    }

    /// Reverse-geocode the pending coordinates to a Chinese place name,
    /// then update the weather model so the UI refreshes.
    private func reverseGeocodeLocation() {
        guard let lat = pendingLatitude, let lon = pendingLongitude else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "zh_CN")) { [weak self] placemarks, error in
            guard let self = self,
                  let pm = placemarks?.first,
                  error == nil else { return }

            // Prefer locality (city) + subLocality (district); fall back step by step.
            let name: String = {
                if let city = pm.locality, let district = pm.subLocality {
                    return "\(city)\(district)"
                }
                if let city = pm.locality { return city }
                if let area = pm.administrativeArea { return area }
                return pm.name ?? "未知位置"
            }()

            var updated = self.currentWeather
            updated?.location = name
            self.currentWeather = updated

            DispatchQueue.main.async {
                self.delegate?.weatherServiceDidUpdateWeather(self)
            }
        }
    }

    private func handleWeatherServiceError(_ error: Error) {
        isUpdating = false
        DispatchQueue.main.async {
            self.delegate?.weatherServiceDidFailWithError(self, error: error)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()

        guard let location = locations.last else {
            handleWeatherServiceError(NSError(domain: "WeatherService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No location data"]))
            return
        }

        fetchWeatherForCoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        handleWeatherServiceError(error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorized || status == .authorizedAlways {
            updateWeather()
        } else {
            // Use default coordinates if permission is denied
            fetchWeatherForCoordinates(latitude: defaultLatitude, longitude: defaultLongitude)
        }
    }
}

struct WeatherModel {
    let temperature: Double
    let conditionCode: Int
    var location: String

    // Convert temperature to string with proper formatting
    var temperatureString: String {
        return String(format: "%.1f°C", temperature)
    }
}