#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$ROOT/scripts/check-image-tag.sh"
FAKE_BIN=$(mktemp -d)
FAKE_DOCKER="$FAKE_BIN/docker"

cleanup() {
    rm -f "$FAKE_DOCKER"
    rmdir "$FAKE_BIN"
}
trap cleanup EXIT

cat >"$FAKE_DOCKER" <<'SH'
#!/usr/bin/env bash
case "$FAKE_MODE" in
    exists)
        exit 0
        ;;
    missing)
        echo "ERROR: manifest unknown: tag was not found" >&2
        exit 1
        ;;
    unavailable)
        echo "ERROR: failed to do request: 429 Too Many Requests" >&2
        exit 1
        ;;
esac
SH
chmod +x "$FAKE_DOCKER"

exists=$(PATH="$FAKE_BIN:$PATH" FAKE_MODE=exists IMAGE_REF=example:test bash "$SCRIPT")
grep -qx 'tag_exists=true' <<<"$exists"

missing=$(PATH="$FAKE_BIN:$PATH" FAKE_MODE=missing IMAGE_REF=example:test bash "$SCRIPT")
grep -qx 'tag_exists=false' <<<"$missing"

if PATH="$FAKE_BIN:$PATH" FAKE_MODE=unavailable IMAGE_REF=example:test bash "$SCRIPT" \
    >/dev/null 2>&1; then
    echo "registry failure must not be treated as a missing tag" >&2
    exit 1
fi

echo "check-image-tag tests passed"
