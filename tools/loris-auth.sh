#!/bin/sh
# git-annex web-download auth helper for LORIS API datasets.
# Prints: Authorization: Bearer <token>
# Uses the RUNNING USER's own LORIS account:
#   LORIS_USERNAME / LORIS_PASSWORD env vars, or interactive prompt on /dev/tty.
# NOTE: git-annex runs this command with piped stdio, so interactive input
# must read from /dev/tty, otherwise it blocks forever.
# Token cached in /tmp (1h, keyed by username) to avoid one login per file.
API_BASE="https://registeredpreventad-new.loris.ca//api/v0.0.3"

USERNAME="${LORIS_USERNAME:-}"
if [ -z "$USERNAME" ]; then
    printf 'LORIS username: ' >/dev/tty 2>/dev/null || printf 'LORIS username: ' >&2
    if [ -e /dev/tty ]; then read -r USERNAME < /dev/tty; else read -r USERNAME; fi
fi

CACHE="/tmp/loris-token-$(id -u)-$(printf %s "$USERNAME" | cksum | cut -d' ' -f1)"
if [ -f "$CACHE" ] && find "$CACHE" -mmin -60 2>/dev/null | grep -q .; then
    cat "$CACHE"
    exit 0
fi

PASSWORD="${LORIS_PASSWORD:-}"
if [ -z "$PASSWORD" ]; then
    printf 'LORIS password: ' >/dev/tty 2>/dev/null || printf 'LORIS password: ' >&2
    if [ -e /dev/tty ]; then
        stty -echo < /dev/tty 2>/dev/null
        read -r PASSWORD < /dev/tty
        stty echo < /dev/tty 2>/dev/null
        printf '
' >/dev/tty 2>/dev/null
    else
        read -r PASSWORD
    fi
fi

# Build the JSON with Python so special characters in the password (quotes,
# backslashes, unicode) can never break the request.
TOKEN=$(LORIS_API_BASE="$API_BASE" LORIS_USERNAME="$USERNAME" LORIS_PASSWORD="$PASSWORD" python3 -c '
import json, os, sys, urllib.request, urllib.error
req = urllib.request.Request(
    os.environ["LORIS_API_BASE"] + "/login",
    data=json.dumps({"username": os.environ["LORIS_USERNAME"],
                     "password": os.environ["LORIS_PASSWORD"]}).encode(),
    headers={"Content-Type": "application/json"})
try:
    resp = urllib.request.urlopen(req, timeout=30)
    print(json.load(resp).get("token") or "")
except urllib.error.HTTPError as e:
    sys.stderr.write("loris-auth.sh: login HTTP %d %s (check username/password)
" % (e.code, e.reason))
except Exception as e:
    sys.stderr.write("loris-auth.sh: login error: %s
" % e)
')
if [ -z "$TOKEN" ]; then
    exit 1
fi
printf 'Authorization: Bearer %s
' "$TOKEN" | tee "$CACHE"
