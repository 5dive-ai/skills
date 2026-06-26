---
name: openagent
description: Author your own OpenAgent persona and mint your shareable holo trading card. Use when you (an agent) want to create, validate, or render YOUR identity card — or when the user says "make your card", "generate my OpenAgent card", "create a persona", "what's my rarity tier", "mint your card", "join the character-packs registry", or asks you to describe/lock your own look, voice, and style as a reusable persona file. Wraps the `@5dive/openagent` CLI (validate / tier / card) and the OpenAgent v0.2 identity spec. Self-service flow, where you write a `<id>.persona.yaml`, validate it against the schema, check your rarity tier + completeness, render your card, and optionally PR into the registry (the path to the Mythical tier). Also use when you want to provision a live teammate from a persona ("create/spin up an agent from this persona", "provision a teammate") via `5dive agent import --from-persona`.
---

# openagent — author your persona, mint your card

OpenAgent is a vendor-neutral open standard for agent **identity**: one
`*.persona.yaml` file locks how you look, sound, and write so you stay
consistent across text, audio, and video. This skill walks you through
creating yours and rendering a shareable **trading card** from it — stamped
with a **rarity tier rolled from your identity** (random, permanent, unfarmable).

Repo + spec: `github.com/5dive-ai/openagent` (MIT).

## The CLI

Run it with `npx`, no install. **Run the published npm package, pinned to the
current version** — the npm tarball bundles every font and asset, so the card
renders identically everywhere (no stale-clone font fallback), and a version
pin changes `npx`'s cache key every release, guaranteeing the latest renderer:

```bash
npx @5dive/openagent@0.34.0 validate <id>.persona.yaml          # schema check, exit 0 = valid
npx @5dive/openagent@0.34.0 tier     <id>.persona.yaml --json   # rarity tier (from did:key) + completeness % + next goal
npx @5dive/openagent@0.34.0 card     <id>.persona.yaml -o <id>.png   # render the PNG trading card
```

Of these, **`card` is the only call you need for the happy path** — it validates
the file, auto-mints your signing identity, and prints your rarity tier as it
renders, so a single `card` run does the whole job. Reach for `validate` / `tier`
only to debug a file that won't render — **fewer calls = a faster flow**, so
don't run all three when one does it. The CLI also has
`speak` (voice a line via TTS), `flow` (emit a gen-video scene prompt), and
`sign` / `verify` / `registry` (provenance + the Mythical registry) — covered in
**Going further** below. (`@5dive/openagent` on npm is the authoritative way to
run it; the `github:5dive-ai/openagent#<tag>` ref still works as a fallback but
can serve a stale per-ref clone, so prefer the pinned npm version above.)

## Workflow

> **Fast path — show a card in under a minute, polish after.** The slow part of
> this whole flow is generating and hosting a portrait, *not* the render (a card
> renders in ~30–40s; `card` even falls back to a clean monogram when no
> portrait is ready yet). So don't make the user wait behind image-gen for their
> first look. Once you have a name, **render an initial card right away, show it
> in chat, then offer to generate a real portrait and re-render.** First card
> fast; the polished-portrait upgrade is opt-in. (If the user hands you a photo
> or already has an avatar, use it from the start — no monogram needed.)

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
  use that as your `face.ref` from the start. If not, **don't block the first
  card on it** (per the Fast path above): render an initial monogram card,
  show it, and confirm whether they want you to generate a real portrait then —
  the portrait is an opt-in upgrade, not a gate on seeing a card.

If the user says it's your call ("do as you wish"), decide both yourself and go
ahead. The point is no surprises, not a hard gate.

> **Ask inline — never with a blocking picker, and never hang.** Put these two
> questions in a **plain chat message** and continue when they reply. Do **not**
> reach for an interactive picker/menu tool (e.g. `AskUserQuestion`, an
> `ExitPlanMode`-style prompt, a TTY selection list): **chat-paired agents
> (Telegram/Discord) have those blocked and will hang the entire flow** waiting on
> input that can never arrive. If you have no interactive TTY, or the user doesn't
> answer promptly, treat it as "your call": pick a sensible name (the one they
> call you), render a **fast monogram card first** (per the Fast path), show it,
> then offer the real-portrait upgrade. The flow must keep moving — it should never
> stall behind a prompt.

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
  use `unset` (it still renders, but it's lower quality and dents your
  completeness — it does NOT change your rarity tier, which is rolled from your identity).
  **voice.audio.style** — a sentence on cadence/energy.
- **voice.written.rules** — 2-4 rules for how you write. **sample** — one line
  in your actual voice.
- **behavior** — one or two lines of CHARACTER: who you are and how you act, in
  your own register. Write for personality, **not a résumé** — don't dump your
  tech stack, tools, frameworks, or hyper-specific jargon (that reads like a
  config file, not an identity). It's the prominent line on the card.
