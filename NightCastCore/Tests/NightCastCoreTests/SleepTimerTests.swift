import Foundation
import Testing
@testable import NightCastCore

@Suite("SleepTimer — V1 spec")
struct SleepTimerTests {
    let min = 60.0

    // MARK: M4.1 fade delay

    @Test("Fade delay: long episode caps at 30 min")
    func fadeDelayLong() {
        #expect(SleepTimer.fadeDelay(remaining: 3 * 3600) == 30 * min)
        #expect(SleepTimer.fadeDelay(remaining: 60 * min) == 30 * min)
    }

    @Test("Fade delay: short episode uses R/2")
    func fadeDelayShort() {
        #expect(SleepTimer.fadeDelay(remaining: 40 * min) == 20 * min)
        #expect(SleepTimer.fadeDelay(remaining: 90) == 45)
        #expect(SleepTimer.fadeDelay(remaining: 0) == 0)
    }

    @Test("Fade delay: unknown duration uses 30 min")
    func fadeDelayUnknown() {
        #expect(SleepTimer.fadeDelay(remaining: nil) == 30 * min)
        #expect(SleepTimer.fadeDelay(remaining: .infinity) == 30 * min)
        #expect(SleepTimer.fadeDelay(remaining: .nan) == 30 * min)
    }

    @Test("Activation returns the delay and reports waiting")
    func activation() {
        var timer = SleepTimer()
        let delay = timer.activate(baseline: 1, remaining: 40 * min)
        #expect(delay == 20 * min)
        #expect(timer.isActive)
        #expect(timer.status == .waiting(untilFade: 20 * min))
        #expect(timer.gain == 1)
    }

    // MARK: M4.2 deterministic gain sequence

    @Test("Gain holds at baseline until fade starts")
    func holdsBaseline() {
        var timer = SleepTimer()
        timer.activate(baseline: 0.9, remaining: nil)
        timer.advance(activeSeconds: 30 * min - 0.001)
        #expect(timer.gain == 0.9)
        #expect(timer.isActive)
    }

    @Test("Exact step levels after each 2 s ramp", arguments: [
        (0, 0.8), (1, 0.6), (2, 0.4), (3, 0.2),
    ])
    func stepLevels(step: Int, level: Double) {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 30 * 60 + Double(step) * 180 + 2)
        #expect(abs(timer.gain - level) < 1e-9)
        #expect(timer.status == .fading(level: level))
        // Holds until the next step.
        timer.advance(activeSeconds: 177.9)
        #expect(abs(timer.gain - level) < 1e-9)
    }

    @Test("Steps are smoothed: halfway through a ramp is halfway between levels")
    func rampMidpoint() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 30 * min + 1) // halfway 1.0 → 0.8
        #expect(abs(timer.gain - 0.9) < 1e-9)
        timer.advance(activeSeconds: 180) // F + 181: halfway 0.8 → 0.6
        #expect(abs(timer.gain - 0.7) < 1e-9)
    }

    @Test("Baseline scales every step")
    func baselineScales() {
        var timer = SleepTimer()
        timer.activate(baseline: 0.5, remaining: nil)
        timer.advance(activeSeconds: 30 * min + 180 + 2)
        #expect(abs(timer.gain - 0.3) < 1e-9)
    }

    @Test("Full sequence sampled every second is identical across runs")
    func deterministic() {
        func run() -> [Double] {
            var timer = SleepTimer()
            timer.activate(baseline: 1, remaining: 50 * min)
            var out: [Double] = []
            for _ in 0..<(40 * 60) {
                timer.advance(activeSeconds: 1)
                out.append(timer.gain)
            }
            return out
        }
        #expect(run() == run())
    }

    // MARK: M4.5 reaching zero

    @Test("Reaching zero fires once, ends Sleep, restores baseline")
    func reachesSilence() {
        var timer = SleepTimer()
        timer.activate(baseline: 0.8, remaining: nil)
        let silence = 30 * min + 4 * 180 + 2
        #expect(timer.advance(activeSeconds: silence - 0.5) == nil)
        #expect(timer.gain < 0.8 * 0.2) // gliding 0.2 → 0
        #expect(timer.advance(activeSeconds: 0.5) == .reachedSilence)
        #expect(!timer.isActive)
        #expect(timer.status == .off)
        #expect(timer.gain == 0.8)
        #expect(timer.advance(activeSeconds: 600) == nil)
    }

    @Test("One huge advance still reports silence exactly once")
    func hugeAdvance() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        #expect(timer.advance(activeSeconds: 10 * 3600) == .reachedSilence)
        #expect(timer.advance(activeSeconds: 1) == nil)
    }

    @Test("Zero, negative, NaN advances change nothing")
    func ignoresBadInput() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        let before = timer
        timer.advance(activeSeconds: 0)
        timer.advance(activeSeconds: -5)
        timer.advance(activeSeconds: .nan)
        #expect(timer == before)
    }

    // MARK: M4.4 cancel

    @Test("Cancel while waiting restores immediately")
    func cancelWaiting() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 60)
        timer.cancel(isPlaying: true)
        #expect(!timer.isActive)
        #expect(timer.gain == 1)
    }

    @Test("Cancel while fading and playing glides back to baseline over 1 s")
    func cancelFadingPlaying() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: nil)
        timer.advance(activeSeconds: 30 * min + 2 * 180 + 2) // at 0.4
        timer.cancel(isPlaying: true)
        #expect(!timer.isActive)
        #expect(abs(timer.gain - 0.4) < 1e-9)
        timer.advance(activeSeconds: 0.5)
        #expect(abs(timer.gain - 0.7) < 1e-9)
        timer.advance(activeSeconds: 0.5)
        #expect(timer.gain == 1)
        #expect(timer.status == .off)
    }

    @Test("Cancel while paused restores baseline at once")
    func cancelFadingPaused() {
        var timer = SleepTimer()
        timer.activate(baseline: 0.7, remaining: nil)
        timer.advance(activeSeconds: 30 * min + 2)
        timer.cancel(isPlaying: false)
        #expect(timer.gain == 0.7)
        #expect(!timer.isActive)
    }

    // MARK: M4.6 episode end

    @Test("end() turns Sleep off with baseline gain")
    func endRestores() {
        var timer = SleepTimer()
        timer.activate(baseline: 1, remaining: 10 * min)
        timer.advance(activeSeconds: 5 * min + 100)
        #expect(timer.gain < 1)
        timer.end()
        #expect(!timer.isActive)
        #expect(timer.gain == 1)
    }
}
