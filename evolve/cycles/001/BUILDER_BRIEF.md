# Builder brief (cycle 001, one iteration per builder)

Repo: /Users/harrison/projects/YawnCast-evolve (a fresh clone; never touch ~/projects/yawncast). Native SwiftUI iPhone app YawnCast.
Simulator: "YawnCast iPhone" (UDID 320413B0-276D-486C-B9A9-568500A1A47A). Use `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
Builders run one at a time, so you own the repo working tree and the simulator while you run.

## Steps
1. `git checkout evolve/001/base && git checkout -b evolve/001/<slug>`. Clean tree required.
2. Read your card `evolve/cycles/001/cards/<slug>.md`, `evolve/DESIGN.md`, `YawnCast/App/Experiments.swift`, and the code it names. Read `DECISIONS.md` D07 (Sleep edge rules) before touching Sleep.
3. Build the change behind `Experiments.isOn(.<case>)` at the smallest seam, so with the flag OFF the old path is byte-for-byte the same behavior. No flag reads on a hot path without caching (Experiments caches launch args; `isOn` reads UserDefaults, fine for event handlers, not per-frame/per-tick; cache in a stored property if needed).
4. **Impeccable pass** (use the `impeccable` skill: shape, then critique, then polish) on any UI you add, against `evolve/DESIGN.md` and Apple HIG for SwiftUI. Record what it changed or kept.
5. **Accessibility check** (use the `ios-accessibility` skill as reference): VoiceOver label/identifier, Dynamic Type including accessibility sizes, contrast per DESIGN.md, Reduce Motion, 44 pt targets.
6. **Tests:** add or update tests that pass with the flag on AND off. UI tests launch with `-uitest -resetStore` (fixture mode, see YawnCastUITests/SleepUITests.swift and SleepBubbleUITests.swift; `-fastSleep` gives short Sleep timings). Turn a flag on in a test with the launch argument `-<flag key> YES` (for example `-exp_wake_extend YES`). Run only the relevant test classes, serially:
   `xcodebuild -project YawnCast.xcodeproj -scheme YawnCast -destination 'platform=iOS Simulator,name=YawnCast iPhone' -derivedDataPath build/DerivedData -parallel-testing-enabled NO -only-testing:YawnCastUITests/<Class> test > build/<slug>-tests.log 2>&1` in the background and poll the log for "Test Suite 'Selected tests' (passed|failed)" or "TEST (SUCCEEDED|FAILED)", then kill xcodebuild (it does not exit here, DECISIONS D19). Also confirm `cd YawnCastCore && swift test` stays green if you touch Core, and that Debug and Release both build.
7. **Screenshots:** with the app in `-demo` mode, capture flag OFF and flag ON states with `xcrun simctl io <UDID> screenshot evolve/cycles/001/shots/<slug>-off.png` and `<slug>-on.png`. Install with `xcrun simctl install`, launch with `xcrun simctl launch --terminate-running-process <UDID> com.rarecreatures.yawncast -demo ...`. If a state can't be shown, write NOT VERIFIED and why.
8. Update the card: Status READY (or ABANDONED with the reason), and fill Design / Accessibility / Tests / Screenshots / Risk honestly. Done criteria: builds; tests pass flag on and off; flag-off unchanged; two screenshots; accessibility recorded; no persisted-data, permission or dependency change.
9. Commit on your branch, one concern per commit (code; tests; card+shots). End each commit message with:
   `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`
   Do not push, do not merge, do not touch main.

## Limits
- Time slot about 40 minutes. If the build breaks and three serious attempts don't fix it, mark ABANDONED, leave the branch, and stop.
- Never add dependencies, permissions, analytics, or change `LibrarySnapshot`/saved data. Never weaken or skip a test. Never copy competitor code, assets or copy.
- Don't call any `mcp__hearthbot__` tools. Don't install packages. Don't send messages.
- Final message: 6 lines max: status, commits, tests run and result, screenshots, anything not done.
