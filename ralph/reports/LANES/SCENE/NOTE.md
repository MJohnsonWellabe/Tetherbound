# LANE-SCENE NOTE (branch `tb/scene`; this file is the channel)

## TO THE COORDINATOR (13 Nov 2026, about 17:00 UTC)
1. **LAND (correctness fix, no GPU verdict needed):** `tb/scene-benchfix-land` 364b775c8, cut from main 4f9ee396. The shipped Tidewake camp workbench model has its hung tools, rope coil, vise and lantern thrown up to 1.6 m off the bench by its build script (model 4.61 m long against a 2.6 m top). Those parts are the floating dark squares and the stray white ring in the F39#13 GPU frames. The fixed model (r2b) puts them back. New bounds test fails on the old model and passes on r2b; the model-name pin in `tests/test_camp_props_vl.gd` is updated. READY: `ralph/reports/LANES/SCENE-BENCHFIX-LAND/READY.md` (on that branch).
2. **RE-SCORE after 1 lands:** F39#13 (6.14) was judged on the broken model.
3. **ARM SCENE-CACHE**, `tb/scene`, row F38#12 (5.89). **Replaces BELOW6-TONIC-STASH: please drop that one from the queue** (this overlay turns the tonic crate on too).
4. **ARM SCENE-WORKSHOP**, `tb/scene`, row F39#13. Overlay only, over the bench fix.
5. **Queue count:** with 3 and 4 plus HALLMOSS and TELLDUST2 the lane is over the limit of two. I suggest withdrawing THINGS-SOLENE and holding SCENE-WORKSHOP behind SCENE-CACHE. I send nothing more until slots free.
6. **RE-SCORE, no build:** F39#19 (6.56). On the GPU frame the roster already sits on dark panels; the recorded pale text is gone.
7. `tb/scene` has origin/main (after #951) merged in.

## State (13 Nov 2026, lane started)
- `tb/scene` holds origin/main (after #951) plus this lane's work. Every candidate is flag-off or overlay-only.
- Criteria closed: 0. Landed on main: 0.
- **Ready to land, no GPU verdict needed (objective geometry fix):** `tb/scene-benchfix-land`. The shipped Tidewake camp workbench model had its hung tools, rope, vise and lantern thrown up to 1.6 m off the bench by its build script. See `ralph/reports/LANES/SCENE-BENCHFIX-LAND/READY.md`.

## Waiting on the GPU (limit two; inherited arms count)
| Arm | Rows | Status |
|---|---|---|
| SCENE-CACHE | F38#12 (5.89) | New. Replaces BELOW6-TONIC-STASH (same switch file; its overlay turns the tonic crate on too). |
| SCENE-WORKSHOP | F39#13 (6.14) | New. Overlay only over the bench fix. |
| THINGS-HALLMOSS | F38#28 | Inherited, front of queue, near-bar closer. |
| THINGS-TELLDUST2 | F38#3, F38#28 | Inherited, front of queue, near-bar closer. |
| THINGS-SOLENE | F38#17 | Inherited. Its own note says the change is small on CPU and that character light fixes do not predict the GPU. **I suggest withdrawing it** to keep the lane at the limit; say if you want it kept. |

That is four with SOLENE withdrawn and TONIC-STASH replaced, which is over the limit of two. I am not sending anything further until HALLMOSS and TELLDUST2 are judged. If the coordinator prefers, hold SCENE-WORKSHOP behind SCENE-CACHE.

## Findings that need no build
- **F39#19 (roster contrast, 6.56):** on the GPU frame the roster already sits on dark panels; the recorded pale text is gone. The frame still shows the stale "Gather Reef Stone" prompt (fixed since) and a black void at the top right where the camera sees past the dune. Wants a re-score, and the void belongs to the Tidewake places lane.
- **F38#12:** the recorded "generic crates" defect is already gone on the GPU frames; staging is what is left (SCENE-CACHE).

## Next (while waiting; nothing sent)
1. F38#19 HUD cluster: describe the layout change to the coordinator before building (as directed).
2. Dialogue rows F38#37, F40#10, F41#15, F39#26: read the current GPU frames per row for a shared foreground rule beyond the shipped tighter shot.
3. F38#6 / F40#16 pickup silhouettes; F39#9 catch camera distance.

## Runbook additions
- A fresh container has no `.godot` import: `godot --headless --path . --import` takes about 20 minutes once.
- Tidewake camp frames: `tools/phase2_capture_tidewake_camps.gd --seed=2042 --output=res://ralph/reports/VISUAL/phase2/tidewake/<name>`, about 4 minutes on CPU, 9 frames.
- Harvest reward frames: `tools/phase2_capture_world_inventory.gd --biome=meadows --subset=meadows__inventory__harvest__<slug> --seed=2042 --output=res://ralph/reports/VISUAL/phase2/meadows/<name>`, about 4 minutes. The camera stands on the node's -z side: +z is behind the reward, -x is screen right.
- Blender-built props: check the exported model's bounds against the design size. A joined group rotated about its own origin scatters its parts.
