# Burrow Warrens approach — `final-warrens-04` independent judgment

**Verdict: FAIL / not accepted for OWNER-0912 Tier 2 #5.** (Tier 2 #7 in the
owner directive is riding; the Warrens row is Tier 2 #5.) The set is complete
and the repaired shell closes the prior threshold roof holes, but the exterior
still reads as assembled facade pieces on a smooth cone, the night facade still
collapses, and the new sequential threshold receipt clips into the mound instead
of proving an outside-to-inside traversal view.

## Evidence integrity

- `manifest.json` reports `complete: true`, **9 / 9** expected frames, no
  failures, and native 1280 × 720 output for every PNG.
- The fixture disclosure uses the production Meadows scene and live Terrain3D,
  props, vegetation, player, and encounters. Frames `03`, `03a`, and `03b` are
  declared as a sequential player-height receipt with no geometry or collision
  alteration.
- All nine PNGs were inspected at native resolution and compared with the
  `final-warrens-03` HOLD.
- Manifest completion is not visual acceptance. The declared sequential
  receipt is visibly invalid in its final two frames, and `03b`'s telemetry is
  internally suspicious: player Y is 12.016 while the recorded surface Y is
  15.111, and the recorded player XZ is about 2.05 m from the requested stand
  XZ, despite a reported ground delta of only -0.154 m.

## Strict criteria

| Requirement | Verdict | Native-frame evidence |
|---|---:|---|
| Road-to-mouth hierarchy | **PASS** | `01-arrival-day/night` retains the successful broad worn route and central destination. The mouth is easy to locate from the road. |
| Embedded traveled wear | **PASS** | The accepted irregular ochre/brown surface wear remains integrated with grass and terrain; no black rail-like approach strips return. |
| Earth/root facade | **FAIL** | `01-*` and especially `02-mid-oblique-*` still show a smooth, tall conical mound behind a separately articulated green arch. Sparse roots and trees decorate the assembly but do not make the mouth read as an excavated, load-bearing root-and-earth cut. |
| No slab, wedge, or portal-ring impression | **FAIL** | The opening is still wrapped by a high-contrast curved green band with hard triangular teeth/shoulders. Long thin brown shelves project left, right, and across the sill in `02-mid-oblique-day`; the pieces read as attached planes rather than buried roots or strata. |
| Closed exterior shell | **PASS with capture caveat** | The large bright sky/terrain wedges that failed `final-warrens-03` are no longer visible in `03-threshold-day/night`; the immediate entrance roof now reads continuous. However, `03a`/`03b` collide with or enter that shell, so the full threshold transition is not validly demonstrated. |
| Day facade/threshold readability | **PARTIAL** | Day frames clearly locate the mouth and the repaired immediate ceiling. The brown liner differentiates the passage, but the entrance remains a dark, smooth tube beneath a separate pale cap, and the oblique view still exposes assembled edges. |
| Night facade/threshold readability | **FAIL** | `02-mid-oblique-night` loses nearly all brow, root, wall, and projecting-piece separation except the pale cap and a small warm interior point. `03-threshold-night` preserves only part of the right liner and floor; the left wall and ceiling merge into black. |
| Outside-to-inside player-height receipt | **FAIL** | `03-threshold-day` is useful. `03a-threshold-step-day` is dominated by an extreme close view of the mound surface with clipped root/edge fragments. `03b-threshold-inside-day` is almost entirely a flat green wall texture. Neither shows forward spatial continuity, and `03b` does not show an interior at all. |
| Interior continuity/context | **PARTIAL / not closure evidence** | `04-den-arrival-day` again shows the guardian through the traversable rectangular corridor. It is valid context, but it cannot cure the failed facade or invalid threshold sequence. |

## Delta from `final-warrens-03`

- **Improved:** the immediate threshold roof is materially more continuous;
  the former bright sky/terrain shell holes are closed in the paired `03` views.
- **Retained:** the accepted road hierarchy and embedded wear.
- **Still failing:** smooth cone plus applied portal-cap read, thin projecting
  shelves/wedges, and insufficient night value separation.
- **Regressed evidence:** two added motion frames do not show the motion path.
  They put the camera into exterior shell geometry, so the promised sequential
  proof is weaker than the single useful threshold frame by itself.

## Required repair and reproof

Retain the road, wear, and newly closed entrance ceiling. Break the remaining
high-contrast arch/shelf assembly into a laterally weighted, buried earth/root
facade with no long unsupported planar projections, and add bounded night value
separation for brow, roots, walls, and traveled floor.

Before another judgment, repair the capture path itself: place and aim the
camera independently at each valid player stand, ray/clearance-check its eye
against the shell, and record a coherent outside → threshold → inside sequence
where the passage remains visible in every frame. Add disclosed bounded night
evidence light for the facade/threshold rather than treating near-black output
as proof. Recapture under a fresh directory; do not promote this set.