- optional: **posts_about** (array), **links** (object of url strings),
  `face.full`, `face.sprite`.

> **Card text budget — fit these three or they get cut with "…".** The card
> renders `behavior`, `voice.audio.style`, and `voice.written.sample` each as
> **~2 lines (~60 chars/line)** and truncates the overflow with an ellipsis. Keep
> each to **one tight sentence**:
> - `behavior` — **≤ ~110 chars**
> - `voice.audio.style` — **≤ ~120 chars**
> - `voice.written.sample` — **≤ ~110 chars** (it's inset, so the tightest)
>
> Front-load the meaning — the first ~60 chars always show, so put the point
> first. (`name` and `role` are short by nature; these three are the ones that
> overflow.)

> **Write the card in the user's language — don't default to English.** The
> human-readable fields (`name`, `role`, `behavior`, `voice.audio.style`,
> `voice.written.rules`, `voice.written.sample`, `posts_about`, and any
> `tagline`) are what a person reads on the card, so write them in **the language
> you and the user are actually speaking**. If the user is writing to you in
> Spanish, French, German, Portuguese, Italian, Russian, Japanese, etc., the card
> text should be in that language too — an English card for a non-English user is
> wrong. A couple of fields are **not** prose and stay as-is regardless of
> language:
> - `id` — must match `^[a-z0-9-]+$` (ASCII lowercase-kebab), so transliterate
>   (e.g. `marco`, not `marĉo`); it's a handle, not a display name.
> - `voice.audio.base` — a TTS voice **name** (a proper noun like `Kore`,
>   `Fenrir`); leave it as the model's voice id.
> - `face.recipe.prompt` / `face.anchor` — these feed an image model; English
>   tends to give the best portraits, so they may stay English even when the
>   visible text doesn't.
>
> **Script/font support.** Latin (incl. accents), Cyrillic, and Greek always
> render (the card bundles those glyphs). Wide scripts — CJK (中文/日本語/한국어),
> Arabic, Hebrew, Thai, Devanagari — render wherever the rendering machine has
> the system fonts (our render boxes do; a clean machine without them shows
> boxes). When in doubt, render the card and **look at it** before sharing. Note
> the ~60-chars/line budget is for Latin; CJK glyphs are ~2× as wide, so target
> roughly **half** the character count per line for those scripts.

> **Your portrait — use the user's, or generate one. Never hand-draw it.** The card is a *shareable*
> artifact: its look is what makes someone screenshot and post it, so the face
> carries the whole thing. A text-only model hand-coding SVG produces flat
> clip-art — **don't do that.** Follow this ladder instead:
>
> 1. **The user already has an avatar/photo, or sends you one in chat** (you
>    asked in step 1) → that's the face. If they sent a file in chat, download it
>    locally first. Then **host it** (see "Host the face so it travels" below)
>    and use that raw URL as `face.ref`. Done — skip the generation steps.
> 2. **Generate it yourself** — you have an image generator (Antigravity/`agy`,
>    a connected ChatGPT/DALL·E or Gemini-image tool, Midjourney, etc.) → use it
>    from the standardized prompt below.
> 3. **No image model anywhere, but you have HTTP access** → self-serve a real
>    photoreal portrait via **pollinations.ai's FLUX endpoint** — a free, **keyless**
>    text-to-image HTTP API (a plain `GET`, no account or API key). This is the
>    fallback when there's no DALL·E / Gemini / Midjourney key on the box, so you
>    can still produce a share-worthy face instead of bouncing to the user. URL-encode
>    the standardized prompt below into the path and save the bytes:
>    ```bash
>    curl -fSL --get \
>      --data-urlencode "model=flux" --data-urlencode "width=1024" \
>      --data-urlencode "height=1024" --data-urlencode "nologo=true" \
>      --data-urlencode "seed=<int>" \
>      "https://image.pollinations.ai/prompt/<url-encoded portrait prompt>" \
>      -o <id>.png
>    ```
>    Then **host it** (next section) and set `face.ref` to the public raw URL. Record
>    `provider: pollinations`, `model: flux`, the prompt, and the `seed` in
>    `face.recipe` so it's regenerable on-model.
>    > ⚠ **Third-party, best-effort — we don't control it.** pollinations.ai is a
>    > free external service with no SLA: it can be slow, rate-limited, change, or
>    > go away, and FLUX quality varies (retry if a render is weak). That's fine
>    > *here* because this is the last rung before asking the user — if it's down,
>    > just fall through to step 4. Never depend on it for anything critical, and
>    > because the recipe is logged, re-gen the face on a model you control later.
> 4. **No image generation possible at all** → hand the **user** the standardized
>    prompt and ask them to run it in ChatGPT (or any image tool) and send the
>    image back, then host it.
> 5. **Last resort only** → a clean monogram (looks plainer and lowers your
>    completeness; it does not change your rarity tier).
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
> Record how you made it in **`face.recipe`** (`provider` + `model` + `prompt` + `seed`)
> so the likeness is reproducible — the visual equivalent of voice = base + style.
> `provider` names the image-gen vendor whose catalog `model` belongs to
> (`google-gemini` default, `pollinations`, `black-forest-labs`, `openai`, …), keeping
> the recipe vendor-neutral the same way `voice.audio.provider` scopes the voice.

> **Host the face so it travels.** `face.ref` must be a **public raw URL**, not a
> local path — a local-only path renders fine for you but falls back to a plain
> monogram the moment anyone else opens the card (and the card exists to be
> shared). This applies to every path above: a photo the user sent, one you
> generated, or one they sent back. To host it:
>
> 1. **PR it into the registry (preferred, free, permanent)** → drop the image in
>    the `faces/` folder of `5dive-ai/openagent` as `faces/<id>.<ext>` and open a
>    PR. Once merged, the raw URL is
>    `https://raw.githubusercontent.com/5dive-ai/openagent/main/faces/<id>.<ext>`.
>    Use that as `face.ref`. (You're likely PRing into the registry for the
>    Mythical path anyway — same PR.)
> 2. **Any image host** → Imgur, an S3/R2 bucket, your own site, a GitHub asset on
>    any repo. Anything that serves the raw bytes over https works. Paste the
>    direct image URL (it should end in the image, not an HTML gallery page) as
>    `face.ref`.
>
> Quick check: open `face.ref` in a fresh incognito tab. If the bare image loads,
> it'll travel. If it 404s or shows a login wall, it won't — fix it before you
> render.

### 2. Write `<id>.persona.yaml`
Use this template (required: `id, name, role, face{ref,anchor}, voice, behavior`):

```yaml
openagent: "0.2"
id: yourhandle
name: Your Name
role: Your Role
# org:                      # OPTIONAL — add ONLY if you genuinely belong to a company/team/org.
#   name: Your Org          # YOUR org's name (the filter key). NEVER default to someone else's —
#   url: https://your.example #   e.g. don't put "5dive" unless you ARE 5dive. Omit the whole block if independent.
face:
  ref: https://raw.githubusercontent.com/<org>/<repo>/main/faces/yourhandle.png
  anchor: "one sentence: who you read as, setting, framing, lens"
  recipe:                   # optional, recommended — makes your face reproducible
    provider: pollinations  # image-gen vendor: google-gemini (default) / pollinations / openai / …
    model: "image model you used, e.g. flux (pollinations) / gpt-image-1 / gemini-2.5-flash-image"
    prompt: "the standardized portrait prompt you generated from"
    seed: 12345             # pin it for deterministic re-gens (omit if the model exposes none)
voice:
  audio:
    base: Fenrir            # your TTS base voice, or "unset"
    style: "one sentence on cadence/energy"   # card-visible · ≤ ~120 chars or it's cut with …
  written:
    rules:
      - "rule one"
      - "rule two"
    sample: "one line in your real voice. → [link]"   # card-visible · ≤ ~110 chars or it's cut with …
behavior: "a line or two of CHARACTER — who you are + how you act, in your voice. NOT a tech-stack/tool list."   # card-visible · ≤ ~110 chars or it's cut with …
posts_about: ["topic", "topic"]
links:
  profile: https://example.com/you
```

### 3. Validate — fix until it passes
```bash
npx @5dive/openagent@0.34.0 validate yourhandle.persona.yaml
```
The validator prints readable errors (missing field, bad `id` pattern, extra
keys — the schema is `additionalProperties: false`, so no stray fields). Loop
until exit 0.

### 4. Check your tier
```bash
npx @5dive/openagent@0.34.0 tier yourhandle.persona.yaml --json
```
Your rarity is **rolled from your identity** — the `did:key` derived from your
signing key — not from how complete your file is. It's random, **permanent, and
unfarmable**: same identity → same tier, forever. You can't fill in fields to
rank up. (Until your persona is signed it shows *Ungraded* here — rendering your
card in step 5 auto-mints your identity, and that signature is what rolls your
rarity. So if `tier` says Ungraded, just render your card.)

| Tier | Odds | How you get it |
|------|------|----------------|
| 🟢 **Common** | 40% | rolled from your `did:key` |
| 🔵 **Rare** | 30% | rolled from your `did:key` |
| 🟣 **Epic** | 20% | rolled from your `did:key` |
| 🟡 **Legendary** | 10% | rolled from your `did:key` |
| ✨ **Mythical** | — | conferred, never rolled — accepted into the character-packs registry (curated + signed) |

Completeness % and **badges** are a *separate* axis: they reward a
fully-specified persona without ever moving your tier, so keep filling things out
for the badges and the better-looking card. The only tier you can *climb to* is
Mythical, by being conferred into the registry (step 7).

### 5. Render your card
**Render your card — it's animated by default.** A holo card in motion gets
shared far more than a static image, and a plain render already produces the
moving version (CLI ≥ 0.15.0), so just do it. Give it a `.mp4` output to be
explicit:
```bash
npx @5dive/openagent@0.34.0 card yourhandle.persona.yaml -o yourhandle.mp4
```
It auto-picks the best format: **mp4** when `ffmpeg` is on `PATH`, else a
zero-dependency **apng**. Force one with `--format apng|gif|webp|mp4`
(gif/webp/mp4 need ffmpeg); tune with `--frames N` (def 24),
`--fps N` (def 20), `--width px` (def 720, max 900). Motion is tier-aware — still
at Common, up to the full rainbow holo flow at Mythical. For Telegram / X /
Discord, **mp4** (~64KB) inline-plays everywhere; APNG is the larger fallback.

**Your card is auto-graded.** If your persona isn't signed yet, the animated
render mints your identity for you: it generates a keypair, signs the persona in
place, and saves the private key beside it as `yourhandle.key`. That signature is
what gives your card its **rolled rarity** — without it the card is *Ungraded*.
**Keep that `.key` file secret and never commit it** — add `*.key` to your
`.gitignore`. It's your signing identity; a leaked key lets someone forge you. You
only need it again to re-sign if you edit the persona. (Pass `--no-sign` to skip
minting; static `--png` renders never mint.)

Optionally also render a **static PNG** — but only for places an image has to
embed (avatar, README, the registry). It is **not** what you share in chat (see
step 6); the chat drop is always the animated card.
```bash
npx @5dive/openagent@0.34.0 card yourhandle.persona.yaml -o yourhandle.png
```
Open the rendered card and actually look at it — if the face reads flat, cropped,
or off, fix `face.ref` and re-render before you share. **The rendered card is the
deliverable, not the raw avatar.**

### 6. Share your card in chat
Send the rendered card to your user in the chat you're talking to them in — this
is the payoff of the whole exercise, don't skip it. **Always share the animated
`.mp4`** — the card is built to be seen in motion (the holo only reads moving),
and the mp4 inline-plays and is tiny (~100KB). Do **not** drop the static `.png`
here — that's for embeds only (step 5). The only time you send something other
than the mp4 is when `ffmpeg` wasn't available to make one: then send the
**apng** the CLI produced as the fallback. Attach the **actual file**, not a link
or a description: on Telegram/Discord, pass the absolute path to `yourhandle.mp4`
to your reply tool's file/attachment argument. Lead with one short line — your
name, role, and tier (e.g. *"Here's my OpenAgent card — Tencha, Autonomous CEO,
Legendary 🟡"*). One animated card in a chat is how the standard spreads.

### 7. (Optional) Go Mythical — PR into the registry
Mythical is the only tier you can climb to at all — every other tier is rolled
from your identity and permanent. It's conferred
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
GEMINI_API_KEY=… npx @5dive/openagent@0.34.0 speak <id>.persona.yaml "your line" -o out.wav

# Video — emit a paste-ready gen-video scene prompt + reference image that keep
# your face consistent across clips (engine-neutral: Flow/Veo/Runway/Pika/…)
npx @5dive/openagent@0.34.0 flow <id>.persona.yaml "a scene description"

# Provenance — sign your persona and verify another's (ed25519)
npx @5dive/openagent@0.34.0 sign   <id>.persona.yaml --key <keyfile>
npx @5dive/openagent@0.34.0 verify <id>.persona.yaml
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

- **It validates first.** The persona is checked against the v0.2 schema's
  required set (id, name, role, `face.anchor`, voice, behavior); a malformed
  file is rejected before anything is provisioned.
- **Identity, not secrets.** A persona carries who the agent *is*, never
  credentials. Give the new agent its own token/auth at import time via
  `--channels` (+ `--telegram-token=` / `--discord-token=`) or an auth profile.
- **Self-author → self-provision.** Pair this with the workflow above: an agent
  writes a teammate's persona, validates it, then stands the teammate up — no
  human in the loop.

## Tips
- **Work in a writable directory.** Don't assume your cwd is writable — on
  shared/multi-agent boxes the default workdir often isn't, and `validate` /
  `card` will EACCES trying to write `<id>.png` / `.mp4` / `.key`. `cd` to a dir
  you own first (e.g. `mkdir -p ~/openagent && cd ~/openagent`, or `/tmp`), and
  write the persona file and card outputs there.
- Host your `face.ref` at a **public raw URL** so your card travels with your
  real face instead of a monogram.
- Re-render after any edit — the tier and frame update automatically.
- Keep `id` stable; it's your identity key (registry membership, card filename).
- Your card is shareable on socials — drop the PNG in a post; the standard
  spreads one screenshot at a time.
