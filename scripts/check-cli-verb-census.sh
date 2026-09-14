#!/usr/bin/env bash
# DIVE-4482 — derive the command census from the installed CLI, then require
# both skill bundles together to contain an actual top-level invocation.
set -euo pipefail

cd "$(dirname "$0")/.."

help_file=""
core_file="5dive-cli/SKILL.md"
extras_file="5dive-cli-extras/SKILL.md"

while (($#)); do
  case "$1" in
    --help-file=*) help_file=${1#*=} ;;
    --core=*) core_file=${1#*=} ;;
    --extras=*) extras_file=${1#*=} ;;
    *) echo "usage: $0 [--help-file=PATH] [--core=PATH] [--extras=PATH]" >&2; exit 2 ;;
  esac
  shift
done

for file in "$core_file" "$extras_file"; do
  [[ -s "$file" ]] || { echo "FAIL: skill bundle file is missing or empty: $file" >&2; exit 2; }
done

read_help() {
  if [[ -n "$help_file" ]]; then
    [[ -s "$help_file" ]] || { echo "FAIL: help input is missing or empty: $help_file" >&2; return 2; }
    command cat -- "$help_file"
  else
    5dive --help
  fi
}

mapfile -t verbs < <(
  read_help |
    sed -nE 's/^[[:space:]]+5dive[[:space:]]+([a-z][a-z0-9-]*).*/\1/p' |
    sort -u
)

((${#verbs[@]} > 0)) || { echo "FAIL: live help yielded zero top-level verbs" >&2; exit 2; }

missing=()
for verb in "${verbs[@]}"; do
  # Literal top-level syntax prevents --channel-proof and
  # `5dive crew ... uninstall` from posing as proof/uninstall coverage.
  pattern="(^|[^[:alnum:]_-])(sudo[[:space:]]+)?5dive[[:space:]]+${verb}([^[:alnum:]_-]|$)"
  if ! grep -Eqs -- "$pattern" "$core_file" "$extras_file"; then
    missing+=("$verb")
  fi
done

printf 'live top-level verbs: %d\n' "${#verbs[@]}"
printf 'documented top-level verbs: %d\n' "$(( ${#verbs[@]} - ${#missing[@]} ))"
printf 'missing top-level verbs: %d\n' "${#missing[@]}"
if ((${#missing[@]})); then
  printf 'missing: %s\n' "${missing[*]}"
  exit 1
fi

echo "OK — every live top-level verb has a literal invocation in the skill bundle"
