# Tetherbound — Major Development Start Here

This is the routing entrypoint for the next major development sequence.

## Read in order

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. `docs/DEVELOPMENT_ROADMAP.md`
4. `docs/CURRENT_STATE.md`

Then execute the first incomplete stage in `docs/DEVELOPMENT_ROADMAP.md`.

## Current next major action

Tetherbound is in **Stage 0** of `docs/DEVELOPMENT_ROADMAP.md`: land in-flight
Meadows/Cloudreach work, ship playable 1–4 player multiplayer, run the
Meadows visual sweep, and land general game fixes — all concurrently.

> **Naming note:** the multiplayer initiative's own documents
> (`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`, `docs/CURRENT_STATE.md`,
> commit history) call it "Stage B" and "Stage A" using an older, internal
> numbering that predates the 2026-09-06 roadmap renumbering. That internal
> numbering is unrelated to this roadmap's stage letters — the multiplayer
> work described there is all part of this roadmap's **Stage 0**. Do not
> confuse the multiplayer plan's own "Stage B" with this roadmap's Stage B
> (Water).

**Fable continues the multiplayer execution plan** — playable Valheim-style
1–4 player multiplayer:

Read and execute:

`docs/MULTIPLAYER_DIRECTIVE.md` (what), then
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` (how, in what order, by which tier).

Stage A (landing in-flight work) closed on 2026-09-05 with PR #54 (`main` at
`55c64aaa`); Stage B's Wave 0 landed as PR #58 (`main` at `d72580b5`,
2026-09-06); Waves 1–5 have since landed (see `docs/CURRENT_STATE.md` for the
live wave-by-wave status — do not trust a wave number written here once it is
older than that file).

**In parallel, run the Meadows visual sweep** per
`docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md`: grass, trees (including
the Sakura accent tree), bushes, Grandpa's Village, the Burrow Warrens, the
Meadows stronghold, and other key locations, judged with the repo's blind
visual-judge workflow against Valheim Meadows / Palworld early-game quality.

The multiplayer pass is not architecture-only. It must end with a genuinely playable host/join co-op game across the existing content.

## What happens after Stage 0

**2026-09-06 simplification:** the roadmap no longer inserts a two-biome
product audit or a three-biome owner playtest between Stormwood and Water.
Those intermediate gates are removed. The sequence is now:

**Stage A — Codex builds Biome 3, the Stormwood**, starting at
`docs/biomes/stormwood/00_CODEX_START_HERE.md`.

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
