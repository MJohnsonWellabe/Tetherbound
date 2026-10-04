# F08#4 — Settlements and cliff identity pass the C2 visual matrix

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, captured 1920x1080; committed/judged as 1280x720 JPG copies
- Frames: shared with CH-Cloudreach C2 (`../CH-Cloudreach-C2/day|night/`). Settlements rows 05, 25, 36, 37; cliff rows 01–04, 06–11, 31; night 01, 05, 06, 25, 37.
- Commands: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_frame_matrix.gd -- --active=terrapup --output=<dir>` (+ `--night` pass). Exit 0, 37/37 each. Log: `ERROR: unscoped chapter flag: fly_tutorial_completed`.
- Replaces: ralph/reports/CLOUDREACH/f08-4-settlements/ (r1, r1c, r1d, r1f)

## Code-blind judge (fresh agent; frames, criterion, Cloudreach bar, both Cloudreach boards, palworld-04): FAIL

Settlements height-aware: NO. Cliffs distinct stacked strata: NO. Bar A: NO. Bar B: NO ("Character and creature quality is close to that bar. Terrain and cliff modelling is not.")

Settlement defects (verbatim):
- 05 Galefoot (day/night) and 36 postfinale: "look like a flat Meadows village: half-timber cottages on level grass with a dirt plaza and lawn. There is no cliff edge, drop, terrace, stair or anchor in view ... 36 is almost pixel-identical to 05, so the postfinale state shows no visible change. A tall bare pole and a slack rope cut across the left and right foreground ... At night ... the right-hand house is a near-black slab with a blown-out window grid."
- 37 Galefoot approach: best settlement frame (cliff wall, watchtower, tents, campfire) but "still a flat lawn with the cliff as a backdrop".
- 25 Cliffhold: "A grassy mesa top with four cottages and a tower, and a sharp beveled grass edge with no stone strata exposed. Past the edge is an empty grey horizon (navy at night) with no cloud banks below ... reads as a placeholder hilltop."

Cliff defects (verbatim summary):
- 01/night 01: crag is smooth rounded "pancake" layers with painted dark bands; featureless grey void right of the plateau, flat navy sea plane at night; white slab at left edge.
- 02, 03, 11: low, boxy, brown extruded blocks with smeared texture; read as Meadows hills with rock boxes.
- 04: frames the gate and a smooth mound, not a crag; blurry brown grain; white plane lower left.
- 06, 07, night 31: single-plane brown/grey walls, no strata, untextured bevel ledges.
- 08: far island edge is a flat fence-like wall; grey haze horizon, no cloud banks, no moored-island anchors.
- 09 rope bridge: companion fills ~60% of the frame, trainer not visible; bare-pole rails; white void plane below.
- 10 lure bells: creature wing occludes right third (bell gate and plank bridge good).
- Throughout: brown/tan not pale stone; no cloud banks, ruined skyroads, anchors; moss as flat caps; night often too dark to read cliff form (31, night 06).

Blocking defects: blank grey void / white or navy plane where the cloud sea should be (01, 04, 08, 09, 25, night 01, night 25); placeholder extruded cliff silhouettes (02, 06, 07, 11, 31); camera occlusion in 09 and partly 10; postfinale 36 indistinguishable from 05.

## Verdict: FAIL
