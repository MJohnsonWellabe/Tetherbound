# SCENE-BENCHFIX-LAND: the camp workbench's tools are back on the bench

STATUS: land (correctness fix; no GPU verdict claimed, no score claimed)

Branch `tb/scene-benchfix-land`, cut from origin/main 4f9ee396 (after #951).

## The bug
`assets/props/vl-1103/camp_workbench/camp_workbench_r2.glb` is the workbench shown at every Tidewake water camp. Its build script turned each joined material group about that group's own origin instead of the bench centre. Result:
- the hung tools, rope coil, vise, jar and lantern sit up to 1.6 m off the bench: the model measures 4.61 m by 2.36 m against a 2.6 m by 1.05 m top;
- on the GPU frames (`G-rescore-stale-ext-tidewake/F39-13`) these are the small dark squares floating beside the tent and the white ring left of the bench, and the tool board is bare;
- the bench is centred by its bounds, so it also stood about 0.9 m off its craft prompt.

## The fix
- `camp_workbench_r2b.glb`: the same build with every group turned about the bench centre (`source/workbench_r2b.py`, one added block). Same materials and textures as r2.
- `data/config/meshy_camp_props.json` `workbench.vl_candidate.model` points at r2b, with `_why_r2b`.
- `tests/test_camp_workbench_model_parts.gd` (new): the model in use is no longer than 3.4 m and no deeper than 2.7 m. It fails on r2 (4.61 m) and passes on r2b.
- `tests/test_camp_props_vl.gd`: the pin on the shipped model name now names r2b and checks `_why_r2b`. This is a pin update for the fix, not a skipped test.

## What it looks like
CPU, `phase2_capture_tidewake_camps.gd --seed=2042`: the hammer, saw, tongs and rope coil hang on the board, the vise and jar sit on the top, and nothing floats beside the tent. The bench is still pale on the sand; that is the SCENE-WORKSHOP arm, not this fix. Sheet: `ralph/reports/LANES/SCENE-WORKSHOP/_sheet_cpu.jpg` on `tb/scene`, top row.

## Checks (run on `tb/scene` afed6086, same files)
- 13 related test files run together: 133 tests. One failed on the first run (the model-name pin in `test_camp_props_vl.gd`); after the pin update the two bench files re-run at 5 tests, 0 failed. The other 11 files passed on the first run.
- `tools/art_pipeline/texture_import_policy.py --check`: PASS (1561 sidecars).
- Not run: the full suite, and any GPU capture.

## Note for F39#13
The board score (6.14) was judged on the broken model. After this lands the row is worth a re-score on its own, before or alongside SCENE-WORKSHOP.
