# Tool environment (pre-built run, 2026-10-17)

| Tool | Result |
| --- | --- |
| xcodebuild 27.0 (27A266a) | answers; Debug and Release builds succeed |
| xctrace | answers; Time Profiler records on the simulator. The App Launch template produced an empty lifecycle table on the simulator, so launch time came from XCTApplicationLaunchMetric instead |
| simctl | answers; dedicated simulator `NightCast-prebuilt` (5E4786AD-2A04-4FCC-A4E9-CF947DD33BBB) created for this run |
| Project test script | `scripts/test.sh`; uses the user's `NightCast iPhone` simulator, no erase |
| Fixture mode | present: `-uitest -resetStore -theme ink` |
| periphery, swiftlint, swift-format | not installed; no approval requested yet |
| Physical device | not drivable from this session |
| `scripts/baseline.sh` | copied from the skill, excluded locally via `.git/info/exclude`, not committed |
