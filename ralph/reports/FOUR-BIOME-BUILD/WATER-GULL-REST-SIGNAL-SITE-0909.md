# Gull Rest Signal Spire — 2026-09-09

Status: one focused production candidate is source-bound and mechanically tested;
ordinary-view capture failed twice and no visual acceptance is claimed.

## Attribution and contract

The corrected Water catalogue's `water__gull_rest__19__gull_rest_signal_spire__day.png`
and night counterpart show a bare low ridge and a clipped distant creature. The named
signal spire is absent. This matches source: `water_world.json` authors landmark
`gull_rest_signal_spire` at XZ `(-72.615, 899.886)`, role `stranded_researcher`, but no
runtime code consumes that id. Gull Rest is the optional sheltered Reedhaven branch;
the Water build contract requires its defining landmark and says configured counts do
not excuse empty walking.

The candidate is one compact timber signal lookout at XZ `(-70, 881.5)`, 18.57m from the
landmark waypoint. It uses only installed textured modules:

- four `Prop_Support.gltf` braces;
- one `Floor_WoodDark.gltf` platform;
- four `Prop_WoodenFence_Single.gltf` cross-braced rails;
- the existing visible `torch_prop.tscn` and one bounded site-local practical light.

The known `WatchTowerWRoof.obj` was deliberately excluded: the existing prefab record
documents that its only materials are flat `Celing` and `LightWood`, so it cannot receive
the project's weathered masonry treatment and already failed as a beige hut elsewhere.
The selected family instead carries the installed WoodTrim base colour, normal and ORM
textures. No source asset or import sidecar changes.

## Route, terrain and collision

The site sits outside both complete route segments adjacent to the authored waypoint:
`(-123.694,839) -> (-72.615,899.886)` and `(-72.615,899.886) ->
(-33.865,921.607)`. Its declared conservative visible radius is 2.5m and the route is
4m wide. Its nearer centreline is 13.82m away, leaving 9.32m after the route half-width
and declared footprint. The focused test measures every transformed installed mesh and requires that
the actual radius fits the declaration, then recomputes clearance against both segments;
the final result remains greater than the required 6m beyond the route edge.

The retained canonical stand 19 camera is at XZ `(-73.332, 904.922)` with heading
`(0.141, -0.990)`, 70-degree FOV and 1280x800 output. The final site centre projects
23.66m forward and 0.005m laterally, essentially on the camera axis. Even its complete
2.5m conservative radius occupies only about 6.0 degrees horizontally, inside the
unchanged canonical frustum. This corrects the initially proposed `(-84,905)` site,
which projected behind/side-on and could not satisfy canonical visibility.

Each brace independently samples production terrain. The highest foot establishes a
common platform plane 4.4m above it; every brace scales vertically from its own sampled
foot to that plane. This keeps all four feet in terrain contact on a slope without
tilting the platform. Each brace receives a box collision built from its final rendered
AABB after scaling. The platform, rails, flame and light add no extra collision. The
candidate does not move or edit Rune, wild encounters, pickups, harvest nodes, route
points, terrain, docks or progression.

At the final translated site, the nearest authored cast/wild/pickup separations are
32.07m to Rune at `(-64,850)`, 23.28m to `water_gull_rest_wild_001` at
`(-79.171,860.108)`, and 41.93m to pickup `water:gull_rest:pickup:003` at
`(-64,840)`. These are source-coordinate clearances; no actor or pickup was moved.

## Exact source scope

- `data/config/water_gull_rest_signal_site.json`
- `scripts/world/water_gull_rest_signal_site.gd`
- `tests/test_water_gull_rest_signal_site.gd`
- one distinct non-simulation presentation mount in `scripts/world/water_world.gd`

The mount is separate from the held First Shore gate-site code and is skipped by remote
simulation shells. Current hashes:

- `water_world.gd`: `E09BF9197CBD343562896D6EE736018F5A08637C66F7001A9A447D71CA1A4B4A`
- site helper: `740C920F7CB21B3935E33A5BA5CAAD2604DD255CB2B382386DC4E42EC0654FCE`
- site config: `B8EEAB0BA46CE0C4D63C185B6237F7CA47CA004A0D4148E64AA5CFEC8E215329`
- focused test: `AA140BCE3D8BEB67113FE9E010DDE6739CF44AC6F6AB8B6922C1410A4C8023B4`
- final unused capture helper: `A78F5083203EE5B2253652152576EE1E6D6896763B34B0B2C16BCD872E90EAAC`

## Focused evidence

The first focused run is retained as a failure. It exited `1` after a test-local variable
used GDScript's reserved `signal` keyword: `1 test / 0 assertions / 1 failed`. No
production source path executed. Raw log SHA-256:
`05E64685E26966D9E5796E687DEC6001FCAF37907BC30072D2E340A59A7FB5A8`.

The corrected final run used Godot 4.7 and exited `0`:

- time: `2026-09-09T15:02:43.413Z` to `15:02:44.754Z`;
- result: `2 tests / 41 assertions / 0 failed`;
- final raw log SHA-256:
  `9A8C3286CC96DC3041B8C070BA71404BC8951D42B25313BF074A56C770B8F39B`;
- no `ERROR`, `SCRIPT ERROR` or `WARNING` lines in the final raw log;
- all owned Godot processes were terminal before the lease was released.

The tests cover installed asset existence, authored identity, landmark proximity, full
segment clearance, transformed visible footprint, finite terrain samples, exact brace
foot and common-top contact, final visible-AABB collision correspondence, and the
bounded light's placement at the visible flame. This run preceded the source-only
translation from `(-84,905)` to `(-70,881.5)`: the translation leaves every measured
mesh extent and collision size unchanged. Final-site route clearance, frustum position,
and actor/pickup separations were recomputed from source coordinates, but were not
re-run through Godot under the explicit one-run ceiling.

## Capture failures and evidence limit

The first authorized capture attempt never booted the world. Godot rejected two
warning-as-error type inferences in the scoped helper. It ran from
`2026-09-09T15:18:22.659Z` to `15:18:31.416Z`; the raw log SHA-256 is
`7DD1DE05041621366CDCD332D3B45DC289EB03EA7591EEBD63BD876E24201B90`.

The corrected attempt booted the production Water world and ran for 68.092 seconds,
`2026-09-09T15:20:39.656Z` to `15:21:47.748Z`, with peak system commit 62.50%, peak
process count 258 and no guard termination. Its PowerShell argument list split the
output option into an empty `--output=` plus a separate value. All three PNG saves
therefore targeted the filesystem root and failed. The raw log contains six `ERROR`
lines: three engine PNG-save errors and three corresponding tool failures. It also
contains the known Terrain3D no-mipmap and interpolation-deprecation warnings. Raw log
SHA-256: `976C93C1577A7C53124C92FD3E55FB2086CA2728EE7FF22AF559EBF64BDA891D`.

Control flow reached all three save calls and the final `0/3` finish after the ordinary
navigation block. That means the helper did not take its earlier failure exits for
terrain support contact, canonical placement, the incoming 70% point, ordinary look,
banner clearing, the authored Gull Rest waypoint, or the next authored waypoint. This
is control-flow evidence only: because the empty output path also prevented the
manifest, exact player endpoints, grounded states, support deltas and screen bounds are
unavailable. The traversed authored centreline legs are 79.47m and 44.42m by source
coordinates; the run does not provide a quantitative travelled-distance receipt.

No frame was retained from either attempt. The helper now ignores empty output values,
but it was not run again. One unchanged canonical stand 19 day/night pair and one
ordinary grounded incoming-spine view remain required. This report makes no
image-quality or whole-biome acceptance claim.
