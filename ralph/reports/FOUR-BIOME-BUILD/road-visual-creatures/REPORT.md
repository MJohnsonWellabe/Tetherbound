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
existing ecology and adds small pairs on alternating 5.5 m route shoulders;
it does not increase global draw distance, activation distance, wander radius
or active-peer caps.

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
  pre-existing `UITokens` parse errors listed below, so it correctly does not
  claim runtime render proof. Root must rerun the included probe after fresh
  integrated import.

All focused Godot commands on this base also report a pre-existing autoload
parse failure in `scripts/ui/game_menu.gd` at lines 178–180, 242, 283, 285,
299, 302 and 304: `Identifier "UITokens" not declared in the current scope`.
The Water settle smoke additionally reaches the same failure through
`scripts/combat/throw_preview.gd` lines 166–167. Root directed this lane not to
merge integration or repair that unrelated owner.

## Required integrated follow-up (not yet acceptance)

1. Fresh import, with BUILD-SIZE owning the new texture `.import` sidecars and
   applying VRAM Compressed policy. ROAD commits no sidecars.
2. Rerun `probe_creature_fitted_bounds.gd`,
   `smoke_water_surface_wild_settle.gd`, Cloudreach wild retention, Stormwood
   wild presence, Water wild presence, and real-game route capture.
3. Capture fresh in-world creature/route frames. ROAD does not judge its own
   frames; send baseline/new frames and Palworld/key-art references to an
   independent code-blind judge. If rejected, accept its named defects for one
   bounded repair round.
