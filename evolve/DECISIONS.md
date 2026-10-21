# Evolve decisions (append only)

## Cycle 001 · 2026-10-21 · Harold
- **approve: wake-extend** (Play soon after Sleep's fade turns Sleep back on). Tested on iPhone: Lock Screen Play restarted Sleep with a fresh countdown.
- **approve: drift-back**, **change:** move the "Back to …" key from under the scrubber to the row above the Moon, beside the ±5 bubble. Done in the approval branch.
- **approve: lock-status**. First install did nothing until relaunch (flag cached at launch); fixed, then confirmed working on iPhone.
- **approve: mini-moon**. Tested on iPhone.
- **approve: night-auto**. Not yet seen after 10 pm on device; Harold assumed it works and approved.
- Ship path: approved branch → PR into `main`; a TestFlight build next (App Store submission stays Harold's step).
- Model choice for building: split, Opus for Sleep-logic iterations, Sonnet for simple UI (Harold, 2026-10-21).
