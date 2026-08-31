# S10c finding: a recurring, unresolved traversal stall

S10c completed (`INVENTORY.json`: `complete: true`, 23 pass / 2 fail / 1
delegated, `S10c-exit.json` written and loadable) but did NOT reach either of
its two `move_to` targets:

- S10c-91 (approach drain -> (-8,7100)): stopped 252.3m short at (-4.0,-5.0,7352.0).
- S10c-93 ((-4,-5,7352) [where 91 left it] -> Old Mill Crossing (-152,4203)):
  stopped 3152.7m short, at the exact same (-4.0,-5.0,7352.0) -- the walk never
  moved from there again.

This is the SAME class of defect fixed earlier in this lane
(`scripts/world/world_perimeter.gd`'s kill-volume false-positive, GAME
session commits `ff9f105a3`/`62cdbc113`), recurring at a new position ~65m
further along the same corridor. `run_segment.sh`'s own captured stderr shows
dozens of repeated `[player] velocity 121 m/s exceeded the 120 m/s ceiling at
-3.7, -5.4, 7352.2; clamped` warnings at this exact spot -- a CONTINUOUS,
frame-after-frame runaway-velocity condition (not a one-time spike), with the
player's actual position never changing (X/Y/Z pinned at -3.7/-5.4/7352.2 the
whole time route.csv was sampled there).

Diagnosed with the same tools as the earlier stall
(`tools/_probe_s10c_stall_collision.gd`, STALL updated to this position):
terrain and collision at this exact point are clean -- nothing within 15m in
any direction at any of the three probe heights. This rules out a static wall
or prop as the cause, the same conclusion the first stall reached.

**Not root-caused within this lane's time budget.** The `world_perimeter.gd`
fix earlier in this lane stops the WORST failure mode of this same underlying
issue (falling through into the kill volume and being reset 7km away); it
does not stop the player from being momentarily PINNED in place by whatever is
imparting this runaway velocity, without ever falling far enough to trigger
the kill volume's rescue. `stick_navigator.gd`'s own stall/detour/backoff
logic does not escape it either (`move_to` burned its full budget both times).

This reads as a broader, still-unresolved defect: something in this
corridor is capable of imparting large, sustained velocity onto a standing/
walking player without a corresponding visible obstacle, more than once
along a single long walk. Recommended follow-up: instrument
`player_controller.gd::_clamp_runaway_velocity` itself to log the player's
`get_last_slide_collision()`/platform information at the moment it fires
(this lane did not have time to add that instrumentation and re-run), which
would identify WHAT is imparting the velocity rather than only where it
happens.

**Consequence for this lane's evidence chain:** `S10c-exit.json` is valid and
loadable (party, flags, day, version all correct) but positions the player at
(-3.7,-5.4,7352.2) rather than at Old Mill Crossing as S10c's own header
intends. S10d's own first `move_to` (toward the Tether Relay) will simply
have further to walk than originally budgeted for; its `budget_frames`
(31500) may not be enough to cover the shortfall on top of its own intended
distance -- worth checking if S10d also fails to reach its own first target.
