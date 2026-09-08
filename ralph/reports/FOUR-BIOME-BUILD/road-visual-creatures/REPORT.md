# ROAD-VISUAL-CREATURES checkpoint — 2026-09-07

Base: `61bc957805671956d912df2b1325555a5b4e0503`, followed by the ROSTER content
commit (`07664415c`, cherry-picked here as `ecbe355af`) before any placement
work. No roster mapping, role, weight, level, catchability or model assignment
was changed by ROAD.

## Player-visible result

- CP-2 now samples Water as well as Meadows, Cloudreach and Stormwood. Its
  required route set is 36 routes / 4,253 samples at 10 m intervals.
- The production GDScript probe reports zero samples below two creature bodies
  in the forward 180-degree view: Meadows 5/5 routes, Cloudreach 6/6,
  Stormwood 3/3 and Water 22/22.
- Every one of the 57 shared species and 12 Water runtime presentations has a
  fitted rendered height above the fixed 1.80 m trainer. The actual ladder is
  1.90–7.20 m. The GLB/node-transform audit specifically measures Mosshock at
  2.95 m and Tanglevolt at 3.40 m; no body remains footprint-clamped below its
  declared height.
- 32 installed later-biome species now have authored ordinary `vivid` albedo
  outputs. These are palette/region repaints of extracted source textures, not
  generated meshes or whole-body runtime tints. All outputs are 1024x1024;
  their combined size is 36,793,375 bytes. No ImageGen, Meshy or credits were
  used.
- Water's required sailing choices use 17 explicit peaceful surface pairs.
  The adapter preserves the authored sea level, and a Water-only wild subtype
  clamps its body origin after inherited physics so gravity cannot put it on
  the seabed. Dry sites retain the existing grounding path.

## Authored population delta

The route authoring tool is deterministic and idempotent. It preserves all
existing ecology and normally adds small pairs on alternating 5.5 m route
shoulders; it does not increase global draw distance, activation distance,
wander radius or active-peer caps. The Band 1 Creek Hollow repair is the one
documented exception: order 1911 remains outside the compact ecology rectangle
at `[-297.167, 0, 610.055]`, and the existing order-1912 pair was reassigned to
`[-394.549, 0, 640.171]` rather than adding or gating population. That centre is
79.5 m from the route because exhaustive single- and two-pair searches found no
5.5 m shoulder placement that was both outside Creek Hollow and forward-visible
from its formerly failing 730 m sample.

- Meadows: 35 pair sites (3, 13, 8, 10, 1 across bands 1–5).
- Cloudreach: 74 pair sites (9 arrival, 6 lower, 17 causeway, 15 floor loop,
  13 counterweight, 14 summit). Existing six authored sites remain.
- Stormwood: 71 pair sites (19 ash, 32 conductor, 20 deepwood). The exact
  catalogue contract is now 401 clusters.
- Water: 46 land-spine pair sites and 17 surface pair sites. The exact census
  is 303 sites: 209 dry, 77 shallow and 17 surface.

Runtime cost remains local to each player neighborhood. Cloudreach still
activates within 130 m. Water still activates within 100 m and retains its
16-body per-peer cap. Each new site contains two bodies, so the expected local
population is several readable pairs rather than a realm-wide simultaneous
spawn.

Cloudreach ROAD bodies also receive one reciprocal collision exception with the
trainer. This is deliberately trainer-only: the enlarged creatures retain their
normal terrain, attack and other-body collisions, but cannot seal a narrow
authored walking ribbon. The production arrival capture and the repaired
Windscar capture both pass with that exception active.

## Production capture result

The final Compatibility-renderer run loaded each shipped biome scene in series,
used the real trainer, exploration camera, HUD and runtime encounter directors,
and wrote 12 valid 1280x800 PNGs. Every frame contains at least two living
runtime creature bodies in the forward 180 degrees and at least two of those
bodies inside the real camera frustum. The per-frame `forward/framed` counts are:

- Meadows: `b01_s01` 8/8, `b01_s02` 5/3, `b01_s03` 10/10.
- Cloudreach: `b02_s01` 4/4, `b02_s02` 6/6, `b02_s03` 2/2.
- Stormwood: `b03_s01` 8/4, `b03_s02` 7/5, `b03_s03` 4/4.
- Water: `b04_s01` 3/3, `b04_s02` 3/2, `b04_s03` 3/2.

The capture runner pins Band 1's first frame to the exact 730 m route sample and
identifies order 1912 as its authored anchor. It disables only trainer physics
during each deterministic still so the production controller cannot integrate a
teleport as extreme velocity and invoke recovery; it then hard-fails if the live
trainer drifts more than 0.5 m from the authored stand before frame grading. This
guard caught and explained a superseded River Lock attempt before the clean
12-frame run.

Honest limitation: Band 1 frame `b01_s01` passes with eight other production
wildlife bodies forward and framed. The reassigned order-1912 Meadowhart pair is
about 138 m from that stand and is not among the runner's conservative <=130 m
credited body list. Therefore the frame proves the player-visible multiple-body
contract at the repaired sample, but it does **not** prove that the distant
order-1912 pair itself is clearly legible. No blind visual judge has accepted
these frames, and this report does not claim Palworld-bar acceptance.

## Evidence

- `static-zero-target.json`: the mirrored static CP-2 result, zero failures.
- `road-probe.log`: production GDScript CP-2 result, zero failures on all 36
  routes.
- `scale-ladder.json`: original-to-final declared scale changes.
- `scale-ladder-fitted.json`: transformed GLB bounds and exact fitted world
  size for all 69 runtime presentations; zero errors, minimum 1.90 m.
