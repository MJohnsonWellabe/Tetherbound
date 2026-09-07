# Tetherbound — Major Development Start Here

This is the routing entrypoint for the next major development sequence.

## Read in order

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. `docs/DEVELOPMENT_ROADMAP.md`
4. `docs/CURRENT_STATE.md`

Then execute the first incomplete stage in `docs/DEVELOPMENT_ROADMAP.md`.

## Current next major action — 2026-09-07

**Run `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.** It is the one
consolidated contract for the next long orchestration run and it advances Stage 0
and Stage A together, which the owner has authorised:

- **Stage 0** stays open on two owner-only items (the outside-tester multiplayer
  session and the owner's own LAN session) and on the Meadows visual sweep, which the
  goal prompt carries as lane VIS-MEADOWS. The multiplayer implementation scope is
  complete and on `main`.
- **Stage A (Stormwood)** is in progress: five PRs merged, the Dynamo, legendary
  release, Spark/aftermath and Waterward view unbuilt, visual bars failed. The goal
  prompt carries it as lane STORMWOOD, resuming from
  `ralph/reports/STORMWOOD-PROGRESS/fresh-session-tail-0907.md`.
- **Stage B (Water)** is being built ahead of sequence on its own draft branch (PR #69)
  and is held there by owner instruction; the goal prompt carries it as lane WATER.
- The owner's 2026-09-07 playtest adds two P0 freezes and a road-presence P1 that
  come first (lanes STAB and ROAD).

> **Naming note:** the multiplayer initiative's own documents
> (`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`, `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`,
> commit history) call it "Stage B" and "Stage A" using an older, internal
> numbering that predates the 2026-09-06 roadmap renumbering. That internal
> numbering is unrelated to this roadmap's stage letters — the multiplayer
> work described there is all part of this roadmap's **Stage 0**. Do not
> confuse the multiplayer plan's own "Stage B" with this roadmap's Stage B
> (Water).

## What happens after Stage 0 and Stage A

**2026-09-06 simplification:** the roadmap no longer inserts a two-biome
product audit or a three-biome owner playtest between Stormwood and Water.
Those intermediate gates are removed. The sequence is:

**Stage B — build Biome 4, the Water Archipelago**, starting at
`docs/biomes/water/00_START_HERE.md`, immediately after Stormwood — do not
wait for an intermediate playtest.

**Stage C — one full four-biome product audit** (Meadows + Cloudreach +
Stormwood + Water), covering:

- continuous playability;
- solo and multiplayer reliability;
- item/creature/trainer/resource/NPC/content density;
- dead travel and exploration payoff;
- progression and bonding;
- combat and difficulty;
- building/camping/traversal/swimming;
- whether the game is actually fun minute-to-minute;
- whether the world feels authored;
- visual quality against the commercial stylized Valheim/Palworld comparison bar.

That audit produces a short P0/P1/P2/DO-NOT-WORK repair plan.

**Stage D — Fable closes the P0s and blocking P1s** across all four biomes
before any Biome 5–8 work begins.

**Stage E — the four-biome Beta Ready gate**, then **Stage F — beta launch**,
then **Stage G — Biomes 5–8** over time using the same build → audit → repair
discipline.

The living sequence and acceptance criteria are always in:

`docs/DEVELOPMENT_ROADMAP.md`

Update that file as stages change. Do not create a competing master roadmap.
