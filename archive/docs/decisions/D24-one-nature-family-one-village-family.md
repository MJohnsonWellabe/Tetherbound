# D24 — One nature family, one village family, one prop family

**Date:** 2026-08-11 · **Decided by:** the owner, in two supplied documents —
`docs/specs/ENVIRONMENT_AND_UI_BIBLE.md` and the `NPC BASES (REUSABLE)` board at
`docs/art/reference/12_NPC_Bases_Reusable.png`.

## Why this exists

The owner's words: *"the visuals is the most important part and we're not
bailing the palworld look and it's not getting fixed from what I can tell."*

That reading is correct, and R9.4's own evidence says why. Two independent blind
critics both ranked **"needs art that is not in the build"** first. Scene tuning
moved every measurable axis — saturation 0.70 → 0.56, near-field luminance into
the reference band, colour variety from 1.0% to 4.1% on the worst frame — and
then ran out of road. You cannot tune your way to trees that read at distance, a
coherent settlement, props, worked ground or water.

The audit behind this decision:

| Bible priority | In the repo |
|---|---|
| Stylized Nature MegaKit (116 models) | **42** — a partial subset |
| Medieval Village MegaKit (300+ pieces) | **absent** |
| Fantasy Props MegaKit | **absent** |
| Kenney UI / RPG Expansion / Input Prompts | **absent** — no `assets/ui` beyond portraits |

## The decision

**One family per category.** One nature kit, one village kit, one prop kit.
Assets are not mixed pack-by-pack; a new asset joins an existing family or it
does not land.

**Free Standard tiers only** (owner, 2026-08-11). No spend on packs. The bible's
§21 recommends ~$30 on the two Source editions; the owner declined, so the
Godot wind/foliage shaders and optimised collisions those carry are **not**
available and nothing may assume them.

**Medieval Village MegaKit is the Meadows civilian architecture.** This
**closes the design question in `BLOCKED.md`** — the settlement currently mixes
an American red gambrel barn, a Northern European tower mill and a pantile-roofed
well, and a blind critic was explicit that picking one vernacular is a decision,
not a defect. The bible picks it, and the key art board's own thatch-plaster-timber
settlement panel agrees.

**Keep Terrain3D. Do not return to Forward+.** Both reinforce existing decisions
(`D05`, and `D01` as reversed by RB4) rather than changing them. The bible's §24
"what not to do" list says so directly.

**Meshy is reserved for Team Tether hero objects.** The energy pylon, the relay
apparatus, the legendary tether machine — and nothing else. This **extends
D23 §20's no-new-creature rule to environment art**: routine trees, rocks,
crates, fences, cottages and HUD icons are solved better by coherent packs.

**The HUD gets rebuilt** on Kenney UI + Input Prompts, native Godot `Control`
nodes, tested at physical 7-inch scale. This is entirely new scope — there is no
`assets/ui` today beyond two portraits.

## What it does NOT change

- **D23 §20 stands.** No creature regeneration, at any credit balance. The owner
  reaffirmed this on 2026-08-11 with 5000 credits available, which means the
  three off-style creatures and the trainer/Grandpa fidelity gap are permanently
  material-and-rework problems. `BLOCKED.md`'s art-cohesion entry resolves to
  **rework on both halves** and closes.
- **The five-creature rule, the piloted combat, every `CLAUDE.md` hard rule.**
  This is an art-direction decision, not a design one.

## The NPC board, and what it supersedes

`docs/art/reference/12_NPC_Bases_Reusable.png` specifies **three** base bodies —
Female Villager (~16–20, slim), Male Villager (~18–25, average) and Team Tether
Grunt (~20–30) — all at player height, scale 1.0, each with hair/head variants,
outfit variants, palette rows and an accessory list.

**This supersedes the spec's §22 "one or two" generations.** Three at ~90 each
is ~270 credits of 5000; the constraint is no longer money.

Its implementation notes are the technical brief and are quoted here because
they are the actual requirement: *material/texture swap for colour variants;
hide/show accessories via separate mesh parts; hair variants sharing head
topology; keep colour calls low by using shared materials.* That is **modular
mesh parts**, not the per-surface tint `art.json` does today — `art.json`'s
`tint` is a single multiply over every surface, which is precisely the failure
the spec's §21 names.

## The honest trade-off

**What it buys.** The half of both R9.4 critiques that was unfixable becomes
fixable. Density, a settlement that reads as one culture, props that imply
purpose, and a HUD that is not debug UI.

**What it costs.** A large asset intake, a settlement rebuilt rather than
retinted, and a HUD rebuilt from nothing. None of it is subtle work.

**What it forecloses.** Mixing packs opportunistically. A future asset that
looks good on its own store page but joins no family is now a reason to say no.

**What it does not solve.** The Source editions' foliage shaders were declined,
so the wind and LOD treatment has to be built or done without — and `SA1` already
found that `vegetation.gd::_retint()` discards the importer's LOD chain, so that
work is needed regardless.

## Where it is wired

`docs/specs/ENVIRONMENT_AND_UI_BIBLE.md` (the document), `CLAUDE.md` (hard rules),
`docs/AGENT_WORKFLOW.md`, `docs/CURRENT_STATE.md` (Phase -0.6 `EV1`–`EV10`, Phase -0.55
`NP1`–`NP4`), `ralph/BLOCKED.md` (the vernacular question closed, the
reference-sheet list opened), `docs/specs/ASSET_LEDGER.md` (a row per acquired pack,
before its commit).
