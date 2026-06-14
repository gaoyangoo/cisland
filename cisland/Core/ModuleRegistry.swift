//
//  ModuleRegistry.swift
//  cisland
//
//  Created by Claus on 2026-06-14.
//

import Foundation

/// Registry managing all available island modules and tracking active state
@MainActor
public final class ModuleRegistry: ObservableObject {
    /// Array of all available modules
    public private(set) var modules: [any IslandModule] = []

    /// Index of the currently active module
    @Published public private(set) var activeModuleIndex: Int = 0

    /// Currently active module
    public var activeModule: any IslandModule {
        modules[activeModuleIndex]
    }

    /// Initialize with default modules
    public init() {
        // Will be populated by individual modules conforming to IslandModule
    }

    /// Add a module to the registry
    /// - Parameter module: The module to add
    public func addModule(_ module: any IslandModule) {
        modules.append(module)
    }

    /// Set the active module by index
    /// - Parameter index: Index of the module to activate
    public func setActiveModule(at index: Int) {
        guard index < modules.count else { return }
        activeModuleIndex = index
        modules[index].initialize()
    }

    /// Set the active module by ID
    /// - Parameter id: ID of the module to activate
    public func setActiveModule(id: String) {
        if let index = modules.firstIndex(where: { $0.id == id }) {
            setActiveModule(at: index)
        }
    }

    /// Get module by ID
    /// - Parameter id: ID of the module to retrieve
    /// - Returns: The module if found, nil otherwise
    public func getModule(id: String) -> (any IslandModule)? {
        modules.first(where: { $0.id == id })
    }
}