# Gull Rest lookout — installed-asset replacement proposal

Root disposition17:38 UTC: **held after Wave17**. The second form is more
substantial and visible at night, but independent source-blind image review
finds a new pale flat-base/grass-contact drawback. No unconditional improvement
or commercial acceptance. Two substantive form rounds are exhausted; preserve
both candidates and evidence, with no third geometry/material/camera tuning.

Date: 2026-09-09  
Status: approved config-only form candidate implemented and focused-tested; no render yet

## Visible defect and bounded response

Wave16 accepts that the current feet meet the hill and that the landmark is taller
than the trainer, but describes the exposed object as a simple timber stand. The
canonical pair supports that attribution: the four long `Prop_Support` braces cross
into one dominant X silhouette, while the upper platform and flame sit behind the
ordinary instruction banner. Adding more posts or changing their colour would preserve
the same placeholder construction language.

The strongest installed-only replacement is a compact, closed signal-tower shaft made
from the same textured Quaternius Medieval family already used by the platform. It
keeps the existing site centre, platform elevation, floor, signal flame/light, route
clearance and 2.5 m declared radius. It does not add an interior, stairs, entrance,
interaction or traversable route.

## Recommended installed modules

### `assets/buildings/quaternius_medieval/Wall_Plaster_WoodGrid.gltf`

Offline glTF accessor bounds are:

- minimum `(-1.000000, 0.000000, -0.314035)`;
- maximum `(1.000000, 3.122689, 0.092447)`;
- size `(2.000000, 3.122689, 0.406482)` m.

The file carries real `MI_WoodTrim` and `MI_Plaster` surfaces with the installed
WoodTrim and Plaster base-colour, normal and roughness/ORM textures. Four copies form a
square shaft, one per side. Each wall is 1.5 scale across its width, remains 1.0 through
its thickness, and uses the existing terrain-foot-to-common-platform scaling seam only
on Y. At the current approximately 4.4 m platform rise this is about 1.41 Y scale, so
the module remains recognizable timber-framed plaster instead of becoming a stretched
post.

With wall origins 1.35 m from site centre and the asymmetric local-Z bounds accounted
for, a wall occupies at most about 1.44 m along its outward axis and 1.50 m laterally.
Its far corner radius is about 2.08 m, inside the unchanged 2.5 m site radius. Each
wall receives collision from its final transformed visible AABB, replacing the four
brace collisions rather than adding another collision layer.

### `assets/buildings/quaternius_medieval/Balcony_Cross_Straight.gltf`

Offline glTF accessor bounds are:

- minimum `(-1.000000, -0.105087, 0.897970)`;
- maximum `(1.000000, 1.124799, 1.104253)`;
- size `(2.000001, 1.229887, 0.206283)` m.

It carries the installed textured `MI_WoodTrim` material. Four rotations at the common
platform centre provide one modeled balcony edge per side. At X/Z scale 1.5 its far
corner radius is about 2.23 m. A modest 0.9 Y scale gives a 1.107 m rail/support height,
keeps the existing signal flame above the rail line, and stays close to the current
waist-high safety silhouette. The unchanged `Floor_WoodDark.gltf` remains underneath;
the new balcony module replaces the four isolated fence pieces.

The existing floor's 1.65 scale has a 2.33 m corner radius, so it remains the largest
rendered footprint. The whole proposal therefore fits the existing 2.5 m declaration.
Because site centre and declared radius do not change, the previously calculated 9.32 m
clearance beyond both adjacent route envelopes and all actor/pickup separations remain
unchanged.

## Why this is preferable to the installed one-piece tower

`assets/buildings/quaternius_castle/Watchtower.obj` is a real complete model and its
offline OBJ bounds are compact: `1.493544 x 3.078559 x 1.493544` m. The roofed variant
is `1.493542 x 3.836871 x 1.493543` m. Either could fit geometrically at roughly 2.25
scale. Both have zero texture coordinates. The first uses only flat `LightWood`; the
roofed model uses only flat `LightWood` and `Celing`. Repository evidence already
records the roofed one as the rejected beige-hut module. Choosing it would exchange the
crossed-stick defect for an established flat-placeholder material defect, so neither is
recommended.

