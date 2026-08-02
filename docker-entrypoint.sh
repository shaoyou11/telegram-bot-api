#!/bin/sh
set -eu

: "${TELEGRAM_API_ID:?TELEGRAM_API_ID is required}"
: "${TELEGRAM_API_HASH:?TELEGRAM_API_HASH is required}"

set -- --api-id "$TELEGRAM_API_ID" --api-hash "$TELEGRAM_API_HASH"

if [ "${TELEGRAM_LOCAL:-0}" = "1" ]; then
    set -- "$@" --local
fi

if [ -n "${TELEGRAM_HTTP_PORT:-}" ]; then
    set -- "$@" --http-port "$TELEGRAM_HTTP_PORT"
fi

exec telegram-bot-api "$@"
