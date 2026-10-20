#!/usr/bin/env bash
# Every examples/*.before.txt must fail check.py and every *.after.txt must pass,
# plus a few hand-made screens that pin the counting rules.
set -uo pipefail
cd "$(dirname "$0")/.."
pass=0 fail=0
expect() {  # expect <exit code> <label> <screens text>
  local want=$1 label=$2 got
  printf '%b' "$3" | python3 scripts/check.py - >/dev/null; got=$?
  if [ "$got" = "$want" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $label: exit $got, want $want"; fi
}
for f in examples/*.before.txt; do expect 1 "$f" "$(cat "$f")"; done
for f in examples/*.after.txt; do expect 0 "$f" "$(cat "$f")"; done
thirteen="one two three four five six seven eight nine ten eleven twelve thirteen"
expect 0 "15 words pass" "picture: a bike\n$thirteen 👇\n[Buy now]\n"
expect 1 "16 words fail" "picture: a bike\n$thirteen fourteen 👇\n[Buy now]\n"
expect 1 "quoted picture text counts" "picture: a bike \"Fast\"\n$thirteen 👇\n[Buy now]\n"
expect 0 "circled steps, emoji and ✓ are not words" "① Pick › ② Pay › ③ Ride ✓ 👇\npicture: a bike\n\$24/month\n[Buy now]\n"
expect 1 "two buttons fail" "picture: a bike\nGet a bike 👇\n[Buy now] [Compare plans]\n"
expect 1 "tribe words fail" "picture: a bike\nThe seamless bike platform 👇\n[Buy now]\n"
expect 1 "a later screen failing fails the file" "Hi 👇\n[Go]\n---\n$thirteen fourteen fifteen sixteen\n"
echo "$pass pass, $fail fail"
[ "$fail" = 0 ]
