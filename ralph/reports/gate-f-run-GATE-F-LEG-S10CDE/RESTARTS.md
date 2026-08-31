# Restarts

## S10c, restart 1

- **Old SHA:** 453107fb (main) + this lane's uncommitted GAME-F4 fix, pre-world_perimeter fix.
- **New SHA:** same branch, + world_perimeter.gd local-recovery fix.
- **Reason:** S10c's first attempt (S10c-superseded-1/) was manually interrupted after its
  first `move_to` (S10c-91, approach drain -> (-8,7100)) burned its entire 31500-frame
  budget stuck at (13.47,-0.08,7416.99) and the second `move_to` (S10c-93, -> Old Mill
  Crossing) was repeating the same freeze. Diagnosed via three new probe scripts
  (`tools/_probe_s10c_stall.gd`, `_probe_s10c_stall_collision.gd`,
  `_probe_s10c_stall_repro.gd`): the terrain and collision at that exact position are
  clean (player lands and stands there stably, y matches the analytic heightfield within
  0.01m) -- the freeze is `world_perimeter.gd`'s "fell below the world" kill-volume
  false-triggering on a player who is legitimately standing on solid ground (a residual
  case of the "platform velocity inheritance" glitch `player_controller.gd::
  _clamp_runaway_velocity`'s own header already documents as a known, admittedly
  unresolved risk), which then reset the player to the WORLD SPAWN -- 7km from both the
  walk's start and its target -- so `move_to` spent its entire budget trying to walk back
  and never got anywhere near (-8,7100) or Old Mill Crossing. Fixed in `world_perimeter.gd`:
  the kill volume now recovers to the player's last verified on-ground position instead of
  unconditionally resetting to spawn, so a recurrence of the underlying glitch (still not
  root-caused) costs a few centimetres instead of the whole segment's budget.

## S10c, restart 2 (and S10d, restart 1)

- **Reason:** S10c's second attempt (S10c-superseded-2/) completed but never
  escaped `sigil_gate_gorge_west_wing` (see S10c-superseded-2/FINDING.md for
  the full diagnosis) -- both its own move_to legs failed, stopping at the
  same position. S10d chained from that broken exit save and inherited the
  same pin for its own entire budget (S10d-superseded-1/), never moving at
  all. Root cause fixed for real this time: `sigil_gate_gorge_west`/`_east`
  and their `_west_wing`/`_east_wing` siblings (terrain_playground.json) are
  11m-deep, ~72-degree carved trenches that were never wired to
  severed_spokes.gd's own carve-failsafe rescue (the mechanism south_bridge/
  storm_road/river_gorge already use for the identical hazard shape) --
  confirmed nothing else in the codebase ever called `_add_carve_failsafe`
  for these four crossings. Fixed in `road_gate.gd` (new opt-in
  `gorge_carve_ids`) + `playground_world.gd::_build_sigil_gate` (wires all
  four carves) + `terrain_playground.json` (the `"failsafe": true` flag
  `_add_carve_failsafe` itself gates on). Verified with
  `tools/_probe_gorge_failsafe.gd`: a player dropped at the exact historical
  pin point is rescued to the Sigil Gate's own position within 30 frames,
  down from burning an entire move_to budget (tens of thousands of frames).
  Re-running S10c fresh from the same S10b-exit seed, then S10d from its
  real exit.

## S10e, restart 1

- **Reason:** S10e's first attempt (S10e-superseded-1/) completed (32
  pass/3 fail) but never closed the chapter -- `meadows_acknowledged` was
  not set. The single-leg `move_to` at S10e-99 (straight to the village
  centre, `(10,-10)`) does not cross the village fence anywhere near its
  one gate (`playground_world.gd::GATE_AT`, `(27.5,-16.0)`), so
  `stick_navigator.gd` (a local wall-follower, not a pathfinder)
  oscillated against the fence for its whole 60750-frame budget, stopping
  28.4 m short. The Grandpa leg (S10e-103) then also fell 6.5 m short,
  starting from much further away than intended with too little budget
  (3000 frames) -- steadily closing the gap, not stuck.
- **Fix:** `tools/gate_f/segments/S10e.json`: split S10e-99 into a new
  S10e-98g (walk to the gate first) + the original S10e-99 (gate to
  village centre); doubled S10e-103's budget (3000 -> 6000). Re-running
  S10e fresh from the same S10d-exit seed.

## S10e, restart 2

