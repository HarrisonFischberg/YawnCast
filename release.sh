#!/bin/bash
# One command for the App Store (YawnCast is iPhone only). Dry run unless --live.
# Usage: ./release.sh [ios|all] [--live] [--track internal|production] [--version X.Y]
#   internal (default) = TestFlight (lane beta), production = App Store review (lane release, automatic release)
#   --version sets MARKETING_VERSION first
# Dry run: archives only (it still reads the latest TestFlight build number). Lanes: fastlane/Fastfile.
# Needs a Mac with Xcode and fastlane, and ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (see fastlane/Fastfile).
set -euo pipefail
cd "$(dirname "$0")"
usage="usage: ./release.sh [ios|all] [--live] [--track internal|production] [--version X.Y]"
live=false track=internal version=
while [ $# -gt 0 ]; do
  case "$1" in
    ios|all) ;;
    mac|android|chrome|firefox) echo "$1: not shipped from this repo (YawnCast is iPhone only)." >&2; exit 2 ;;
    --live) live=true ;;
    --track) track=${2:-}; shift ;;
    --version) version=${2:-}; shift ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
  shift
done
case "$track" in internal) lane=beta ;; production) lane=release ;; *) echo "$usage" >&2; exit 2 ;; esac
[ "$(uname)" = Darwin ] || { echo "needs a Mac with Xcode" >&2; exit 1; }
command -v fastlane >/dev/null || { echo "fastlane is not installed: brew install fastlane" >&2; exit 1; }
for v in ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH; do
  [ -n "${!v:-}" ] || { echo "missing env var $v (App Store Connect API key, see fastlane/Fastfile)" >&2; exit 1; }
done
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 # xcpretty crashes on a non-UTF-8 locale
if [ -n "$version" ]; then
  [[ "$version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "--version wants X.Y or X.Y.Z" >&2; exit 2; }
  sed -i '' -E "s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $version;/" YawnCast.xcodeproj/project.pbxproj
fi
[ "$live" = true ] || echo "Dry run: archiving only. Add --live to upload."
fastlane ios "$lane" live:"$live"
