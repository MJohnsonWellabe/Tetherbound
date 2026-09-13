# Burrow Warrens — `final-warrens-06` independent judgment

**Verdict: FAIL / not accepted for OWNER-0912 Tier 2 #5.**

Round 06 makes a meaningful structural improvement over round 05: the mouth is
now surrounded by production terrain mass rather than a complete freestanding
portal ring, and the retained road and outside-to-inside sequence remain valid.
It does not clear the owner's visual complaint. The required oblique still
reads primarily as several very smooth conical hills with a pale curved cap and
straight branch pieces attached to their face. The interior receipt also
confirms, rather than resolves, the separately logged hard-prism debt.

## Evidence integrity

- `manifest.json` is complete: **9 / 9** planned frames are present, with no
  failures, and every recorded image is 1280 × 720. All nine native PNGs were
  inspected individually.
- The manifest names the production Meadows scene and discloses ordinary live
  Terrain3D, scatter, props, vegetation, player, and encounters. Its only
  visual intervention is bounded capture-only key/rim lighting in the three
  night exterior frames; world materials and geometry are reported unchanged.
- The production repair is traceable to `fcf258506` (`Rebuild Warrens outer
  bank facade`): the new shoulders are part of the bank height field and the
  root runs are production meshes. This is not a capture-only facade.
- The three day motion rows are ordered 0 → 1 → 2, have zero recorded stand
  drift, collision-clear camera eyes, and small/bounded floor deltas. The
  images agree with a continuous outside → throat → first-hall route.

## Strict visual criteria

| Requirement | Verdict | Native-frame evidence |
|---|---:|---|
| Road-to-mouth hierarchy and approach sightline | **PASS** | `01-arrival-day/night` gives the destination a strong central silhouette and preserves the broad, embedded traveled road. The mouth is findable at ordinary travel distance in both lighting states. |
| Buried-den structural read | **PARTIAL / FAIL overall** | The opening is more buried than R5 and no longer presents a complete pale ring. However, `01-arrival-*` still resolves into a tall central cone plus multiple smaller cones; `02-mid-oblique-*` makes their uniformly smooth, steep profiles dominant. It reads as assembled mound primitives, not an excavated, laterally weighted earth bank. |
| Earth/material integration | **FAIL** | In `02-mid-oblique-day`, the bank is a broad, nearly featureless grey-green surface with little soil strata, broken rock, weathering, moss transition, or planted edge detail. The mouth floor and brown throat pieces meet it as separate flat sheets. The production height-field integration is real, but its rendered surface treatment does not sell buried earth. |
| Pale cap / no portal-shell impression | **FAIL** | The complete circular rim is gone, which is an improvement. A thick, high-value curved cap still stands proud above the mouth in every exterior frame, most starkly in `02-mid-oblique-day/night`. Its clean arc and abrupt pale-to-dark boundary read as a separate shell or awning laid over the opening rather than compacted earth or root structure. |
| Root facade | **FAIL** | The newly tapered roots do not form a convincing load-bearing brow in the images. `02-mid-oblique-*` shows long nearly horizontal cylinders, abrupt cut ends, thin straight bars, and dark triangular/planar pieces projecting from either flank. Several still read as unsupported shelves or attached debris rather than roots disappearing naturally into the bank. |
| Day/night threshold readability | **PASS with quality caveat** | `03-threshold-day/night` keeps the route, curved throat walls, resident, floor, warm practical, and onward opening readable. Night separation is strong enough to judge the same geometry. The overhead cap remains extremely bright and the tunnel skin strongly faceted, but neither obscures traversal. |
| Closed outside → threshold → inside evidence | **PASS** | `03-threshold-day`, `03a-threshold-step-day`, and `03b-threshold-inside-day` form a credible sequential receipt. `03a` is mostly blocked by the player's back, but the manifest telemetry and adjacent frames close the path without an apparent camera collision or discontinuity. |
| Believable den interior / no hard-prism debt | **FAIL** | `03b-threshold-inside-day` is a flat-ceiling rectangular chamber terminating in a square stone frame and box tunnel. `04-den-arrival-day` is dominated by another perfectly rectangular stone surround, a long cuboid passage, planar floor/walls, and straight ceiling beams. A few roots, rocks, mushrooms, and live creatures add use context but do not overcome the hard 90-degree extruded-prism read. |
| Creature/guardian context | **PASS as context only** | `03b` retains a resident and `04` retains the guardian at the end of the earned route. This proves occupation and progression context; it does not make the room or facade visually finished. |

## Delta from round 05

- **Improved:** the full pale portal ring is removed; new production earth
  shoulders surround the outer cut; the closed threshold route, road wear, and
  useful night values remain intact.
- **Still failing:** smooth cone massing, shallow/monochrome bank surfacing,
  separate pale cap, straight shelf-like roots and planar teeth.
- **Explicitly still open:** the interior's square frames, cuboid tunnels, flat
  ceilings, and beam grid remain the known organic-tunnel-kit debt.

## Required repair and reproof

Preserve the accepted road, collision route, threshold lighting, and encounter
sequence. Break the exterior silhouette into broad eroded shoulders rather than
cones; bury or replace the pale cap so no clean high-value arc stands proud;
make every visible root branch, taper, and disappear into earth without flat
ends or shelf silhouettes; and add grounded earth/rock/moss transition at the
mouth. T2 #5 needs another fresh approach/oblique/day/night proof after those
changes. The interior hard-prism issue remains a separate production repair and
must not be promoted on the strength of this traversal receipt.
