//
//  WeatherService.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Island. All rights reserved.
//

import Foundation
import CoreLocation

protocol WeatherServiceDelegate: AnyObject {
    func weatherServiceDidUpdateWeather(_ weatherService: WeatherService)
    func weatherServiceDidFailWithError(_ weatherService: WeatherService, error: Error)
}

// Protocol for value types (structs)
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
        let urlString = "https://wttr.in/\(latitude),\(longitude)?format=j1"

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
               let current = json["current_condition"] as? [[String: Any]],
               let condition = current.first,
               let tempC = condition["temp_C"] as? String,
               let temperature = Double(tempC),
               let weatherCodeStr = condition["weatherCode"] as? String,
               let weatherCode = Int(weatherCodeStr) {

                // Use wttr.in's area name if available
                var location = getCurrentLocationString()
                if let nearest = json["nearest_area"] as? [[String: Any]],
                   let area = nearest.first,
                   let areaName = area["areaName"] as? [[String: Any]],
                   let name = areaName.first?["value"] as? String {
                    location = name
                }

                let weather = WeatherModel(
                    temperature: temperature,
                    conditionCode: weatherCode,
                    location: location
                )

                DispatchQueue.main.async {
                    self.currentWeather = weather
                    self.lastUpdated = Date()
                    self.isUpdating = false
                    self.delegate?.weatherServiceDidUpdateWeather(self)
                }
            } else {
                throw NSError(domain: "WeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid weather data format"])
            }
        } catch {
            self.isUpdating = false
            handleWeatherServiceError(error)
        }
    }

    private func getCurrentLocationString() -> String {
        // Return cached city name if available
        if let cached = UserDefaults.standard.string(forKey: "weatherCity"), !cached.isEmpty {
            return cached
        }
        // Reverse geocode in background
        if let loc = locationManager.location {
            CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
                if let pm = placemarks?.first {
                    let name = pm.subLocality ?? pm.locality ?? pm.administrativeArea ?? "Unknown"
                    // Log available fields for debugging
                    print("Weather geocode: subLocality=\(pm.subLocality ?? "nil"), locality=\(pm.locality ?? "nil"), adminArea=\(pm.administrativeArea ?? "nil"), subAdmin=\(pm.subAdministrativeArea ?? "nil")")
                    UserDefaults.standard.set(name, forKey: "weatherCity")
                    DispatchQueue.main.async { self?.objectWillChange.send() }
                }
            }
        }
        return "Loading..."
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
    let location: String

    // Convert temperature to string with proper formatting
    var temperatureString: String {
        return String(format: "%.1f°C", temperature)
    }
}