# E3-RELAY-POPULATION — before/after evidence

Task: `ralph/reports/audit/E-2026-08-31.md` §E3 found the Tether Relay's hero
hardware genuinely strong ("the strongest asset-level work in the whole
survey") but the site had zero legible NPC presence, no worker/tool clutter,
and no scorch/damage decals across all three capture stands
(`tools/_capture_locations.gd --only=06-relay`), so it read as abandoned
architecture rather than an active Team Tether operation.

Root cause, confirmed by re-running the capture tool against `main` before
touching anything: the site already had a captain and an officer
(`data/config/bands/band3_the_river_lock/trainers.json`) and a small prop
cluster (`relay_station`, same file's `props.json`), but every one of them
sits off the `approach`/`standing` cameras' own sightlines — present in the
scene, not legible in the frame. Same "built but not legible" defect class
the audit found at the Hall's own occupation layer.

## What changed (scene-tuning only, no new meshes)

- `scripts/world/village_npcs.gd`: `model_config()` now accepts the same
  `rank` field `trainer_npc.gd` already reads, so a non-combat body can wear
  a Team Tether rank rig/palette/badge instead of a villager `config_key`.
- `data/config/relay_site.json`: two new non-combat `people` entries —
  "Relay Sentry" (gate mouth) and "Relay Watch" (yard workstation) — using
  `rank: grunt`, NOT `trainers.json` (the chapter is already at its 24-trainer
  cap, see band3's own `_comment_river_nest_doss`). Both gated
  `unless_flag: relay_disabled`.
- `data/config/bands/band3_the_river_lock/props.json`: three props added to
  the existing `relay_station` cluster, positioned on the same sightline as
  the new grunts instead of the cluster's original off-axis corner.
- `scripts/world/tether_relay.gd` + `data/config/tether_relay.json`: a small
  procedural scorch/damage-decal builder (`_build_scorch_marks`), same
  no-new-asset technique the site's own `_build_dead_ground` already uses.

## Verification

- `tests/smoke_relay.gd`, `tests/smoke_relay_station.gd`: pass.
- `tests/test_trainers_data.gd` (50 tests incl.
  `test_every_relay_position_sits_inside_the_authored_site`,
  `test_the_captains_defeat_flag_is_the_one_se27_waits_on`): pass.
- `tests/test_band_content.gd`, `tests/test_chapter_content_map.gd` (24-trainer
  cap), `tests/test_dialogue_runner.gd`: pass.
- Frames: `E3-relay-before/` (main @ pre-fix) vs `E3-relay-after/` (this
  branch), both `--only=06-relay` day pass, identical camera stands.
  `06-relay-approach-day.png`: a human silhouette is now clearly visible
  standing in the gate opening from 32m out. `06-relay-standing-day.png`: a
  grunt worker is now visible beside a crate a few metres from the player,
  in addition to the pre-existing (barely visible) captain/officer pair.
  `06-relay-apparatus-day.png` is unchanged by design — it is the hero
  object's own close-up detail shot and was left alone per this task's scope.
- Independent blind visual-judge pass (fresh sub-agent, no context on what
  changed): confirmed `06-relay-standing-day` is now "the strongest frame for
  occupation" with legible NPCs and clutter, while still flagging that raw
  population/clutter density falls short of the Palworld reference bar and
  that the scorch marks are not legible through grass cover in these specific
  stills (real but grass-obscured, same situation the site's own
  `dead_ground` skin is already in — not touched here, since thinning grass
  is a shared, previously-troublesome global system out of this task's scope).

## Known remaining gap (out of this task's scope)

The palette question (teal-only vs. the stronghold's oxblood) and the hero
apparatus/pylon assets themselves were explicitly out of scope and untouched.
Overall population density still falls short of Palworld's bar per the
independent judge; closing that further would mean either more bodies/props
(future scene-tuning) or is bounded by how much a single automated capture
stand can show.
