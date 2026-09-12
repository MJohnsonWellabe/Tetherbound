# Meadows final riding visual review — `final-riding-02`

**Verdict: HOLD / visual FAIL for T0 #12 and T2 #7.** The receipt is a valid,
complete production capture, and the current riding smoke is clean, but these
frames do not visibly prove that the saddle fits the back or that the rider's
hips and legs contact the authored seat without floating or intersecting.

## Evidence integrity

- `manifest.json` is complete: **6 / 6** planned frames, all 1280 × 800,
  `failures: []`, captured on the Windows display server.
- The fixture uses the production Meadows scene, Terrain3D, trainer, party,
  EncounterDirector, and `RidingController.mount()`. It declares no pose,
  carrier, saddle-transform, creature-art, or progression-reward injection.
- The two unsaddled frames report no fitted flag and no saddle node. All four
  mounted frames report the fitted flag, live saddle visual, mounted
  controller, and matching production mount body.
- `final-riding-01` is not a visual comparison baseline: its manifest is
  incomplete at **0 / 6** and contains no frames. `final-riding-02` is the
  first complete final-set receipt.
- On the current revision, `tests/smoke_riding.gd` exited 0 with
  `riding: OK — saddled, mounted, ridden, dismounted, and refused when it had to be.`
  Its live transform receipt measured Hips-in-player Y at **0.0268 m** and the
  saddle **0.12 m** from the authored seat. That is strong mechanical evidence,
  but it cannot substitute for the requested visual half.

## Native-resolution frame judgment

All six PNGs were inspected at their original 1280 × 800 resolution.

| Frame pair | Strict visual judgment |
|---|---|
| `01-unsaddled-three-quarter` day/night | **PASS for the before state.** No saddle or rider is visibly present. The night animal is very dark, but absence is consistent with the paired day frame and receipt. |
| `02-mounted-three-quarter` day/night | **FAIL for fit proof.** Mounting is obvious, but only the rider from roughly the upper torso upward clears the shell. The high stone plates hide the saddle/back junction, pelvis, thighs, knees, and boots. The torso reads as emerging from behind or within the shell; the frame cannot distinguish correct seating from intersection. Night reduces the shell and tack to near-black. |
| `03-mounted-side` day/night | **FAIL for fit proof.** This is a clearer creature profile, not a clear seat profile. A small tan saddle/rider detail is visible behind the torso, but its contact with the back is hidden. The rider's hips and both legs remain occluded below the shell crest, so authored-seat contact, leg drape, clearance, float, and clipping are not inspectable. Night again collapses the critical interface. |

## Requirement matrix

| T0 #12 / T2 #7 visual requirement | Result | Reason |
|---|---:|---|
| Saddle appears only after fitting/mounting | PASS | Paired state change is visible and matches the production receipt. |
| Saddle visibly fitted to the creature's back | FAIL | The saddle/back contact surface is occluded in all four mounted views. |
| Rider hips visibly contact the authored seat | FAIL | Pelvis is hidden in every mounted frame. |
| Rider legs visibly wrap/hang from the seat | FAIL | Thighs, knees, and boots are hidden in every mounted frame. |
| No rider float or mount/saddle intersection | FAIL / not proven | The necessary silhouettes and contact gaps are not visible; the torso-from-shell read cannot exclude clipping. |
| Day side and three-quarter coverage | PRESENT but non-probative | Both angles exist, but both preserve the same critical occlusion. |
| Night side and three-quarter coverage | FAIL for readability | The mount/tack interface collapses to near-black even at native resolution. |

## Required reproof

Capture the same production-mounted state with no pose or geometry override,
but make the evidence judgeable:

1. Raise and tighten the aim to the saddle/rider interface while lowering the
   camera enough to see the back contour below the saddle.
2. Use the creature side whose shell plates least occlude the pelvis and add a
   closer rear-three-quarter or opposite-side view if necessary.
3. Keep the full hips-to-boots silhouette in frame so both legs can be checked
   against the saddle and body.
4. Add bounded night evidence light aimed at the subject (not a material or
   world-state change) so the saddle, back contour, pelvis, and legs separate.
5. Retain one unsaddled comparison and the manifest's production-path receipts.

Acceptance requires the recapture itself to show the saddle resting on the
back and the seated pelvis/legs without float or clipping in both day and
night. Until then, the mechanics may pass while the owner-visible riding issue
remains visually unclosed.
