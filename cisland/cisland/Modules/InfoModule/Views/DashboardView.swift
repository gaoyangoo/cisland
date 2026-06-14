//
//  DashboardView.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Island. All rights reserved.
//

import SwiftUI

struct DashboardView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            header

            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else {
                cardsGrid
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .onAppear {
            setupWeatherService()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    refreshAllData()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Refresh")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .disabled(isLoading)
            }

            Text("Stay updated with your island information")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading dashboard...")
                .font(.headline)
                .foregroundColor(.primary)

            ProgressView()
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Dashboard Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                refreshAllData()
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    // MARK: - Cards Grid

    private var cardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            MusicCard()
                .frame(height: 200)
                .transition(.scale.animation(.easeInOut))

            CalendarCard()
                .frame(height: 200)
                .transition(.scale.animation(.easeInOut))

            WeatherCard()
                .frame(height: 200)
                .transition(.scale.animation(.easeInOut))
        }
    }

    // MARK: - Actions

    private func refreshAllData() {
        isLoading = true
        errorMessage = nil

        refreshAllDataSources()
    }

    private func refreshAllDataSources() {
        // This method could be expanded to refresh multiple data sources
        // For now, we'll just set up the weather service as it's the primary source
        setupWeatherService()
    }

    private func setupWeatherService() {
        let weatherService = WeatherService.shared
        weatherService.delegate = self
        weatherService.start()

        // Simulate loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            // Check if weather service has data
            if weatherService.currentWeather != nil {
                self.isLoading = false
            } else {
                self.isLoading = false
                // If no weather data after timeout, show placeholder
            }
        }
    }
}

// MARK: - WeatherServiceDelegate

extension DashboardView: WeatherServiceDelegate {
    func weatherServiceDidUpdateWeather(_ weatherService: WeatherService) {
        // Weather data updated, update loading state
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.errorMessage = nil
        }
    }

    func weatherServiceDidFailWithError(_ weatherService: WeatherService, error: Error) {
        // Handle weather service error
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DashboardView()
}