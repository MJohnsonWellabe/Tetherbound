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
