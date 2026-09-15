#!/bin/sh
# Exercise the real session writer in a temporary directory; no HTTP or router.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export RUIJIE_PANEL_SESSION_DIR="$scratch/sessions"
. "$ROOT/api/common.sh"
for entropy in '' abc 0123456789abcdef0123456789abcdeg; do
    panel_new_session_token() { printf '%s' "$entropy"; }
    if panel_create_session >/dev/null; then
        echo 'invalid entropy accepted' >&2
        exit 1
    fi
    [ -z "$(find "$PANEL_SESSION_DIR" -type f -print)" ]
done
panel_new_session_token() { printf '%s' 0123456789abcdef0123456789abcdef; }
token="$(panel_create_session)"
panel_session_exists "$token"
printf '%s\n' 'PASS: empty, short and invalid entropy rejected; valid session persisted'
