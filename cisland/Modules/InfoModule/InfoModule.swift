//
//  InfoModule.swift
//  cisland
//
//  Created by Claus on 6/14/24.
//  Copyright © 2024 Claus. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
public class InfoModule: ObservableObject, IslandModule {
    public var id: String { "info" }
    public var displayName: String { "Info" }
    public var tabIcon: String {
        "info.circle.fill"
    }
    public var accentColor: Color {
        Color(red: 0.05, green: 0.45, blue: 0.25)
    }
    public var expandedHeight: CGFloat {
        600
    }

    public var expandedView: AnyView {
        AnyView(contentView())
    }

    public init() {}

    // MARK: - IslandModule Conformance

    public func initialize() {
        // Initialize info module
        print("InfoModule initialized")
    }

    public var body: some View {
        VStack(spacing: 0) {
            moduleHeader()
            contentView()
        }
    }

    private func moduleHeader() -> some View {
        HStack {
            Image(systemName: tabIcon)
                .font(.title2)
                .foregroundColor(accentColor)

            Text("Info")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
    }

    private func contentView() -> some View {
        VStack(spacing: 20) {
            WelcomeSection()
            CalendarSection()
            StatsSection()
        }
        .padding()
    }
}

// MARK: - Content Sections
private struct WelcomeSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Claus Island")
                .font(.title2.bold())

            Text("Your personal information dashboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CalendarSection: View {
    @State private var calendarData = CalendarData()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.headline)

            CalendarGridView(calendarData: calendarData)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            StatsGrid()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CalendarGridView: View {
    let calendarData: CalendarData

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(calendarData.weekDates, id: \.self) { date in
                    CalendarDayView(date: date)
                }
            }
            .padding()
        }
    }
}

private struct CalendarDayView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.caption2)
                .fontWeight(.medium)

            Text(date.formatted(.dateTime.day()))
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(width: 50, height: 70)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct StatsGrid: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            StatsCard(
                title: "Events",
                value: "12",
                icon: "calendar"
            )

            StatsCard(
                title: "Tasks",
                value: "8",
                icon: "checklist"
            )

            StatsCard(
                title: "Notes",
                value: "24",
                icon: "note.text"
            )
        }
    }
}

private struct StatsCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

