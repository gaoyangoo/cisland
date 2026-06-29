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

    @Published var currentWeather: WeatherModel?
    @Published var lastUpdated: Date?
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

    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        updateWeather()
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
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
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let current = json["current_condition"] as? [[String: Any]],
                  let condition = current.first,
                  let tempC = condition["temp_C"] as? String,
                  let temperature = Double(tempC),
                  let weatherCodeStr = condition["weatherCode"] as? String,
                  let weatherCode = Int(weatherCodeStr) else {
                self.isUpdating = false
                return
            }

            var location = getCurrentLocationString()
            // If geocode hasn't completed yet, trigger it now
            if location == "Loading..." { triggerReverseGeocode() }

            var tomorrowTemp: String? = nil
            var tomorrowCode: Int? = nil
            if let weatherArr = json["weather"] as? [[String: Any]], weatherArr.count >= 2 {
                let tomorrow = weatherArr[1]
                if let tMin = tomorrow["mintempC"] as? String,
                   let tMax = tomorrow["maxtempC"] as? String,
                   let hly = tomorrow["hourly"] as? [[String: Any]],
                   let midday = hly.first(where: { ($0["time"] as? String) == "1200" }),
                   let codeStr = midday["weatherCode"] as? String,
                   let code = Int(codeStr) {
                    tomorrowTemp = "\(tMin)~\(tMax)"
                    tomorrowCode = code
                }
            }

            let weather = WeatherModel(
                temperature: temperature,
                conditionCode: weatherCode,
                location: location,
                tomorrowTemp: tomorrowTemp,
                tomorrowCode: tomorrowCode
            )

            DispatchQueue.main.async {
                self.currentWeather = weather
                self.lastUpdated = Date()
                self.isUpdating = false
                self.delegate?.weatherServiceDidUpdateWeather(self)
            }
        } catch {
            self.isUpdating = false
            handleWeatherServiceError(error)
        }
    }

    private func getCurrentLocationString() -> String {
        if let cached = UserDefaults.standard.string(forKey: "weatherCity"), !cached.isEmpty {
            return cached
        }
        triggerReverseGeocode()
        return "Loading..."
    }

    private func triggerReverseGeocode() {
        guard let loc = locationManager.location else { return }
        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            guard let self, let pm = placemarks?.first else { return }
            // Iterate all available fields to find the most specific Chinese name
            let name = pm.subLocality          // e.g. 浦东新区
                    ?? pm.thoroughfare          // e.g. 世纪大道
                    ?? pm.subAdministrativeArea // e.g. 浦东新区 (alt)
                    ?? pm.administrativeArea    // e.g. 上海市
                    ?? pm.locality              // e.g. 上海市
                    ?? pm.country
                    ?? "Unknown"
            if !name.isEmpty, name != UserDefaults.standard.string(forKey: "weatherCity") {
                UserDefaults.standard.set(name, forKey: "weatherCity")
                DispatchQueue.main.async { self.objectWillChange.send() }
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
    let location: String
    let tomorrowTemp: String?
    let tomorrowCode: Int?

    var temperatureString: String {
        return String(format: "%.0f°", temperature)
    }

    var tomorrowString: String? {
        guard let t = tomorrowTemp, let c = tomorrowCode else { return nil }
        return "\(t)°  \(WeatherModel.iconFor(code: c))"
    }

    static func iconFor(code: Int) -> String {
        // wttr.in weather codes
        switch code {
        case 113: return "☀️"       // Sunny
        case 116: return "🌤️"       // Partly cloudy
        case 119, 122: return "☁️"  // Cloudy / Overcast
        case 143, 248, 260: return "🌫️" // Mist / Fog
        case 176, 263, 266, 293...296: return "🌦️" // Light rain
        case 179, 281...284, 299, 302, 305, 308: return "🌧️" // Moderate/heavy rain
        case 182, 185: return "🌧️"  // Heavy sleet
        case 200, 386, 389: return "⛈️" // Thunder
        case 227, 230, 320, 323, 326, 329, 332, 335, 338...350: return "🌨️" // Snow
        case 311...318: return "🌨️" // Sleet
        default: return "☁️"
        }
    }
}