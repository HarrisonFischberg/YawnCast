# Smoke, baseline 2026-10-17

| # | Check | Status | Evidence | Tool |
| --- | --- | --- | --- | --- |
| S1 | Launches clean, no crash | PASS | `baseline/2026-10-17/smoke/s1-launch.txt`, `screens/home-default-dark.png` | simctl launch + screenshot |
| S2 | Core flow completes | PASS | `raw/tests.log`: CoreFlowUITests, HomePagesUITests, SleepUITests, V4UITests, 19/19 | project UI tests |
| S3 | No error logs during S1-S2 | NEEDS REVIEW | `smoke/s3-errors.txt`: 39 error-level lines, all system-framework noise (CoreFSCache, CoreAnimation handler, BoardServices XPC, launch-measurement event); none from app code | simctl log show |
| S4 | No failed requests | NOT APPLICABLE | fixture mode makes no network calls; live-network test not run | n/a |
| S5 | Layout holds at two sizes | NEEDS REVIEW | `screens/home-default-dark.png`, `screens/home-largest-dynamic-type-dark.png`: at the largest size the headline and body wrap and the "Find a podcast" button is pushed to the bottom edge; reachable only by scrolling, if the screen scrolls | simctl ui content_size |

Only the Library empty state was captured (cap of 5 screens, one screen sufficient for the baseline).
