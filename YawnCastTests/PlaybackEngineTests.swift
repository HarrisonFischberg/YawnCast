import AVFoundation
import Foundation
import YawnCastCore
import Testing
@testable import YawnCast

/// The engine's edge paths: interruptions, seeking before the item is ready, Play after a failed load.
@MainActor
@Suite(.serialized)
struct PlaybackEngineTests {
    private static func episode(_ url: URL) -> Episode {
        Episode(id: "engine-\(url.lastPathComponent)", showFeedURL: URL(string: "https://fixtures.yawncast.invalid/quiet.xml")!,
                showTitle: "Quiet Hours", title: "Engine", published: nil, duration: 90, audioURL: url)
    }
    private static let tone = episode(Bundle.main.url(forResource: "fixture-tone", withExtension: "m4a")!)
    /// A local file that doesn't exist: the item fails without any network.
    private static let broken = episode(URL(fileURLWithPath: "/nonexistent/yawncast-missing.m4a"))

    /// Each engine listens on its own center, so posted notifications never reach the host app's engine.
    private let center = NotificationCenter()
    private func engine() -> PlaybackEngine { PlaybackEngine(center: center) }
    private func failed(_ engine: PlaybackEngine) -> Bool { if case .failed = engine.loadState { true } else { false } }

    private func wait(_ what: String, _ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(25)) }
        #expect(condition(), "\(what)")
    }

    private func interruption(_ type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions = []) {
        center.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: type.rawValue,
            AVAudioSessionInterruptionOptionKey: options.rawValue,
        ])
    }

    @Test func playingResumesAfterAnInterruptionEvenIfTheSystemPausedFirst() async {
        let engine = engine()
        engine.load(Self.tone, start: 0, autoplay: true)
        await wait("playing") { engine.isPlaying }
        // The system pauses the player before the .began notification arrives.
        engine.player.pause()
        await wait("paused") { !engine.isPlaying }
        interruption(.began)
        try? await Task.sleep(for: .milliseconds(100))
        interruption(.ended, options: .shouldResume)
        await wait("resumed") { engine.isPlaying }
        engine.pause()
    }

    @Test func pausedByTheListenerStaysPausedAfterAnInterruption() async {
        let engine = engine()
        engine.load(Self.tone, start: 0, autoplay: true)
        await wait("playing") { engine.isPlaying }
        engine.pause()
        await wait("paused") { !engine.isPlaying }
        interruption(.began)
        interruption(.ended, options: .shouldResume)
        try? await Task.sleep(for: .milliseconds(300))
        #expect(!engine.isPlaying)
    }

    @Test func seekingBeforeTheItemIsReadyKeepsThePositionAndSavesIt() {
        let engine = engine()
        var saved: [TimeInterval] = []
        engine.onProgress = { _, position, _, _ in saved.append(position) }
        engine.load(Self.broken, start: 0, autoplay: false)
        engine.seek(to: 30) // used to raise an AVFoundation exception while not readyToPlay
        engine.skip(by: 15)
        #expect(engine.position == 45)
        #expect(saved.last == 45)
    }

    @Test func playAfterAFailedLoadReloadsTheEpisode() async {
        let engine = engine()
        engine.load(Self.broken, start: 0, autoplay: false)
        await wait("failed") { failed(engine) }
        engine.play()
        #expect(engine.loadState == .loading)
        engine.pause()
    }

    private func playing() async -> PlaybackEngine {
        let engine = engine()
        engine.load(Self.tone, start: 0, autoplay: true)
        await wait("playing") { engine.isPlaying }
        return engine
    }

    @Test func pauseDuringAnInterruptionStaysPaused() async {
        let engine = await playing()
        engine.player.pause()
        interruption(.began)
        engine.pause()
        interruption(.ended, options: .shouldResume)
        try? await Task.sleep(for: .milliseconds(300))
        #expect(!engine.isPlaying)
    }

    @Test func sleepPauseDuringAnInterruptionStaysPaused() async {
        let engine = await playing()
        engine.player.pause()
        interruption(.began)
        engine.pauseForSleep()
        interruption(.ended, options: .shouldResume)
        try? await Task.sleep(for: .milliseconds(300))
        #expect(!engine.isPlaying)
    }

    @Test func unplugDuringAnInterruptionStaysPaused() async {
        let engine = await playing()
        engine.player.pause()
        interruption(.began)
        center.post(name: AVAudioSession.routeChangeNotification, object: nil, userInfo: [
            AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue,
        ])
        try? await Task.sleep(for: .milliseconds(100))
        interruption(.ended, options: .shouldResume)
        try? await Task.sleep(for: .milliseconds(300))
        #expect(!engine.isPlaying)
    }

    @Test func aFailedEpisodeIsNotReloadedByAnInterruptionEnding() async {
        let engine = engine()
        engine.load(Self.broken, start: 0, autoplay: true)
        await wait("failed") { failed(engine) }
        interruption(.began)
        interruption(.ended, options: .shouldResume)
        try? await Task.sleep(for: .milliseconds(200))
        #expect(failed(engine), "nobody asked to play")
        engine.play() // an explicit tap still retries
        #expect(engine.loadState == .loading)
    }

    @Test func toggleAfterAFailedPlayRetriesEveryTime() async {
        let engine = engine()
        engine.load(Self.broken, start: 0, autoplay: true) // waiting to play, then fails
        await wait("failed") { failed(engine) }
        engine.togglePlayPause()
        #expect(engine.loadState == .loading)
        await wait("failed again") { failed(engine) }
        engine.togglePlayPause()
        #expect(engine.loadState == .loading)
    }

    @Test func toggleSwitchesBetweenPlayingAndPaused() async {
        let engine = await playing()
        engine.togglePlayPause()
        await wait("paused") { !engine.isPlaying }
        engine.togglePlayPause()
        await wait("playing again") { engine.isPlaying }
        engine.pause()
    }
}
