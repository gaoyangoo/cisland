//
//  CalendarServiceTests.swift
//  cisland
//
//  Created by Claus on 14/06/2026.
//  Copyright © 2026 Claus Inc. All rights reserved.
//

import XCTest
import Combine
@testable import cisland

class CalendarServiceTests: XCTestCase {

    var calendarService: CalendarService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        calendarService = CalendarService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        calendarService = nil
        cancellables = nil
        super.tearDown()
    }

    func testCalendarServiceInitialization() {
        XCTAssertNotNil(calendarService)
        XCTAssertEqual(calendarService.events.count, 0)
        XCTAssertEqual(calendarService.hasCalendarAccess, false)
        XCTAssertEqual(calendarService.isLoading, true)
        XCTAssertNil(calendarService.errorMessage)
    }

    func testCalendarServiceHasObservableObjectConformance() {
        let expectation = XCTestExpectation(description: "ObservableObject conformance")
        calendarService.$hasCalendarAccess
            .dropFirst()
            .sink { hasAccess in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }
}