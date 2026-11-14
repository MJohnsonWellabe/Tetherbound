# LAND-CS-TURFGRAIN: give the Cloudreach lawn its fine grain back

Branch `tb/land-cs`. Flag `cloudreach_visual.json surface.turf_detail_1113`, OFF on the branch; `overlay.json` turns it on.

## Rows and scores (GPU High, mapped)
- F40#1 open terrain 5.90; F40#7 grass and stone finish 6.26; F40#0, F40#19, F40#21 matrix rows 5.98; F40#4 6.12.
- Every Cloudreach frame with turf in it carries the change, so F40#3, F40#2, F40#8 and F40#15 are no-loss rows.

## Defect, as the judges put it
- `G-rescore-f40-0-sample` (3/3): "uniform lawn with lone blades, blurry low-resolution path and plot splats".
- `F-cloudreach`, batch-wide: "flat grass discs". `G-places-gatepaving`: "the flat lawn is the defect".
- `CLUSTERS-6TO7` P-GROUND: "blurry, smeared ground", "uniform olive carpet".

## Cause, and how I know
1. **The lone blades are the configured density, not a bug.** A temporary probe in `cloudreach_ground_cover.gd` (not committed) printed every patch: 1,905 patches, 2.23 million tufts over 807,000 m², 2.1 to 4.8 tufts per m² (the three largest islands are capped at 135,000 tufts, about 2.1 per m²). A tuft is seven thin blades about 0.25 m across, so tufts cover under a tenth of the ground. Re-clustering them by overlay (`cluster_frequency`, `cluster_threshold`) left the frame looking the same, so that was dropped.
2. **The lawn under them is flat because the shader flattens it.** `cloudreach_turf.gdshaderinc` blends two samples of the grass texture and then cuts the contrast to 0.52 ("suppress large lumpy camouflage patches"). That removes the broad patches and every blade-scale mark with them, so the ground is one blurred green and the sparse tufts stand alone on it.
- Confirmed on the frame: with the fine detail added back and nothing else changed, the same lawn patch at the gate keeps its brightness (112.5 to 111.1) and its fine contrast goes from 6.8 to 15.3 (standard deviation against a local blur). The lawn reads as turf and the tufts sit in it.

## Change
- Shader: when `turf_detail_1113.x` is above 0, add the texture's fine detail only: the sample minus its own blurred mip (so no broad patch comes back), plus a finer second octave that mipmapping fades out with distance. Default 0: the shipped turf, unchanged.
- `cloudreach_environment_materials.gd turf_detail()` reads the flag once and sets the uniform on every turf, trail-shoulder and blade material (they share the function, so blade roots still match the ground).
- Values: strength 1.25, fine octave scale 3.1, fine octave strength 0.8.
- Shader uniforms only. No geometry, collision, route or scatter change.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`. Top: Realm Gate approach, base and arm at the shipped values. Bottom: Sky Shrine approach, base and the arm's first, stronger values (1.6 / 0.9); I lowered them after that frame because the grain looked a little noisy.

## By-eye line for the GPU lane
- Realm Gate approach and Sky Shrine approach, day: the lawn shows fine grass grain right up to the camera instead of a smooth blurred green; the trail and stones look as on base.
- Hold the arm if the lawn looks the same as base, or if it sparkles or crawls (noise) in the middle distance.

## Risks and no-loss frames
- Too much grain could read as noise at High, which filters sharper than the CPU renderer. The strength is one number in the overlay.
- Night and rain sets use the same turf; they are judged in the matrix sample.
- No-loss: F40#3 landmarks, F40#2 aviary, F40#8 route markers, the overlook pair.
- This does not fix the tuft density itself. A dense near-camera turf would need a camera-following field, which Cloudreach's stacked islands do not have; not attempted here.

## Tests
`tests/test_cloudreach_turf_detail_flag.gd` (ships OFF; OFF passes nothing; the shader default is strength 0), run with five existing Cloudreach look tests: 45 tests, 0 failed.
