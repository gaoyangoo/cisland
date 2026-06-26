//
//  WeatherCard.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Island. All rights reserved.
//

import SwiftUI

struct WeatherCard: View {
    @ObservedObject private var weatherService = WeatherService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            header

            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else if let weather = weatherService.currentWeather {
                weatherView(weather: weather)
            } else {
                placeholderView
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "cloud.sun.fill")
                .font(.title2)
                .foregroundColor(.weatherIcon)

            Text("Weather")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {
                refreshWeather()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .disabled(isLoading)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading weather...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)

            Text("Weather Error")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Weather View

    private func weatherView(weather: WeatherModel) -> some View {
        VStack(spacing: 12) {
            // Temperature
            Text(weather.temperatureString)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)

            // Weather Icon
            weatherIcon(for: weather.conditionCode)
                .font(.title)
                .foregroundColor(.weatherIcon)

            // Location
            Text(weather.location)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Last updated
            if let lastUpdated = weatherService.lastUpdated {
                Text("Updated \(lastUpdated.timeAgo())")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No weather data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Weather Icon

    @ViewBuilder
    private func weatherIcon(for conditionCode: Int) -> some View {
        let iconName: String
        let iconColor: Color

        switch conditionCode {
        case 0: // Clear sky
            iconName = "sun.fill"
            iconColor = .yellow
        case 1: // Mainly clear
            iconName = "sun.max.fill"
            iconColor = .orange
        case 2: // Partly cloudy
            iconName = "cloud.sun.fill"
            iconColor = .blue
        case 3: // Overcast
            iconName = "cloud.fill"
            iconColor = .gray
        case 45, 48: // Fog
            iconName = "smoke.fill"
            iconColor = .gray
        case 51, 53, 55, 56, 57: // Drizzle
            iconName = "cloud.drizzle.fill"
            iconColor = .blue
        case 61, 63, 65: // Rain
            iconName = "cloud.rain.fill"
            iconColor = .blue
        case 66, 67: // Freezing rain
            iconName = "cloud.snow.fill"
            iconColor = .cyan
        case 71, 73, 75: // Snow fall
            iconName = "cloud.snow.fill"
            iconColor = .cyan
        case 77: // Snow grains
            iconName = "cloud.snow.fill"
            iconColor = .cyan
        case 80, 81, 82: // Rain showers
            iconName = "cloud.heavyrain.fill"
            iconColor = .blue
        case 85, 86: // Snow showers
            iconName = "cloud.snow.fill"
            iconColor = .cyan
        case 95, 96, 99: // Thunderstorm
            iconName = "cloud.bolt.rain.fill"
            iconColor = .yellow
        default:
            iconName = "cloud.fill"
            iconColor = .gray
        }

        return Image(systemName: iconName)
            .foregroundColor(iconColor)
    }

    // MARK: - Actions

    private func refreshWeather() {
        isLoading = true
        errorMessage = nil

        refreshWeatherData()
    }

    private func refreshWeatherData() {
        // Clear current weather to show loading state
        weatherService.currentWeather = nil

        // Update weather and set up delegate callback
        weatherService.delegate = self

        weatherService.updateWeather()
    }

    // MARK: - Helper Extensions

    struct DateAgoFormatter {
        static let formatter: RelativeDateTimeFormatter = {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter
        }()
    }
}

extension WeatherCard: WeatherServiceDelegateProtocol {
    func weatherServiceDidUpdateWeather(_ weatherService: WeatherService) {
        isLoading = false
        errorMessage = nil
    }

    func weatherServiceDidFailWithError(_ weatherService: WeatherService, error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
    }
}

// MARK: - View Extensions

extension Color {
    static let cardBackground = Color(NSColor.windowBackgroundColor)
    static let weatherIcon = Color.primary
}

extension Date {
    func timeAgo() -> String {
        return WeatherCard.DateAgoFormatter.formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    WeatherCard()
}