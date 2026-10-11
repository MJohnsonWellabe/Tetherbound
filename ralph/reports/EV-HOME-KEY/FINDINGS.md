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

## 3. Endgame rematch walk: 110 min stall was a fenced-in straight line (fixed in the proof helpers)

Per-second navigator heartbeat (diagnostic only, not committed): frame cost flat
0.8–1.0 s per process frame (~8 physics frames/s) and ~184.7k nodes for the whole
run, before and after the rematch setup, so it is not a performance collapse. The
nearest Meadows endgame leader is `south_bridge_grunt` at (14, 1314), 1,269 m from
the bounty board. The straight walk pinned the capsule in a 6×4 m pocket
(x 79–86, z 47–51) against the village boundary fence; the confined watchdog
fired but could not escape, and the 82,491-frame budget is about 2.9 h here.
The disclosed post-finale fixture also lacked `road_gate_open`, so the TrailGate
at (13.8, 22.4) was locked. Fix: walk the authored lawn → main street → Lower
Meadows trail (26 headings, same budget and watchdog) and set `road_gate_open` in
the fixture. Result: the capsule reached (15.4, −2.9, 1315.1) and ordinary input
activated the rematch, about 63 min of walking at this host speed (11:49 AM CT run end).

## 4. Open: combat admission refuses the south_bridge_grunt rematch fight

At the grunt, `combat_manager.gd:904 begin` refused: AllyCreature seat at
(18.08, −2.81, 1314.36), rendered radius 5.41 m, clearance 0.6,
`clear_seat_search_exhausted` after 395 attempts. The director reports
trainer_active=true with fighting=false and no enemy, so F44#1 fails
"endgame leader tier L58 (enemy L-1)". This may be related to batch #677's
fight-placement changes (for example 6ddb3724, which added clearance to the shared orbit
containment bound). Not bisected.