The proposed textured wall and balcony modules supply broad construction mass, visible
joinery and a legible platform edge using a coherent installed family. From the
unchanged stand-19 view, the tower shaft should remain readable below the banner even
when the top is occluded. This is a form/composition correction, not texture tuning.

## Exact implementation and proof boundary if approved

The bounded source change would edit only:

- `data/config/water_gull_rest_signal_site.json` — replace support/rail module rows and
  record their transforms;
- `tests/test_water_gull_rest_signal_site.gd` — assert installed accessor/render bounds,
  actual final footprint, four finite terrain feet/common top, and collision equality;
- this report and the existing Gull Rest source report.

No production script change is required: the existing site helper already accepts a
model path, X/Z scale, yaw and offset for each terrain-fitted support, then derives its
collision from the final visible AABB. Its raised-piece path already accepts the same
transform data for rails. `scripts/world/water_gull_rest_signal_site.gd`,
`scripts/world/water_world.gd`, the production mount, site centre, floor, signal,
lighting, route, terrain, actor, encounter, pickup and progression data remain frozen.
One focused initialized test must measure imported bounds and actual terrain contact
before any world capture. If it passes, one mature catalogue stand-19 day/night pair is
the visual proof; no custom Gull capture helper or physical-route claim returns.

The ordinary First Shore instruction banner will still overlap the upper platform in
that catalogue view. This proposal does not move the camera, clear HUD state or claim
to solve that separate evidence limitation. Independent review must assess the visible
shaft and any exposed signal detail without treating banner occlusion as repaired.

## Implemented source boundary

The approved candidate changed only the site config and its focused test. The four
support rows now use the wall-grid model at the measured transforms; the four raised
edge rows now use the cross-balcony model. Site centre, 2.5 m radius, 4.4 m platform
rise, route segments, floor, torch and light are byte-for-byte unchanged within the
config. Both production scripts and the Water mount remain unchanged.

- config SHA-256:
  `564C9C3A501E796BFB41D2FFE8A3AB4D030C470A721D3C9DC2C3148AF43AB803`
- focused test SHA-256:
  `0D7A50476209FDAF6C56C6B54A75CD7B6ED905EABA8B8DB167E280C270DC442D`
- initialized child SHA-256:
  `C0236B179547D9FBC1C51CA26E947889C5A9676AAC754022E548FD43ECB8F605`

The initialized fixture's sloped ground function produced wall feet at 21.78140,
21.77060, 21.74225 and 21.80975 m and a shared top at 26.20975 m. Resulting visible
and collision heights are 4.42835, 4.43915, 4.46750 and 4.40000 m. Every wall bottom
equals its sampled foot, every top equals the platform, and each collision size,
centre and yaw equals the final transformed wall AABB. The imported wall bounds match
`2.0000005 x 3.1226888 x 0.4064820` m. The imported balcony bounds match
`2.0000007 x 1.2298867 x 0.2062830` m; all four balcony bottoms equal the platform.
The actual complete rendered footprint is greater than 2.3 m and no more than 2.5 m;
the unchanged floor's calculated 2.33345 m corner radius remains the expected maximum.
Both route-edge clearances therefore remain above six metres without changing the
declared envelope.

The first focused attempt is retained as a fixture failure despite process exit 0.
`run_tests.gd` invoked the method during SceneTree initialization, so
`Engine.get_main_loop()` was null. The raw output contains one `SCRIPT ERROR`, one
leak warning and one resources-in-use error; only 26 assertions executed before the
parent incorrectly printed the second method as okay. It ran from
`2026-09-09T17:22:57.5291666Z` to `17:22:59.2281670Z` and returned Godot count to zero.

The first correction used an artifact-only deferred SceneTree probe. It completed 86
assertions with zero failures from `2026-09-09T17:24:17.3744338Z` to
`17:24:19.1961726Z`, exit 0, Godot before/after 0, but did not repair the standard test
entrypoint. It is retained as intermediate evidence rather than the final result.

