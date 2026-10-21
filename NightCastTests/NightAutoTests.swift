import Foundation
import NightCastCore
import Testing
@testable import NightCast

/// exp_night_auto: starting an episode late at night turns Sleep on, once per load.
@MainActor
@Suite(.serialized)
struct NightAutoTests {
    private static func episode(_ n: Int) -> Episode {
        Episode(
            id: "night-\(n)",
            showFeedURL: URL(string: "https://fixtures.nightcast.invalid/quiet.xml")!,
            showTitle: "Quiet Hours",
            title: "Night \(n)",
            published: nil,
            duration: 90,
            audioURL: Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a")!
        )
    }

    private func withFlag(_ on: Bool, hour: Int, _ body: (AppModel) -> Void) {
        let previous = Experiments.isOn(.nightAuto)
        Experiments.set(.nightAuto, on)
        defer { Experiments.set(.nightAuto, previous) }
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
        withFlag(true, hour: 23) { model in
            model.play(Self.episode(1))
            #expect(model.sleepStatus != .off)
            #expect(model.nightNote == "It’s late, so Sleep is on.")
        }
    }

    @Test func daytimeStartLeavesSleepOff() {
        withFlag(true, hour: 14) { model in
            model.play(Self.episode(1))
            #expect(model.sleepStatus == .off)
            #expect(model.nightNote == nil)
        }
    }

    @Test func flagOffLeavesSleepOff() {
        withFlag(false, hour: 23) { model in
            model.play(Self.episode(1))
            #expect(model.sleepStatus == .off)
            #expect(model.nightNote == nil)
        }
    }

    @Test func turningSleepOffSticksForTheSameLoad() {
        withFlag(true, hour: 23) { model in
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
}
