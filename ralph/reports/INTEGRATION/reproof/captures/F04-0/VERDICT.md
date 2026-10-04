# F04#0 — Warrens guardian: named tactical question visible at normal distance

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1280x720
- Command: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script tests/smoke_warrens.gd -- --guardian-attacks --guardian-settled-approach --capture-dir=<dir>` → exit 1; 10 frames (frames/, JPG q90); guardian naturally admitted after a 17.1 m input walk.
- Replaces: ralph/reports/MEADOWS-CORE/f04/guardian_03b7a17b/

## Smoke: FAIL (smoke_lines.txt)
- "attack 1/3 used tell/recovery 1.00/0.90, expected 0.85/1.10"; "attack 1/3 signal interval was 1.00s, expected 0.85s"
- "quick attack did not retain generic enemy geometry"
- "Earth Fist cone_degrees did not come from MoveDB"; "Earth Fist lunge did not come from MoveDB"
(Whether the smoke's expectations or the guardian data are stale relative to the F22 timings is for the owning lane; recorded as observed.)

## Code-blind judge (fresh agent; 10 frames, criterion, M3 gate): FAIL

Verbatim: "The tactical question exists only as HUD text. The two attack types share one identical magenta-ring tell. The boss's attack is never shown landing on the player creature, and the avoidance is only a caption. The camera is too close or occluded in 8 of 10 frames."
- Tactical question read only from panel text ("! incoming — move", "!! HEAVY — get clear", "it's open — hit it"); no burrow path, fist wind-up or ground marker in the scene.
- Burrow strike (01/03 tell_mid) and Earth Fist (02/04 tell_mid) both use the same solid magenta ring; ring cropped by frame edge/Terrapup card (quick_tell, 01_tell, charged_tell) and under the move panel (04_tell).
- Hit: only a pale burst on the boss and "19" (player hitting boss); no boss hit on the player creature. Avoidance only as the "it missed you" caption (02_strike).
- Framing: 00/quick/charged/01/02_tell extreme close-up on two faces (bodies, feet, rings cropped), "Engage Warren Guardian" prompt still up in 00; trainer half-hidden (charged_tell, 02_tell), absent (02_strike, 03_*), hidden behind the move panel (04_tell); camera nearly inside the guardian's back (02_strike); foreground orange spike props occlude the player creature (02_strike, 03_*).
- Scale: guardian barely larger than the level-12 player creature, two similar ground badgers — doesn't read as a boss.

## Verdict: FAIL
