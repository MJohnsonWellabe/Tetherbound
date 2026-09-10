# WATER-HORIZON01 candidate

Date: 2026-09-10  
Scope: Water render horizon only

## Diagnosis

The Gull Rest open-water defect had two independent production sources at the
same sea-level height:

1. `WaterSurface` built a finite `PlaneMesh` exactly from Water's authored world
   bounds: 3,100 x 5,400 m, centered at `(350, 0, 2200)`. From the matched Gull
   Rest camera, its west edge was visible about 1,240 m away and projected near
   the middle of the image.
2. Water's Terrain3D material retained its default `FLAT` world background
   (`world_background == 1`). That supplies a flat background outside the baked
   terrain regions at Y=0, coplanar with Water's sea plane at the authored
   `sea_level_m == 0`.

The first extent-only diagnostic ran under the guarded wrapper from
`2026-09-10T06:05:49.5457974Z` through `06:07:05.7163837Z`, exited 0, and
captured the fixed production Gull Rest camera. It enlarged only the water
plane from 3,100 x 5,400 m to 17,100 x 19,400 m while holding the process,
camera, clock, player, height texture and authored height region fixed. The
visible yellow striped/angular horizon defect remained. This was a clean
diagnostic execution and a failed visual mechanism: water extent alone did not
remove the competing Terrain3D background.

The follow-up guarded 2 x 2 isolation ran from
`2026-09-10T06:14:25.6789447Z` through `06:15:43.0825760Z`, exited 0, completed
all eight requested frames, and reported no failures. At one frozen day pose it
captured:

| Frame | Water plane | Terrain3D background | Result |
| --- | --- | --- | --- |
| `gull-rest-open-water-ordinary-day` | finite | FLAT | Original striped/angular defect |
| `gull-rest-open-water-day-extended-edge` | extended | FLAT | Defect remains; extent alone fails |
| `gull-rest-open-water-day-background-none` | finite | NONE | Coplanar background is removed, but the finite water edge remains visible |
| `gull-rest-open-water-day-extended-background-none` | extended | NONE | The stripe/finite-edge combination is removed |

The manifest read back the original background enum as 1, NONE as 0, restored
the original background to 1, and restored the original water mesh and material.
It also retained the exact in-region depth expression and the same Terrain3D
height texture. This isolates the required mechanism as the combination of an
extended Water render surface and removal of Water's coplanar Terrain3D FLAT
background.

Evidence:

- `.artifacts/broad-visual-0910/runs/water-finite-edge-cause-first/`
- `.artifacts/broad-visual-0910/runs/water-background-isolation-first/`
- `shots/catalogue/water/broad-water-finite-edge01/manifest.json`
- `shots/catalogue/water/broad-water-background-isolation01/manifest.json`

## Production candidate

The candidate changes four production/test files:

- `scripts/world/water_surface.gd` derives a per-edge visual extension from the
  existing shipping camera contract, `camera_far_m + 500 m`. With the current
  6,500 m far clip this builds the proven 17,100 x 19,400 m plane. The mesh
  remains centered at Water's authored bounds and sea level.
- The water shader's `region` uniform remains the original 3,100 x 5,400 m
  terrain rectangle. The visual extension therefore does not enlarge or repeat
  the baked height domain.
- `shaders/water.gdshader` adds the default-off
  `outside_region_deep_water` guard. Water enables it, so fragments beyond the
  authored region use the existing `height_min` as deep ground while in-region
  fragments retain the prior texture depth expression. Default-off preserves
  the behavior of any other shader user.
- `scripts/world/water_world.gd::_build_materials()` sets only Water's
  Terrain3D material background to `Terrain3DMaterial.WorldBackground.NONE`.
  Authored Terrain3D regions, terrain data, water colour/tint, wave settings,
  fog, sky, camera, collision, navigation and world bounds are unchanged.

The candidate changes render geometry and depth sampling only. It does not
enlarge a collision surface or mutate current/traversal data.

## Verification

Root's focused guarded run `water-horizon-unit-first` executed from
`2026-09-10T06:27:23.2422387Z` through `06:27:28.3407025Z`, exited 0 with
`errors=[]`, and passed **4 tests / 25 assertions**:

