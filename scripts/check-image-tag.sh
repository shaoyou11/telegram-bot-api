#!/usr/bin/env bash
set -euo pipefail

image_ref=${IMAGE_REF:?IMAGE_REF is required}
error_file=$(mktemp)

cleanup() {
    rm -f "$error_file"
}
trap cleanup EXIT

if docker buildx imagetools inspect "$image_ref" >/dev/null 2>"$error_file"; then
    printf 'tag_exists=true\n'
    exit 0
fi

if grep -Eiq 'manifest unknown|manifest[^[:alnum:]]+not found|tag[^[:alnum:]]+not found|(^|[^0-9])404([^0-9]|$)' \
    "$error_file"; then
    printf 'tag_exists=false\n'
    exit 0
fi

echo "无法确认镜像标签状态，停止发布流程。" >&2
sed -E 's#(https?://)[^/[:space:]]+#\1<registry>#g' "$error_file" >&2
exit 1
