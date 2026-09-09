# Meadows Relay gate presentation — 2026-09-09

## Scope

This round replaces only the Tether Relay entrance's visible three-box gate
with an installed castle-family arch. The existing two jamb colliders and
lintel collider, the 6.8 m traversable opening, route, progression, ground,
weathered masonry material and Team Tether material remain unchanged.

The retained before evidence is
`shots/catalogue/meadows/round-camera-20260909T011407Z/meadows__band3_the_river_lock__05__the_tether_relay__day.png`.
Its entrance is a pair of rectangular piers under a rectangular lintel. This
matches `ralph/reports/audit-resume/JUDGE-MEADOWS.md`'s finding that the relay
gate reads as giant rectangular blockout.

## Geometry-derived fit

The installed asset is
`assets/buildings/quaternius_castle/WallEntranceBricks.obj`, already used by
the project's castle/arch family. Its actual imported geometry measures:

- AABB: 1.536070 m wide, 1.549451 m high, 0.559213 m deep.
- Floor jamb edges: x -0.445377 and +0.445379, for a 0.890756 m aperture.
- Centre crown: y 0.987536 above floor y -0.001898, for a 0.989434 m open height.
- Surface 0 `LightRock`: broad masonry. Surface 1 `DarkRock`: raised brick detail.

`tether_relay.gd` derives the fit from those vertices. The 6.8 m collision
opening plus 0.02 m clearance on each side produces:

- scale `(7.678871, 5.614892, 4.649391)`;
- visible aperture 6.84 m wide, so mesh stone cannot intrude into the existing
  traversable opening;
- visible crown height 5.555565 m;
- outer presentation 11.795283 m wide, 8.7 m high and 2.6 m deep;
- 0.297641 m of outer shoulder overlap per side past the old 11.2 m envelope,
  so the arch meets the retained wall runs without a misleading daylight gap.

The arch's level sill is placed at the lowest of the same centre and two jamb
terrain samples used by the old gate. This may embed a jamb slightly into the
slope, but it prevents either jamb floating. The old pier/lintel/faction-band
visuals are built only when the model is missing or its aperture cannot be
measured; a valid arch never layers in front of the old boxes.

Surface 0 reuses the relay's weathered stone shader. Surface 1 reuses the
existing Team Tether oxblood material.

## Verification

Focused command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . \
  --script tests/run_tests.gd -- --only=test_tether_relay_gate_presentation.gd
```

Result: **1 test, 15 assertions, 0 failed**. The test reads the installed OBJ,
asserts both named surfaces and measured aperture, derives the configured fit,
and guards clearance, authored height/depth and wall overlap.

One preliminary real-world location run was used before the final route proof:

```text
Godot_v4.7-stable_win64_console.exe --path . --rendering-driver opengl3 \
  --resolution 1280x800 --script tools/_capture_locations.gd -- --only=06-relay
