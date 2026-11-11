#!/bin/bash
# Screenshot captures with the synthetic library (Debug, `-synthetic`; see TestSupport/SyntheticSeed.swift).
# Builds, then launches the app on its own simulator once per screen and saves raw PNGs.
#   scripts/design_capture.sh [out-dir]
#   DEVTYPE=iPhone-17e DEV="YawnCast design small" scripts/design_capture.sh out   (another size)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-screenshots/raw}"
DEV="${DEV:-YawnCast design}"
DEVTYPE="${DEVTYPE:-iPhone-17-Pro}"
BUNDLE=com.rarecreatures.yawncast
AUDIO="$PWD/DerivedData/design/silence.m4a"
mkdir -p "$OUT" "$(dirname "$AUDIO")"

xcrun simctl list devices | grep -q "$DEV (" || xcrun simctl create "$DEV" "com.apple.CoreSimulator.SimDeviceType.$DEVTYPE" >/dev/null
xcrun simctl bootstatus "$DEV" -b >/dev/null
# 12-hour clock so the status bar reads 9:41 (the Mac's 24-hour setting leaks into new simulators;
# takes effect after a restart of this one simulator).
if [ "$(xcrun simctl spawn "$DEV" defaults read -g AppleICUForce24HourTime 2>/dev/null)" != 0 ]; then
  xcrun simctl spawn "$DEV" defaults write -g AppleICUForce24HourTime -bool NO
  xcrun simctl spawn "$DEV" defaults write -g AppleICUForce12HourTime -bool YES
  xcrun simctl shutdown "$DEV" && xcrun simctl bootstatus "$DEV" -b >/dev/null
fi
# A silent 38:40 file, so the scrubber shows a real length and Sleep has something to fade.
[ -f "$AUDIO" ] || ffmpeg -loglevel error -y -f lavfi -i anullsrc=r=8000:cl=mono -t 2320 -c:a aac -b:a 8k "$AUDIO"
[ -n "${SKIP_BUILD:-}" ] || xcodebuild -project YawnCast.xcodeproj -scheme YawnCast -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEV" -derivedDataPath DerivedData build | grep -E "error|BUILD" || true
xcrun simctl install "$DEV" DerivedData/Build/Products/Debug-iphonesimulator/YawnCast.app
xcrun simctl ui "$DEV" appearance "${APPEARANCE:-dark}"
xcrun simctl status_bar "$DEV" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

shot() { # name, seconds to wait, then launch arguments
  local name="$1" wait="$2"; shift 2
  # ONLY="04 08" re-takes just those shots.
  [[ -z "${ONLY:-}" || " $ONLY " == *" ${name%%-*} "* ]] || return 0
  xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$DEV" "$BUNDLE" -synthetic -syntheticAudio "$AUDIO" -nightHour 12 "$@" >/dev/null
  sleep "$wait"
  for _ in 1 2 3 4; do
    xcrun simctl io "$DEV" screenshot "$OUT/$name.png" 2>/dev/null
    # The simulator sometimes paints the Dynamic Island for a moment after launch; wait it out.
    python3 -c "import sys;from PIL import Image;im=Image.open(sys.argv[1]).convert('RGB');sys.exit(im.getpixel((im.width//2,95))==(0,0,0))" "$OUT/$name.png" && break
    sleep 1
  done
  echo "$name"
}

# Sleep for real: -fastSleep starts the fade 4 s after the moon and steps every 3 s,
# so about 15 to 20 s after launch the volume is somewhere between 70% and 40%.
FADE=(-openPlayer -autoplay -sleepOn -fastSleep)
if [ -n "${ONLY_FADES:-}" ]; then
  for t in city rainforest ocean beach mountain midnight almanac; do shot "fade-$t" "${FADE_WAIT:-13}" -theme "$t" "${FADE[@]}"; done
else
  shot 03-now-playing-sleep-off 5 -theme city -openPlayer
  shot 01-now-playing-fading-city "${FADE_WAIT:-13}" -theme city "${FADE[@]}"
  shot 02-library-underwater 6 -theme ocean -page library -layout large -sleepOn
  shot 04-fade-rainforest "${FADE_WAIT:-13}" -theme rainforest "${FADE[@]}"
  shot 05-fade-underwater "${FADE_WAIT:-13}" -theme ocean "${FADE[@]}"
  shot 06-fade-beach "${FADE_WAIT:-13}" -theme beach "${FADE[@]}"
  shot 07-fade-mountain "${FADE_WAIT:-13}" -theme mountain "${FADE[@]}"
  shot 08-fade-midnight "${FADE_WAIT:-13}" -theme midnight "${FADE[@]}"
  shot 09-new-mountain 6 -theme mountain -page new
  shot 10-explore-beach 6 -theme beach -page explore
  shot 11-show-rainforest 6 -theme rainforest -openShow
  shot 12-library-small-midnight 6 -theme midnight -page library -layout small
  shot 13-library-list-city 6 -theme city -page library -layout list
  shot 14-themes-sheet 6 -theme midnight -page library -themes
  shot 15-now-playing-almanac-day 5 -theme almanac -openPlayer -autoplay -sleepOn
fi
xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
