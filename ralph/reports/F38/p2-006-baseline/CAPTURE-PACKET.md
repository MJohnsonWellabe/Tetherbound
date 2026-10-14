# P2-006 exact-sighting baseline capture packet

Status: source-only preparation. No native process, import, render, parser, CI, or PR was run. This packet captures the catalog’s four exact P2-006 sightings at High and Medium, for eight baseline frames total. It does not change source, create a candidate, or close the row. Frozen source: `06bedfa5082e6ea5dd425c9fc04ffd1d5ace84eb` (`tb/codex-visual-meadows`).

## Requested evidence

Capture each exact target below with `--times=day --views=close`, once at High and once at Medium:

| Catalog frame ID | Source location | Authored target XZ | View heading |
| --- | --- | ---: | ---: |
| `meadows__band3_the_river_lock__06__old_mill_crossing__day__close` | Band 3 debug-teleport spot `Old Mill Crossing` | `[-152, 4170]` | `-12.24°`, route-forward to the following authored spot `[-345, 5060]` |
| `meadows__landmark__village__day__close` | `map_landmarks.json: village` | `[10.5, -6]` | `116.14°`, route-forward to `road_gate` `[38.72, -19.85]` |
| `meadows__landmark__band1_trail_camp__day__close` | `map_landmarks.json: band1_trail_camp` | `[348, 919.5]` | `-24.42°`, route-forward to `band2_ranger_camp` `[-259, 2256.5]` |
| `meadows__landmark__band2_ranger_camp__day__close` | `map_landmarks.json: band2_ranger_camp` | `[-259, 2256.5]` | `-24.42°`, last-position route-forward rule in `phase2_capture_locations.gd` |

These headings are derived from the fixture’s `_capture_forward()` and `_route_forward()` logic because the four source entries have no authored `view_heading_deg`. The capture must retain the actual production-camera records; these calculations identify the intended direction but do not replace the runtime receipt.

For `close`, the fixture tries stand offsets `[5, 8, 12]` metres and lateral offsets `[0, -5, 5]` metres, in order, rejecting unsupported/blocked stands. Require the same first accepted `selected_stand_xz`, stand offset/lateral, player transform, camera transform, pitch, and spring length in each High/Medium pair. A mismatch is a missing matched frame, not a reason to relax the support check. Let the fixture choose the supported stand; do not hard-code a new camera or bypass its rejection rules.

## Source pins

Git object IDs below are exact Git blob pins under the frozen commit; the full commit pins the rest of the loaded scene and project. They are not SHA-256 values.

| File | Git blob |
| --- | --- |
| `tools/phase2_capture_locations.gd` | `663598fa0caf27fbb070e7c349169696ceef53a2` |
| `tools/lookdev_capture_bootstrap.gd` | `8c1859c4094c5bce3030080831810a67cf0a06c1` |
| `scripts/ui/graphics_prefs.gd` | `4483a445ee2fa1c72a0acfae63190b4acd301708` |
| `scenes/world/meadows_playground.tscn` | `3cbee594715800bffcde25e20492ea3bf0323379` |
| `data/config/debug_teleport_spots.json` | `4a542ae81cbbc178dada9abe5766782d90520c9b` |
| `data/config/map_landmarks.json` | `b040ae461b3949e63bece43b6c3df23a5840abb3` |
| `data/config/art.json` | `d806b08949ff0dbd6b61dd6ffd4fe5e589fd15c4` |
| `data/config/water.json` | `32341192f0171f681c4976dd2cf43515ad7399e3` |
| `data/config/terrain_playground.json` | `fb2804d8f388c59a746e84bd534465d6b02745e8` |
| `data/config/bands/band3_the_river_lock/props.json` | `1fbb2e2094dc144cba6af1d7863276435bf02ae1` |
| `data/config/bands/band3_the_river_lock/vegetation.json` | `bda6617f075e3c300d5efb4e341024ad13efe210` |
| `data/config/bands/band1_lower_meadows/props.json` | `8e6eaa4ca4745cfea67172deff5090ed4f1b2c2f` |
| `data/config/bands/band2_stone_and_root/props.json` | `45e21a94fded4e621e9285127c741a0eb89ec46a` |
| `data/config/village.json` | `4aff7e1df9bbbc2525079036b743a828fa1bb119` |
| `data/config/village_npcs.json` | `67a75d9dfe7a07d495b578570d0d934420a2dbcc` |
| `scripts/world/water.gd` | `2a298ce3bf74356d47526eed09cfa1158cd676f8` |
| `scripts/world/water_vegetation.gd` | `a03a346f27038bfd3f75a71770a8aea22f4528f4` |
| `scripts/world/stonewater_reach.gd` | `463df9e39215f2e92882509f32c5c27e57716622` |
| `scripts/world/mill_crossing.gd` | `57a1dfdc870fe108bc586a82aa7ce7c4f995eeb0` |
| `scripts/world/props.gd` | `dc869d0360146644789422d3a420904acba3396e` |
| `scripts/world/building_prefabs.gd` | `c9d6c7a46015be85fca305c050115a2b9a18c9c6` |

Key directly visible installed assets, also pinned by the same commit:

