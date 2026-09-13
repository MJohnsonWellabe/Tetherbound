# Meadows riding R7 — independent 09/12 review

## Verdict

| Owner row | Verdict | Evidence |
| --- | ---: | --- |
| **T0 #12 — saddle sits on the creature's back and character sits in the saddle** | **PASS** | The unsaddled pair shows a genuinely bare Meadowhart back. All four mounted views show a separate fitted saddle resting on that same back, the rider's pelvis down on the seat, and a continuous near thigh/knee/shin/boot rather than the former half-body intersection. Side and three-quarter views agree in day and night. |
| **T2 #7 — riding visual fit** | **POLISH** | R7 clears the prior missing-leg/empty-stirrup blocker: the near leg is continuously visible and its boot lands at the hanging stirrup height. The side pair still looks visibly constructed rather than naturally ridden—the blue leg is very straight and tube-like, the knee bend is weak, and the oversized rectangular brown boot reads as a block beside the stirrup more than a foot settled in it. The fit is now readable and functional, but the broader “doesn't look right” visual complaint is not at a commercial PASS. |

**Overall: POLISH.** Accept the Tier 0 attachment repair; retain one bounded
rider-leg/boot presentation pass for Tier 2 rather than reopening saddle or seat
placement.

## Evidence integrity and continuity

- `manifest.json` is complete at **6 / 6**, has no failures, and all six listed
  native 1280x800 PNGs are present as matched unsaddled, mounted three-quarter,
  and mounted-side day/night pairs.
- Every frame records a clear camera-to-subject sightline. Day frames use
  production lighting; the night key/rim is explicitly capture-only, so the
  night pair proves geometry and value separation, not unchanged gameplay-night
  illumination.
- The fixture disclosure is honest about audit-adding canonical Meadowhart to
  the ephemeral party. Summoning, fitting, mounting, rider attachment, and
  carrier state still pass through production `EncounterDirector` and
  `RidingController.mount()`; no rider pose, saddle transform, creature art,
  carrier, geometry, or progression reward is injected.
- Both unsaddled frames report bare production body present, fitted flag false,
  saddle visual absent, and mounted false. The visible back agrees.
- Every mounted frame reports fitted flag true, saddle visual present, mounted
  true, and the production mount body matching. Bilateral production leg-fit
  continuity is true, and the visible near-right chain is complete in all four.
  Its ankle is 0.453 m below the hip and 0.491 m from the saddle origin; day and
  night receipts are identical.

## Native-frame findings

- `01-unsaddled-three-quarter-day/night`: **PASS.** No baked seat, cinch,
  stirrup, strap, or pouch silhouette remains on the judged Meadowhart. The live
  animal changes bearing between frames, but both independently expose a bare
  back.
- `02-mounted-three-quarter-day/night`: **PASS for attachment.** The fitted
  saddle is unmistakably new, follows the back contour, and supports the rider's
  hips. The camera-side leg clears the saddle skirt and reaches the tack instead
  of disappearing into the flank.
- `03-mounted-side-day/night`: **PASS for contact; POLISH for finish.** This is
  decisive proof that saddle/back and hip/seat no longer float or intersect in
  the old way. It is also where the rigid leg line, minimal knee articulation,
  and rectangular boot/stirrup silhouette are most conspicuous.

R7 therefore closes **T0 #12**. For **T2 #7**, preserve all current transforms
and continuity and refine only the visible rider leg/boot articulation and
stirrup enclosure; do not disturb the now-passing bare/fitted transition,
saddle/back contact, or hip seat.

## Review-only scope

This commit adds only `REPORT.md`; it does not modify source, tests, manifest,
PNG evidence, riding state, or production content.
