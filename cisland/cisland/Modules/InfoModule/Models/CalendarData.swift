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
        let color: String?

        init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, isAllDay: Bool = false, color: String? = nil) {
            self.id = id
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.isAllDay = isAllDay
            self.color = color
        }

        var isAllDay: Bool {
            return startDate.isAllDay && endDate.isAllDay
        }
    }

    let currentDate: Date
    let weekDates: [Date]
    let selectedDate: Date?
    let events: [Event]

    init(currentDate: Date = Date(), weekDates: [Date]? = nil, selectedDate: Date? = nil, events: [Event] = []) {
        self.currentDate = currentDate
        self.weekDates = weekDates ?? generateWeekDates(for: currentDate)
        self.selectedDate = selectedDate
        self.events = events
    }

    private func generateWeekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let startOfWeek = calendar.date(from: components)!

        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        }
    }
}