| Asset | Git blob |
| --- | --- |
| `assets/vfx/shaders/flowing_water.gdshader` | `0bf5920c1db193ff41e253afdd9bfa1a147aed9c` |
| `shaders/mill_race_water.gdshader` | `a27ebbf05a119cd0053e594a62b77cbbd999ca51` |
| `assets/environment/stylized_nature/Grass_Wispy_Tall.gltf` | `2821e49904bc1e7c9fe3b7b7b39f1da1e2e518e7` |
| `assets/environment/stylized_nature/Grass_Wispy_Tall.bin` | `b747e424e0975256ec48b3e0ec83a01981b1be44` |
| `assets/environment/stylized_nature/Grass_Wispy_Tall.gltf.import` | `36e4d3da26cda4bdd70e8dc9cbbd0563df4cb303` |
| `assets/environment/stylized_nature/Grass_Wispy_Short.gltf` | `9e73049370b967ee6bba43fa5c60be6bfead9a0f` |
| `assets/environment/stylized_nature/Grass_Wispy_Short.bin` | `bb62b3768f54b700c1334980aa57c5543f447c56` |
| `assets/environment/stylized_nature/Grass_Wispy_Short.gltf.import` | `3f4ab07423a18e400e677fd7a22a9f7ee164b6e4` |
| `assets/environment/stylized_nature/Bush_Common.gltf` | `46023123dbdfe3e0b47f4e9408c070ffa79f3f3d` |
| `assets/environment/stylized_nature/Bush_Common.bin` | `c594b0091a4644b0236e287cf43cb1c94a8825c7` |
| `assets/environment/stylized_nature/Fern_1.gltf` | `2be91c742acf0c19f6b5a5195ac5070e9dbd56b2` |
| `assets/environment/stylized_nature/Fern_1.bin` | `8712382dcdcf5a335e0bba000060acf285e918a0` |
| `assets/environment/stylized_nature/Plant_1_Big.gltf` | `ce9aef6b78590223458276a888f28ca8c9ee9874` |
| `assets/environment/stylized_nature/Plant_1_Big.bin` | `cf8ddd39e929479602801f2e4ba7e022bbf7f904` |

## Native-supervisor launch plan

Use only the prepared launcher in `run_p2_006_capture.ps1`, following `RUNNER.md`. It runs one preset at a time through the root native lease and adds `--preset`, `--source-commit`, a fresh output path, isolated user-data home, and the four exact full-identity subset arguments. The raw Godot command must not be launched directly. High is first; Medium follows only after High has a clean terminal receipt and retained manifest. Source remains exactly `06bedfa5082e6ea5dd425c9fc04ffd1d5ace84eb`; no candidate or source edit is part of this packet.

The supervisor records the executable/version, source and canonical blob pins, exact argv, UTC start/end, exit code or stop reason, output/home/log paths, resource headroom, manifest hash, and each frame hash. It refuses reused output, home, or receipt paths. Preserve raw receipts and manifests before any cleanup.

Budget: eight 1920×1080 JPEGs plus two manifests should occupy under 50 MB; reserve 100 MB for final outputs and logs. Temporary import/shader/cache use is not bounded by the still count, so measure it in the supervisor and retain at least 12 GiB free on C: throughout; stop if the supervisor predicts crossing the 11 GiB floor. The comparable P2-034 two-frame Low run took about 96 seconds including world boot; four exact frames at each of two presets are estimated at 5–10 minutes plus first-use import/cache work. Treat this as a planning estimate only.

No ≥200 rendered-frame or FPS requirement applies to these catalog stills. The existing fixture waits 24 physics frames after world boot; for each sighting it waits 20 after arrival, 45 for population, 12 while pinning/settling the requested time, 4 for pose, then `RenderingServer.frame_post_draw`. It records a still rather than a performance sample. Do not add an unsupported `--frames=200` argument or infer performance acceptance from this packet. The fixture explicitly requests clear weather before capture but does not write an observed-weather field to its manifest; these are day-only catalog receipts, not a weather comparison.

## Validation and acceptance of the baseline packet

For each preset, accept the run only if the supervisor records a clean terminal result and the manifest says `complete: true`, `failures: []`, `seed: 2042`, `requested_times: ["day"]`, `requested_views: ["close"]`, and resolution 1920×1080. Verify `graphics_capture.source_commit`, `.preset`, `.renderer`, `.resolution`, and `.graphics_config_sha256` match the frozen source, requested High/Medium preset, `forward_plus`, 1920×1080, and pinned `art.json`. Require the exact four planned frame IDs above. Verify all eight images exist, are non-empty and 1920×1080; preserve each SHA-256, each manifest SHA-256, and the full native receipt. Failures, rejected-only sites, missing IDs, fresh-output violations, renderer/resolution/source mismatches, or supervisor stops remain missing evidence.

For a later candidate, rerun the same eight IDs and preset matrix from an explicitly pinned candidate commit and compare the per-frame production player stand, camera/rigger transforms, view heading, time, selected offset/lateral, and resolution. The current packet has no candidate source commit and creates no A/B claim.

This packet fills only the baseline capture request. P2-006 stays open at impact 36 until each exact view has matched baseline/candidate High and Medium evidence and blind categorical review. The village and camp captures are necessary because the catalog’s defect includes settlement activity; the prior mill-only blind pair cannot substitute for them.
