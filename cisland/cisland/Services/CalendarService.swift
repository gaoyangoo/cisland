//
//  CalendarService.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Inc. All rights reserved.
//

import Foundation
import EventKit

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?

    @Published var events: [EKEvent] = []
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
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasCalendarAccess = granted
                if !granted {
                    self?.errorMessage = "Calendar access denied. Please enable calendar access in Settings."
                } else {
                    self?.fetchEvents()
                }
            }
        }
    }

    // MARK: - Event Management

    func fetchEvents() {
        guard hasCalendarAccess else { return }

        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let calendars = self?.eventStore.calendars(for: .event) ?? []
                let startDate = Date()
                let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

                let predicate = self?.eventStore.predicateForEvents(
                    withStart: startDate,
                    end: endDate,
                    calendars: calendars
                )

                let events = try self?.eventStore.events(matching: predicate ?? NSPredicate()) ?? []

                DispatchQueue.main.async {
                    self?.events = events.sorted { $0.startDate < $1.startDate }
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
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