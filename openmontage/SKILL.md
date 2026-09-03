---
name: openmontage
description: Produce real videos end-to-end with OpenMontage, an open-source agentic video production system you drive from your coding agent. Use when the user wants to make a video, short, explainer, documentary montage, trailer, ad cut, talking-head or avatar video, B-roll sequence, or animated piece — or says "make me a video", "turn this into a short", "produce a YouTube video", "edit these clips", "generate a voiceover", "add subtitles", "build a timeline", "render an mp4". Also for scripting, storyboarding, asset generation, stock-footage retrieval, TTS narration, and final composition. Installs on demand (it is NOT preinstalled on a 5dive box) and then exposes its own pipelines and stage-director skills, which you drive rather than reimplement.
---

# openmontage — turn your coding agent into a video studio

[OpenMontage](https://github.com/calesthio/OpenMontage) is an open-source
**agentic video production system**. You describe the video in plain language;
the agent runs a pipeline that researches, scripts, generates or retrieves
assets, edits a timeline, and renders a finished file.

It is a **local toolkit, not a hosted service** — there is no API to call and no
account to create. You install it on the box and drive it through files and
Python tools. It ships its own agent skills (49 bundles under `.claude/skills/`,
plus stage-director skills under `skills/pipelines/`), so once installed, **read
its skills and use them** instead of writing your own video code.

It can produce genuine motion video, not only pan-and-zoom over stills: a
pipeline can build a corpus from free stock footage and open archives, retrieve
real clips, cut them to a timeline, and render.

## When to use this skill

Use it when someone wants a **video artifact produced**. Do not reach for it to
answer questions *about* video, to inspect an existing file (use `ffprobe`), or
to do a single trivial transform such as a format convert or a trim — plain
`ffmpeg` is the right size of tool for those.

## Install — on demand, not preinstalled

It is deliberately **not** part of the default 5dive skill set: it pulls a
Python venv, a Node workspace, and FFmpeg, which is a lot of disk for a box that
may never make a video. Install it the first time it is actually needed, and say
you are doing so.

**Prerequisites:** Python 3.10+, FFmpeg, Node.js (for the Remotion composer).

```bash
sudo apt install -y ffmpeg          # if FFmpeg is missing
git clone https://github.com/calesthio/OpenMontage.git
cd OpenMontage
make setup
```

No `make` available:

```bash
python3 -m venv .venv && source .venv/bin/activate \
  && python -m pip install -r requirements.txt \
  && (cd remotion-composer && npm install) \
  && python -m pip install piper-tts \
  && cp .env.example .env
```

**It works with no paid API keys.** `make setup` provisions a free/open-source
path (local TTS via piper, open asset sources), so you can produce a real video
before anyone decides to fund a provider. Add keys to `.env` only to unlock
paid generators — and if a request would spend money, say so first.

## How to drive it

Treat every request as a **pipeline selection problem**, in this order:

1. **Pick the pipeline.** Read `pipeline_defs/` and choose one; do not improvise
   a bespoke sequence when a manifest already describes the job.
2. **Read that pipeline's manifest**, then its **stage-director skill** under
   `skills/pipelines/`. These encode the production knowledge — following them
   is the point of the tool.
3. **Discover the tools** rather than guessing at them:

   ```bash
   python -c "from tools.tool_registry import registry; import json; registry.discover(); print(json.dumps(registry.support_envelope(), indent=2))"
   python -c "from tools.tool_registry import registry; import json; registry.discover(); print(json.dumps(registry.provider_menu(), indent=2))"
   ```

4. **Run the stages** through those tools.

Watch a run with **Backlot**, its local production board — stages light up, the
script lands as a screenplay page, and every provider decision and dollar spent
is shown:

```bash
python -m backlot open                  # every project on disk
python -m backlot open <project-id>     # one production's live board
```

## Licence — read this before bundling

OpenMontage is **AGPL-3.0**. Running it on a user's own machine to produce their
video is ordinary use and carries no obligation on them.

Bundling it into a **hosted or networked service you offer to others** triggers
AGPL's network clause: you must offer the corresponding source of the combined
work. So install it on the box that wants a video; do **not** vendor it into a
closed product or wire it behind a service you host without deciding that
deliberately. Nothing in this skill copies OpenMontage code — it points at the
upstream repository.

## Output

Say where the rendered file landed and what it cost. If a paid provider was
used, report the spend; if the free path was used, say that too — it is the
difference between a result someone can repeat and one they cannot.
