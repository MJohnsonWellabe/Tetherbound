# LIFE lane — VP9 first slice

Branch `claude/vp-life`, tip commit at time of writing: see `git log -1` on this branch.

## The problem this pass answers

Every blind judge so far in the visual-parity program said the same thing about the Meadows:
"no creature appears in any frame" of a creature-bonding game. The gameplay wild population
existed (`ralph/reports/ENCOUNTER_DESIGN_2026-08-30.md`'s system, 261 clusters/881 individuals),
but the visible population at the evidence stands the program judges by did not agree with it.
This lane's job was to close that gap in the real game, not in screenshots.

## What changed

### Placement (round 1)

- `data/config/spawn_tables.json`: `roll_new_worlds` flipped `false` -> `true` per owner directive
  D-0830-1 — a new game now rolls its own wild population instead of always reproducing the
  authored seed-0 world. `TB_WORLD_SEED` still overrides per-process.
- `data/config/bands/band4_upper_meadows_ironwood/spawns.json`: new order-4076 cluster (3
  Burrowback, `meadows_rock` table, `rocky_shoulder` habitat) 32m southwest of `ridge_patrol_camp`
  — the one evidence stand of the five named in the brief with no wild cluster in the 25-40m band.
  The other four (village edge, mill pond, band1 open meadow, relay camp) already had a qualifying
  cluster within range; verified by direct distance computation against every band's `spawns.json`,
  not assumed.

### Capture tooling

- New `tools/_capture_life.gd`, modelled on `tools/_capture_locations.gd`'s boot/pin/freeze/
  raycast-reseat pattern: photographs the five evidence stands (day, plus night for the three
  the brief names — village edge, mill pond, relay camp) and a starter-beside-trainer frame.
  `--only=stands|starter` re-renders one half without repaying the ~4 minute world boot.

### Round 2 (program coordinator verdict on round 1: "placement landed, evidence did not show it")

- All five stands' capture eyes moved from round 1's 25-40m (a PLACEMENT distance — how far the
  wild cluster sits from the named stand in the world, an instruction this pass's config changes
  satisfy) to 8-15m (a CAMERA distance — how far the capture eye stands from the cluster, which
  round 1 conflated with the placement number). `SETTLE_FRAMES` 40->70, `ARRIVE_FRAMES` 18->30, so
  a cluster is fully streamed and settled at the new close range before the shutter.
- `02-mill-pond-banks`: eye moved onto the bank (round 1 stood in the water looking at the mill,
  no creature in frame).
- `03-band1-open-meadow`: eye moved off whatever it was clipped inside (round 1 rendered solid
  green — the near clip plane inside a mesh).
- `06-starter-beside-trainer`: moved off Grandpa's yard (three re-renders fighting the house's own
  roof/wall colliders — `_capture_locations.gd`'s own header names this exact trap) onto the open
  Practice Meadow, reframed three-quarter from behind-and-to-the-side.

### Round 2 addendum (code-blind judge: creatures in frame read as low-contrast blobs)

- `data/creatures/species.json`: `paddlenewt` and `burrowback` had no `field_emission` set at all
  (unlike bramblebun/terrapup/mudsnout, already tuned 2026-09-01 for the same grass-blending
  complaint). Both set to `field_emission: 0.9` — bramblebun's own conservative, no-glow value,
  taken as an UNMEASURED placeholder (no time in this round's budget to run
  `tools/_probe_grass_separation.gd`'s sweep, and that tool measures against a grass reference, not
  water or rock). Flagged `TUNABLE` and due a real sweep in both entries' own comments.
  **File-path note**: the addendum named "the `creatures` block of `data/config/art.json`" for
  this edit. That file has no creatures block — it holds NPC materials, sky, sun, environment,
  times. The real lever is `species.<name>.placeholder.field_emission` in
  `data/creatures/species.json`, where bramblebun/terrapup/mudsnout are already tuned this exact
  way. Edited there instead of leaving the addendum's instruction as a no-op.
- `04-relay-camp`'s eye/look shifted 8m east, toward the open trail side round 1's own frame
  showed, rather than re-tuning bramblebun's shared `field_emission` (already owner-set for grass
  separation everywhere else the species spawns; pushing it further to fight one stand's tree
  shadow risked the "glow" the addendum explicitly said not to cross, and risked visibly changing
  every other bramblebun frame in the program).

## Frames

`ralph/reports/visual-parity/LIFE/round1/` — first pass, 9 frames + contact sheet
(`_sheet.png`) + 5 combat frames (`combat/`, `tools/survey_combat.gd`, its own contact sheet).

`ralph/reports/visual-parity/LIFE/round2/` — corrected framing + field_emission fixes, 9 frames +
contact sheet (`_sheet.png`):