- the existing mature Fresnel material bindings;
- the existing Water shape/tuning contract;
- the production plane extension, unchanged authored height region and enabled
  outside-region deep-water guard;
- the production Water Terrain3D factory's NONE background binding.

The frozen source hashes at that evidence point were:

| File | SHA-256 |
| --- | --- |
| `scripts/world/water_surface.gd` | `05202BFF155520A39A62969B8B1EC5AF804063E501E773628343363F3946FEA3` |
| `scripts/world/water_world.gd` | `A8F83D609431272AE70857E44A09493BA3BB230AF28F86205A24E7EA7EE47250` |
| `shaders/water.gdshader` | `C11010F3C8D50711E33EF78BCF62A1016EB4102C5DFA68929F7DA2D43C8B356C` |
| `tests/test_water_surface_material.gd` | `8CCCE58C2739258D2D5367DF29A5CFFBDD8ACE82AE958FEFF2B0FD34687E65A5` |

## Native evidence and limits

The production-on capture `water-horizon-candidate-first` ran clean from
`2026-09-10T06:39:08.0632708Z` through `06:40:25.0865809Z`; the matched
production-off control `water-horizon-control-first` ran clean from
`2026-09-10T06:40:25.8483217Z` through `06:41:37.6036123Z`. Both exited 0
with `errors=[]`; each produced five frames through the production Water scene
and Gull Rest capture route. The control read back the original 3,100 x 5,400 m
plane, FLAT background and disabled outside-region guard against the candidate's
17,100 x 19,400 m plane and NONE background.

`JUDGE-WATER-HORIZON01.md` then blindly preferred the candidate F03/F04 day and
night pair over the control F01/F02 pair. It found the candidate's distant water
meaningfully cleaner: the yellow-green daytime strip and blue-grey nighttime
equivalent were removed, producing a more continuous water expanse and a simpler
transition into haze. The remaining angular water depth/value boundary is still
plainly visible, especially in F04. The judge therefore supports a bounded
horizon-artifact reduction, not a complete water correction. Its separate bars
were key-art world **No**, same broad kind of game as Palworld **Yes, narrowly**,
and commercial visual quality **No**.

The judge also disclosed slight framing differences between pairs, so the
foreground is not a controlled comparison. The grass-normal candidate was
identical in both horizon pairs. That grass change was later withdrawn on its
own evidence and is independent of WATER-HORIZON01; these images do not claim
or define the final grass presentation.

## Opening continuity receipt

Root's guarded `water-horizon-opening-first` run executed from
`2026-09-10T06:47:03.5723602Z` through `06:48:18.8131526Z`, exited 0 with
`errors=[]`, and completed the production Water arrival-to-Pell-to-physical
lesson sequence. It used the real production arrival pose and Pell dialogue,
then recorded 64.486 m of physical swimming with no post-arrival fixture writes.

This was an isolated Water entry fixture: it did not earn or execute the
Stormwood-to-Water transition. It establishes that the retained render candidate
loads through the production Water scene and does not block that opening route;
it does not prove the cross-realm transition, combat, broader traversal feel,
visual quality, wave motion, temporal artifacts, or performance.

## Disposition

Retain WATER-HORIZON01. The exact 2 x 2 isolation, production material tests,
matched native pair, blind day/night preference and clean opening continuity
smoke support its narrow removal of the striped finite-edge/background artifact.
The angular water value boundary remains open and should not be described as
fixed by this candidate.

The canonical `scripts/world/build_water_terrain.gd` refresh ran clean at
06:52:16.138–06:53:28.951 UTC (`water-terrain-provenance-refresh-first`): exit 0,
no engine errors, 30 regions, height range -65..620 m. SHA256 comparison of all
31 existing `.res` files, including the surface-height image, found zero changes.
Only `data/terrain/water/manifest.json` refreshed its stale config/visual hashes.
The record was produced by the real builder, not manually stamped. Pre-refresh
hashes are preserved in `.artifacts/broad-visual-0910/water-pre-refresh-hashes.json`.
This reconciles bake provenance; it does not add visual or collision acceptance
beyond the checks above.
