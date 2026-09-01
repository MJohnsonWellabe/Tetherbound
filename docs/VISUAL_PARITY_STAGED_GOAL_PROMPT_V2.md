# TETHERBOUND — MEADOWS VISUAL PARITY PROGRAM (STAGED + RESUMABLE)

**Status:** Owner directive for the dedicated visual-parity branch.  
**Scope:** Meadows only. This does not authorize Biome 2 work.

This program supersedes normal `ralph/ACTIVE_GAME_PLAN.md` routing **for the visual-parity branch only**. All `CLAUDE.md` hard rules remain binding.

Use `VP0`–`VP11` for these visual passes so they are never confused with gameplay Gate A/B/etc.

## Governing target

Read and follow:

- `docs/TETHERBOUND_VISUAL_BIBLE_V2.md` — authoritative visual target
- `CLAUDE.md`
- `ralph/START_HERE.md`
- `ralph/conventions.md`
- `docs/ENVIRONMENT_AND_UI_BIBLE.md`
- `docs/reference/tetherbound-meadows-keyart.png`
- current owner-approved website/world art references in the repo

Primary goal:

> Make the real playable Meadows deliver roughly 80% of the visual impression of the approved website art: lush, colorful, layered, alive, composed, readable, polished, and recognizably the same Tetherbound world.

Do not fake screenshots, redesign Meadows canon, or implement Biome 2.

## Branch

Start from current `main` and use:

`codex/meadows-visual-parity`

Do not work on `main`. Do not merge. Do not force-push.

If the branch already exists, fetch it, read `docs/VISUAL_PARITY_PROGRESS.md`, verify the latest pushed pass, and resume at the first incomplete VP pass.

## VP-PRE — capability check

Before visual changes:

1. Confirm Godot is available and the project imports.
2. Confirm the real game can launch.
3. Produce and open a real screenshot file from the repo capture pipeline.
4. Discover and run the repo's actual test command from current repo conventions/workflows.
5. Attempt the blind visual-judge workflow.

If 1–3 fail, stop and report. Do not make visual changes you cannot render and inspect.

If the blind judge cannot run in Codex, continue but record `JUDGE: DEFERRED` and preserve the full evidence set for external review.

## Fixed measurement target

Use the same settings for all comparable measurements:

- Renderer: Compatibility
- Capture/measurement resolution: 1920×1080
- Target platform: Windows / ROG Ally
- Minimum sustained FPS: 45
- Minimum 1% low: 30
- Graphics preset: identify the current intended ROG Ally/default gameplay preset, record its exact settings in `docs/VISUAL_PARITY_PROGRESS.md`, and keep it fixed for all measurements

If a VP pass drops below the performance floor, fix the cost within that pass rather than carrying the debt to the end.

## Persistent checkpoint

Create and maintain:

`docs/VISUAL_PARITY_PROGRESS.md`

It must always record:

- branch and starting `main` SHA
- current SHA
- current VP pass
- completed/remaining passes
- commit SHA for each completed pass
- last successful push SHA
- VP-PRE results
- exact test command and result
- performance measurements
- judge verdict or `DEFERRED`
- evidence paths
- decisions/regressions/known limits
- exact next action

Update, commit, and push this file after **every completed pass**.

## Per-pass completion rule

A VP pass is not complete until:

1. changes are implemented;
2. tests pass;
3. the real game is captured;
4. matched evidence exists;
5. performance is measured;
6. major Meadows traversal still works;
7. NPC/creature pathing, spawns, triggers, interactables, and save/load have not regressed;
8. blind judgement runs or is explicitly deferred with evidence;
9. the progress file is updated;
10. the pass is committed and **pushed**.

Then continue automatically if usage/context remains.

If usage/context appears low, do not begin another pass. Finish the current coherent checkpoint, commit, push, write the resume note, and stop.

## Passes

### VP0 — Baseline
Capture current wide Meadows, village day/night, Grandpa yard, tournament, pond/stream, Warrens, camps/waystop, Relay, Hall where available, creature/world, combat, and building/home views. Record baseline performance and defects. Commit and push.

### VP1 — Sky / sun / lighting / atmosphere
Fix smeared clouds, sun presentation, directional lighting, shadows, distance haze, and foreground/mid/background separation. Validate several outdoor locations, not one hero angle. Commit and push.

### VP2 — Terrain materials + ground cover
Reduce exposed uniform terrain; improve grass/groundcover layering, macro variation, texture scale, dirt/grass/rock transitions, water edges, and path integration. Optimize with Terrain3D/MultiMesh/LOD/culling rather than brute-force density. Commit and push.

### VP3 — Vegetation layering + clustering
Create groves, forest edges, bushes/saplings beneath trees, varied tree scale, hero trees, stream vegetation, foreground framing, clearings, and distant tree masses. Remove obvious mismatched foliage language. Commit and push.

### VP4 — Mid-ground + travel corridors
Eliminate `player → empty grass → sky`. Strengthen actual player routes with canonical groves, rocks, fences, streams, ridges, structures, paths, creature groups, and landmark framing. Build visual rhythm rather than clutter. Commit and push.

### VP5 — Village / tournament / camps
Make the village unmistakably inhabited in daylight; make the tournament visually read as an event; make camps read around clear fire/rest focal points with authored prop clusters and appropriate people/creatures. Commit and push.

### VP6 — Burrow Warrens
Improve exterior rock/material integration and make the interior read as a genuine den through dressing, surface variation, moisture/use marks, and directional lighting. Verify creature staging in motion. Commit and push.

### VP7 — Team Tether Relay
Keep the strong pylon/apparatus identity but make the entire site visibly operational through personnel, work clutter, mounts, cables, damage/work signs, faction identity, and purposeful composition. Commit and push.

### VP8 — Meadows Hall
Deliver **ancient ruin reclaimed by nature + Team Tether industry bolted onto it**, never a clean cream castle. Improve weathered stone, moss, ivy, broken walls, gate/roof/rubble, courtyard dressing, banners, scaffolds, pipes, machinery, boiler/chimney, and occupation evidence without breaking gameplay layout. Commit and push.

### VP9 — World life
Increase believable roaming creatures, creature groups, NPC walkers, trainers, villagers, Team Tether personnel, and ambient motion where appropriate. Do not fake population only for screenshots or break encounter balance. Commit and push.

### VP10 — Performance retention
Profile the accumulated visual pass and optimize LOD, visibility, scatter, shadows, MultiMesh, materials, overdraw, particles, textures, and always-active nodes while preserving the visual read. Commit and push.

### VP11 — Final recapture + handoff
Produce matched before/after evidence for major locations, hero gallery, baseline-vs-final performance, per-pass judge history, known limits, branch/commit information, and final progress state. Commit and push. Do not merge.

Final status must be:

> **CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT**

Codex is the builder, not the final visual authority. Final acceptance belongs to the owner and external ChatGPT review.
