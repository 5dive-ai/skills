#!/usr/bin/env bash
# DIVE-4407 — skill name+description is loaded at SELECTION time in every
# session, so a command catalog there is paid on every turn and mis-routes.
# This gate keeps every description to at most 2 sentences and a hard char
# budget, and prints the total description bytes so a PR can show before/after.
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_CHARS=${MAX_CHARS:-400}
MAX_SENTENCES=${MAX_SENTENCES:-2}

python3 - "$MAX_CHARS" "$MAX_SENTENCES" <<'PY'
import glob, io, re, sys, yaml

max_chars, max_sent = int(sys.argv[1]), int(sys.argv[2])
total, bad = 0, []
for path in sorted(glob.glob("*/SKILL.md")):
    text = io.open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?\n)---\n", text, re.S)
    if not m:
        bad.append(f"{path}: no YAML frontmatter")
        continue
    fm = yaml.safe_load(m.group(1))
    desc = " ".join((fm.get("description") or "").split())
    if not desc:
        bad.append(f"{path}: empty description")
        continue
    total += len(desc)
    # A sentence ends at . ! or ? followed by whitespace or end of string.
    # Guard the common abbreviations that would otherwise over-count.
    probe = re.sub(r"\b(e\.g|i\.e|etc|vs)\.", r"\1", desc)
    sentences = len(re.findall(r"[.!?](?:\s|$)", probe))
    if len(desc) > max_chars:
        bad.append(f"{fm['name']}: {len(desc)} chars > {max_chars}")
    if sentences > max_sent:
        bad.append(f"{fm['name']}: {sentences} sentences > {max_sent}")

print(f"total description chars: {total}")
if bad:
    print("\nFAIL — a description is a routing surface, not a catalog:")
    for b in bad:
        print(f"  - {b}")
    sys.exit(1)
print("OK — every description is within the selection budget")
PY
