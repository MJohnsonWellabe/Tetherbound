# Exit handoff — visuals first — 2026-09-09

The owner requested a handoff, then explicitly requested that all outstanding
project work be pushed to main **after this exit document was written**. Stop new
feature work in this session. Consolidation, checks and landing are the remaining
wrap-up work. This document is written before that push; the landing receipt at
the end must be updated with the actual result. The overall four-biome goal is
unfinished. Do not interpret a landing as visual acceptance or campaign completion.

## Start here, without repeating the entire history

Read `CLAUDE.md`, `docs/00_START_HERE.md`, then
`docs/owner/OWNER_PLAYTEST_2026-09-09_VISUALS_FIRST.md` and this handoff.
The full goal contract remains `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.
Claude's documentation prerequisite already landed. Do not wait for it again.
Do not cold-read `archive/` or restart the long fresh-game replay.

The latest owner allocation is **30% creature faces/colours/crowding, 30%
Stormwood, 30% Water, 10% other**. The owner explicitly rejects the pink spider
and axolotl palettes, reports buried houses, dislikes the legendary-piece shrine
sites, and still sees grass gaps. Vegetation improved, but no biome passed.
Get these visuals good before resuming the broader gameplay goal.

## Repository and preservation

- Workspace: `C:/Projects/Tetherbound`.
- Integration branch: `codex/resume-four-biome-0909`.
- HEAD when this exit was started: `e67390f3ff9835518ad1a969f764c533704c5ed1`.
- Fetched main: `671e1b8bc5f52eeec527fa69e997faf226df9a4b`.
- The shared checkout includes older held experiments as well as current work.
  The owner's latest request authorizes consolidation; it does not retroactively
  turn failed experiments into accepted art. Keep that distinction in reports.
- Original stopped-session preservation: `.artifacts/session-wrapup-20260909/files/`.
  Earlier mixed scratch commit: `df7259359b4c299b9848ff7a24e6cffe23737040`.
- New exit snapshot: `.artifacts/exit-handoff-20260909/` (binary working-tree
  patch, untracked-file copies, status and file hashes). Raw captures stay local.
- Hundreds of `.import` line-ending changes and generated `.uid` files coexist
  with actual changes. Classify them; do not mistake their counts for work done.
- The root `manifest.json` is a stray Water diagnostic, not project source.
  The phone attachment is also evidence, not a game asset.

## Concrete checkpoints already committed

| Commit | What it actually establishes |
|---|---|
| `d268e23c3` | Teleport buttons include biome names; focused test passed 6 tests / 981 assertions. Local at handoff start. |
| `0cf8d8855` | Stormwood GrassField integration, clustered green understory, official scatter bake, split-tree candidate and evidence. Ground cover rendered at Rodline Post and Lantern Hollow. Tree fixture passed 1 test / 127 assertions. No finale or art acceptance. |
| `1e8c223e1` | First Water vegetation layer and first production evidence. Reedhaven has vegetation; Veilfall visibly fails. |
| `f6c7874e2` | Real Stormheart approach probe and exact alpha/road/teleport overlap evidence. Three retained frames still obstructed; no tree silhouette pass. |
| `e67390f3f` | Latest owner palette rejection, buried-house and shrine feedback recorded. |

## Creature lane — held candidate, not a fix claim

Current owned changes: `scripts/combat/combat_manager.gd`, `data/config/combat.json`,
`tests/smoke_combat_camera.gd`, `data/creatures/four_biome_colourways.json`, and five
derived vivid PNGs under `assets/creatures/tetherbound/{riptusk,mirejaw,cragclaw,
sirenseal,mangrove_monitor}/models/`.

The old camera size term compared each creature with its own species baseline,
so an ordinary huge creature received no size allowance. The candidate uses the
larger live height/footprint span of both fighters, while preserving the existing
4m extra-distance cap and tight-room ceiling. This does not prove that the
largest fighters fit or that combat is now playable.

The five palette candidates preserve the installed source's anatomical colour
blocks, cap excessive saturation, and use bounded face masks instead of globally
darkening every speckle. These are deterministic derived outputs from the existing
repaint pipeline. Original input images were not repainted. The owner-rejected
pink spider is **Voltarach alpha**, whose active alpha texture/material must be
corrected separately; a vivid-only change will not fix it.

First camera run:
`.artifacts/creature-face-native-0909/run-20260909T235131683Z/combat-camera/`.
23:51:36–23:53:05 UTC, 89.14s. Near frame 8.42m, far frame 10m, base 6m;
capped-separation checks passed. **Failure: second production encounter would
not start.** No native script errors were logged. Launcher exit code was null;
console explicitly prints FAIL and the smoke calls `quit(1)`. Preserve this first
result. The wrapper omitted immediate process-handle retention despite earlier
guidance. The later face render was not reached by this wrapper.

All five candidate PNGs were confirmed **unimported** at freeze: their source
MD5s differ from the existing imported-cache receipts. No new face capture ran.
Before claiming any new face render, perform a guarded import and verify current
source MD5 plus actual loaded texture readback. The prepared ignored
`capture_only.ps1` has a known receipt-path bug: replace `.s3tc.ctex` with `.md5`,
not only the final extension. Runtime `load()` can use stale imported textures. The isolated
`tools/capture_creature_presentation.gd` stage can inspect faces, but its green
ground plane is not production-biome evidence. Follow it with an actual Water
capture. Root made no camera-test diagnostic edits after this first failure;
the missing next evidence is the second-entry arbiter winner, candidate distance,
party HP/state and physical clearance, not an unchanged retry.

## Stormwood lane

Evidence report:
`ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-FOREST-AND-STORMHEART-0909.md`.
The companion `-BAKE-FILES.txt` lists all 122 bake outputs.

The first tree capture failed on `_bark_quad` Array typing and empty mesh errors;
it is preserved. The corrected ground-cover capture completed 2/2 frames with
no script/engine errors. Lower inner bark radius is 46m through playable floors,
outside the 44m annuli; taper begins above 185m. That fixture is geometry evidence,
not ordinary ascent or a good-looking tree.

Finale evidence:
`shots/catalogue/stormwood/stormheart-context-first-0909/`.
The canonical frame and ordinary 12.146m backstep still show a huge magenta/cyan
spider dominating the view. The alpha, route waypoint and teleport destination
all occupied XZ `(-310,5050)`. This is a real authored overlap.

New unvalidated production candidate moves only `glass_field_alpha` XZ to
`(-250,5080)` in `data/config/stormwood_encounters.json`. Offline clearance:
67.08m from the canonical point, 31.95m from the road, 15.29m from baked solid
edges. Actual imported mesh/animation/wander envelope, terrain support and slope
still need the new `tests/test_stormwood_glass_field_approach.gd` run.
`tools/_capture_stormwood_stormheart_lateral.gd` is a prepared supplemental probe.

The ugly gray Lantern Hollow cluster is the legendary-piece shrine, not arena
decks. `stormwood_ending.gd` mounts it at `(-450,3960)`, also the catalogue/potion
coordinate, so the canonical trainer stands on its central pedestal. New
`scripts/world/stormwood_heart_shrine.gd`, its ending hook and
`tests/test_stormwood_heart_shrine.gd` were being prepared when the owner stopped
implementation. Treat them as unparsed/unrendered until the landing checks say
otherwise. Preserve functional relic state, prompts and collisions.

## Water lane

Committed first-capture report:
`ralph/reports/FOUR-BIOME-BUILD/WATER-VEGETATION-FIRST-CAPTURE.md`.
Raw run: `.artifacts/water-vegetation-candidate-0909/run-20260909T233259230Z/`.
Exactly two production frames passed capture mechanics. Runtime had 10,437
instances, Reedhaven 1,273, **Veilfall only seven shrubs**. Reedhaven's foreground
remains sparse/mottled. Veilfall's bare walls and crowding visibly fail.

Subsequent files are source-only at freeze:
`scripts/world/water_vegetation.gd`, `scripts/world/water_veilfall.gd`, new
`scripts/world/water_veilfall_exterior.gd`, `data/config/water_veilfall.json`,
`data/config/water_encounters.json`, `scripts/combat/water_encounter_director.gd`.

- Cache prepared meshes per model across local visibility cells instead of
  duplicating every mesh/material for 1,343 cells.
- Six configured faceted geological formations with matching trimesh collisions
  and 170 authored plants on supported caps. This replaces the failed attempt
  to populate very steep radial terrain through random sampling alone.
- Four near-gate two-creature sites moved to supported-habitat candidates about
  92–99m from the gate; explicit member anchors are 10m apart. The director
  grounds each member around its own anchor and applies initial/rest heading.
  Ordinary notice-turn still operates. Counts, sizes and rewards are unchanged.

Only JSON parsing and diff checks passed for these later changes. Required next
checks: Godot parsing, outward geometry and six physical cap ray hits, 170 plants,
unobstructed route/entry, all eight creature support/home positions, and production
Veilfall approach capture. No new waterfall material tuning was done.

## Buried houses and support work

Root traced `scripts/world/village.gd::_place`: default seating deliberately takes
the **lowest** of footprint centre/corners, then subtracts 0.05m. On a slope this
buries the uphill wall/door. Stormwood heightfield has no settlement pads. Merely
switching to highest would create floating downhill walls and raised doorways.
Investigate actual house threshold/floor heights and provide physically supported
level approaches. **No house, shared village or terrain-pad change was made.**

Loading remains open: realm overlay appears only after synchronous sync/autosave;
title startup uses a status label and does not use that root-owned overlay.
Overlay presence in a smoke is not proof the player saw it before blocking work.
Saddle remains open: its recipe exists, gated by tournament `recipe_saddle`, with
Rootstone/Ironwood costs. The cause of the owner's missing availability is not
established. Do not remove intended progression gates on speculation.

## Other preserved obligations — do not let these displace visuals

- PR114: https://github.com/MJohnsonWellabe/Tetherbound/pull/114, draft diagnostics
  on head `638718b58eddcbc2c6f526b7b04cab750a0d730d`. CI `34415815087` failed first
  attempt: multiplayer movement peer1 moved 0.86m instead of at least 2m after
  300 forward-input frames. Host moved 14.61m, replication agreed. No cause or
  retry-to-green claim. All 29 job records/26 raw logs retained in
  `.artifacts/pr114-638718b58-ci/`. Export skipped. Preserve this if superseded.
- Main `671e1b8bc` CI `34412789099` completed success; final export log downloaded.
  Previous detailed code-job audit and release verification are in existing
  reports. The final export addition still needs the final audit write-up.
- Original dc83 shared-fight failure remains unresolved. Added host receipts are
  diagnostics, not proof of a friendly-fire fix.
- Fresh route replay is paused. Last 566.782s fresh run earned five creatures and
  materials, then failed the exterior fence-return approach. `be5deaaf2` fixes
  the helper with 12/98 test evidence but lacks physical return validation.
  Detached proof checkout: `C:/Projects/Tetherbound-opening-prefix-d3cdb57`.
- Older held texture/mipmap/character/Torrentoad experiments remain documented;
  do not relabel them accepted merely because the owner asked for consolidation.

## Runtime and next operator

Use one native Godot world/import/render lease at a time. Godot:
`C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`.
Checks/tests 120s, captures/bakes 180s, monitor 90% system commit / 400 processes,
and clean only owned descendants. Cache `$process.Handle` immediately after
`Start-Process`, then `WaitForExit`/`Refresh`, or Windows can report null exit.
Never silently turn first failed evidence into a pass or rerun unchanged inputs.

No new native work should start during exit snapshot. All three agents confirmed
their files frozen and no active Godot processes. The creature wrapper's handle
retention was corrected after the first failure, but that correction is untested.
Stormwood's own frozen tail is `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-HANDOFF-0909.md`.
Fresh blind visual judge creation hit the thread limit in this session; no author
self-accepted art. A new operator should use fresh independent judges against
the supplied references once substantive production frames exist.

## Landing receipt

Exit written and committed first in `cb7d052bf`. All agents frozen; exit snapshot
contains 216 files / 20,265,496 bytes and a binary diff. Initial final census zero.

Pre-landing validation, 2026-09-10 UTC, under
`.artifacts/exit-handoff-20260909/`:

- `import-first` failed despite engine exit0: five extracted images contained
  JPEG bytes under PNG names. Corrected the existing extractor to encode genuine
  PNGs; verified mode, dimensions and decoded pixel SHA unchanged for all five.
  `import-corrected` exited0 with no errors. These are pipeline corrections,
  not another art revision. First failure and original files remain preserved.
- `focused-first`: 10 tests / 1,166 assertions / zero failures. Includes actual
  Stormwood alpha clearance, shrine state/collision and tree/bake/teleport checks.
- `water-focused-first`: two failures, both preserved. Host simulation shell
  lacked the intentionally absent scenic vegetation renderer; skip decorative
  groves on those shells while retaining physical crags. Optional heading was
  written as NaN into every ordinary spawn plan, breaking deterministic equality;
  now omit the field unless explicitly supplied and finite.
  `water-focused-options-corrected`: 13 tests / 2,218 assertions / zero failures.
- No new face/biome visual acceptance is established by these checks. The earlier
  camera second-entry failure remains recorded and unresolved.

Consolidation PR: https://github.com/MJohnsonWellabe/Tetherbound/pull/115.
First shipping head `99ae647917f8e7c1b6c7391ee085566052c61e59`, tree
`d4a10d4c53ab85a4559dc4db8875e0b76e0eebcf`. First CI run `34419951264`
failed three unit checks; raw logs remain in `.artifacts/pr115-99ae64791-ci/`.

- The badge hierarchy test read accessory slot zero, now the Warden's staff.
  Select the actual badge/rim by identity and retain the strict size hierarchy.
- The dielectric-body test included deliberately metallic staff fittings.
  Restrict that invariant to body surfaces; existing badge-metal checks remain.
- The four Veilfall pair relocations broke the unchanged ROAD visibility bar:
  17 failing samples, longest empty run 90 m. Withdraw those four placement
  changes to the main catalogue, retaining their candidate in commit `2a9e86dfe`
  and the exit snapshot. **Gate crowding remains unresolved.** Do not reuse the
  candidate's empty-gate screenshots as evidence for the resulting shipping tree.
  Per-member grounding/optional heading support remains available in production.

Corrected local checks: `badge-identity-corrected` passed 50 tests / 1,433
assertions; `ci-unit-corrections` passed 19 tests / 2,496 assertions. Both exited
zero, no engine/script errors, final Godot census zero. This is a correction of
identified first-run failures, not an unchanged retry-to-green.

`consolidation-art-first` passed the real art smoke in 57 seconds, exit zero,
no engine errors. `consolidation-playground-first` completed the world/gameplay
smoke in 54 seconds, engine exit zero, but its strict wrapper flagged one known
`ERROR: Parameter "material" is null.` from the established alpha-material debt.
It is not an error-free pass; no new distinct runtime error was observed and no
unchanged retry was performed. Both owned process trees finished, census zero.

The pre-correction `water-production-first` render exited zero with four frames
and no errors. Reedhaven and Veilfall were inspected; vegetation exists but the
owner's visual bar remains unmet. Veilfall recorded 177 plants (170 authored),
six physical crags; those counts do not prove traversability or visual quality.

Resulting main SHA remains pending. Verify the corrected shipping CI and actual
merge ancestry; do not claim the consolidation has landed from a push alone.

### First CI completion and Stormwood consolidation hold

Run `34419951264` completed failed at 00:27:08 UTC (29 jobs, 26 raw logs,
three intentionally skipped jobs). In addition to the three unit failures,
five first-invocation multiplayer smokes timed out during Stormwood transitions:
`stormwood_hosted_trainers`, `stormwood_livewire`, `stormwood_realms`,
`stormwood_finalized_death`, and `water_return` entering Stormwood. Other
executed jobs passed; no smoke was rerun to hide a failure. Raw error comparison
against main `671e1b8bc` found existing null-material/shutdown-resource categories
with count variation, no new script-error category. Failed peer artifacts from
shard 6 are retained under `.artifacts/pr115-99ae64791-ci/net6/`.

Two local repair hypotheses failed the same hosted-trainer transition:
`stormwood-population-corrected` (population time slicing; exit 2, 115 seconds)
and `stormwood-spatial-corrected` (also spatially indexed spawn clearance;
exit 2, 106 seconds). Both preserved their first logs and cleaned owned peers.
Neither establishes the cause or a fix. The unsuccessful patch is retained at
`.artifacts/exit-handoff-20260909/unsuccessful-transition-fixes.patch`; those
speculative production/test changes were removed from the shipping tree.

Changed strategy for handoff: restore main's Stormwood scatter generator,
vegetation configuration and matching baked regions, holding the denser forest
candidate at `0cf8d8855`. The grass-field binding, tree/shrine work and alpha
clearance change remain included. This withdraws density work rather than
pretending the multiplayer regression is fixed by a green local unit test.
`consolidation-restored-density` passes 63 tests / 1,790 assertions, engine exit
zero, no errors, census zero. Full shipping validation remains required.

`stormwood-density-rollback` then passed the actual two-peer hosted-trainer
smoke on its first invocation after that rollback: 00:34:32–00:36:38 UTC,
exit zero, no coordinator errors, owned process census zero. Client entered
Stormwood, actual strikes completed both trainer rounds, shared rewards/flags
and final world hash agreed. This supports withdrawing the denser scatter for
consolidation; it does not accept the remaining art or prove all other net paths.
