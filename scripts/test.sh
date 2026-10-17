#!/bin/zsh
# Runs NightCast's automated checks and prints a summary.
#   scripts/test.sh          core tests + Debug/Release builds + app unit tests + fixture UI tests
#   scripts/test.sh --live   also runs the opt-in live-network UI test (real iTunes + RSS + stream)
# App unit and UI tests run serially: parallel simulator clones hang on this setup (DECISIONS D14), and
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

# run_tests <log> <finished-pattern> <xcodebuild args...>
UI_DONE="Test Suite '(All tests|Selected tests)' (passed|failed)|TEST (FAILED|SUCCEEDED)|BUILD FAILED"
UNIT_DONE="Test run with .* (passed|failed)|$UI_DONE"
run_tests() {
  local log=$1 finished=$2; shift 2
  xcodebuild -project NightCast.xcodeproj -scheme NightCast -destination "$DEST" \
    -derivedDataPath build/DerivedData -parallel-testing-enabled NO "$@" test > "$log" 2>&1 &
  local pid=$!
  for _ in $(seq 1 180); do
    sleep 5
    grep -qE "$finished" "$log" && break
  done
  kill $pid 2>/dev/null
  grep -E "error: |Test Case.*(passed|failed)|Executed [0-9]+ tests|✘|Test run with|Testing failed|TEST FAILED" "$log" | sort -u
}

echo "== App unit tests"
run_tests build/unit-tests.log "$UNIT_DONE" -only-testing:NightCastTests

echo "== UI tests (fixture mode)"
run_tests build/ui-tests.log "$UI_DONE" -only-testing:NightCastUITests -skip-testing:NightCastUITests/LiveNetworkUITests

if [[ "${1:-}" == "--live" ]]; then
  echo "== Live network UI test"
  TEST_RUNNER_NIGHTCAST_LIVE=1 run_tests build/ui-live.log "$UI_DONE" -only-testing:NightCastUITests/LiveNetworkUITests
fi
