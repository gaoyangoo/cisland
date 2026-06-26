//
//  CalendarService.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Inc. All rights reserved.
//

import Foundation

class CalendarService: ObservableObject {
    private var refreshTimer: Timer?

    @Published var events: [CalendarData.Event] = []
    @Published var hasCalendarAccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Initialization

    init() {
        requestCalendarAccess()
        startPeriodicRefresh()
    }

    deinit {
        stopPeriodicRefresh()
    }

    // MARK: - Calendar Access

    func requestCalendarAccess() {
        // Simplified - assume access granted
        hasCalendarAccess = true
        fetchEvents()
    }

    // MARK: - Event Management

    func fetchEvents() {
        guard hasCalendarAccess else { return }

        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Create sample calendar data for demo
            let sampleEvents = [
                CalendarData.Event(
                    title: "Team Meeting",
                    startDate: Date().addingTimeInterval(3600),
                    endDate: Date().addingTimeInterval(7200),
                    isAllDay: false,
                    color: "Blue"
                ),
                CalendarData.Event(
                    title: "Lunch with Client",
                    startDate: Date().addingTimeInterval(86400),
                    endDate: Date().addingTimeInterval(90000),
                    isAllDay: false,
                    color: "Green"
                )
            ]

            DispatchQueue.main.async {
                self?.events = sampleEvents.sorted { $0.startDate < $1.startDate }
                self?.isLoading = false
            }
        }
    }

    // MARK: - Periodic Refresh

    private func startPeriodicRefresh() {
        stopPeriodicRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}