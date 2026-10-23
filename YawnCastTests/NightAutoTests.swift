import Foundation
import YawnCastCore
import Testing
@testable import YawnCast

/// Night auto: starting an episode late at night turns Sleep on, once per load.
@MainActor
@Suite(.serialized)
struct NightAutoTests {
    private static func episode(_ n: Int) -> Episode {
        Episode(
            id: "night-\(n)",
            showFeedURL: URL(string: "https://fixtures.yawncast.invalid/quiet.xml")!,
            showTitle: "Quiet Hours",
            title: "Night \(n)",
            published: nil,
            duration: 90,
            audioURL: Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a")!
        )
    }

    private func atHour(_ hour: Int, _ body: (AppModel) -> Void) {
        let model = AppModel(store: MemoryLibraryStore(), directory: FixtureDirectory(), feeds: FixtureFeedService())
        model.currentHour = { hour }
        body(model)
        model.player.pause()
    }

    @Test func windowIsTenPMToBeforeFiveAM() {
        for hour in [22, 23, 0, 1, 4] { #expect(AppModel.isLate(hour: hour), "\(hour)") }
        for hour in [5, 6, 12, 14, 21] { #expect(!AppModel.isLate(hour: hour), "\(hour)") }
    }

    @Test func nightHourLaunchArgument() {
        #expect(LaunchOptions(arguments: ["-nightHour", "23"]).nightHour == 23)
        #expect(LaunchOptions(arguments: ["-nightHour", "0"]).nightHour == 0)
        #expect(LaunchOptions(arguments: ["-nightHour", "24"]).nightHour == nil)
        #expect(LaunchOptions(arguments: ["-nightHour"]).nightHour == nil)
        #expect(LaunchOptions(arguments: []).nightHour == nil)
    }

    @Test func lateStartTurnsSleepOnWithNote() {
        atHour(23) { model in
            model.play(Self.episode(1))
            #expect(model.sleepStatus != .off)
            #expect(model.nightNote == "It’s late, so Sleep is on.")
        }
    }

    @Test func daytimeStartLeavesSleepOff() {
        atHour(14) { model in
            model.play(Self.episode(1))
            #expect(model.sleepStatus == .off)
            #expect(model.nightNote == nil)
        }
    }

    @Test func turningSleepOffSticksForTheSameLoad() {
        atHour(23) { model in
            let episode = Self.episode(1)
            model.play(episode)
            model.toggleSleep()
            #expect(model.sleepStatus == .off)
            #expect(model.nightNote == nil)
            model.player.pause()
            model.play(episode)
            #expect(model.sleepStatus == .off, "resume does not re-arm")
            // A different episode is a new load (D07 cancels, then this re-arms).
            model.play(Self.episode(2))
            #expect(model.sleepStatus != .off)
        }
    }
    @Test func openingAnEpisodeLoadsItPausedWithSleepOff() {
        atHour(23) { model in
            model.open(Self.episode(1))
            #expect(model.player.episode?.id == "night-1")
            #expect(model.isPlayerPresented)
            #expect(model.sleepStatus == .off, "Sleep waits for Play")
            #expect(model.nightNote == nil)
        }
    }

    /// Any play (mini player, Now Playing, Lock Screen) arms Sleep, not just a row tap.
    @Test func lateTransportPlayTurnsSleepOn() async {
        let model = AppModel(store: MemoryLibraryStore(), directory: FixtureDirectory(), feeds: FixtureFeedService())
        model.currentHour = { 23 }
        model.open(Self.episode(1))
        model.player.togglePlayPause()
        for _ in 0..<40 where model.sleepStatus == .off {
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(model.sleepStatus != .off)
        #expect(model.nightNote == "It’s late, so Sleep is on.")
        model.player.pause()
    }
}
