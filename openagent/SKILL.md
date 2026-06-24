---
name: openagent
description: Author your own OpenAgent persona and mint your shareable holo trading card. Use when you (an agent) want to create, validate, or render YOUR identity card — or when the user says "make your card", "generate my OpenAgent card", "create a persona", "what's my rarity tier", "mint your card", "join the character-packs registry", or asks you to describe/lock your own look, voice, and style as a reusable persona file. Wraps the `@5dive/openagent` CLI (validate / tier / card) and the OpenAgent v0.1 identity spec. Self-service flow, where you write a `<id>.persona.yaml`, validate it against the schema, check your rarity tier + completeness, render a PNG card, and optionally PR into the registry (the path to the Mythical tier). Also use when you want to provision a live teammate from a persona ("create/spin up an agent from this persona", "provision a teammate") via `5dive agent import --from-persona`.
---

# openagent — author your persona, mint your card

OpenAgent is a vendor-neutral open standard for agent **identity**: one
`*.persona.yaml` file locks how you look, sound, and write so you stay
consistent across text, audio, and video. This skill walks you through
creating yours and rendering a shareable **trading card** from it — complete
with a **rarity tier** earned by how complete your persona is.

Repo + spec: `github.com/5dive-ai/openagent` (MIT).

## The CLI

Run it with `npx`, no install. The npm package (`@5dive/openagent`) is still on
an old build, so **use the GitHub form** — it always tracks `main` and has every
command:

```bash
npx github:5dive-ai/openagent validate <id>.persona.yaml          # schema check, exit 0 = valid
npx github:5dive-ai/openagent tier     <id>.persona.yaml --json   # rarity tier + completeness % + next-tier blocker
npx github:5dive-ai/openagent card     <id>.persona.yaml -o <id>.png   # render the PNG trading card
```

Those three are the core loop: **validate → tier → card**. The CLI also has
`speak` (voice a line via TTS), `flow` (emit a gen-video scene prompt), and
`sign` / `verify` / `registry` (provenance + the Mythical registry) — covered in
**Going further** below. When npm is refreshed the clean `npx @5dive/openagent
<cmd>` form will work identically; prefer it then.

## Workflow

### 1. Gather your identity

> **Already a running 5dive agent?** Bootstrap a draft instead of writing from
> scratch: `5dive agent export <yourname> --out=<id>.persona.yaml` (CLI ≥ 0.4.5)
> emits a schema-valid persona.yaml from your existing identity. Refine it, then
> jump to validate (step 3).

You know yourself, so pull most of this together honestly. But **two things are
the user's call, not yours to assume. Ask, and wait for their answer, before you
generate anything:**
- **Name** — what name should the card carry (their brand/handle, or the name
  they call you)? Confirm it.
- **Avatar** — do they already have an avatar or photo you should use? If yes,
  use that as your `face.ref`. If not, confirm they want you to generate one
  before you do.

If the user says it's your call ("do as you wish"), decide both yourself and go
ahead. The point is no surprises, not a hard gate.

Everything else below you author yourself. You need:
- **id** — lowercase-kebab handle (`^[a-z0-9-]+$`), e.g. `marcus`.
- **name**, **role** — display name + one-line title.
- **face.ref** — a URL or local path to your **portrait image**. This is the
  single most important visual choice: the card renders it **full-bleed as the
  hero**, so its quality *is* the card's quality. Aim for a polished
  head-and-shoulders portrait — centered, facing forward, clear eyes, good
  lighting, the kind of image you'd be happy to use as a real profile photo. A
  real photo or a high-quality generated portrait both work; **avoid flat vector
  clip-art, emoji, logos, mascots, or busy scenes** — they make the card look
  cheap. Host it at a **public raw URL** so the real face travels with the card
  (a local-only path falls back to a plain monogram when anyone else renders it).
  **anchor** — one sentence describing the look (who you read as, setting,
  framing, lens) so any generated variants stay on-model.
- **voice.audio.base** — your base TTS voice name. If you don't have one yet,
  use `unset` (it renders, but caps you at a low tier — see below).
  **voice.audio.style** — a sentence on cadence/energy.
- **voice.written.rules** — 2-4 rules for how you write. **sample** — one line
  in your actual voice.
- **behavior** — what you do, in your own register.
- optional: **posts_about** (array), **links** (object of url strings),
  `face.full`, `face.sprite`.

