#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/scripts/resolve-release.sh"

assert_output() {
    local output=$1
    local expected=$2
    if ! grep -qx "$expected" <<<"$output"; then
        echo "缺少输出：$expected" >&2
        echo "$output" >&2
        exit 1
    fi
}

same_schedule=$(EVENT_NAME=schedule TAG_EXISTS=true bash "$SCRIPT")
assert_output "$same_schedule" "build_required=false"
assert_output "$same_schedule" "publish_required=false"

same_manual=$(EVENT_NAME=workflow_dispatch TAG_EXISTS=true bash "$SCRIPT")
assert_output "$same_manual" "build_required=true"
assert_output "$same_manual" "publish_required=false"

same_push=$(EVENT_NAME=push TAG_EXISTS=true bash "$SCRIPT")
assert_output "$same_push" "build_required=true"
assert_output "$same_push" "publish_required=true"

pull_request=$(EVENT_NAME=pull_request TAG_EXISTS=false bash "$SCRIPT")
assert_output "$pull_request" "build_required=true"
assert_output "$pull_request" "publish_required=false"
assert_output "$pull_request" "reason=pull-request-verification"

new_schedule=$(EVENT_NAME=schedule TAG_EXISTS=false bash "$SCRIPT")
assert_output "$new_schedule" "build_required=true"
assert_output "$new_schedule" "publish_required=true"

forced=$(EVENT_NAME=workflow_dispatch TAG_EXISTS=true FORCE_PUBLISH=true bash "$SCRIPT")
assert_output "$forced" "build_required=true"
assert_output "$forced" "publish_required=true"

echo "resolve-release tests passed"
