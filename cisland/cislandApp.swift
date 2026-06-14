//
//  cislandApp.swift
//  cisland
//
//  Created by claus on 2026/6/14.
//

import SwiftUI

@main
struct cislandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            EmptyView()
        }
    }
}
