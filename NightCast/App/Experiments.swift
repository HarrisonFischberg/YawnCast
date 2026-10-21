import Foundation

/// One case per Evolve iteration. Each is OFF for App Store users no matter what.
enum Experiment: CaseIterable, Identifiable {
    var id: String { key }

    /// UserDefaults key and launch argument (`-<key> YES`).
    var key: String {
        switch self {}
    }

    var title: String {
        switch self {}
    }
}

/// Feature flags for Evolve iterations. Overrides live in their own UserDefaults suite
/// (`evolve.experiments`), apart from the library, so clearing them can't touch real data.
enum Experiments {
    private static let store = UserDefaults(suiteName: "evolve.experiments")!
    private static let arguments = ProcessInfo.processInfo.arguments
    private static let allOnByLaunch = arguments.contains("-evolve_all")

    /// Debug and TestFlight/sandbox builds only. Always false from the App Store.
    static let canOverride: Bool = {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }()

    static func isOn(_ experiment: Experiment) -> Bool {
        guard canOverride else { return false }
        if allOnByLaunch || arguments.contains("-\(experiment.key)") { return true }
        return store.bool(forKey: experiment.key)
    }

    static func set(_ experiment: Experiment, _ on: Bool) {
        store.set(on, forKey: experiment.key)
    }

    static func setAll(_ on: Bool) {
        Experiment.allCases.forEach { set($0, on) }
    }

    static func reset() {
        Experiment.allCases.forEach { store.removeObject(forKey: $0.key) }
    }
}