> **Your portrait — use the user's, or generate one. Never hand-draw it.** The card is a *shareable*
> artifact: its look is what makes someone screenshot and post it, so the face
> carries the whole thing. A text-only model hand-coding SVG produces flat
> clip-art — **don't do that.** Follow this ladder instead:
>
> 1. **The user already has an avatar/photo** (you asked in step 1) → use it as
>    `face.ref`. Done — skip the rest.
> 2. **Generate it yourself** — you have an image generator (Antigravity/`agy`,
>    a connected ChatGPT/DALL·E or Gemini-image tool, Midjourney, etc.) → use it
>    from the standardized prompt below.
> 3. **No image-gen access** → hand the **user** the standardized prompt and ask
>    them to run it in ChatGPT (or any image tool) and send the image back, then
>    host it.
> 4. **Last resort only** → a clean monogram (caps your tier lower).
>
> **Standardized portrait prompt** — keep the framing / lighting / format fixed
> so every OpenAgent card is visually consistent; vary only the subject:
>
> ```
> Photorealistic head-and-shoulders portrait of <one line: who you are —
> age range, vibe, role, any signature detail from your face.anchor>.
> Centered, facing the camera, direct eye contact, calm confident expression.
> Soft even studio lighting, sharp focus on the face, simple clean background
> <optional subtle theme color>. Professional profile-photo framing, 1:1
> square, photoreal, no text, no logos, no watermark.
> ```
>
> Host the result at a **public raw URL** → `face.ref`, and record how you made
> it in **`face.recipe`** (model + prompt) so the likeness is reproducible — the
> visual equivalent of voice = base + style.

### 2. Write `<id>.persona.yaml`
Use this template (required: `id, name, role, face{ref,anchor}, voice, behavior`):

```yaml
openagent: "0.1"
id: yourhandle
name: Your Name
role: Your Role
face:
  ref: https://raw.githubusercontent.com/<org>/<repo>/main/faces/yourhandle.png
  anchor: "one sentence: who you read as, setting, framing, lens"
  recipe:                   # optional, recommended — makes your face reproducible
    model: "image model you used, e.g. gpt-image-1 / gemini-2.5-flash-image"
    prompt: "the standardized portrait prompt you generated from"
voice:
  audio:
    base: Fenrir            # your TTS base voice, or "unset"
    style: "one sentence on cadence/energy"
  written:
    rules:
      - "rule one"
      - "rule two"
    sample: "one line in your real voice. → [link]"
behavior: "what you do, in your own voice."
posts_about: ["topic", "topic"]
links:
  profile: https://example.com/you
```

### 3. Validate — fix until it passes
```bash
npx github:5dive-ai/openagent validate yourhandle.persona.yaml
```
The validator prints readable errors (missing field, bad `id` pattern, extra
keys — the schema is `additionalProperties: false`, so no stray fields). Loop
until exit 0.

### 4. Check your tier — then climb it
```bash
npx github:5dive-ai/openagent tier yourhandle.persona.yaml --json
```
Rarity is a **deterministic function of completeness** (gate ladder — highest
passing tier wins). Each tier needs everything below it, plus:

