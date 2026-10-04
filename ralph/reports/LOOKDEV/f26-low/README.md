# F26 Low preset (Compatibility) lane evidence

Lane `tb/lookdev-low`, Claude. Renderer `gl_compatibility` (`--rendering-driver opengl3`) under
Xvfb on Mesa llvmpipe. This container has no GPU. **No frame time or performance figure is recorded
or claimed.** F26#4 and F26#5 stay with Codex and the owner.

## F26#0, Low half: materials and the Low preset

- **Census:** `census-low-receipt.json`. The unchanged Codex harness
  `tools/capture_renderer_material_census.gd` ran at `--preset=Low --times=day` on source `4d75308a`
  (Codex `8593c488` plus Low tooling only). Results:
  - Meadows (village and placed Crossing Hall `Village/crossing_hall_shell_12` with arches): 10/10 frames.
  - Tidewake: 24/24. Cloudreach: 12/12. Stormwood: 12/12.
  - Every run exited 0 with zero native ERROR lines.
  - No missing sources, empty shaders or required null textures, and zero magenta-flagged frames
    (`sheets/census-low-scan.json`).
  - Findings are in the receipt: LOW-C1 Master signpost and fly-support primitives have no material
    (renderer-independent, F28); LOW-C2 Cloudreach null uniforms are benign.
  - Raw manifests (about 335 MB each) are kept gzipped in the lane container only; their SHA-256 is in the receipt.
- **Low selectable and persisted:** `tests/smoke_graphics_low_persist.gd`, two processes with an isolated
  user dir; logs are in `logs/settings-low-*.log`, 11/11 PASS.
  - Physical pad A on the real Settings preset button cycles High to Low and persists `gl_compatibility`.
  - A fresh process started without `--rendering-method` boots Compatibility with Low selected.

## Low route visuals

- **Route-point stills:** `tools/capture_lookdev_route_stills.gd` covers each declared point of the four
  `data/config/lookdev_routes.json` routes, day and night: 28 frames
  (`route-stills/`, `sheets/route-stills-low-*`). They are visual only.
- **Judge:** a fresh code-blind judge reviewed 86 frames; see `judge-verdict.md`.
- **Timed routes:** the timed route (`tools/run_lookdev_routes.py --preset Low`) was started once. It was
  stopped during Meadows warmup to make the far-floor fix and has not been rerun. It is open; see below.

## Fixes from the Low judgement (isolated commits)

| Commit | Fix | Proof |
|---|---|---|
| 1c71f089, 94929005, d825d181 (integration), d80a07b5 | Each realm camera keeps its authored far plane as the draw-distance floor. The preset had cut it to 320 m on Low, the shipping default. | `tests/test_realm_camera_far_floor.gd` 3/21/0; blinded A/B in `ab-far-floor/`: after better 18, before better 0, same 14 |
| ced438ee | Free-standing Hall pedestal and Master labels billboard instead of reading mirrored | Hall 2/13 and Master 5/43 tests; `verify/` |
| 3704c5ca | Veilfall spray puffs fade when the camera is inside them | `verify/` |
| b1d76e75, 5390b5b6 | Burrow, Old Bram and Doss lure smoke matched to the accepted Tidewake plume | `verify/` |
| fca48154 | Catalogue stands clear of the trunk (Ridgeline), sandstone (Veilfall crown) and on-spot pickups (three Stormwood landmarks) | probe arm length 5.82 m; teleport catalogue tests 10/1094 and 2/28; `verify/` |

Not defects, or reported to other lanes: Stormwood is always purple (owner WO-F10-08); the night torch
is owner-mandated; the water current lanes have the P2-066 candidate; the night-sea grade and Low shadow
cost go to Codex F26#1; Tidewake dune heightfield; Cloudreach items go to `tb/visual-cloudreach`; the
Crown Arch fall-through is a gameplay bug and its stand is kept as the witness.

## Commands

```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1920x1080 --script tools/capture_renderer_material_census.gd -- --biome=<b> --preset=Low \
  --source-commit=<sha> --times=day --output=<fresh dir>
... --script tools/capture_lookdev_route_stills.gd -- --biome=<b> --preset=Low --source-commit=<sha> --output=<dir>
... --script tests/smoke_graphics_low_persist.gd -- --graphics-proof --low-select   (same user dir, then:)
godot --path . --script tests/smoke_graphics_low_persist.gd -- --graphics-proof --low-reload
python3 tools/f26_low_frame_scan.py --frames <dir> --out <dir> --sheet-name <name>
python3 tools/f26_low_census_summary.py --manifest <m.json.gz> ... --out <receipt>
```

Each run uses an isolated `XDG_DATA_HOME`/`XDG_CONFIG_HOME`. `--audio-driver Dummy` is used because the
container has no ALSA device.
