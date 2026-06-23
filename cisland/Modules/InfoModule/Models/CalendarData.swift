//
//  CalendarData.swift
//  cisland
//
//  Created by Claus on 6/14/24.
//  Copyright © 2024 Claus. All rights reserved.
//

import Foundation
import SwiftData

struct CalendarData {
    struct Event {
        let id: UUID
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let location: String?
        let color: String?

        init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, isAllDay: Bool = false, location: String? = nil, color: String? = nil) {
            self.id = id
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.isAllDay = isAllDay
            self.location = location
            self.color = color
        }
    }

    let currentDate: Date
    let weekDates: [Date]
    let selectedDate: Date?
    let events: [Event]

    init(currentDate: Date = Date(), weekDates: [Date]? = nil, selectedDate: Date? = nil, events: [Event] = []) {
        self.currentDate = currentDate
        self.selectedDate = selectedDate
        self.events = events
        self.weekDates = weekDates ?? Self.generateWeekDates(for: currentDate)
    }

    private static func generateWeekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let startOfWeek = calendar.date(from: components)!

        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        }
    }
}