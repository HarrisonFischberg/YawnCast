#!/bin/bash
# Design exploration captures (branch design/explore). Builds Debug, then launches the app on the
# "YawnCast design" simulator once per option and screen and saves raw screenshots.
#   scripts/design_capture.sh [out-dir] [options...]     e.g. scripts/design_capture.sh out A B
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-/Users/harrison/projects/design-review/yawncast}"; shift || true
OPTIONS=("$@"); [ ${#OPTIONS[@]} -eq 0 ] && OPTIONS=(base A B C)
DEV="YawnCast design"
BUNDLE=com.rarecreatures.yawncast
AUDIO="$PWD/DerivedData/design/silence.m4a"
mkdir -p "$OUT" "$(dirname "$AUDIO")"

xcrun simctl list devices | grep -q "$DEV" || xcrun simctl create "$DEV" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro >/dev/null
xcrun simctl bootstatus "$DEV" -b >/dev/null
# 12-hour clock so the status bar reads 9:41 (the Mac's 24-hour setting leaks into new simulators;
# takes effect after a restart of this one simulator).
if [ "$(xcrun simctl spawn "$DEV" defaults read -g AppleICUForce24HourTime 2>/dev/null)" != 0 ]; then
  xcrun simctl spawn "$DEV" defaults write -g AppleICUForce24HourTime -bool NO
  xcrun simctl spawn "$DEV" defaults write -g AppleICUForce12HourTime -bool YES
  xcrun simctl shutdown "$DEV" && xcrun simctl bootstatus "$DEV" -b >/dev/null
fi
[ -f "$AUDIO" ] || ffmpeg -loglevel error -y -f lavfi -i anullsrc=r=8000:cl=mono -t 2320 -c:a aac -b:a 8k "$AUDIO"
[ -n "${SKIP_BUILD:-}" ] || xcodebuild -project YawnCast.xcodeproj -scheme YawnCast -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEV" -derivedDataPath DerivedData build | grep -E "error|BUILD" || true
xcrun simctl install "$DEV" DerivedData/Build/Products/Debug-iphonesimulator/YawnCast.app
xcrun simctl ui "$DEV" appearance dark
xcrun simctl status_bar "$DEV" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

shot() { # name, then launch arguments
  local name="$1"; shift
  xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$DEV" "$BUNDLE" -designAudio "$AUDIO" "$@" >/dev/null
  sleep 5
  for _ in 1 2 3 4 5 6; do
    xcrun simctl io "$DEV" screenshot "$OUT/$name.png" 2>/dev/null
    # The simulator sometimes paints the Dynamic Island for a moment after launch; wait it out.
    python3 -c "import sys;from PIL import Image;sys.exit(Image.open(sys.argv[1]).convert('RGB').getpixel((603,95))==(0,0,0))" "$OUT/$name.png" && break
    sleep 2
  done
  echo "$name"
}

for o in "${OPTIONS[@]}"; do
  p="$o"; [ "$o" = base ] && p=baseline
  shot "$p-1" -design "$o" -theme city -openPlayer -designSleep fade
  shot "$p-2" -design "$o" -theme ocean -page library -layout large -designSleep wait
  [ "$o" = base ] || shot "$p-3" -design "$o" -theme city -openPlayer
done
xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
