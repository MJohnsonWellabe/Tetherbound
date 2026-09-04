# G2C — Gate 2 evidence run CAPTURE lane: frames from the played route (S04 tournament, S05 Lower Meadows -> pond -> detour -> South Bridge)

### preflight — capture available
- display_server: X11, smoke 5346 bytes, self-test shots/_preflight.png

### G2C-01 — declare the lane
- expected: a note event carries the derivation into events.jsonl
- actual: CAPTURE lane derived by tools/gate_f/derive_gate2_route_captures.py from the PLAYED route in run (segments S04,S05). Every stand below is a position, heading and clock hour the logic lane's own 2 Hz trace recorded; nothing here is a posed stand.
- events: t=0.23
- verdict: PASS

### G2C-02 — empty the live save directory
- expected: no stale slot can be loaded by mistake
- actual: wiped 2 files from /root/.local/share/godot/app_userdata/Tetherbound/saves (kept slots [])
- events: t=0.23
- verdict: PASS

### G2C-03 — seed slot 4 from the route's entry save
- expected: the same save the played route started from
- actual: seeded slot 4 from ralph/reports/GATE2-EVIDENCE-0903/run/S04/saves/S04-exit.json (1421694 bytes)
- events: t=0.23
- verdict: PASS

### G2C-04 — boot the real title screen
- expected: the title screen, focused
- actual: booted title in 450 ms (30 settle frames); re-priced at boot:title: 0.0284 s/frame (was 0.0047), 1461 frames left + 0 s boot = 42 s against 14399 s of budget left
- events: t=1.30
- verdict: PASS

### G2C-05 — move focus to Load Game
- expected: focus on Load Game
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=1.45
- verdict: PASS

### G2C-06 — open the slot list
- expected: the slot list
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=1.78
- verdict: PASS

### G2C-07 — load the seeded slot
- expected: the world loads from slot 4
- actual: pressed ui_accept x1 (tap, 1 frames each) on the default device, resolved to JoyBtn:0
- events: t=2.87
- verdict: PASS

### G2C-08 — let the loaded world stand up
- expected: terrain, scatter and the party are standing; priced in frames, not seconds, because every physics frame is a rendered frame here
- actual: waited 240 physics frames
- events: t=6.87
- verdict: PASS

### G2C-09 — the world owns input
- expected: no modal is holding the loaded world
- actual: input_context=world (wanted world)
- events: t=6.87
- verdict: PASS

