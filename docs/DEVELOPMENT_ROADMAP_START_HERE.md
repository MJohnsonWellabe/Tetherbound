# Tetherbound — Major Development Start Here

This is the routing entrypoint for the next major development sequence.

## Read in order

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. `docs/DEVELOPMENT_ROADMAP.md`
4. `docs/CURRENT_STATE.md`

Then execute the first incomplete stage in `docs/DEVELOPMENT_ROADMAP.md`.

## Current next major action

Once all currently in-flight Meadows and Cloudreach work has landed and `main` is stable:

**Fable executes Stage B — playable Valheim-style 1–4 player multiplayer.**

Read and execute:

`docs/MULTIPLAYER_DIRECTIVE.md` (what), then
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` (how, in what order, by which tier).

Stage A closed on 2026-09-05 with PR #54 (`main` at `55c64aaa`); Stage B's Wave 0 landed as
PR #58 (`main` at `d72580b5`, 2026-09-06). Wave 1 (state and save separation) is the current
lane; its briefs are under `ralph/briefs/MP-W1/`.

The multiplayer pass is not architecture-only. It must end with a genuinely playable host/join co-op game across the existing content.

## What happens immediately after multiplayer

Do **not** start Biome 3 immediately.

Fable next executes Stage C in `docs/DEVELOPMENT_ROADMAP.md`: a full player-facing Meadows + Cloudreach product audit covering:

- continuous playability;
- solo and multiplayer reliability;
- item/creature/trainer/resource/NPC/content density;
- dead travel and exploration payoff;
- progression and bonding;
- combat and difficulty;
- building/camping/traversal;
- whether the game is actually fun minute-to-minute;
- whether the world feels authored;
- visual quality against the commercial stylized Valheim/Palworld comparison bar.

That audit produces a short P0/P1/P2/DO-NOT-WORK repair plan. Fable closes the P0s and blocking P1s before Codex begins Stormwood.

## After the audit/repair

Codex starts Biome 3 at:

`docs/biomes/stormwood/00_CODEX_START_HERE.md`

After Stormwood, the owner performs the formal three-biome playtest, Fable repairs the findings, then Biome 4 is designed/built, followed by the four-biome Beta Ready gate and beta launch.

The living sequence and acceptance criteria are always in:

`docs/DEVELOPMENT_ROADMAP.md`

Update that file as stages change. Do not create a competing master roadmap.
