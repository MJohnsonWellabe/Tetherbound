# CH-Cloudreach#C2 — art matrix part

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, captured 1920x1080; committed/judged as 1280x720 JPG copies (day/, night/)
- Commands: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_frame_matrix.gd -- --active=terrapup --output=<dir>` and the same with `--night`. Exit 0, 37/37 rows each (cmd.txt, manifest_lines.txt per folder). Log: `ERROR: unscoped chapter flag: fly_tutorial_completed`.
- High-perch part reused from ../F08-3 (FAIL); settlement/cliff part judged separately in ../F08-4 (FAIL); aviary in ../F40-4 (FAIL).
- Replaces: CLOUDREACH/c2-card evidence (f08-3 r5, f08-4 r1/r1c/r1d/r1f)

## Code-blind judge (fresh agent; full matrix, criterion, §4.1/§4 Cloudreach bar, both Cloudreach boards, palworld-02/-04): FAIL — Bar A NO, Bar B NO ("closer")

Blocking defects (verbatim summary):
- Camera blocked/unreadable: day/16 two rock slabs fill ~90% of screen; day/18 and night/18 detail-shrine the whole frame is a rock face, no shrine, blocky shadow-map aliasing; day/09 Staticub's back fills the frame; day/10 Craghorn hides the right ~40%; day/20 perch-vista camera at ground level with a gold ring clipped across the bottom; day/29 and night/29 Staticub hides the left 60% of the Aviary. "Overall, the matrix does not show correct high-perch production-camera footage."
- Floating/placeholder objects: day/20 blue dragonfly creature with no ground contact; day/15 and day/20 banners are flat unshaded blue quads; day/20 plank props flat on grass, loose pink rod, black cylinder leaning on nothing (also day/15); day/01 flat white snow-like slab on the plateau edge.
- Silhouette/strata: cliffs are smooth brown blobs or extruded slabs (day/12, 22, 27); gate crag day/01 has the forbidden horizontal barcode banding; no moored-island anchors, ruined skyroads or stacked shelves.
- Horizon/depth: grey-white void fog below shelves (day/01, 09, 12, 25) or flat ocean plane at night (night/13, 25); no inter-shelf haze; most frames read as a flat meadow on a mesa.
- Colour: saturated Meadows-green grass everywhere; stone mid-brown to dark grey, never pale.
- Settlements: day/05, day/25 generic flat-lot timber cottages, no terracing or edge rails (day/25 watchtower is the best landmark).
- Aviary: thin gold lattice dome over a squat ruined keep on flat ground; night/29 masonry lit near day value, no warm windows.
- Night: sky, moon and stars work (night/02, 07, 21); warm route cues almost absent; grass stays bright green; night/07 rock is a flat grey wall.
- Scale: Staticub correctly larger than the trainer; creatures repeatedly park in frame and block composition.

Biggest gaps from references: (1) layered height — boards show stacked islands, waterfalls, bridges and a cloud sea; frames show single flat shelves over grey void; (2) materials — pale strata stone vs green turf and brown blob rock; (3) landmark/craft — domed stone sanctuary vs lattice dome on a small ruin, placeholder banners/poles.

Scene-fixable: camera framing and keeping creatures/rocks out of lens (09, 10, 16, 18, 20, 29); cloud-sea layer and distance haze; grass tint/density and pale rock tint; night warm emissives and lower night value on Aviary masonry; ground/remove loose props, fix shadow aliasing; settlement edge rails/terracing from installed parts.
Needs new art: stratified pale cliff/shelf modules; a proper domed stone Aviary stronghold; moored-island anchors and ruined skyroads; cloth banners with the board's emblem.

## Verdict: FAIL
