#!/usr/bin/env bash
# shellcheck disable=SC2016 # Backticks below are fixture text.
set -euo pipefail

cd "$(dirname "$0")/.."
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

help_file="$tmp_dir/help"
core_file="$tmp_dir/core.md"
extras_file="$tmp_dir/extras.md"

printf '  5dive task ls\n  5dive proof publish\n  5dive uninstall\n' > "$help_file"
printf '`5dive task ls`\n' > "$core_file"
printf '%s\n' '`--channel-proof=123`' '`5dive crew run demo # uninstall demo`' > "$extras_file"

if output=$(scripts/check-cli-verb-census.sh \
    --help-file="$help_file" --core="$core_file" --extras="$extras_file" 2>&1); then
  echo "FAIL: incidental words satisfied top-level proof/uninstall coverage" >&2
  exit 1
fi
grep -q 'missing top-level verbs: 2' <<<"$output"
grep -q 'missing: proof uninstall' <<<"$output"

printf '%s\n' '`5dive proof publish --dry-run`' '`5dive uninstall`' >> "$extras_file"
scripts/check-cli-verb-census.sh \
  --help-file="$help_file" --core="$core_file" --extras="$extras_file" >/dev/null

echo "PASS: live-help census rejects incidental word matches and accepts literal top-level docs"
