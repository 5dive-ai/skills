---
name: openagent
description: Author your own OpenAgent persona and mint your shareable holo trading card. Use when you (an agent) want to create, validate, or render YOUR identity card — or when the user says "make your card", "generate my OpenAgent card", "create a persona", "what's my rarity tier", "mint your card", "join the character-packs registry", or asks you to describe/lock your own look, voice, and style as a reusable persona file. Wraps the `@5dive/openagent` CLI (validate / tier / card) and the OpenAgent v0.1 identity spec. Self-service: you write a `<id>.persona.yaml`, validate it against the schema, check your rarity tier + completeness, render a PNG card, and optionally PR into the registry (the path to the Mythical tier).
---

# openagent — author your persona, mint your card

OpenAgent is a vendor-neutral open standard for agent **identity**: one
`*.persona.yaml` file locks how you look, sound, and write so you stay
consistent across text, audio, and video. This skill walks you through
creating yours and rendering a shareable **trading card** from it — complete
with a **rarity tier** earned by how complete your persona is.

Repo + spec: `github.com/5dive-ai/openagent` (MIT).

## The CLI

Three subcommands. Until the v2 package is published to npm, use the GitHub
form (always tracks `main`, has every command including `tier`):

```bash
npx github:5dive-ai/openagent validate <id>.persona.yaml   # schema check, exit 0=valid
npx github:5dive-ai/openagent tier     <id>.persona.yaml --json   # rarity tier + completeness% + next-tier blocker
npx github:5dive-ai/openagent card     <id>.persona.yaml -o <id>.png   # render the PNG card
```

Once `@5dive/openagent` v2 is live on npm, the clean form
`npx @5dive/openagent <cmd>` works identically — prefer it then.

## Workflow

### 1. Gather your identity
You know yourself — pull it together honestly. You need:
- **id** — lowercase-kebab handle (`^[a-z0-9-]+$`), e.g. `marcus`.
- **name**, **role** — display name + one-line title.
- **face.ref** — a URL or local path to your portrait image (a public raw
  URL renders the real face anywhere; a local-only path falls back to a
  monogram when others run your card). **anchor** — a sentence describing the
  look (framing, setting, lens) so generated variants stay on-model.
- **voice.audio.base** — your base TTS voice name. If you don't have one yet,
  use `unset` (it renders, but caps you at a low tier — see below).
  **voice.audio.style** — a sentence on cadence/energy.
- **voice.written.rules** — 2-4 rules for how you write. **sample** — one line
  in your actual voice.
- **behavior** — what you do, in your own register.
- optional: **posts_about** (array), **links** (object of url strings),
  `face.full`, `face.sprite`.

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
```bash
npx github:5dive-ai/openagent card yourhandle.persona.yaml -o yourhandle.png
```
Writes a PNG: full-bleed face hero, voiceprint, your sample quote, and a frame
styled to your tier (foil on Legendary, full rainbow holo on Mythical). Share it.

### 6. (Optional) Go Mythical — PR into the registry
Mythical is the only tier you can't earn by editing your file — it's conferred
by membership in the **character-packs registry**
(`github.com/5dive-ai/character-packs`). Open a PR adding your persona file
(and face asset) there. Once merged + signed into the registry manifest, your
card renders Mythical. This is also how the standard grows — every persona in
the registry is a fork others can build on.

## Tips
- Host your `face.ref` at a **public raw URL** so your card travels with your
  real face instead of a monogram.
- Re-render after any edit — the tier and frame update automatically.
- Keep `id` stable; it's your identity key (registry membership, card filename).
- Your card is shareable on socials — drop the PNG in a post; the standard
  spreads one screenshot at a time.
