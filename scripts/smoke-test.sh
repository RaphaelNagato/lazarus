#!/usr/bin/env bash
# Usage: smoke-test.sh <base-url> <expected-version>
# Fails unless /healthz returns 200 and both /healthz and /version report the expected version.
set -euo pipefail

base_url="${1%/}"
expected="$2"
attempts=5
delay=15

check() {
  local body status
  body="$(mktemp)"
  status="$(curl -sS -o "$body" -w '%{http_code}' --max-time 20 "$base_url/healthz")" || return 1
  [ "$status" = "200" ] || { echo "/healthz returned $status"; return 1; }
  local health_version version_version
  health_version="$(jq -r '.version' "$body")"
  version_version="$(curl -fsS --max-time 20 "$base_url/version" | jq -r '.version')" || return 1
  echo "/healthz version=$health_version, /version version=$version_version, expected=$expected"
  [ "$health_version" = "$expected" ] && [ "$version_version" = "$expected" ]
}

# The app may still be restarting after a deploy or swap, so retry before failing.
for i in $(seq 1 "$attempts"); do
  echo "Attempt $i/$attempts against $base_url"
  if check; then
    echo "Smoke test passed"
    exit 0
  fi
  sleep "$delay"
done

echo "Smoke test failed after $attempts attempts" >&2
exit 1