The final correction checks in
`tests/helpers/gull_rest_signal_site_initialized.gd`. The discovered unit invokes that
child with the repository's established `OS.execute` pattern, parses its structured
result and checks its retained log for engine errors. The standard `run_tests.gd`
entrypoint completed 2 tests / 31 parent assertions / 0 failed; the child result records
the complete 60 initialized geometry assertions / 0 failures. It ran from
`2026-09-09T17:30:12.9902364Z` to `17:30:17.2205316Z`, exit 0, Godot before/after 0,
at 55.90% system commit and 251 processes. Console, stderr, child and engine logs have
zero `ERROR`, `SCRIPT ERROR` or `WARNING` lines. Evidence paths:

- `.artifacts/gull-rest-lookout-form-test-0909` — retained failed fixture;
- `.artifacts/gull-rest-lookout-form-test-0909-final` — clean intermediate
  artifact-only initialized fixture;
- `.artifacts/gull-rest-lookout-form-test-0909-ci-entrypoint` — clean standard parent
  plus checked-in initialized child;
- final console SHA-256:
  `EB6CE9B1C2CA3FD2902562D9720822D5A3B0AEFAB44ADB6ADF5B2330B8F3C2C7`;
- final stderr SHA-256:
  `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`;
- final child-log SHA-256:
  `5A058672A1F089BA6B601E64F421FE94DA98618A0E3F82DA6380A42713A6BCF6`;
- final engine-log SHA-256:
  `A248651F09AA6830BD65DF423ECDCFC9A0003FB23FC00E0DF3C6138516DA875A`.

This establishes bounded initialized geometry and collision behavior. It is not visual
acceptance.

## Frozen mature catalogue pair

The one authorized mature stand-19 run used the unchanged catalogue camera and
ordinary gameplay HUD. It ran from `2026-09-09T17:32:37.9546309Z` to
`17:32:57.5574099Z`, wrapper exit 0 after retaining the process handle and calling
`WaitForExit()`. All owned PIDs (`13932`, `4120`, `9436`, `13540`) were terminal and
global Godot count was zero at release. The guard did not trigger; peak system commit
was 63.212% and peak process count was 261.

`shots/catalogue/water/20260909T173239Z/manifest.json` records `complete=true`, exact
planned/captured count 2/2 and `failures=[]` for:

- `water__gull_rest__19__gull_rest_signal_spire__day`;
- `water__gull_rest__19__gull_rest_signal_spire__night`.

Both PNGs are nonempty 1280x800 production-camera frames with distinct hashes. The
manifest records the authored destination/player XZ `(-72.615,899.886)`, resolved
ground 28.85113 m and production `CameraRig/Camera3D`. The raw streams contain zero
`ERROR` or `SCRIPT ERROR` lines. They contain seven known warning events, duplicated
between wrapper stderr and `engine.log`: one interpolation deprecation plus six
Terrain3D no-mipmap warnings.

- output manifest SHA-256:
  `07234AA8F1E69154660C9F60E739AED71594D03BCA9D18483826B712E12195CA`;
- day PNG SHA-256:
  `491790ADED3318CC0C078CD0ABA3E168EC2FACE5E2642ED04A8FD42CE4282551`;
- night PNG SHA-256:
  `E765F98027221217DFDE755BB468CF809B7290243CF0891787877B4B04E81710`;
- engine-log SHA-256:
  `B617AE7F3634A960E87DB6838ED7F509DAE7362BEE9E54B674F26FC5BB83DEEF`;
- guarded receipt SHA-256:
  `009715F4B3454FC44433D944A66D3998F6329A086CF6BB104350C568EFDC97BD`.

The pair shows the frozen installed wall/balcony form. The existing First Shore
instruction banner still covers the upper part of the landmark in both frames, so the
pair cannot establish an unobstructed view of the platform or signal. No camera, HUD,
geometry or source was adjusted during capture. The candidate is frozen for independent
image review; this report makes no visual acceptance or route-traversal claim.
