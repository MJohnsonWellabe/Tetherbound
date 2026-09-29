# Colony06-native01 independent capture validation

**PASS for capture integrity within the recorded scope. No art or performance verdict.** Independently read the raw manifest, runner receipt and stdout/stderr; checked source/artifact hashes, live observations and pairs; parsed all six JPEG headers for dimensions without viewing images. No engine/GPU activity or production writes by this reviewer.

Run receipt: `471baef4c7d9f44fc1f778b8e4e47a4202d4e3f2`, exit 0, completed `2026-09-28T17:26:37.7536408Z`. Manifest complete=true, planned/captured 6/6, failures empty. Stdout contains exactly six capture lines and final `CATALOGUE SURVEY OK: 6/6`. Godot 4.7, OpenGL 3.3, `gl_compatibility`, GTX 1060 3GB. No script/shader/compiler/error messages found in either log. Stderr contains one deprecated `instance_reset_physics_interpolation()` warning from world setup.

## Source, variant and gate identity

All six source anchors in the receipt/embedded review match the current files: grass shader, grass controller, Water world, parent capture driver, teleport catalogue and Water ground-cover config. Wrapper and runner file hashes match the receipt. The review was prepared at earlier commit `ebd5c625...`; the run is `471baef4c...`, with those relevant source anchors unchanged. The exact two-config 05 runtime pack hash matches `f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12`.

Baseline shader text hash is `edae2afffe384929aa944eb3fbcd7540b3bc2b4a695932c131b8602aa36c99d9`; candidate is `2b48b3cea48da27afa440fb93a97841a2e829782fac5d5e56596fffc1845922e`. Independently hashed normalized text snapshots match these values. Every live frame reports the proper variant hash at `res://shaders/grass_field.gdshader`. All six share shader ID `-9223372006555122119`, material ID `-9223371737331134071`, and live field `/root/WaterArchipelago/WaterGroundCover`. This is the cached resource/material identity checked by the runtime wrapper, not a separately substituted fixture material.

Each candidate's effective shift is `0.180000007152557`, the expected float representation of .18; baseline shift is absent/null. The production controller never forwards the new parameter and the shared 05 config does not contain it, consistent with using the candidate shader default. The finish receipt restores the exact baseline text hash. No independent post-exit GPU-state query is possible; the restored resource is an in-process observation, and that process exited.

The 27 reported custom parameters match the mounted 05 ground-cover values (numeric tolerance 1e-6) and are exactly equal within each pair. Active configs also match exactly within pairs. All frames retain requested 54,000 tufts, five blades and four segments; actual lattice allocation is 57,836 instances over 52 grass tiles. The counts, tile paths, MultiMesh IDs and mesh IDs are identical within every pair. Stdout independently reports the same 57,836-instance ring. Requested count and actual allocation are correctly distinguished.

Both live process gates are true, while disk gates remain false and retain their pre-run/receipt hashes:

- Terrain: `21253bb62ba36b4195d83d1a8f079159e3354ff7eed5d3ab1fa71093125ff8e5`.
- Cover: `bdbe87f081ef3a338984d994fc07d4492aac37d9ba37c64c505ff4e13b27dba6`.

## Pair measurements

All six JPEG headers are exactly 1920x1080 and file byte counts match the manifest. Ordered pairs are Gull baseline/candidate, Sluice baseline/candidate, Welcome Beacon baseline/candidate; all day/close. No stand retries were needed; both frames of each pair report on-floor, non-swimming stands. Stand XZ, selected offset/lateral, terrain height and resolved ground height match exactly.

| Site | Stand XZ | Terrain Y / player Y (m) | Camera displacement (m) | Maximum camera basis-component delta |
|---|---|---|---|---|
| Gull Rest Beach | -59.972973, 785.180359 | 1.563169 / 1.566554 | 4.76837e-7 | 2.98023e-8 |
| Sluice Isle Twin Pumps | 906.622925, 2859.801514 | 93.197174 / 93.203163 | 7.62939e-6 | 2.98023e-8 |
| First Shore Welcome Beacon | 40.585953, 99.197525 | 23.505394 / 23.504841 | 1.90735e-6 | 0 |

Player displacement is exactly zero for all pairs. Camera displacements are below the 0.05m limit; basis component differences are below 1e-6. Per-frame camera snapshots report exactly matching FOV 70, projection 0 and keep_aspect 1 within every pair. These observations come from final settled/draw snapshots, not just requested camera settings.

## Limits and custody

The world remains live between captures. Recorded day hours vary slightly within each pair (largest difference about 0.000583 hour), and wind/creatures are not frozen; this is not a pixel-identical scene replay. The actual Gull stand is low, while Sluice and Welcome Beacon stand heights are above 6m; that does not establish the height distribution of every visible pixel. No image was opened or judged, no frame-time benchmark was run, and no visual-density/contact/terrain-appearance conclusion follows from these receipts.

Root separately verified the grass process had exited and the lock was clear before starting a separately authorized task. This reviewer does not independently assert current lock vacancy: one optional read encountered its later exclusive owner, and no retry or interference followed. The successful grass receipt is not reinterpreted as permission to inspect or disturb that new run.

Raw evidence hashes:

- Manifest: `dfabc721ee2aaafee90e924f9881ae2020a982229f6d6aab5f287cda2da00cf4`.
- Runner receipt: `6e37c796386c7a6219b9e6a754e10d0b4e09c0fbe206700d33088b64bc8e2dee`.
- Stdout: `3259d28e9d31975ab3fb7e0155ebb812c2d49c20f29fce84678b367211aa86c7`.
- Stderr: `b166b7545c9ec5377c4302715f5ace6a7496f6c77d78e5bddb6c8d5b81cf2c2f`.