- **Reason:** S10e's second attempt (S10e-superseded-2/) still had 5
  fails, `meadows_acknowledged` still not set. The restart-1 budget split
  was wrong -- S10e-98g (South Bridge to the gate, ~1300 m, the bulk of
  the original leg's distance) and S10e-99 (gate to village centre, ~20 m)
  both got 15000 frames each, when the original undivided leg had 60750
  for the whole distance. S10e-98g fell 173.3 m short, so S10e-99 started
  far away again and repeated the same fence-oscillation shape. The
  Grandpa leg was also still 5.9 m short at the doubled 6000-frame budget,
  still steadily closing the gap.
- **Fix:** S10e-98g budget 15000 -> 54000 (matching its own much longer
  real distance), S10e-99 kept at a smaller 10000, S10e-103 doubled again
  to 12000. Re-running S10e fresh from the same S10d-exit seed.

## S10e, restart 3

- **Reason:** S10e's third attempt (S10e-superseded-3/) completed (34
  pass/2 fail) -- all three `move_to` legs finally reached their targets,
  but two real defects remained. FIRST: `meadows_acknowledged` still never
  set, because both interacts (village and Grandpa) were aimed at abstract
  destinations rather than the actual NPCs -- the village-centre arrival
  point was 6.5 m from the nearest villager (Tam), outside
  `npc_body.gd::add_prompt`'s default 3.8 m prompt radius, and Grandpa's
  real standing position (`grandpa_house.gd::marker("grandpa")`,
  `(-24.4,-14.8)`) is 2.68 m from the house-origin point (`(-22,-16)`)
  S10e-103 was aiming at, which is enough slack for a `close_enough: 3.0`
  arrival to land outside his own 3.8 m radius. SECOND: the `distance_above`
  floor on S10e-108 (3000.0 m) was miscalibrated against this leg's real,
  direct geography (South Bridge to the village to Grandpa's is
  ~1.4-1.5 km measured, not the ~3.5 km the step's own comment estimated).
  Neither is a game defect -- see
  `S10e-superseded-3/WHY_SUPERSEDED.md` for the full diagnosis.
- **Fix:** S10e-99 retargeted at Tam's own position `(8,-16)`
  (`close_enough` 5.0 -> 2.5); S10e-103 retargeted at Grandpa's actual
  marker `(-24.4,-14.8)` (`close_enough` 3.0 -> 2.0); S10e-108's distance
  floor lowered 3000.0 -> 1300.0, with the cross-check against S10c/S10d's
  own measured distances recorded inline. Re-running S10e fresh from the
  same S10d-exit seed.
- **Note:** this attempt's raw run artifacts (telemetry/saves/frames) were
  lost to an operator error during the supersede move (see the note at the
  bottom of `S10e-superseded-3/WHY_SUPERSEDED.md`) -- the findings above
  were recorded before the loss and are not in question, but there is no
  raw telemetry left to re-inspect for this specific attempt.

## S10e, restart 4

- **Reason:** S10e's fourth attempt (S10e-superseded-4/) completed (31
  pass/5 fail) and, for the first time, both restart-3 fixes held -- the
  walker reached Tam and Grandpa within their own prompt radii,
  `meadows_acknowledged` was set, and the recalibrated `distance_above:
  1300.0` floor passed at 1470.26 m walked. One new defect, all 5 fails
  the same cause: `S10e-105` ("hear his post-win line out") was still the
  original blind `press interact x14` count, and `grandpa_freed` (3 lines)
  does not close on an exact boundary at 14 presses -- the excess presses
  re-open the same greeting because Grandpa is re-talkable and standing in
  his prompt radius makes the next `interact` a new open, not a no-op.
  His dialogue was still open (`narrative_modal`/`DialoguePanel`) when
  S10e-112 tried to open the pause shell, and every step needing the world
  back after that failed the same way, including the final save (slot 4
  stayed byte-identical to the seed). Not a game defect -- this is exactly
  the CD-3 hazard `advance_dialogue_until_closed` already exists to
  eliminate (see S02-28's own header); `S10e-102`'s identical blind-count
  shape (Tam, 10 presses) happened to land on a closed boundary by luck on
  this same run, not because it was actually safe. Full diagnosis in
  `S10e-superseded-4/WHY_SUPERSEDED.md`.
- **Fix:** replaced both `S10e-102` and `S10e-105`'s blind press-count
  steps with `action: "advance_dialogue_until_closed"`, the predicate-
  driven primitive `S02`/`S02C`/`S03` already use for this exact failure
  mode. Re-running S10e fresh from the same S10d-exit seed.

## S10e, restart 5

- **Reason:** S10e's fifth attempt (S10e-superseded-5/) DERAILED at
  `S10e-105` (19 pass/2 fail/15 skipped). Restart 4's dialogue-advance fix
  held cleanly for Tam -- `S10e-102` opened and closed
  `village_tam_freed` in three ticks, no over/under-press. But `S10e-103`
  (straight `move_to` at Grandpa's real marker, `(-24.4,-14.8)`) failed
  outright this time: "did not reach (-24, -15) in 12000 walking frames;
  stopped 4.8 m short at (-27.0, 1.0, -11.0)" -- a position OUTSIDE the
  house's own footprint on both axes. `stick_navigator.gd` (a local
  wall-follower, not a pathfinder) walked around the OUTSIDE of the house
  toward the target instead of through the doorway on the east wall, and
  stalled at a north-west exterior corner it could not route past. The
  door is confirmed open (`_refresh_door_gate()` holds it for any beat at
  or after `walk_out`); this is the same "aimed at the abstract
  destination instead of the real passage point" shape `S10e-98g`'s own
  header already diagnosed for the village gate, this time against a
  doorway. `S10e-105` then correctly BLOCKERed (no modal was open to
  advance) rather than mis-firing. Full diagnosis in
  `S10e-superseded-5/WHY_SUPERSEDED.md`.
- **Fix:** split `S10e-103` behind a new `S10e-103d` waypoint at
  `grandpa_house.gd::marker("door")` (`(-15.7,-16.0)`), the same shape
  `S10e-98g`/`S10e-99` already use for the village gate. Budgets
  rebalanced 12000 -> 6000/6000 now that each leg covers only its own
  short distance. Re-running S10e fresh from the same S10d-exit seed.
