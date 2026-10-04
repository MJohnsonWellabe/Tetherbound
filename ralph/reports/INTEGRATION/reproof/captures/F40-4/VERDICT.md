# F40#4 — Sky Aviary reads at distance and up close

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility) = Low preset; Xvfb + llvmpipe, opengl3, captured 1920x1080, judged/committed as 1280x720 JPG copies
- Frames: shared with CH-Cloudreach C2 — `../CH-Cloudreach-C2/day/` and `../CH-Cloudreach-C2/night/`, rows 24 (≈850 m), 26–28, 29 detail-aviary, 33 finale400, 34 finale100, 35 postfinale.
- Commands: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_frame_matrix.gd -- --active=terrapup --output=<dir>` and the same with `--night`. Both exit 0, 37/37 frames.
- Tool substitution: the planned F40 tool `tools/capture_cloudreach_f40_matrix.gd` is a 384-frame Forward+ High/Medium matrix that refuses subsets; the closest current tool with the aviary distance/close rows is the chapter frame matrix above.
- **High/Medium (Forward+): needs native GPU (Codex F26 lane).** Not attempted.
- Replaces: no prior executed F40#4 evidence (R2-F40 runtime proofs pending).

## Code-blind judge (fresh agent; aviary rows, criterion, Cloudreach bar, aviary board, palworld-04): FAIL

DISTANCE NO; CLOSE NO (partial); NIGHT NO (partial); Bar A NO; Bar B NO.

Defects (verbatim):
1. 33_finale400 (day and night): the aviary is not visible at 400 m. The path is framed by cliffs and trees with no landmark sightline.
2. 28_reverse_day: a distant dark box with an antenna on the summit is a placeholder-like silhouette.
3. 24_observatory (day and night): no aviary appears on the skyline.
4. 34_finale100 and 35_postfinale (day): near-identical captures; canyon walls untextured-looking, large flat dirt planes, no strata. A floating green triangular sliver at the right wall base is a geometry or clip artifact, also visible in 34_night.
5. 26_approach_day: a floating rock chunk in the upper left sky reads as an unanchored floating object.
6. 29_detail-aviary (day and night): a companion clips and blocks most of the frame. The night version has no warm window light.
7. All frames: no cloud sea, so the "distinct from bright cloud sea" requirement cannot be met.
8. 34 (day and night): dome-to-base scale is unbalanced. The thin stone wall carries no drum, turrets or arcade — "reads as a greenhouse on a gate, not an aviary stronghold".

Positive: 29/34 show a gold-ribbed lattice glass dome, crenellated rough-stone gatehouse and arch; no missing or magenta materials. 34 night: one warm doorway, dome silhouette holds, restrained stars.

Judge's PASS needs: sightline to the dome from 850 m and 400 m (ideally over a cloud sea); massed stone drum with arched windows and turrets; multi-window warm night glow; stratified pale cliff material; remove the placeholder box and floating slivers; re-frame detail so the companion does not block it.

## Verdict: FAIL (Low/Compatibility). High/Medium: needs native GPU (Codex F26 lane).
