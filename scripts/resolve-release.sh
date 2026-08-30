#!/usr/bin/env bash
set -euo pipefail

event_name=${EVENT_NAME:-}
tag_exists=${TAG_EXISTS:-false}
force_publish=${FORCE_PUBLISH:-false}

build_required=true
publish_required=true
reason=new-upstream-revision

if [ "$force_publish" = "true" ]; then
    reason=manual-force-publish
elif [ "$tag_exists" != "true" ]; then
    reason=new-upstream-revision
elif [ "$event_name" = "schedule" ]; then
    build_required=false
    publish_required=false
    reason=scheduled-revision-unchanged
elif [ "$event_name" = "workflow_dispatch" ]; then
    build_required=true
    publish_required=false
    reason=manual-verification-only
else
    build_required=true
    publish_required=true
    reason=wrapper-source-changed
fi

printf 'build_required=%s\n' "$build_required"
printf 'publish_required=%s\n' "$publish_required"
printf 'reason=%s\n' "$reason"
