#!/bin/zsh
# Re-seed the populated library and run the pre-built performance tests (Release).
#   scripts/prebuilt/measure.sh <label>     # label: baseline2 | after-F001 | ...
# Output: baseline/<date>/raw/perf-populated/<label>.log and <label>.summary.txt
set -u
cd "$(dirname "$0")/../.."
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
LABEL=${1:?label}
UD=${NIGHTCAST_PERF_UDID:-5E4786AD-2A04-4FCC-A4E9-CF947DD33BBB}
OUT=baseline/2026-10-17/raw/perf-populated; mkdir -p $OUT
xcrun simctl terminate $UD com.nightcast.ktv2g3z883 2>/dev/null
xcodebuild -project NightCast.xcodeproj -scheme NightCast -configuration Release -destination "id=$UD" \
  -derivedDataPath build/DerivedData -parallel-testing-enabled NO build-for-testing > $OUT/$LABEL.build.log 2>&1 \
  || { echo "BUILD FAILED, see $OUT/$LABEL.build.log"; exit 1; }
xcrun simctl install $UD build/DerivedData/Build/Products/Release-iphonesimulator/NightCast.app
python3 scripts/prebuilt/seed_library.py $UD > $OUT/$LABEL.seed.txt
shasum -a 256 "$(xcrun simctl get_app_container $UD com.nightcast.ktv2g3z883 data)/Library/Application Support/NightCast/library.json" > $OUT/$LABEL.library.sha
xcodebuild -project NightCast.xcodeproj -scheme NightCast -configuration Release -destination "id=$UD" \
  -derivedDataPath build/DerivedData -parallel-testing-enabled NO -only-testing:NightCastUITests/PreBuiltPerfTests test-without-building > $OUT/$LABEL.log 2>&1 &
PID=$!
for _ in $(seq 1 240); do sleep 5; grep -qE "TEST (SUCCEEDED|FAILED)|Test Suite 'Selected tests' (passed|failed)" $OUT/$LABEL.log && break; done
kill $PID 2>/dev/null
python3 - "$OUT/$LABEL.log" > $OUT/$LABEL.summary.txt <<'PY'
import re, sys, statistics as s
for line in open(sys.argv[1]):
    m = re.search(r"Test Case '-\[\S+\.(\w+) (\w+)\]' measured \[(.+?)\] average: ([\d.]+).*?values: \[(.*?)\]", line)
    if not m: continue
    vals = [float(v) for v in m.group(5).split(",")]
    print(f"{m.group(2)} | {m.group(3)} | median {s.median(vals):.3f} | min {min(vals):.3f} | max {max(vals):.3f}")
PY
cat $OUT/$LABEL.summary.txt
