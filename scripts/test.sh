#!/bin/zsh
# Runs NightCast's automated checks and prints a summary.
#   scripts/test.sh          core tests + Debug/Release builds + fixture UI tests
#   scripts/test.sh --live   also runs the opt-in live-network UI test (real iTunes + RSS + stream)
# UI tests run serially: parallel simulator clones hang on this setup (DECISIONS D14), and
# xcodebuild does not exit after tests here (D19), so we wait for the suite summary and stop it.
set -u
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
DEST=${NIGHTCAST_DEST:-'platform=iOS Simulator,name=NightCast iPhone'}
mkdir -p build

echo "== Core (swift test)"
(cd NightCastCore && swift test 2>&1 | grep -E "✘|Test run")

for config in Debug Release; do
  echo "== Build $config"
  xcodebuild -project NightCast.xcodeproj -scheme NightCast -configuration $config \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build 2>&1 \
    | grep -E "error:|warning: .*\.swift|BUILD (SUCCEEDED|FAILED)" | sort -u
done

run_ui() {
  local log=$1; shift
  xcodebuild -project NightCast.xcodeproj -scheme NightCast -destination "$DEST" \
    -derivedDataPath build/DerivedData -parallel-testing-enabled NO "$@" test > "$log" 2>&1 &
  local pid=$!
  for _ in $(seq 1 180); do
    sleep 5
    grep -qE "Test Suite '(All tests|Selected tests)' (passed|failed)|TEST (FAILED|SUCCEEDED)|BUILD FAILED" "$log" && break
  done
  kill $pid 2>/dev/null
  grep -E "error: |Test Case.*(passed|failed)|Executed [0-9]+ tests" "$log" | sort -u
}

echo "== UI tests (fixture mode)"
run_ui build/ui-tests.log -skip-testing:NightCastUITests/LiveNetworkUITests

if [[ "${1:-}" == "--live" ]]; then
  echo "== Live network UI test"
  TEST_RUNNER_NIGHTCAST_LIVE=1 run_ui build/ui-live.log -only-testing:NightCastUITests/LiveNetworkUITests
fi
