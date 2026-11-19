import Foundation
import Testing
@testable import YawnCastCore

/// Pocket Casts bug class: a timer that survives relaunch and cuts audio later.
/// YawnCast's rule (DECISIONS: "Sleep state is never persisted"): a relaunch
/// always starts with Sleep off. A "relaunch" here = persisted state on disk +
/// a brand-new controller and clock.
@MainActor
@Suite("Sleep — relaunch")
struct SleepRelaunchTests {
    @Test("Persisted state carries no Sleep data, even after a Sleep session")
    func snapshotHasNoSleepState() throws {
        let clock = FakeClock(), player = FakePlayer()
        let controller = SleepController(clock: clock, configuration: .v1)
        controller.toggle(player: player, episodeID: "e1", remaining: 3600)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("relaunch-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try JSONLibraryStore(fileURL: url).save(LibrarySnapshot(themeID: "t"))
        let json = try String(contentsOf: url, encoding: .utf8).lowercased()
        #expect(!json.contains("sleep") && !json.contains("fade") && !json.contains("timer"))
    }

    @Test("After relaunch a stale timer is off and never pauses playback, even a day later")
    func staleTimerDoesNotRestore() {
        // Session 1: Sleep on, 20 min in, then the app dies.
        let clock1 = FakeClock(), player1 = FakePlayer()
        let first = SleepController(clock: clock1, configuration: .v1)
        first.toggle(player: player1, episodeID: "e1", remaining: 20 * 60)
        clock1.advance(5 * 60)
        first.sync()

        // Session 2, a day later: fresh controller, fresh clock, user plays again.
        let clock2 = FakeClock(), player2 = FakePlayer()
        let second = SleepController(clock: clock2, configuration: .v1)
        #expect(!second.isActive)
        #expect(!second.needsTicks)
        #expect(second.status == .off)
        #expect(second.episodeID == nil)

        for _ in 0..<(3 * 3600 * 4) { // 3 h of playback at 4 Hz
            clock2.advance(0.25)
            second.sync()
        }
        #expect(player2.pauseCount == 0)
        #expect(player2.isPlaying)
        #expect(player2.gain == 1)
    }

    @Test("A timer still running does not restore: Sleep is never resumed, remaining time is not carried over")
    func runningTimerIsNotRestored() {
        let clock1 = FakeClock(), player1 = FakePlayer()
        let first = SleepController(clock: clock1, configuration: .v1)
        first.toggle(player: player1, episodeID: "e1", remaining: 3600)
        clock1.advance(10 * 60)
        first.sync()
        #expect(first.isActive)

        let second = SleepController(clock: FakeClock(), configuration: .v1)
        #expect(second.status == .off)
        #expect(second.timer.elapsed == nil)
    }
}
