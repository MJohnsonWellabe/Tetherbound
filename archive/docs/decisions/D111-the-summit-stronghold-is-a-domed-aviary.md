# D111 — The Summit Stronghold is a domed aviary, not a castle keep

**Date:** 2026-09-06 · **Decided by:** implementing owner playtest addendum
`docs/owner/OWNER_PLAYTEST_2026-09-05.md` OP-0906-05, verbatim: "we should
make the final stronghold look more like a domed aviary than a castle. but
still keep some rustic stone elements."

## What was decided

The Summit Stronghold's massing (`cloudreach_world.gd::_build_summit_stronghold`,
built for the `summit_eyrie_stronghold` landmark) reads as a Quaternius-castle
keep: `UpperKeep` (a 24x15x22 windowless cuboid), a stacked `UpperKeepCornice`
band, four square `SummitWatchtower`s at the corners, a row of `Crenellation`
merlons along the top, and a `TetherCrown` cap slab. That silhouette is
exactly what OP-0906-05 is reacting to. `ralph/reports/CLOUDREACH-LOOK-0906/
_sheet_before.png` frame `06-summit-final-approach` is the reproduction.

**New standalone builder, not applied yet:** `scripts/world/cloudreach_aviary.gd`
(`static func build(root, materials, spec) -> Dictionary`), driven entirely by
`data/config/cloudreach_aviary.json`, proven by `tests/smoke_cloudreach_aviary.gd`
on a bare `Node3D` with placeholder materials — no Cloudreach world, no
chapter runtime. This decision record and the standalone file are the
deliverable; wiring it into `_build_summit_stronghold` is a separate task
(see the hookup plan the implementing report carries).

The aviary replaces the keep's massing with:

1. **A rustic stone drum** — a low masonry ring wall (~21-22m radius, 9m
   tall, 1.6m thick), built as 32 straight chord segments around an ellipse
   rather than a single cylinder, each a real `StaticBody3D` box. Four
   segments' worth of angular range is never built at all (not cut out of a
   solid ring — simply never placed), which is what makes the throat
   provably clear rather than clear-by-eyeball.
2. **Four tall arches** — two on the route axis (the throat: astride pure
   east/west, wide enough that a single arch's opening spans both
   `portal_z` bands `-1.5` and `7.5` the route wings already use, each
   ≥8.5m clear against the `8.0m` `PORTAL_CLEAR_HEIGHT` the wings promise)
   and two side arches on the old front-gate/rear-courtyard axis (north/
   south), each dressed with stone jambs and a flat lintel.
3. **A rustic detail budget, kept small on purpose** — four piers at the
   diagonals (away from every arch) each carrying three low crenellation
   stubs, and a low plinth course at the drum's foot (gapped at the same
   four arches as the main wall, or it would silently wall off the throat at
   ankle height while the visible wall above it stood open). This is the
   "still keep some rustic stone elements" half of the directive: battlements
   exist, but only as a detail on four piers, not as the building's whole
   skyline.
4. **The great dome** — a lattice hemisphere (sphere centred at the drum's
   top, radius 23m, apex at drum-height + 23 ≈ 32m — about 17.8x the 1.80m
   trainer) built from 16 tapered-cylinder meridian ribs and 5 iron-toned
   latitude rings (`TorusMesh`), open air between every rib. Ribs stop short
   of the pole at the oculus latitude (`asin(oculus_radius / dome_radius)`)
   instead of converging to a point, so the crown is a genuinely open ring
   (proven by a straight-down ray from its centre reaching the floor, not
   just a visual gap) — that open oculus is exactly where
   `OccupiedSummitPylon` already stands. `build()` hands back a
   `pylon_anchor` transform at the oculus centre so the hookup does not have
   to recompute it.
5. **Aviary furniture** — 10 roost perches (timber beams spanning the dome's
   inner curve at 12-20m up, each with a short rope tail), 3 woven nest
   baskets sitting on perches, 4 lantern posts at the arch flanks, 6 iron
   mooring-ring anchors on the drum face, and a handful of translucent
   wind-veil panels near the drum's crown (using the world's own
   `_wind_veil_material()` family if supplied, a plain translucent
   `StandardMaterial3D` otherwise).

No new mesh, no Meshy generation, no new humanoid or creature asset — every
piece is `BoxMesh`/`CylinderMesh`/`TorusMesh`/`PlaneMesh` built at runtime
from `_materials["masonry"]`/`["stone"]`/etc, the same primitive-and-material
approach `_build_summit_stronghold`'s own `_box`/`_cylinder`/`_castle_piece`
already use elsewhere in this file. This is the one prop family CLAUDE.md
reserves for Meshy (Team Tether hero objects) staying exactly as reserved —
`OccupiedSummitPylon` is untouched by this file; it is still the existing
`tether_pylon.glb` instance, just now anchored at the aviary's oculus instead
of a `TetherCrown` slab.

## What is preserved (the reason this is safe to build standalone first)

- **The open central throat and both `portal_z` route bands** (`-1.5` and
  `7.5`) that `_build_summit_route_wing`'s `PORTAL_HALF_WIDTH`/
  `PORTAL_CLEAR_HEIGHT` already promise the summit-overlook circuit. The
  aviary's own throat arches are wider (half-width ≥5m matching
  `PORTAL_HALF_WIDTH`, clear height ≥8.0m matching `PORTAL_CLEAR_HEIGHT`)
  and are proven by a real capsule shape-cast (r=0.5, h=1.8) walking
  x=-30..30 at both z lines, not by inspection.
- **`OccupiedSummitPylon`** — Team Tether's machine at the summit is
  untouched; only what it stands on/inside changes shape.
- **Every node name another file references.** A repo-wide search for
  `UpperKeep`, `GateBridge`, `SummitGatehouse`, `SummitWatchtower`,
  `OccupiedSummitPylon`, `TetherCrown`, `WingButtress` found exactly one
  reference outside `cloudreach_world.gd` itself:
  `tests/smoke_cloudreach_ground_truth.gd`'s `_check_named_platforms`, which
  does `world.find_child("UpperKeep", ...)` and only probes if the result
  `is Node3D` — a renamed/removed `UpperKeep` makes that probe a no-op, not a
  failure. `data/config/cloudreach_finale.json` and
  `tests/smoke_cloudreach_finale.gd`/`smoke_cloudreach_summit_road.gd`
  reference world *positions* (`arena_origin`, the summit landmark's
  authored `[100.0, 1160.0, 5350.0]`, the road's walk target) and the
  finale's own runtime-built `Relay_<id>` prompts — never a node name this
  file builds. Nothing in the finale controller or its fixture depends on
  `UpperKeep`/`TetherCrown`/`SummitWatchtower`/`GateBridge` existing.

## What this supersedes

`_build_summit_stronghold`'s current keep massing — `UpperKeep`,
`UpperKeepCornice` (all three bands), the four `SummitWatchtower`s, the
`Crenellation` row, and `TetherCrown` — is superseded by the drum + dome
above. `_build_summit_route_wing` (the throat's own load-bearing geometry)
and `_develop_stronghold_spaces` (the rear courtyard, braziers, banners,
approach dressing) are NOT superseded; see the hookup plan for exactly which
calls move, stay, or are deleted. This record does not itself edit
`cloudreach_world.gd` — that edit is out of scope for this task (another
lane owns that file concurrently) and is left as the hookup plan in the
implementing report.
