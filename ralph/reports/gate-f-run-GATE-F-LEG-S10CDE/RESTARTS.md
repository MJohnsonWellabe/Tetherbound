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
