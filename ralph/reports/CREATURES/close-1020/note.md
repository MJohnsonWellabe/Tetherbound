# Creatures lane, close-1020 — work note

Renderer for every capture: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, xvfb, 1280x720, Low. CPU-provisional bar (owner, 17 Oct): Bar A mean ≥ 6.7; a GPU pass must later confirm 7.5.

Capture command (each round): `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=stormursa[,staticub] --candidate --whole-body --context --out=<local>`. The sheet crops the frames and scales Staticub by its camera-distance ratio, so both bears share one pixel scale against the same 1.80 m ruler.

## F29#3 Stormursa v1 — staging fix

With `--context`, the trainer ruler now stands 1.4 m clear of the resting body's rear (`capture_f36_poses.gd`). In r5 it hid behind the bear in the standing and hit frames.

## Round r6 (02:20 UTC): REJECTED

Matched control: the live r5 pose on the new staging. Candidate: `staged_faint` rolled +90° (back to camera), tuck 15, adduct −10, and `held_hit` scale 1.7. Three code-blind judges, Bar A:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Control | 6.4 | 6.4 | 5.6 | 6.13 |
| Candidate | 5.9 | 5.6 | 4.6 | 5.37 |

All three preferred the control. The away-from-camera faint ends as a smeared "fur boulder", and the 1.7× hit reads as cramped. The candidate was discarded.

## Round r7 (02:35 UTC): KEPT, +0.36, still OPEN

Candidate, authored by `assets/creatures/tetherbound/stormursa/source/author_f36_hit_faint_r7.py`:
- **`topple_faint`:** the feet stay planted while the front knees buckle (0–.45), then the body tips −90° onto its flank about the mesh long axis, with a late, small leg tuck and the head in line with the body.
- **`flinch_hit`:** the head snaps away and down, the shoulders hunch and the front knees give, with a 9° lean away. It holds to .35 and recovers by .8.

The guard-stretch solver runs on both. The sheet's "hit recover" column is phase .75. Sheet: `_sheet-f29-3-r7.png`, with the candidate as variant B. Three fresh code-blind judges:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Control Bar A | 6.3 | 5.5 | 6.4 | 6.07 |
| r7 Bar A | **6.8** | **5.9** | **6.6** | **6.43** |
| r7 Bar B | 5.8 | 4.7 | 5.0 | 5.17 |

r7 was preferred 3/3. Hit react: PASS, PASS, WEAK. Faint: WEAK ×3; the faint mid is now grounded and the end frame is the remaining defect.

Remaining defects (consensus):
1. **Faint end:** near paws crush into blobs toward the camera; a white hotspot on the belly and muzzle; the head is hard to read. Pose and material fixes, about +0.4–0.5.
2. **Material:** the fur drifts red-mahogany (toward oxblood) against the board's cool umber, and the veins never flare on hit or dim on faint. Material/shader fixes, about +0.3–0.6.
3. **Identity:** the cub's blue eyes are unreadable, there is no evolved storm feature, and the head is small and realistic. This needs the Meshy v3 model (requested), about +0.4–0.8.

The flag stays OFF; `enabled_species` is unchanged. Unit check: `test_f36_pose_candidates` 1 test, 8 assertions, 0 failed.
