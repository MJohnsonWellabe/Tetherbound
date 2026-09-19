# WORLD-GRASS — give the ground volume, and fill the middle of the frame

**Owner-directed, 2026-08-25.** The owner brought a reference — a Godot
soulslike demo — and said plainly: *"the world looks exactly how I'd want"*,
and, asked what mattered most, **"the grass feels most important to me."**

That is the priority order for this prompt. Grass first. Everything else here
is secondary and may ship separately.

## The reference

Three frames in `docs/reference/`:

- `moong-01-mounted-in-tall-grass.jpg` — the important one. Foreground grass
  stands past the mount's legs. The ground material is **never visible**.
- `moong-02-meadow-with-landmark.jpg` — shin-deep grass over the whole ground
  plane, pink flower drifts in clumps, mid-ground shrubs, a grey rock hill in
  the middle distance as a landmark.
- `moong-03-meadow-with-landmark-alt.jpg` — near-duplicate of 02, a step to one
  side. Kept because two frames of the same place from different angles is
  evidence the look holds when the camera moves, which a single hero shot is not.

Provenance and the limits on using these are in `docs/specs/ASSET_LEDGER.md`. They are
**judging references only** — third-party screenshots, never a source of assets,
never shipped, never traced.

**Read the reference for structure, not for palette.** Our palette is already
settled by `tetherbound-meadows-keyart.png` and `data/config/palette.json`, and
the reference happens to sit close to it, which is why it is usable at all. If
the two ever disagree, the keyart wins — that is `docs/reference/README.md`'s
standing rule and this prompt does not change it.

## What is actually wrong, measured

Do not re-derive this. It was measured on `main` at `ded2e697`.

**The ground plane in our build is a terrain splat texture, not geometry.**
`build_playground_terrain.gd` blends grass/soil/rock by slope. That is fine and
should stay. The problem is what stands on top of it.

`data/config/vegetation.json`'s `grass` layer, on `main`:

| field | main | what it means |
|---|---|---|
| `scale_min` / `scale_max` | **0.14 / 0.42** | the root cause — blades a few centimetres tall |
| `corridor_fill.density_scale` | **1.0** | vs **6.0** for both `bushes` and `trees` |
| `lod_range` | **55.0** | ground is bare texture past 55 m |
| `models` | Short, Tall, Wide_Short, Wide_Tall | all four already wired |

For comparison the same file scales `bushes` at 0.6–1.5 and `trees` at
0.55–1.35. Our grass is placed — 110 clumps × 130, plus 900 strays, plus a 2400
verge — and then scaled to near-invisibility. At eye height the player sees the
terrain texture, which is exactly the blind critique's "60–90% of most frames is
one flat green terrain material with confetti scatter."

**No new assets are needed and none may be added.** `Grass_Common_Tall.gltf` and
`Grass_Wide_Tall.gltf` are already in `models` and already vendored, alongside
`Fern_1` and `Clover_1/2` for the mid-layer. CLAUDE.md's one-nature-family rule
is not in tension with this task; if you believe it is, stop and flag rather
than importing a pack.

## Do not undo VISUAL-GROUNDCOVER

`ralph/VISUAL-GROUNDCOVER` (`ea589dd9`, not yet landed) rescaled `flowers`
0.07–0.26 → **0.025–0.09** and `bushes` 0.6–1.5 → **0.45–1.0**. That is the
correct fix for the critique's separate "violet flowers ~3× oversize, 0.5–0.8 m
blossoms" defect and it must survive.

Note what follows from it, because it is the reason this prompt exists: that
branch **never touched `grass`**, and it made the mid-layer smaller. Landed on
its own it leaves the ground plane emptier than before, not fuller. Merge it
first, keep its numbers, and put the grass work on top.

## The work, in priority order

1. **Grass reads as grass.** Scale up until a standing player is in it to the
   ankle or shin and the terrain texture is not visible on flat ground at
   walking camera height. Prefer the Tall models where the frame is open. Raise
   `corridor_fill.density_scale` off 1.0 — the corridor fill is what covers the
   7.5 km outside authored clumps, and at 1.0 it barely places any.
2. **Grass survives into the middle distance.** `lod_range` 55 m leaves a bald
   ring around the player. Push it out until the ground reads as covered to the
   treeline, then pay for it in the budget below.
3. **Mid-layer.** The reference fills foreground grass → shrubs → trees → rock →
   sky. We currently jump from ground to canopy with nothing between. Ferns,
   clover and the rescaled bushes go here.
4. **Flower drifts in clumps, not an even sprinkle.** The layer already has
   `clumps`/`per_clump`; the reference's pink drifts are tight and irregular.
5. **A landmark in the middle distance** where a band lacks one — the rock hill
   in frames 02/03 is what gives the eye somewhere to go. `docs/CURRENT_STATE.md`
   already carries the band3 dead-stretch horizon item; this is that.

Items 3–5 are secondary. Ship 1–2 alone if the budget forces it.

## Budget — this is the real constraint

Grass is cheap on CPU and expensive on GPU, and **ROG Ally is the target**, so
the usual "it runs fine here" is not evidence.

- `tests/test_scatter_perf_budget.gd` caps placements at
  `MAX_SANE_PLACEMENT_COUNT = 260000`. The current bake is ~144,456. That is the
  headroom you have; do not raise the cap to fit a number you liked.
- `ralph/PERF_ROG_REPORT.md` (OP23-01) just took per-frame CPU from 33–40 ms to
  3.8–4.7 ms against a 16.7 ms frame. **Do not spend that win here.** Re-run
  `tools/perf_profile.gd` at its six corridor sites and report before/after.
- `PERF-ROG-GPU` in `docs/CURRENT_STATE.md` says plainly that this container cannot
  measure GPU frame cost — Compatibility counts MultiMesh batches, not
  instances, and this box rasterises in software. So state your GPU risk
  honestly as a risk. Do not claim a frame rate.
- Prefer cheaper coverage before more instances: larger per-blade scale, wider
  LOD fade, denser clumps over more strays.

## Evidence required

Per `docs/AGENT_WORKFLOW.md`, this is visual-affecting work and the blind pass is
law, not a formality:

- Render real frames, at minimum: band1 open meadow, band2 forest floor, band4
  high pasture, and one mounted frame (the reference's own framing — we have
  Meadowhart riding and `smoke_riding` passes).
- A **blind critic** — a sub-agent told nothing about what changed — judges them
  against `docs/reference/`, iterating until two rounds produce no new defect and
  no measured movement in `tools/frame_stats.py`.
- Re-bake scatter and `--headless --import` after it. A bake that does not reach
  a capture is a documented trap in `docs/AGENT_WORKFLOW.md`.
- `tests: test_veg_corridor, test_scatter_rules, test_scatter_perf_budget,
  test_band_vegetation, test_scatter_fingerprint_covers_bands` plus the full
  suite if you touch anything outside `data/config/vegetation.json`.

## Done means

A player standing anywhere on the corridor is standing **in** grass, not on a
picture of it; the middle distance is covered rather than bald; the mid-layer
is occupied; and the blind critic stops finding new ground-plane defects — with
the scatter budget and the OP23-01 CPU win both intact and measured, and the GPU
risk stated rather than guessed.
