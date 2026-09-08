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

## Remaining acceptance work

ROAD does not judge its own frames. The final images still need an independent,
code-blind visual verdict against the supplied comparison references. In
particular, that verdict must not infer order 1912's legibility from the green
frame-level count; the distant pair needs separate proof or a semantic placement
repair if its own readability is required.
