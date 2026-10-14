# P2-003 Dummy candidate capture packet

Status: native-ready; no capture has been run from this packet. Keep both candidate flags OFF outside the candidate pass. The native engine lease stays with the root operator.

## Frozen source and fixture identity

Run both conditions from the same pushed source checkout and renderer setup. The only condition change is `hall_occupation.p2_003_training_dummy_candidate_enabled` (`false` for baseline, `true` for candidate). Keep `hall_occupation.p2_003_unlit_candidate_enabled` false in both runs. The fixture's `--f38-candidate` argument marks the manifest; it does not toggle game config.

SHA-256 values for the source and installed assets:

| File | SHA-256 |
| --- | --- |
| `data/config/stronghold.json` | `EC9FEF86606EE5956F9F9C1B9BB467962C284457197E983CDEF9AD2F413A4F8F` |
| `scripts/world/stronghold.gd` | `5AA05ED3730C6C1E4F49BA69AF91C2794B0DAED46349A92EFAB23C7D195B85DF` |
| `tools/capture_f38_matrix.gd` | `7F9B6C68AEF2D03323D184193212C8E2DD4AD30AB43E0A43A82C9284E92020E1` |
| `tools/phase2_capture_locations.gd` | `C11525A4F37B4F78CCAFE2FFE122186E5FD7288FB4BFD685AA00BD68AE42A359` |
| `ralph/reports/R2-F38/capture-definition.json` | `E18A7A004277E5B5866C241A17AD0021F9614F31ABF178F67EB2A02BC04B1E14` |
| installed `Dummy.gltf` | `18AF9C715320152C16B9D0DCA97046DA7EF781874CE6C2A1B2DBE5129208FE75` |
| installed `Dummy.bin` | `A8C0897C085B0CEE9EF3F7F2F88BC37FD29D9CDE1CC281F45D936F620ADB98C1` |
| installed `Dummy.gltf.import` | `21C316F326FAF6100CE87B7757F9C7E507FC5B80D0214135025E5D987DB4EEF2` |
| installed `WeaponStand.gltf` | `0D015410818A3524EEF97EC7451218F94AB10C36F8BE6973808B0F112ECB2340` |
| installed `Sword_Bronze.gltf` | `6EF9F1BF5AD0FAFF180D19C18FBC861A37B2A93400BF308FC203F2ADF4F42F14` |
| `scripts/build/creature_bed.gd` | `66034098A9D6C5654B82D6E95DD93C1338A04A37BDFAC8150E86E40EA94C7B94` |

## Footprint check

The installed Dummy import has root scale 1.0; the dressing candidate has unit scale and yaw 110°. The three GLTF primitive accessor bounds combine to local `x[-0.4041,0.4045]`, `y[-0.0029,1.8598]`, `z[-0.2921,0.2925]` m. Its rotated ground footprint is `x±0.413`, `z±0.480` m, so the authored center `(4.4,62.5)` yields world bounds `x[3.987,4.813]`, `z[62.020,62.980]`.

| Nearby constraint | Measured geometry | Candidate clearance |
| --- | --- | --- |
| Recovery bed | Procedural bolster ellipse at `(-5,68)`, radii `2.40 × 2.05` m; conservative axis-aligned bounds `x[-7.40,-2.60]`, `z[65.95,70.05]` | At least 7.2 m from the conservative rectangle; the ellipse itself is farther |
| WeaponStand | Installed bounds `x[-0.6931,0.6931]`, `y[-0.0034,1.1059]`, `z[-0.4947,0.4884]` m, authored at `(-6.6,70.6)` with yaw 90° | Over 12.2 m between ground-plane bounds; Sword_Bronze is co-located |
| Tether-approach room | Interior `x[-8,8]`, `z[55,73]` m | Nearest wall is the east wall at 3.19 m; north/south walls are over 7.0 m away |
| Passage lane | `x[-2.6,2.6]` m | 1.387 m from the lane's east edge to the Dummy bounds |
| Warden clear ring | Center `(0,90.2)`, clear radius 11 m | Nearest Dummy bound is over 27 m from center, leaving over 16 m outside the ring |

These are geometric source checks only; they establish no collision behavior or visual acceptance.

The matching retained OFF baseline images were captured from source `122682ad`. Their byte hashes and the A/B mapping are in `full-frame-sha256.json` and `frame-crosswalk.json`; selected IDs below match the fixture definition exactly. For a same-source causal comparison, also capture the OFF condition from the frozen source SHA before enabling the candidate.

## Exact comparison rows

Select only these four rows from each manifest. The existing fixture produces the full selected-site/day+night matrix, including additional views and weather combinations; keep those receipts in the manifest and deliver these exact IDs for the P2-003 blind comparison.

| ID | View | Time | Weather | Retained OFF files |
| --- | --- | --- | --- | --- |
| `band5_stronghold_approach_0__day__clear__approach` | approach | day | clear | R01-A/B |
| `band5_stronghold_approach_0__night__rain__approach` | approach | night | rain | R02-A/B |
| `band5_stronghold_approach_1__day__clear__detail` | detail | day | clear | R03-A/B |
| `band5_stronghold_approach_1__night__rain__detail` | detail | night | rain | R04-A/B |

## Run recipe

Use the existing `tools/capture_f38_matrix.gd` only. Keep the ordinary production camera, fixed seed `2042`, 1920×1080, production-resolution export, and `High` / `Medium` presets. Run each preset separately so the manifest records its selected preset and actual renderer. Set the config flag before launch, then restore it to false after all runs.

Example user-args for each pass (replace preset, output directory, and final marker as specified):

```text
--f38-preset=High --biome=meadows --seed=2042 --times=day,night --subset=band5_stronghold_approach_0 --subset=band5_stronghold_approach_1 --output=res://ralph/reports/F38/p2-003-rescore/candidate-off-high --f38-baseline
```

Repeat with `--f38-preset=Medium` and output `candidate-off-medium`; then set only the Dummy flag true and repeat into `candidate-on-high` / `candidate-on-medium`, changing the marker to `--f38-candidate`. Preserve each fresh output directory and its `manifest.json`. Do not use the existing `full-resolution` folder as output. The launch must request 1920×1080 and the renderer expected by the saved High/Medium preset; reject any manifest where frame ID, preset, renderer, resolution, seed, time, weather, or candidate marker differs.

The fixture also captures other views and weather combinations for these selected sites and times. Deliver only the four table IDs per preset and condition to the blind reviewer, with A/B order randomized and the condition mapping withheld. Do not treat this debug-travel matrix as earned-route, combat, or performance evidence. The Dummy remains OFF by default until blind full-bar review supports enabling it.