| frame | creatures registered within 60m | note |
|---|---|---|
| `01-village-edge-day/-night` | 3 | bramblebun cluster, legible but small in frame |
| `02-mill-pond-banks-day/-night` | 6 | on the bank now; paddlenewt reads as a bright cyan shape at the shoreline, more legible than round 1's dark smudge but still not a clean silhouette |
| `03-band1-open-meadow-day` | 3 | fixed from solid-green camera-in-geometry; open field frame, creature legibility marginal at this distance |
| `04-relay-camp-day/-night` | 12 | two clearly legible bramblebun on open lit grass — the addendum's own repositioning fix, confirmed in-frame |
| `05-ridge-camp-day` | 4 | three clearly legible burrowback, silhouette now reads distinctly from the actual dark rock beside them — the field_emission fix, confirmed in-frame |
| `06-starter-beside-trainer-day` | n/a | trainer clearly in frame with the ridge/hill landmark behind; the terrapup itself did NOT read as visible in this render despite the log confirming `spawn_wild` succeeded 2.2m away — **unresolved, see below** |

## Unresolved defects

- **`06-starter-beside-trainer`**: the terrapup does not read as visible in the round-2 frame even
  though the tool's own log confirms it spawned 2.2m from the player and the camera stands
  off-axis at both of them. Three prior geometry attempts in round 1 (further along the house's
  outward axis -> landed on the roof collider; side+away offset -> the creature's own back filled
  the frame with no trainer visible; a larger away offset -> walked into another building's wall)
  were abandoned for the open-field reframe in round 2, which fixed the trainer-visibility half but
  not the creature-visibility half. Next step: verify the creature is actually being drawn (a
  `_creatures_near()`-style check at the shot itself, not just at `spawn_wild` time) before
  reasoning about camera geometry further — it is possible the settle window still isn't enough
  for a freshly spawned creature's idle pose to resolve, or that `wander_radius: 0.0` combined with
  a very short spawn-to-shutter window is leaving it mid-spawn-fade.
- **`02-mill-pond-banks` and `03-band1-open-meadow`**: creature legibility improved but is not yet
  as strong as `04-relay-camp`/`05-ridge-camp`. Paddlenewt's `field_emission: 0.9` is unmeasured
  against a water background specifically; band1-open-meadow's pipwing cluster was not touched by
  the addendum and may need its own pass.
- Every `field_emission` value this pass added is a first-guess placeholder, not a
  `tools/_probe_grass_separation.gd`-measured value. Real settling needs that sweep run against
  each new background (water for paddlenewt, ridge rock/grass for burrowback) the way
  bramblebun/terrapup/mudsnout were each measured on 2026-09-01.

## Tests

Named in the LIFE brief, run against the branch tip after all config changes:

| test | result |
|---|---|
| `tests/run_tests.gd -- --only=test_spawn_tables.gd` | **PASS** — 27 tests, 7711 assertions, 0 failed |
| `tests/smoke_wild_streaming.gd` | **PASS** — "wild streaming: OK — distant clusters sleep, near ones tick, engaged/fainting/respawning are never touched, and a round trip changes nothing about a creature's identity." |
| `tests/smoke_catching.gd` | **PASS** — "catching: OK — a throw can be aimed, missed, and landed." |
| `tests/smoke_night_ecology.gd` | **PASS** — "night ecology smoke test passed" (12/12 night bodies hidden by day, present at night) |
| `tests/smoke_aggression.gd` | **PASS** — "aggression: OK — the dangerous one initiates, the peaceful one never does." |
| `tests/smoke_traversal.gd` | **FAIL, pre-existing** — "crossed the South Bridge without the key (6348.4m past the gap) — the gate can be walked around." Unrelated to this pass (wildlife spawns, `roll_new_worlds`, `field_emission`): the program's own `VISUAL_PARITY_PROGRESS.md` already records this exact failure from the PLACES lane as pre-existing on `main`/the program branch. Re-confirmed on this branch's tip both before and after this pass's changes. |

All four tests re-run after the round-2 merge from `claude/coordination-subagents-3fhz1x` and after
the `field_emission` edits, on the merged tip, not just before the merge.

## Environment / scatter bake

Cold-cache Godot 4.7-stable install + double import per `docs/VISUAL_PARITY_LANES.md`'s recipe.
Boot log confirmed a fresh bake before round 1 (`[vegetation] boot phases placements=4004`, low
thousands of ms — no re-bake needed). After merging the program branch for round 2, re-baked with
`scripts/world/bake_playground_scatter.gd` (825,587 placements, 412s) and re-imported before
capturing, since the merge brought in vegetation/village changes from the WORLD/PLACES lanes.

## Playability guards

`smoke_traversal.gd`: one pre-existing failure, see Tests above — not a wild-cluster or path
collision. `smoke_wild_streaming.gd`, `smoke_aggression.gd`: both pass, confirming no new cluster
(including this pass's own order-4076 burrowback) sits on a path, spawn pad, gate, or camp bed in a
way either test would catch.

## Recommended next step

1. Diagnose why `06-starter-beside-trainer`'s terrapup isn't visible in the actual frame despite a
   confirmed successful spawn — likely a settle-timing or draw-order issue specific to a creature
   spawned seconds before the shutter, worth a small standalone repro rather than more camera-angle
   guessing.
2. Run `tools/_probe_grass_separation.gd`'s sweep for paddlenewt (against a water-colour reference
   box, not the tool's default grass box) and burrowback (against both grass and rock references)
   to replace this pass's unmeasured 0.9 placeholders with real numbers.
3. `03-band1-open-meadow` and `02-mill-pond-banks` would benefit from a second contrast/positioning
   pass once 1-2 are further along, using the same before/after discipline this round used for
   relay-camp and ridge-camp.
