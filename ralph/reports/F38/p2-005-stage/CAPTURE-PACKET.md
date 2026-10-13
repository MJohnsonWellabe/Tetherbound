# P2-005 authored-colony candidate packet

Status: source candidate is OFF and native-ready for an A/B look-dev pass. No engine, import, render, or export was run. The frozen runtime source is commit `5bb435c2ded96ecbec6a4a762e231ef7d7fabac0`.

## Change isolation and source pins

Use the same source commit and run settings for both conditions. Change only `data/config/props.json:p2_005_groundcover_candidate_enabled` from `false` to `true`. Keep `stronghold.json:p2_003_unlit_candidate_enabled` and `p2_003_training_dummy_candidate_enabled` false in both runs. The fixture's `--f38-candidate` argument marks the manifest; it does not toggle the config.

| Source | SHA-256 or exact Git blob |
| --- | --- |
| Runtime source commit | `5bb435c2ded96ecbec6a4a762e231ef7d7fabac0` |
| `data/config/props.json` | `0AE6728111BCAF4DE59C4F26644F9AC2746C564287E030CBD7D04D4237FF93DE` |
| `scripts/world/props.gd` | `753BD274FCAD9816621F46E5FDB36E280D0AFDDF4A66FE3FFB85F0E5328849C4` |
| `tools/capture_f38_matrix.gd` | `7F9B6C68AEF2D03323D184193212C8E2DD4AD30AB43E0A43A82C9284E92020E1` |
| `tools/phase2_capture_locations.gd` | `C11525A4F37B4F78CCAFE2FFE122186E5FD7288FB4BFD685AA00BD68AE42A359` |
| `ralph/reports/R2-F38/capture-definition.json` | `E18A7A004277E5B5866C241A17AD0021F9614F31ABF178F67EB2A02BC04B1E14` |
| `data/config/village.json` | Git blob `4aff7e1df9bbbc2525079036b743a828fa1bb119` |
| `data/config/building_prefabs.json` | Git blob `4cec3d717cf251df6df2ece991ef58f4121dd754` |
| `data/config/terrain_playground.json` | Git blob `fb2804d8f388c59a746e84bd534465d6b02745e8` |

Installed mesh sources are pinned below; all four `.gltf.import` files use `apply_root_scale=true`, `root_scale=1.0`.

| Mesh | `.gltf` SHA-256 | `.bin` SHA-256 | `.gltf.import` SHA-256 |
| --- | --- | --- | --- |
| `Flower_3_Group` | `1DC92301637CF9C9456236324356AD3B85F6E0BA5E1F8A8B5B577549AB3C9C5C` | `5AB387DD3D6FE181DF3AF4EEAC4DF85533E4C27E77545AE39A61E0C2AAAAB248` | `EF27CA80204287288E14C7DAEC7B5157CE90215E8AD2B56AB9672D1EE78B9E08` |
| `Flower_4_Group` | `626E920E94761132AA01C091E6637023FC71A65909C600054A9AEFCD0584EE47` | `3AC30B4C9EAA5078A17C061AA29E2E9618CC9EB58CB6D5D2AB0C07FA0B851AE1` | `EFB4C40C26F2D1056BB586CDCE5A1957923668BD417AA491850A6AC16B43A0F6` |
| `Clover_1` | `207BAEAD664921225281B0E9BD6C033E796ABE5EC9C7FC996FB171593C09BB02` | `788FABAFFC3F8F2825AD88399BD4725D8BC397225D93D00926C3223FDEE9516B` | `DB7993931FB1F7B8E7AE7411B7823B21FB2CD4F287366BB469FE8CD1240F2734` |
| `Clover_2` | `9D5E1000A7754863E4FDDE7AA2E223882B054E9B7448710AF96823A68CAD4D9B` | `EEABCA833167F3E20D6F157B3E7885E0ADE908B1F1D61909812076AD52D44047` | `95EE9681FCF4B68E35DBB7FB31BADCAFAD206655ED8263702D8DF4CAC98B8CDE` |

## Bounds and clearance

GLTF accessor bounds were combined per model, scaled by each authored uniform scale, then rotated by its yaw. The production prop placer samples ground height at each authored center. With no extra sink, the lowest mesh point sits only 1.03 cm or less below that sample; all candidate plants top out at 0.45 m. The placement code forces `visual_only`, so these entries add no physics collider.

| Model | Unit-scale local bounds `(x,y,z)` m | Scale | Scaled base / top |
| --- | --- | ---: | ---: |
| `Flower_3_Group` | `[-0.614,0.875] × [-0.035,2.020] × [-0.802,0.789]` | 0.22 | -0.008 / 0.444 m |
| `Flower_4_Group` | `[-0.931,0.849] × [-0.057,2.430] × [-0.636,0.731]` | 0.18 | -0.010 / 0.437 m |
| `Clover_1` | `[-0.502,0.294] × [-0.013,1.132] × [-0.400,0.364]` | 0.35 | -0.005 / 0.396 m |
| `Clover_2` | `[-0.502,0.349] × [-0.002,1.261] × [-0.472,0.364]` | 0.35 | -0.001 / 0.441 m |

The village main street runs at `z=14`, width 5.2 m, with a 1.5 m shoulder. The candidate bound nearest the road is `z=20.857`, 2.757 m beyond the paved-plus-shoulder envelope edge at `z=18.1`. The closest neighboring authored building is Tam's Workshop at `(26,26)`: its exact recipe collider bounds are `x[21.85,30.15]`, `z[21.15,30.85]`; the nearest plant bound is 3.867 m away in X, with no overlap. The other two colonies are at least 5.57 m from neighboring north-row house colliders. The green walk is over 4.1 m beyond its shoulder at the nearest plant. Terrain height and visual fit still need native review.

The three colonies are centered near `(35,21.7)`, `(53,21.7)`, `(71,21.7)` in the gaps between north-row houses. They contain twelve low pieces, four per colony, with unequal positions and rotations. This is a local village treatment only; it is not a fix for all three regional P2-005 sightings.

## Capture recipe

Use only the existing `tools/capture_f38_matrix.gd` fixture at 1920×1080, seed `2042`, one site (`village_road` at `[63,14]`) and High / Medium presets. Run each condition and preset into a new output directory. The fixture emits 16 rows per run (two times, two weather states, four views); select these exact matched IDs for blind review:

- `village_road__day__clear__approach`
- `village_road__day__clear__detail`
- `village_road__night__rain__approach`
- `village_road__night__rain__detail`

Example user-args for the OFF High pass:

```text
--f38-preset=High --biome=meadows --seed=2042 --times=day,night --subset=village_road --output=res://ralph/reports/F38/p2-005-stage/off-high --f38-baseline
```

Repeat as `off-medium`, then turn only the P2-005 flag on and run `on-high` / `on-medium` with matching presets and `--f38-candidate`. Preserve each fresh output directory and manifest. Record actual renderer, preset, output resolution, config hash and candidate marker; reject any mismatch. Randomize A/B order and withhold the condition mapping from the reviewer.

This packet reviews village-shoulder presentation only. The row's exact regional catalog sightings remain unmatched and still require their own matched High/Medium samples and blind categorical review:

- `meadows__band5_stronghold_approach__09__stronghold_approach__day__approach`
- `meadows__band2_stone_and_root__04__the_burrow_warrens__day__approach`
- `meadows__band3_the_river_lock__06__old_mill_crossing__day__close`

No impact, score, or status change follows from this source candidate or diagnostic packet.
