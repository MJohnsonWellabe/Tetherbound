# Burrow Warrens approach — `final-warrens-05` independent judgment

**Verdict: FAIL / not accepted for OWNER-0912 Tier 2 #5.**

The evidence-path defect from `final-warrens-04` is repaired: this is a
complete, collision-clear outside-to-inside sequence, and the night views now
retain materially better facade and threshold information. The owner-facing
subject is still not repaired. In both exterior angles, the Warrens reads as a
smooth pile of large cones behind a separately assembled circular portal, with
thin unsupported shelves and triangular cap pieces attached around it. That is
the same dominant facade failure identified in the prior verdict.

## Evidence integrity

- `manifest.json` reports `complete: true`, **9 / 9** captured frames, no
  failures, and native 1280 × 720 output for every PNG.
- All nine PNGs were inspected individually at native resolution and compared
  with the `final-warrens-04` FAIL.
- The fixture disclosure uses the production Meadows scene, live Terrain3D,
  ordinary player and encounters, and unchanged production world geometry.
  Its only capture lighting is disclosed, bounded night key/rim light.
- The three motion rows are internally coherent. Their indices are 0→1→2,
  player positions progress continuously inward, every recorded camera eye is
  clear, every stand drift is 0.0 m, and ground deltas are bounded (about
  0.003 m, 0.177 m, and 0.001 m respectively). Unlike round 04, the images
  agree with those rows rather than showing a camera embedded in the mound.

## Strict criteria

| Requirement | Verdict | Native-frame evidence |
|---|---:|---|
| Road-to-mouth hierarchy | **PASS** | `01-arrival-day/night` retains the broad worn approach and a clear central mouth. The destination is readable at ordinary travel distance in both times of day. |
| Embedded traveled wear | **PASS** | `01-*` and `02-*` preserve the irregular ochre/brown wear integrated with terrain and grass. The old black rail/decal read does not return. |
| Earth/root facade | **FAIL** | `01-*` presents three smooth, steep conical masses; `02-mid-oblique-*` makes the construction especially obvious. Sparse trees and branch meshes decorate those cones, but do not create a laterally weighted excavated bank or a load-bearing root brow. |
| No assembled cone / portal-ring impression | **FAIL** | `02-mid-oblique-day` shows a pale near-circular band standing proud of a dark tube, triangular pale teeth/caps around its upper-right edge, and long thin brown shelves projecting unsupported to both sides and across the sill. These are visibly attached pieces, not buried roots or earth strata. |
| Day facade and threshold readability | **PARTIAL** | The road, mouth, and immediate tunnel are easy to locate in `01-arrival-day`, `02-mid-oblique-day`, and `03-threshold-day`. The facade's material hierarchy remains incoherent: smooth grey-green cone, bright pale portal cap, black tube, and flat brown shelves read as separate kits. |
| Night facade and threshold readability | **PASS with facade-quality caveat** | This is materially improved from round 04. `01-arrival-night` and `02-mid-oblique-night` preserve the mound silhouette, root/cap outline, road, mouth, and warm interior depth; `03-threshold-night` retains both tunnel walls, traveled floor, resident, and next opening. The lighting reveals the same assembled facade rather than curing it. |
| Closed, coherent outside→threshold→inside receipt | **PASS** | `03-threshold-day` looks through the mouth; `03a-threshold-step-day` advances inside the tube with wall/floor boundaries around the player; `03b-threshold-inside-day` reaches the inner hall and looks toward the next rectangular opening. No frame is filled by exterior shell texture, no sky hole reopens, and the manifest's clearance/drift rows support what the images show. `03a` is compositionally cramped by the player's back, but remains valid traversal evidence. |
| Interior context | **PASS as context; separate visual debt remains** | `03b` establishes the first hall and resident, while `04-den-arrival-day` establishes the deeper doorway and live guardian. This proves continuity and encounter context. The hard rectangular stone frame, box tunnel, flat ceiling, and exposed beams in `04` still support the separately logged interior-prism complaint; they cannot make the exterior approach pass. |

## Delta from `final-warrens-04`

- **Fixed:** the capture no longer collides with the exterior shell. The added
  threshold sequence is spatially and telemetrically coherent.
- **Improved:** night value separation now preserves the facade silhouette,
  tunnel walls, floor, resident, and onward opening.
- **Retained:** road hierarchy, embedded wear, and the closed immediate roof.
- **Still failing:** smooth cone massing, separate pale portal ring, triangular
  cap teeth, unsupported planar shelves, and an assembled-prop material read.

## Required repair and reproof

Keep the road, night values, closed shell, and working threshold receipt.
Rebuild the visible mouth as one buried earth-and-root facade: flatten and
laterally spread the mound shoulders, break the near-complete pale ring into
irregular load-bearing roots/strata, remove the long planar shelves and cap
teeth, and bury every interface into the bank. Re-run the same nine-frame plan
under a fresh directory; the existing approach, oblique, paired night, and
motion angles are now suitable for final judgment.
