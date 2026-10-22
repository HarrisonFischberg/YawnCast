#!/bin/zsh
# Main-thread attribution with Time Profiler, no app changes.
#   scripts/prebuilt/profile.sh launch <label>    # 5 cold launches, samples under launch work
#   scripts/prebuilt/profile.sh <testProfileSaves|testProfileOpenShow|testProfileScroll> <label>   # 5 runs, attach to the app
# Writes baseline/2026-10-17/raw/profile/<label>-<scenario>-<n>.trace and a .counts.txt summary.
set -u
cd "$(dirname "$0")/../.."
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
SC=${1:?scenario}; LABEL=${2:?label}
UD=${NIGHTCAST_PERF_UDID:-5E4786AD-2A04-4FCC-A4E9-CF947DD33BBB}
BID=com.nightcast.ktv2g3z883
xcrun simctl terminate $UD $BID 2>/dev/null; pkill -x NightCast 2>/dev/null; sleep 2
OUT=baseline/2026-10-17/raw/profile; mkdir -p $OUT
PATS=('recomputeLatestFromCache' 'FeedDiskCache' 'AppModel.init' 'NightCastApp.init' 'JSONLibraryStore.(save|load)' 'AppModel.persist' 'hasNewEpisode' 'ShowModel.(init|apply|regroup)' 'ShowView.init')
count() { # trace -> one line per pattern
  xcrun xctrace export --input "$1" --xpath '/trace-toc/run/data/table[@schema="time-profile"]' > /tmp/nc-prof.xml 2>/dev/null
  python3 scripts/prebuilt/mainthread.py /tmp/nc-prof.xml $PATS
}
if [[ $SC == launch ]]; then
  for n in 1 2 3 4 5; do
    xcrun simctl terminate $UD $BID 2>/dev/null
    T=$OUT/$LABEL-launch-$n.trace; rm -rf $T
    xcrun xctrace record --template 'Time Profiler' --device $UD --time-limit 6s --output $T --launch -- $BID > /dev/null 2>&1
    echo "run $n"; count $T
  done > $OUT/$LABEL-launch.counts.txt
else
  for n in 1 2 3 4 5; do
    xcrun simctl terminate $UD $BID 2>/dev/null; pkill -x NightCast 2>/dev/null; sleep 2
    xcodebuild -project NightCast.xcodeproj -scheme NightCast -configuration Release -destination "id=$UD" \
      -derivedDataPath build/DerivedData -parallel-testing-enabled NO -only-testing:NightCastUITests/PreBuiltPerfTests/$SC test-without-building > $OUT/$LABEL-$SC-$n.xcodebuild.log 2>&1 &
    XB=$!
    PID=""
    for _ in $(seq 1 90); do sleep 1; PID=$(pgrep -x NightCast | head -1); [[ -n $PID ]] && break; done
    sleep 1
    T=$OUT/$LABEL-$SC-$n.trace; rm -rf $T
    xcrun xctrace record --template 'Time Profiler' --device $UD --attach $PID --time-limit 240s --output $T > /dev/null 2>&1
    echo "run $n pid $PID"; count $T
    kill $XB 2>/dev/null; wait $XB 2>/dev/null
  done > $OUT/$LABEL-$SC.counts.txt
fi
cat $OUT/$LABEL-*.counts.txt
