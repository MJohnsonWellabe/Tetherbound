# F08#3 — Correct high-perch production camera

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1920x1080, `--fixed-fps 60`
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_high_perch_live.gd -- --output=<dir>`
- Replaces: ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5

## Tool result: FAIL (exit 1), 11/12 frames

- `ERROR: HIGH PERCH LIVE: night departure: second Jump did not launch (Find a clear launch with room for your companion overhead.)` — no night departure frame.
- `ERROR: unscoped chapter flag: fly_tutorial_completed` (flag-scope rule).
- Lines: run_lines.txt.

## Code-blind judge (fresh agent; frames, criterion, §4.1 Cloudreach bar, Cloudreach sky-aviary board): FAIL — Bar A NO, Bar B NO

Camera, verbatim summary:
- arrival-far (day/night): best frame; trainer under mount at centre, perch reads as tall column, horizon level.
- arrival-lip (day/night): "A freestanding stone arch wall sits between the camera and the landing spot. The trainer is seen only through the arch opening and is mostly covered by the mount's wings. The landing itself is hidden. At night the trainer is barely legible inside the dark arch."
- arrival-landed (day/night): "The camera is wedged between two near pillars that fill about 35–40% of the frame ... a bench edge sticks up at the bottom (day) ... a curved rail runs across the bottom and a blue post sits right at the lens (night). This reads as a camera behind or inside the dressing." Mount missing from the day landed frame.
- crown-court (day/night): trainer clear, no clipping; pillars crowd the right; does not read as high.
- crown-rim-out (day/night): "A dark rock mass clips the lower-left corner and a pillar base clips the lower-right."
- departure-lookback (day): readable, reads as high; weak dark-rock silhouette.

Bar defects:
- No structured cloud sea below the shelves: flat grey-green fog plane by day, flat navy plane by night.
- A large flat-shaded near-white disc platform on white cylinder legs (arrival-far, arrival-lip, rim-out, departure) — untextured, pure-white washout, reads as placeholder.
- No Aviary dome/stronghold silhouette; settlement is plain rock pillars with plank scaffolds.
- Cliff strata are mud-brown blobs rather than pale layered rock.
- Night: no contained warm windows (one torch only). Weak haze separation between shelves.

Judge's fix list: (1) move arrival-lip and arrival-landed cameras out from behind arch/pillars/bench/rail and keep the mount in the landed frame; (2) pull rim-out camera off corner rock and pillar base; (3) replace/texture the white disc platform; (4) cloud layer below/between shelves; (5) warm night window lights; (6) capture the missing night departure.

## Verdict: FAIL
Top defects: dressing-blocked cameras at arrival-lip/arrival-landed/rim-out; night departure jump fails to launch (no frame).