```

Result: **4 static frames written, 0 failed**. This tool teleports between
stands, so these frames support only presentation comparison and do not prove
traversal. Raw output retained three existing
approach-camera warnings where the capture harness found no collision under
its analytic seat points `(339,3777)`, `(336,3780)` and `(342,3772)`; it used
its documented analytic fallback and still wrote the exterior frame. The
other three relay stands did not report this warning.

This preliminary run was launched directly after another lane reported its
renderer terminal, without a root lease grant and without the mandatory
resource guard. The Codex wrapper retained session ID 70351 and about 59.6
seconds of raw tool output, but it did not return an OS PID set, exact process
start/end UTC or a guard receipt. The image writes at `16:09:41Z` through
`16:09:43Z` only bound its shutter time. It remains static comparison evidence
and is not promoted into route proof.

Evidence:

- `shots/locations/06-relay-approach-day.png`: exterior gate face and the real
  entrance route. The opening remains visibly unobstructed, both jambs seat in
  terrain, and the arch shoulders meet the wall.
- `shots/locations/06-relay-road-day.png`: reverse/player route view. The arch
  is readable from inside the yard and no old pier/lintel facade remains
  visible behind it.
- `shots/locations/06-relay-standing-day.png`: player-height yard context.
- `shots/locations/06-relay-apparatus-day.png`: the gate remains part of the
  wider relay composition without competing with the apparatus.

Neutral preliminary frame hashes for independent image-only critique:

- `06-relay-approach-day.png`: `3F054B325A0AACE6D5E64BD58F2586EA5B864D95D416F8C968AA5230E2281C9B`
- `06-relay-standing-day.png`: `5B02D6DF24930759A31E88D09DFD9A08E169EB822B0DFB53EFD47732A804FDBB`
- `06-relay-apparatus-day.png`: `82D547031C6100BCA75DB68ABC05F2FF82D9FF1D9C3EF92B1D29571A736EE235`
- `06-relay-road-day.png`: `8955C2769EA839A9A84149465930003D511B6082DB4D408A440CA99A7D300415`

These four images may answer only whether the gate face is a visual improvement.
They cannot answer physical passage, head clearance or deck traversal.

The preliminary worker assessment is that the structural defect is improved in
static real-world evidence. Physical gate, head-clearance and ramp/deck proof is
still pending the exclusive world/render lease through
`tools/_capture_relay_gate_route_0909.gd`. This report does not claim traversal
or independent visual acceptance.

## Guarded combined-route attempt 1 — retained failure

Root granted the exclusive world/render lease for one guarded attempt. The
mandatory launcher used an isolated profile, a 600 second deadline, 90% system
commit ceiling, 400 process ceiling, and tracked the exact launcher/child PID
set. It started at `2026-09-09T16:30:13.0748535Z` and terminated at
`2026-09-09T16:30:18.5460563Z` with launcher PID 14548, owned PIDs
`[14548, 1584]`, exit 1, no guard stop reason and zero Godot processes
remaining. Its single sample recorded 53.88% system commit and 249 processes.

The capture script failed at parse before world construction:

```text
SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant
value, so it will be typed as Variant. (Warning treated as error.)
at: res://tools/_capture_relay_gate_route_0909.gd:302
```

The line is the capture harness's JSON helper (`var parsed :=
JSON.parse_string(...)`); the bounded correction is an explicit `Variant`
annotation. No route leg, sill contact, character head clearance, camera
transform or image was produced, so none is claimed. No repeat was launched
without root review.

All raw output and receipt files are retained under
`.artifacts/meadows-relay-gate-0909/guarded-route/`:

- `result.json` SHA-256 `6CF91839743279C8BF865204E0450AAD11805A58DA1811981C5E482EE5D3831E`
- `console.log` SHA-256 `F048F45C1192A925B0DB8A0715128814CF98E3BADCB3F38A47FF91B81CA788EB`
- `stderr.log` SHA-256 `055FB61455F765770DCD5B7115074DE9335C2F5A33643A8D1E6DC1FC86A8CC39`
- `engine.log` SHA-256 `5D30F7DF225BEF5D6A2F50EE69E273979869D96D2C86EE161CEDDA33C03225BC`
- `resources.csv` SHA-256 `F8BCF6912D6D657136C9A89E19C4B98693C487CAC1D969BDEC230F67D4AF54E3`
- `run.ps1` SHA-256 `3E41BDC007146D835E7E89301638BF4F275303C8723C24DE2C3855A98A00563C`

## Guarded combined-route attempt 2 — terminal harness failure

Root reviewed attempt 1, authorized only its explicit `Variant` annotation,
and granted one final guarded run. Before launch, every remaining inferred
local in the new capture helper was inspected; values returned through dynamic
calls were explicitly typed. The frozen production/config files did not change.

The second isolated-profile guard started at
`2026-09-09T16:33:50.2702725Z` and ended at
`2026-09-09T16:36:19.4613072Z`. Launcher PID 16356 owned PIDs
`[16356, 17052, 17404]`. The script exited 1 with no guard stop reason and zero
Godot processes remaining. Across 59 resource samples, peak system commit was
77.58%, peak process count 261, peak owned private bytes 4,842,221,568 and
peak owned working set 2,033,483,776. The exclusive lease was released on that
terminal receipt; no third run was launched.

The in-world fitted sill measurements completed before travel:

| measured asset x | world sill position | authored ground y | contact |
|---:|---|---:|---:|
| -0.766525 outer end | `(346.964, 5.414, 3774.885)` | 5.953 | -0.539 m |
| -0.445388 inner jamb | `(344.928, 5.414, 3773.493)` | 6.356 | -0.942 m |
| +0.445361 inner jamb | `(339.283, 5.414, 3769.631)` | 6.728 | -1.314 m |
| +0.769545 outer end | `(337.228, 5.414, 3768.226)` | 6.889 | -1.475 m |

All four sampled sill/end points are embedded rather than floating. The largest
gap is -0.539 m. The static day/night frames also show both visible jamb ends
meeting the shoulder. This establishes contact against the builder's production
ground source; it does not establish physical player support.

The real-input route failed before reaching the gate:

```text
outside fixture -> exact approach stand ok=true
player=(338.4657, -48.74335, 3776.862)
local=(-20.42923, -0.000569) on_floor=false
```

The navigator's planar arrival returned true while the player was already
airborne below the world. At the day shutter the player had fallen to y
-126.1708. The perimeter recovery then returned it to farm coordinates
`(-25.4, 4.950128, -15.7)` before the night shutter. The subsequent gate-centre
leg failed from there at local `(2903.28, -2439.898)`. Consequently:

- no physical gate passage is proved;
- no character-head-to-crown clearance measurement was reached;
- no ramp, gantry or apparatus-pad leg was reached;
- neither written frame contains the required player ruler;
- the two frames are retained failed airborne/reset evidence only.

The source-supported harness hypothesis is ordering, not a production terrain
defect. The helper made a new Camera3D current and passed it to
`Terrain.set_camera()` while that camera was still at the world origin. It then
placed the player at the distant relay before positioning the capture camera.
Terrain3D collision streams around the rendering camera. The established
`_capture_locations.gd` sequence instead moves its camera/player to an analytic
seat and waits before querying real support. That missing relay-side stream
step explains the unsupported fixture and is consistent with the grass-field
log switching to the still-unpositioned capture camera.

The exact retained camera transforms were:

- day origin `(336.4501, 9.984393, 3779.809)`;
- night origin `(336.4501, 9.990893, 3779.809)`;
- shared basis x `(0.825375, 0, 0.564584)` with only the expected tiny pitch
  change from the separately sampled camera floor.

Those are the unchanged approach composition, but the missing/relocated player
makes both invalid for traversal acceptance:

- `shots/relay_gate_route_0909/06-relay-approach-day.png`, SHA-256
  `3794EDF29C66693589BB5355BF218D19B8C61B39615AE732CBE13FA7258C0275`
- `shots/relay_gate_route_0909/06-relay-approach-night.png`, SHA-256
  `28F47071D20F34F64CB210EBFD313134B8BC5DD93E6159A9E35E614EA4F43880`

Attempt 2 raw evidence is under
`.artifacts/meadows-relay-gate-0909/guarded-route-2/`:

- `result.json` SHA-256 `1D207858D239915EDDD32799C6CD5CEB92B7A2BE6E0E0FB3518F14A11CF38A37`
- `console.log` SHA-256 `D79B5EC387E5D752EC9B46C4FF81CCBF7419C4159F41EA094D4224595BD6695E`
- `stderr.log` SHA-256 `5787B3CA6ABD9F6CB43E70A2517DF9B0AABEB9EDDF72B3075D4B58B62C788545`
- `engine.log` SHA-256 `453B384195DFE3E1294791D9A6C5D27E5A8CCAC05D5538D92AD498586F9BCE4E`
- `resources.csv` SHA-256 `9165E2A581A5B20C7D61595302570C4BB2C9582E302D06AA782011BDCB0FEE38`
- `run.ps1` SHA-256 `248175481C15BCBC4E9D7A599CDFC450AEDAD548E6B814D75F2D6302280EE251`

Final status: the measured component fit and in-world visual sill contact pass;
static day/reverse presentation improves the blockout entrance. Physical route,
head clearance, ramp/deck traversal and independent visual acceptance remain
unproved. No shipping acceptance is claimed from this sequence.

## Frozen owned paths

Production/config candidate:

- `scripts/world/tether_relay.gd` — SHA-256 `A1AE836D69340C58F83846DA8B63CF4597C87CC768A4E9307F6F631CEF7A7488`
- `data/config/tether_relay.json` — SHA-256 `1887F2A247E3B266F4995FA23FE82D892BEF983F8645A56DF3757848F602A037`

Focused/component evidence:

- `tests/test_tether_relay_gate_presentation.gd` — SHA-256 `2C99327646C0E2C918C058144A05EEE75F83C99AEBB18B7B3995AD6D98A0D84E`
- `tools/_capture_relay_gate_route_0909.gd` — SHA-256 `E3B4132973EB2E843BA0ECF2F6A14687D0624B2678AD6CCF685ECB3C73CFF6D2`
- `ralph/reports/FOUR-BIOME-BUILD/MEADOWS-RELAY-GATE-0909.md`

Ignored raw evidence stays under these exact directories:

- `.artifacts/meadows-relay-gate-0909/guarded-route/`
- `.artifacts/meadows-relay-gate-0909/guarded-route-2/`
- `shots/relay_gate_route_0909/`

The lane's owned PIDs `[14548, 1584]` and `[16356, 17052, 17404]` are terminal.
A later global process check found unrelated PIDs 17660/8216 running
`probe_varga_focused.gd`; they are outside this lane's lease and ownership.
The 287 pre-existing dirty `.import` files remain preserved.
