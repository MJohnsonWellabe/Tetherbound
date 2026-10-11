# EV-HOME-KEY findings (F44#1 evidence lane)

Host: cloud container, Godot 4.7-stable headless, smoke `tests/smoke_f20_ending.gd`.
Times are US Central (CT).

## 1. Home Key refusal: readiness judged one frame early (fixed, 547c3170)

`GameState._await_realm_scene_ready` judged its 120 s wall deadline on the first
frame after Meadows' long synchronous build call. `playground_world.gd` reports
`shell_build_complete()` only after its deliberate one-physics-tick/one-frame
player hold, i.e. one wait iteration later. When build start plus that frame
crossed 120 s, the crossing rolled back to Stormwood, freed the finished
playground (`playground_world.gd:904` null `get_tree()`), and the Home Key
refused "The destination could not load."

| Run | Extra delay in build frame | Longest frame | Readiness-wait elapsed | Outcome |
|---|---|---|---|---|
| clean, before fix | 0 | 63.3 s | under 120 s | arrives |
| simulated slow, before fix | +45 s | 97.7 s | 112.0 s waiting, 113.0 s ready | arrives |
| simulated slow, before fix | +55 s | 112.7 s | 126.5 s → timed out | exact coordinator failure |
| simulated slow, after fix | +55 s | 114.5 s | ready in grace frames | arrives |

Fix: after the deadline, keep polling `REALM_READY_DEADLINE_GRACE_FRAMES = 4`
ordinary frames. The 120 s deadline is unchanged; a stuck build still times out.
Unit: `test_realm_entry_readiness.gd` 8/8.

## 2. Finding (not fixed, out of scope): Meadows builds in one 63 s call with no yield

In each run, entering Meadows by Home Key from Stormwood produced one frame of
63.3 s (clean run), with about 14 s of sliced build before it. The log
lines inside that frame show vegetation boot about 10.3 s
(`harvest_points[56283 nodes]` 7.1 s), scatter bake read/reorder about 6.7 s,
grass field, water, stronghold and the drained meadow, all without yielding a frame.
Even if real hardware is several times faster, a synchronous build this size
freezes the game where players can see it (behind the loading overlay, which
cannot animate during the call). The readiness deadline cannot interrupt it,
so a slow host's crossing time is dominated by this single frame.
