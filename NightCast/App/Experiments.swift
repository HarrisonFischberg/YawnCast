import Foundation

/// One case per Evolve iteration. Each is OFF for App Store users no matter what.
enum Experiment: String, CaseIterable, Identifiable {
    /// Press Play soon after Sleep pauses and Sleep turns back on.
    case wakeExtend = "exp_wake_extend"
    /// After Sleep, Now Playing offers a jump back to where the fade began.
    case driftBack = "exp_drift_back"
    /// Sleep status shows on the Lock Screen and in Control Center.
    case lockStatus = "exp_lock_status"
    /// A Moon key on the mini player.
    case miniMoon = "exp_mini_moon"
    /// Starting an episode late at night turns Sleep on.
    case nightAuto = "exp_night_auto"

    var id: String { key }

    /// UserDefaults key and launch argument (`-<key> YES`).
    var key: String { rawValue }

    var title: String {
        switch self {
        case .wakeExtend: "Play again turns Sleep back on"
        case .driftBack: "Back to where you drifted off"
        case .lockStatus: "Sleep on the Lock Screen"
        case .miniMoon: "Moon on the mini player"
        case .nightAuto: "Sleep turns on late at night"
        }
    }
}

/// Feature flags for Evolve iterations. Overrides live in their own UserDefaults suite
/// (`evolve.experiments`), apart from the library, so clearing them can't touch real data.
enum Experiments {
    private static let store = UserDefaults(suiteName: "evolve.experiments")!
    /// Launch arguments like `-evolve_all YES` land in the standard defaults' argument domain,
    /// so `NO` reads as false instead of counting as present.
    private static let launchDefaults = UserDefaults.standard
    private static let allOnByLaunch = launchDefaults.bool(forKey: "evolve_all")

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
        if allOnByLaunch { return true }
        if launchDefaults.volatileDomain(forName: UserDefaults.argumentDomain)[experiment.key] != nil {
            return launchDefaults.bool(forKey: experiment.key)
        }
        return store.bool(forKey: experiment.key)
    }

    /// Posted when the Experiments screen changes a switch, for flags that are cached.
    static let didChange = Notification.Name("evolve.experiments.didChange")

    static func set(_ experiment: Experiment, _ on: Bool) {
        store.set(on, forKey: experiment.key)
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func setAll(_ on: Bool) {
        Experiment.allCases.forEach { set($0, on) }
    }

    static func reset() {
        Experiment.allCases.forEach { store.removeObject(forKey: $0.key) }
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}
