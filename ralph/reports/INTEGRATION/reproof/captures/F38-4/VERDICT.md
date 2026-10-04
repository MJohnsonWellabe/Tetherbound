# F38#4 — Village road and Crossing Hall read at distance and up close

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility) = Low preset; Xvfb + llvmpipe, opengl3, 1920x1080
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_f38_matrix.gd -- --seed=2042 --f38-preset=Low --f38-candidate --times=day,night --output=<dir> --subset=hall_front --subset=village_road --subset=farm_to_hall --subset=hall_nave`
  - `--times=day,night` is this lane's reduction (golden omitted for runtime: ~3–4 min/frame on llvmpipe). A first run with all times was cut by a container restart after 4 frames (aborted_first_run/manifest.json, same rejections).
- **Tool result: FAIL, `CATALOGUE SURVEY FAILED: 28/64 frames`.** 36 planned frames rejected in preflight: "no supported production-camera stand among 1 candidates", reason "no physical floor supports the resolved land stand" (e.g. farm_to_hall approach stand (66, 14) and gameplay stand (90, 14) on the main road at ground_y 0.9, `on_floor: false`). Rejected: farm_to_hall approach+gameplay (all 8), village_road gameplay/reverse/detail (all 12), hall_front approach/gameplay/detail (all 12), hall_nave approach (4). See frames/manifest.json.
- **High/Medium (Forward+): needs native GPU (Codex F26 lane).**
- Replaces: no prior executed F38#4 evidence (R2-F38 pending).

## Code-blind judge (fresh agent; 28 frames, criterion, Village/Hall bar, key art, Meadows board, palworld-02): FAIL

DISTANCE NO; CLOSE NO; NIGHT NO; RAIN NO; Bar A NO; Bar B NO. "The village street is close to passing. The Crossing Hall fails at every distance and in every condition, and the capture set does not cover the criterion."

Blocking defects (verbatim):
1. Mislabelled views. Everything named farm_to_hall__* and hall_front__* is inside the nave. No frame shows Grandpa's farm, the road from the farm, or the Hall front.
2. Camera clipping the roof. In all four hall_nave__*__gameplay frames, a flat wood roof slab covers the top half of the screen.
3. Placeholder slabs. Portal openings are flat untextured blue fills (every reverse frame). The Home arch is a flat cream or grey slab (farm_to_hall__*__detail and every reverse frame).
4. Unfinished interior. The roof is open to the sky between the rafters. A tree shows through a missing gable (hall_nave__*__detail). Window holes are cut through to exterior roof tiles.
5. Floating object. A lantern on a rod hangs in open sky in hall_nave__*__detail.
6. Labels fail. Text on the lectern-style stands is mirrored ("The Meadows" backwards in farm_to_hall__*__reverse; "Cloudreach"/"Stormwood" backwards in hall_nave__*__detail). Far portal labels unreadable even in daylight.
7. Interior bar not met. Six arches plus the Home arch, not eight arches and eight pedestals. No interior haze or depth; hard sun patches, no window light revealing beams or floor volume.
8. Magenta-pink light blob at the base of the well on the left of all four village_road frames.
Also: village_road approach frames work (straight road to a lit Hall gable; night blue exterior with warm windows, Hall silhouette survives) but are ~8 m, not a 32 m distance view; interior night is a flat blue tint with no warm pools; farm_to_hall__night__rain__reverse reads as daytime grey; interior rain frames ≈ dry frames. Minor: placeholder-looking cyan roof beam; crude tiled-slab road edges.
(Golden hour was omitted by this lane's `--times`, not by the build.)

## Verdict: FAIL (Low/Compatibility). High/Medium: needs native GPU (Codex F26 lane).
Top defects: 36/64 stands have no physical floor (road/Hall-front views uncapturable); Hall interior placeholders (flat blue portal fills, open roof, mirrored labels, 6 not 8 arches).