### G2C-10 — pin the clock to the trace's hour at t=1 s
- expected: the hour and weather the played route had here (0.00 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=6.87
- verdict: FAIL

### G2C-11 — stand where the played route stood at t=1 s (region-change)
- expected: DIAG: the trace's own position (0.0, 0.0) in grandpas_village; the walk that produced it is in S04's route.csv
- actual: DIAG teleport to (0, 0); distance/dead-travel accumulators reset
- events: t=7.20
- verdict: PASS

### G2C-12 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=7.22
- verdict: PASS

### G2C-13 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=7.32
- verdict: PASS

### G2C-14 — capture G2-S04-0000-region-change
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S04-0000-region-change at 1280x720 (mean luma 78.0, spread 39.6, 2.6% dark)
- events: t=7.80
- verdict: PASS

### G2C-15 — pin the clock to the trace's hour at t=206 s
- expected: the hour and weather the played route had here (16.20 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=7.80
- verdict: FAIL

### G2C-16 — stand where the played route stood at t=206 s (dialogue)
- expected: DIAG: the trace's own position (28.0, 8.0) in grandpas_village; the walk that produced it is in S04's route.csv
- actual: DIAG teleport to (28, 8); distance/dead-travel accumulators reset
- events: t=8.13
- verdict: PASS

### G2C-17 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=8.15
- verdict: PASS

### G2C-18 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=8.25
- verdict: PASS

### G2C-19 — capture G2-S04-0206-dialogue
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S04-0206-dialogue at 1280x720 (mean luma 79.3, spread 40.9, 3.8% dark)
- events: t=8.73
- verdict: PASS

### G2C-20 — pin the clock to the trace's hour at t=249 s
- expected: the hour and weather the played route had here (17.93 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=8.73
- verdict: FAIL

### G2C-21 — stand where the played route stood at t=249 s (fight-starts)
- expected: DIAG: the trace's own position (30.0, 6.1) in grandpas_village; the walk that produced it is in S04's route.csv
- actual: DIAG teleport to (30, 6); distance/dead-travel accumulators reset
- events: t=9.07
- verdict: PASS

### G2C-22 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=9.08
- verdict: PASS

### G2C-23 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=9.18
- verdict: PASS

### G2C-24 — capture G2-S04-0249-fight-starts
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S04-0249-fight-starts at 1280x720 (mean luma 71.2, spread 39.9, 7.7% dark)
- events: t=9.67
- verdict: PASS

### G2C-25 — pin the clock to the trace's hour at t=362 s
- expected: the hour and weather the played route had here (22.41 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=9.67
- verdict: FAIL

### G2C-26 — stand where the played route stood at t=362 s (route)
- expected: DIAG: the trace's own position (30.4, 6.2) in grandpas_village; the walk that produced it is in S04's route.csv
- actual: DIAG teleport to (30, 6); distance/dead-travel accumulators reset
- events: t=10.00
- verdict: PASS

### G2C-27 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=10.02
- verdict: PASS

### G2C-28 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=10.12
- verdict: PASS

### G2C-29 — capture G2-S04-0361-route
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S04-0361-route at 1280x720 (mean luma 69.7, spread 39.3, 8.3% dark)
- events: t=10.60
- verdict: PASS

### G2C-30 — pin the clock to the trace's hour at t=400 s
- expected: the hour and weather the played route had here (23.96 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=10.60
- verdict: FAIL

### G2C-31 — stand where the played route stood at t=400 s (dialogue)
- expected: DIAG: the trace's own position (20.2, 12.3) in grandpas_village; the walk that produced it is in S04's route.csv
- actual: DIAG teleport to (20, 12); distance/dead-travel accumulators reset
- events: t=10.93
- verdict: PASS

### G2C-32 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=10.95
- verdict: PASS

### G2C-33 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=11.05
- verdict: PASS

### G2C-34 — capture G2-S04-0400-dialogue
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S04-0400-dialogue at 1280x720 (mean luma 80.2, spread 40.4, 2.3% dark)
- events: t=11.53
- verdict: PASS

### G2C-35 — pin the clock to the trace's hour at t=1 s
- expected: the hour and weather the played route had here (0.00 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=11.53
- verdict: FAIL

### G2C-36 — stand where the played route stood at t=1 s (region-change)
- expected: DIAG: the trace's own position (0.0, 0.0) in grandpas_village; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (0, 0); distance/dead-travel accumulators reset
- events: t=11.87
- verdict: PASS

### G2C-37 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=11.88
- verdict: PASS

### G2C-38 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=11.98
- verdict: PASS

### G2C-39 — capture G2-S05-0000-region-change
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0000-region-change at 1280x720 (mean luma 78.0, spread 38.9, 2.6% dark)
- events: t=12.47
- verdict: PASS

### G2C-40 — pin the clock to the trace's hour at t=181 s
- expected: the hour and weather the played route had here (15.18 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=12.47
- verdict: FAIL

### G2C-41 — stand where the played route stood at t=181 s (route)
- expected: DIAG: the trace's own position (20.2, 12.3) in grandpas_village; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (20, 12); distance/dead-travel accumulators reset
- events: t=12.80
- verdict: PASS

### G2C-42 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=12.82
- verdict: PASS

### G2C-43 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=12.92
- verdict: PASS

### G2C-44 — capture G2-S05-0180-route
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0180-route at 1280x720 (mean luma 79.6, spread 40.3, 2.3% dark)
- events: t=13.40
- verdict: PASS

### G2C-45 — pin the clock to the trace's hour at t=271 s
- expected: the hour and weather the played route had here (18.79 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=13.40
- verdict: FAIL

### G2C-46 — stand where the played route stood at t=271 s (route)
- expected: DIAG: the trace's own position (-235.9, 295.2) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (-236, 295); distance/dead-travel accumulators reset
- events: t=13.73
- verdict: PASS

### G2C-47 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at -49 deg
- actual: camera turned to -49 deg in 0 frames
- events: t=13.75
- verdict: PASS

### G2C-48 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=13.85
- verdict: PASS

### G2C-49 — capture G2-S05-0271-route
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0271-route at 1280x720 (mean luma 46.0, spread 42.8, 41.3% dark)
- events: t=14.33
- verdict: PASS

### G2C-50 — pin the clock to the trace's hour at t=335 s
- expected: the hour and weather the played route had here (21.35 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=14.33
- verdict: FAIL

### G2C-51 — stand where the played route stood at t=335 s (region-change)
- expected: DIAG: the trace's own position (-296.8, 538.0) in the_pond; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (-297, 538); distance/dead-travel accumulators reset
- events: t=14.67
- verdict: PASS

### G2C-52 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 13 frames
- events: t=14.90
- verdict: PASS

### G2C-53 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=15.00
- verdict: PASS

### G2C-54 — capture G2-S05-0335-region-change
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0335-region-change at 1280x720 (mean luma 60.9, spread 40.6, 6.2% dark)
- events: t=15.40
- verdict: PASS

### G2C-55 — pin the clock to the trace's hour at t=451 s
- expected: the hour and weather the played route had here (1.99 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=15.40
- verdict: FAIL

### G2C-56 — stand where the played route stood at t=451 s (route)
- expected: DIAG: the trace's own position (104.2, 857.1) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (104, 857); distance/dead-travel accumulators reset
- events: t=15.73
- verdict: PASS

### G2C-57 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=15.75
- verdict: PASS

### G2C-58 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=15.85
- verdict: PASS

### G2C-59 — capture G2-S05-0451-route
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0451-route at 1280x720 (mean luma 44.4, spread 33.6, 29.5% dark)
- events: t=16.33
- verdict: PASS

### G2C-60 — pin the clock to the trace's hour at t=502 s
- expected: the hour and weather the played route had here (4.04 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=16.33
- verdict: FAIL

### G2C-61 — stand where the played route stood at t=502 s (fight-starts)
- expected: DIAG: the trace's own position (191.1, 897.2) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (191, 897); distance/dead-travel accumulators reset
- events: t=16.67
- verdict: PASS

### G2C-62 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=16.68
- verdict: PASS

### G2C-63 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=16.78
- verdict: PASS

### G2C-64 — capture G2-S05-0502-fight-starts
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0502-fight-starts at 1280x720 (mean luma 71.5, spread 37.5, 4.3% dark)
- events: t=17.27
- verdict: PASS

### G2C-65 — pin the clock to the trace's hour at t=522 s
- expected: the hour and weather the played route had here (4.84 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=17.27
- verdict: FAIL

### G2C-66 — stand where the played route stood at t=522 s (level-up)
- expected: DIAG: the trace's own position (191.1, 897.2) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (191, 897); distance/dead-travel accumulators reset
- events: t=17.60
- verdict: PASS

### G2C-67 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=17.62
- verdict: PASS

### G2C-68 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=17.72
- verdict: PASS

### G2C-69 — capture G2-S05-0522-level-up
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0522-level-up at 1280x720 (mean luma 71.4, spread 37.4, 4.3% dark)
- events: t=18.20
- verdict: PASS

### G2C-70 — pin the clock to the trace's hour at t=578 s
- expected: the hour and weather the played route had here (7.08 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=18.20
- verdict: FAIL

### G2C-71 — stand where the played route stood at t=578 s (landmark)
- expected: DIAG: the trace's own position (324.4, 920.7) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (324, 921); distance/dead-travel accumulators reset
- events: t=18.53
- verdict: PASS

### G2C-72 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=18.55
- verdict: PASS

### G2C-73 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=18.65
- verdict: PASS

### G2C-74 — capture G2-S05-0578-landmark
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0578-landmark at 1280x720 (mean luma 70.4, spread 43.6, 3.8% dark)
- events: t=19.13
- verdict: PASS

### G2C-75 — pin the clock to the trace's hour at t=670 s
- expected: the hour and weather the played route had here (10.76 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=19.13
- verdict: FAIL

### G2C-76 — stand where the played route stood at t=670 s (landmark)
- expected: DIAG: the trace's own position (14.3, 1302.1) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (14, 1302); distance/dead-travel accumulators reset
- events: t=19.47
- verdict: PASS

### G2C-77 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=19.48
- verdict: PASS

### G2C-78 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=19.58
- verdict: PASS

### G2C-79 — capture G2-S05-0670-landmark
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0670-landmark at 1280x720 (mean luma 53.1, spread 38.7, 20.1% dark)
- events: t=20.07
- verdict: PASS

### G2C-80 — pin the clock to the trace's hour at t=723 s
- expected: the hour and weather the played route had here (12.85 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=20.07
- verdict: FAIL

### G2C-81 — stand where the played route stood at t=723 s (route)
- expected: DIAG: the trace's own position (20.2, 1307.8) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (20, 1308); distance/dead-travel accumulators reset
- events: t=20.40
- verdict: PASS

### G2C-82 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=20.42
- verdict: PASS

### G2C-83 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=20.52
- verdict: PASS

### G2C-84 — capture G2-S05-0722-route
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0722-route at 1280x720 (mean luma 71.8, spread 42.1, 7.6% dark)
- events: t=21.00
- verdict: PASS

### G2C-85 — pin the clock to the trace's hour at t=755 s
- expected: the hour and weather the played route had here (14.15 h, clear)
- actual: pin_clock refused: step is not marked "diag": true. Freezing the world clock is a diagnostic instrument, not something a player can do.
- events: t=21.00
- verdict: FAIL

### G2C-86 — stand where the played route stood at t=755 s (objective)
- expected: DIAG: the trace's own position (9.7, 1319.4) in corridor; the walk that produced it is in S05's route.csv
- actual: DIAG teleport to (10, 1319); distance/dead-travel accumulators reset
- events: t=21.33
- verdict: PASS

### G2C-87 — turn the gameplay camera to the trace's yaw
- expected: the real camera rig, steered by the right stick, at 0 deg
- actual: camera turned to 2 deg in 0 frames
- events: t=21.35
- verdict: PASS

### G2C-88 — let the world stream in around the stand
- expected: grass, scatter and any wild spawn near this stand have arrived
- actual: waited 6 physics frames
- events: t=21.45
- verdict: PASS

### G2C-89 — capture G2-S05-0755-objective
- expected: a gameplay frame with the HUD on from this stand
- actual: captured G2-S05-0755-objective at 1280x720 (mean luma 80.7, spread 43.0, 3.1% dark)
- events: t=21.93
- verdict: PASS
