//
//  CalendarCard.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Inc. All rights reserved.
//

import SwiftUI

struct CalendarCard: View {
    @ObservedObject private var calendarService = CalendarService()

    var body: some View {
        VStack(spacing: 16) {
            headerView

            if calendarService.isLoading {
                loadingView
            } else if let errorMessage = calendarService.errorMessage {
                errorView(message: errorMessage)
            } else if calendarService.events.isEmpty {
                emptyView
            } else {
                eventsListView
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.accentColor)
                .font(.title2)

            Text("Calendar")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if calendarService.hasCalendarAccess {
                Text("Next 7 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)

            Text("Loading events...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.title2)

            Text("Calendar Error")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                calendarService.fetchEvents()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .foregroundColor(.secondary)
                .font(.title2)

            Text("No events")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("You don't have any upcoming events")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var eventsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(calendarService.events.prefix(5), id: \.id) { event in
                    EventRowView(event: event)
                }
            }
        }
    }
}

private struct EventRowView: View {
    let event: CalendarData.Event

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if hasLocation {
                    Image(systemName: "location.circle.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            if let color = event.color, !color.isEmpty {
                Text(color)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var hasLocation: Bool {
        guard let location = event.location else { return false }
        return !location.isEmpty && location != "Home" && location != "Office"
    }
}

#Preview {
    CalendarCard()
}