- `test-creature-scale-ladder.log`: 2 tests / 154 assertions / 0 failures.
- `test-water-encounter-runtime-data.log`: 6 tests / 2,122 assertions / 0
  failures, including surface-vs-seabed translation and fail-closed malformed
  surface metadata.
- `runtime-fitted-bounds.log`: deferred runtime probe attempt. This old-base
  worktree lacks fresh `.godot/imported/*.scn` files and also reports the
  pre-existing `UITokens` parse errors listed below, so it remains historical
  diagnostic evidence rather than the final render proof.
- `captures-final/`: final production evidence, containing 12 PNGs and
  `capture-manifest.json`; the manifest records 12 captures, zero failures,
  minimum forward count 2 and minimum framed count 2.
- `capture-final-strict-road-3.log`: final serial production run, exit 0, with
  no `SCRIPT ERROR` or `ERROR` lines.

The following capture evidence is superseded and should not be used or committed
as final evidence: `captures/`, `captures-cloudreach-repair/`,
`captures-final-meadows/`, `capture-final-strict-road.log`,
`capture-final-strict-road-2.log`, and
`capture-final-meadows-stabilized.log`. They record the original failed sites,
the partial Cloudreach repair, the empty required-site-ledger tool fault, the
River Lock stand-drift diagnosis, or the focused Meadows precursor.

The historical old-base probes reported an autoload parse failure for
`UITokens` in `scripts/ui/game_menu.gd` and `scripts/combat/throw_preview.gd`.
That note explains those superseded logs only; it is not the result of the final
integrated production capture, whose log has no `SCRIPT ERROR` or `ERROR` lines.

## Post-verdict Water colourway repair (capture ready for independent review)

The blind verdict identified Water's same-colour heaps in `b04_s01` and
`b04_s02`, while the roster already carried distinct vivid repaints for every
Water presentation. Static tracing found those repaints were not reachable at
runtime: Water's stable species ids are namespaced (`water_*`), but the embedded
GLB fallback textures live in the unnamespaced board-id folders. CreatureBody
therefore searched a folder that does not exist and silently retained each
model's unpainted material.

`water_species_catalog.gd` now carries the presentation's board id into
CreatureBody's ordinary/shiny/alpha texture lookup. The focused catalogue gate
proves all twelve namespaced presentations resolve an existing authored vivid
texture. Together with the unchanged scale ladder, the focused result is 10
tests / 512 assertions / 0 failures: minimum creature height remains 1.90 m
against the fixed 1.80 m trainer, and the apex remains at least 7.0 m. This is a
code/config repair only; it is not a visual acceptance claim.

The focused production recapture used the current Gate-F road tool and pinned
Godot 4.7-stable Compatibility renderer. The tool's `--only=water` parser path
was first checked with `--check-only` (exit 0), then proved live by producing
exactly three Water records and no records from another realm. The exact
PowerShell launch was:

```powershell
$captureDir = 'ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/captures-water-colourway-20260907T2141'
$logPath = Join-Path $PWD 'ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/capture-water-colourway-20260907T2141.log'
$godotExe = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe'
& $godotExe --path . --rendering-method gl_compatibility `
  --rendering-driver opengl3 --resolution 1280x800 --log-file $logPath `
  --script tools/gate_f/capture_four_biome_road_creatures.gd -- `
  --only=water --out=('res://' + $captureDir)
```

PowerShell passed that final expression as an empty `--out=` argument plus a
second token, so the validated files were written at `res://` and then moved,
byte-for-byte, into `captures-water-colourway-20260907T2141/`. The run exited 0;
its manifest records zero failures, a 1280x800 viewport, Windows display server,
Compatibility renderer, and the production scene/camera/HUD/runtime-body
contract. Results are `b04_s01` 3 forward / 3 framed, `b04_s02` 3/2 and
`b04_s03` 3/2. The log has zero `SCRIPT ERROR`, `ERROR` or `FAIL` lines; its ten
warnings are the already-emitted Terrain3D no-mipmap and unsupported Water
footing warnings. Godot process count was zero after exit.

The named blind-verdict offender frames are ready at:

- `captures-water-colourway-20260907T2141/b04_s01.png` — 1,727,118 bytes,
  SHA-256 `BB7F87CFC9DAFD9A8482B6E22BE135B167E4093997433BA4AE66ED8316436910`.
- `captures-water-colourway-20260907T2141/b04_s02.png` — 1,816,492 bytes,
  SHA-256 `09E97409B79F7A217F4EBEBAE0C8DB85125FD1802CA9B52A59552C48B125DE92`.

## Independent blind verdict — Water colourway recapture

A fresh code-blind judge received only `b04_s01.png`, `b04_s02.png`, and the
visual rubric. It did not inspect implementation, reports, manifests, or diffs.
The verdict was: multiple-creature visibility **FAIL**, species readability
**FAIL**, colour separation/palette appeal **FAIL**, visual scale/substance
**PASS**, and the Palworld-quality readability/appeal bar **FAIL**.

The judge found `b04_s01` read as one tangled teal mass and `b04_s02` had useful
pink/red separation but remained overlapped, harshly saturated, and silhouette-
ambiguous. Its second-pass direction is to separate bodies into distinct depth
lanes, bring the smallest body closer, preserve clear silhouette gaps, and tune
the vivid colours into more coherent material families. This is a recorded
one-round cosmetic verdict, not an acceptance claim.

## Remaining acceptance work

ROAD did not judge its own frames. The focused Water recapture has now received
the independent verdict above and remains deferred visual work. The earlier
all-biome frames already have their recorded blind verdict. In particular, no
verdict should infer order 1912's legibility from the green frame-level count;
the distant pair needs separate proof or a semantic placement repair if its own
readability is required.