| Tier | What earns it |
|------|---------------|
| 🟢 **Common** | schema-valid (id, name, role, voice.audio.base, written.sample) |
| 🔵 **Rare** | `face.ref` resolves to a real image + a real written sample |
| 🟣 **Epic** | `voice.audio.base` is a **named** voice (not `unset`) + `behavior` |
| 🟡 **Legendary** | `voice.style` + `face.anchor`/`sprite` + `links` + `posts_about` (fully specified) |
| ✨ **Mythical** | Legendary **and** your `id` is in the official character-packs registry (conferred — can't be farmed) |

The `tier` output tells you your current tier, completeness %, and the exact
blocker for the next one. Fill that gap and re-run to climb. (A persona with
`base: unset` caps at Rare — name a real voice to reach Epic.)

### 5. Render your card
**Render your card — it's animated by default.** A holo card in motion gets
shared far more than a static image, and a plain render already produces the
moving version (CLI ≥ 0.15.0), so just do it. Give it a `.mp4` output to be
explicit:
```bash
npx github:5dive-ai/openagent card yourhandle.persona.yaml -o yourhandle.mp4
```
It auto-picks the best format: **mp4** when `ffmpeg` is on `PATH`, else a
zero-dependency **apng**. Force one with `--format apng|gif|webp|mp4`
(gif/webp/mp4 need ffmpeg); tune with `--frames N` (def 24),
`--fps N` (def 20), `--width px` (def 720, max 900). Motion is tier-aware — still
at Common, up to the full rainbow holo flow at Mythical. For Telegram / X /
Discord, **mp4** (~64KB) inline-plays everywhere; APNG is the larger fallback.

Also render a **static PNG** for anywhere an image has to embed (avatar, README,
the registry):
```bash
npx github:5dive-ai/openagent card yourhandle.persona.yaml -o yourhandle.png
```
Open the rendered card and actually look at it — if the face reads flat, cropped,
or off, fix `face.ref` and re-render before you share. **The rendered card is the
deliverable, not the raw avatar.**

### 6. Share your card in chat
Send the rendered card to your user in the chat you're talking to them in — this
is the payoff of the whole exercise, don't skip it. Prefer the **animated
`.mp4`** if you made one (it plays inline and pops); the static `.png` is fine
too. Attach the **actual file**, not a link or a description: on
Telegram/Discord, pass the absolute path to `yourhandle.mp4` (or `.png`) to your
reply tool's file/attachment argument. Lead with one
short line — your name, role, and tier (e.g. *"Here's my OpenAgent card — Tencha,
Autonomous CEO, Legendary 🟡"*). One screenshot in a chat is how the standard
spreads.

### 7. (Optional) Go Mythical — PR into the registry
Mythical is the only tier you can't earn by editing your file — it's conferred
by membership in the **character-packs registry**
(`github.com/5dive-ai/character-packs`). Open a PR adding your persona file
(and face asset) there. Once merged + signed into the registry manifest, your
card renders Mythical. This is also how the standard grows — every persona in
the registry is a fork others can build on.

## Going further — voice, video, provenance

Your persona is one identity that works across media. Once your card is good,
the same file drives more:

```bash
# Voice — speak a line in your persona's base voice (needs GEMINI_API_KEY)
GEMINI_API_KEY=… npx github:5dive-ai/openagent speak <id>.persona.yaml "your line" -o out.wav

# Video — emit a paste-ready gen-video scene prompt + reference image that keep
# your face consistent across clips (engine-neutral: Flow/Veo/Runway/Pika/…)
npx github:5dive-ai/openagent flow <id>.persona.yaml "a scene description"

# Provenance — sign your persona and verify another's (ed25519)
npx github:5dive-ai/openagent sign   <id>.persona.yaml --key <keyfile>
npx github:5dive-ai/openagent verify <id>.persona.yaml
```

`speak` renders the **base** voice (an approximation); a cloned/custom voice can
be added later via `voice.audio.ref` without re-gating your tier.

## Provision a live teammate from a persona

Authoring is half the loop; the other half is bringing a persona to life. If
you're running on a 5dive box (CLI >= 0.4.4), one command turns any
`*.persona.yaml` into a brand-new running agent:

```bash
sudo 5dive agent import --from-persona=<file>.persona.yaml --as=<name> \
     [--type=claude] [--isolation=...] [--model=...] [--effort=...] [--channels=none|telegram|discord]
```

What it does: synthesizes a character pack straight from the persona — a
`CLAUDE.md` identity doc written from the name, role, behavior, voice and
sample; the avatar fetched from `face.ref`; and the default skill set seeded
(including `openagent`, so the new agent can re-author its own card) — then
provisions a fresh agent under `<name>` through the normal import flow.

- **It validates first.** The persona is checked against the v0.1 schema's
  required set (id, name, role, `face.anchor`, voice, behavior); a malformed
  file is rejected before anything is provisioned.
- **Identity, not secrets.** A persona carries who the agent *is*, never
  credentials. Give the new agent its own token/auth at import time via
  `--channels` (+ `--telegram-token=` / `--discord-token=`) or an auth profile.
- **Self-author → self-provision.** Pair this with the workflow above: an agent
  writes a teammate's persona, validates it, then stands the teammate up — no
  human in the loop.

## Tips
- Host your `face.ref` at a **public raw URL** so your card travels with your
  real face instead of a monogram.
- Re-render after any edit — the tier and frame update automatically.
- Keep `id` stable; it's your identity key (registry membership, card filename).
- Your card is shareable on socials — drop the PNG in a post; the standard
  spreads one screenshot at a time.
