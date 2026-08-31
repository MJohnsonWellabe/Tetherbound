# S09 leg — Stronghold approach / Band 5, isolated clean-seed run

**Honesty rule:** this is CONDITIONAL, ISOLATED evidence. The entry is a
hand-authored idealised state, not a real earned `S08-exit`. Everything
below reads "S09, given a clean entry, does X" — not "the chapter does X".

`ralph/GATE-F-FOUNDATION` never appeared during this session (checked
repeatedly via `git fetch origin`); this leg branched from `origin/main`
(`453107fb2`) instead, per the wake's own "do non-boot prep meanwhile"
allowance. No lane branches from a foundation were available to reconcile
against.

## Seed (`tools/_probe_s09_seed.gd` → `saves/S09-seed.json`)

- Party of 5, level 18 (task's own stated assumption: progression.json notes
  the Warden's ace runs level 20 and the main line should arrive "level with
  the boss" around L19-20 by the finale; 18 sits just under that), full HP,
  built from Band 4/5's own wild roster (burrowback, duskhush, trailpup,
  galecrest, mosshell) rather than arbitrary species.
- All three Sigils (`field_sigil`, `ridge_sigil`, `river_sigil`) held.
- Every Band 1-4 completion flag the Sigils imply (captains, the relay
  captain/captive/console, the Mill Crossing, the tournament ladder's early
  beats) — **except** `hall_approach_open`, deliberately left unset so the
  gate-opening test is real.
- Positioned on the Sigil gate's own causeway centreline (63.6, 7392.0), 8m
  south of the leaf, at the true baked ground height (not embedded).

## What was driven, for real (`tools/_probe_s09_drive.gd` → `saves/S09-exit.json`)

All of the following are real, driven play — camera-aimed movement holding
the actual `move_forward` action, real `interact`/`combat_quick`/
`combat_charged` presses, real combat resolution — not scripted outcomes:

1. **The Sigil gate opens cleanly with all three Sigils held.** One
   `interact` press opens it; all three Sigils are consumed; the
   `hall_approach_open` flag (objective 19/24's own completion flag) fires
   on the open itself, not before.
2. **`stronghold_outer_watch` (Watchman Corr)** — challenged and fought to
   a real win (2/2 felled), defeat flag set.
3. **`stronghold_checkpoint` (Warder Ness)** — challenged and fought to a
   real win (3/3 felled), defeat flag set. This fight is where two real
   defects surfaced (below) before it could be won reliably.
4. **The final camp decision, at the waystop.** `data/config/bands/
   band5_stronghold_approach/props.json`'s `the_waystop` cluster already
   has a real, working, pre-authored rest point (`rest_point.gd` +
   `night_rest.gd`) distinct from the buildable camp — "Rest until morning"
   is offered on approach, and one `interact` press advances the day (1→2)
   and returns control. No build menu, no bed-placement sequence needed;
   Prompt 66's "final preparation opportunity" is already real content here,
   not something this leg had to build.
5. **The Hall threshold.** Walked to the `Stronghold` node's own `entrance`
   marker (the merged Meadows Hall's ramp-foot, post `T1-HALL` re-site —
   (8.0, -5.1, 7508.0), not the pre-merge protocol's stale (150,7595)),
   arriving within 6m with a full, rested belt of five.

Wild encounters (band 5's own aggressive galecrest clusters, real
Prompt-66 "stronger believable wild presence") interrupted the route
several times and were fought to real resolution before the walk resumed.

## Real defects found and fixed (not Band 4/Hall internals — shared infra)

### 1. `apply_loaded_player_pose()` never repositioned the CameraRig

`autoload/game_state.gd`. The function moved the Player and updated the
rig's *rotation* but never its `global_position`; `camera_rig.gd`'s own
`_follow()` closes gaps by a per-frame lerp, so a load that moves the
player far from wherever the camera last was leaves the camera (and
anything that streams terrain/collision off camera proximity) stranded
there. Measured directly: after a load moved the player ~7400m, the rig
sat 7408m away; the player fell through unstreamed terrain, took lethal
fall damage, and `player_death.gd` respawned them at the village fallback
home — **draining the whole satchel, Sigils included, into a death satchel
on the way.** Fixed by snapping `rig.global_position` to the player on
load, the same one-time snap `camera_rig.gd::set_target()` already does
for a target it has never followed before — a load is exactly that case
again. This is a real production Save/Load defect, not specific to Band 5;
it reproduces on any load whose saved position is far from wherever the
camera physically was.

### 2. `base_hp`/`base_attack`/`base_defence` were never part of the save format

`scripts/save/save_game.gd`. These are the species-raw stats
`_apply_level_stats()` recomputes `max_hp`/`attack`/`defence` FROM on
every future level-up. They were missing from both `_party_to_array` and
`_array_to_party` entirely, silently defaulting to `creature_instance.gd`'s
bare class default (1.0 each) on load. A loaded creature's *current* stats
were fine — until it next leveled up, at which point `_apply_level_stats()`
recomputed them from the bogus base and collapsed a level-18 creature
(max_hp in the 200s) to max_hp ≈ 1-2. Reproduced for real driving this
leg's own checkpoint fight: winning fights awards real XP, a save/load/
level-up sequence a full playthrough hits constantly, and the first time it
happened here it turned a full-health party member into a one-hit-faint
liability mid-battle and cost the fight (`combat_exited` outcome='lost',
2/3 of the opponent's team already down). Fixed with a new save version
(15→16): the two fields are now written and read like every other creature
stat, and `_migrate_v15` backfills them for existing saves from
`species.json` by `species_id` (falling back to the creature's own current
stat only for a species the catalogue no longer recognises — the same
"nothing to migrate FROM" posture every earlier migration in this file
already takes). `tests/test_save_format.gd` still passes in full (48
tests, 224 assertions, 0 failed) after this change.

Both are real, load-bearing defects in shared save/load infrastructure —
found only because this leg drove S09 through an actual save→load→win→
level-up sequence, exactly what a real playthrough does constantly. They
are very plausibly why prior full Gate F runs' S09 (and other) segments
never made any recorded progress after their own save handoffs.

## Probe-only workarounds (not game defects, disclosed)

- The route to `stronghold_outer_watch` and back through the gate to
  `stronghold_checkpoint` is hand-routed through explicit waypoints near
  the Sigil gate's own causeway, because `sigil_gate_gorge_west/east` plus
  their `_wing` extensions (GATE-D5 REQUEST 2 / OW6A) seal nearly the whole
  band 4/5 boundary at a z that varies with x — the only crossing is the
  ~10m causeway at the gate itself. A straight line between the two
  trainers crosses that sealed band nowhere near the gate's own gap.
- The party is kept topped up during combat (a stand-in for the potions/
  rest a prepared, already-fully-healed player would actually use) rather
  than left to the probe's own crude auto-battler's mercy — this run is
  about whether S09's own systems work, not about grading this probe's
  combat AI.
- The final few metres into the waystop's own clearing are closed by a
  short teleport after a `PhysicsServer3D.body_test_motion` check confirmed
  the real blocker: ordinary `CommonTree_*` scatter collision, not a
  defect — exactly the "Meadows ecology remains present" Prompt 66 asks
  for, just more than this probe's straight-line-plus-one-sidestep walker
  can thread on its own.

## Exit save

`saves/S09-exit.json` — written through the real production `Game.save_game()`
path (Save tab equivalent), at the Hall threshold, day 2, full rested belt
of five, both approach trainers defeated, `hall_approach_open` set.
