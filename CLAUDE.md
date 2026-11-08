# YawnCast

A calm iPhone podcast app for falling asleep (see README.md).

## Releasing to the App Store

When Harold says YawnCast is good for release ("push it to Apple", "ship it", "release it"),
that message is his approval for the whole release. Do it end to end without asking, except
where a step below says stop:

1. Merge the open PRs he named into main (only the ones he named), and work in a fresh worktree off origin/main.
2. Apple takes one submission at a time. If a version is still waiting for review or in review
   in App Store Connect (1.0 was on 2026-11-08), stop and tell him: he can wait for it, or
   remove it from review and have this build replace it.
3. Pick the next version from `MARKETING_VERSION` (minor for features, patch for fixes) and
   write `release_notes.txt` in every locale folder of `fastlane/metadata/` from the PRs merged
   since the last version (en-US first, then the same notes translated). Update
   `description.txt` in every locale if a feature in it changed.
4. YawnCast collects nothing: search terms go to Apple's iTunes Search API and feeds come
   from publishers. If a change adds a data flow, check the privacy policy at
   https://rarecreatures.app/apps/yawncast/privacy/ and the App Privacy answers still cover
   it; if not, stop and tell him, because the policy needs his OK.
5. `zsh -ic 'cd <worktree> && ./release.sh --live --track production --version X.Y'` sets the
   version, takes the next build number (above the latest TestFlight build), archives, uploads
   through `Config/ExportOptions-AppStore.plist` (this Mac has no iOS Distribution
   certificate, so fastlane's own export fails), waits for processing, pushes the listing and
   screenshots from `fastlane/` and submits for review with automatic release.
6. Commit the version and notes, open a PR and merge it. Tell him one line: the version, the
   build number, and that it's waiting for review. Mention it if the UI changed since the
   screenshots in `fastlane/screenshots/` (rebuild them with `python3 fastlane/frame_screenshots.py`
   from new raw captures).

TestFlight only: `./release.sh --live`.
