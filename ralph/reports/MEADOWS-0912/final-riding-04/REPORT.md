# Meadows final riding review — `final-riding-04`

**Overall verdict: FAIL.** The R4 repair closes the baked-tack defect and now shows a distinct fitted saddle with the trainer's hips seated on it. It does not yet make the near rider leg anatomically readable: none of the four mounted frames shows a continuous thigh, knee, shin and boot, and the visible near stirrup hangs empty. Because Tier 0 #12 and Tier 2 #7 are the same saddle/seat-fit complaint, both remain open.

## Evidence integrity

- `manifest.json` is complete: **6/6** planned frames captured, with no failures.
- All six PNGs are **1280 x 800** and were judged at native resolution.
- The receipt identifies the production Meadows scene, Terrain3D, trainer, party, inventory, `EncounterDirector`, and `RidingController`. Meadowhart is added only to the ephemeral audit party, summoned through the production director, and mounted through `RidingController.mount()`.
- The capture discloses bounded night-only evidence lights. It reports no rider-pose, saddle-transform, carrier, creature-art/material, world-geometry, or progression injection.
- `Grandpa's Village open riding field` is named for every frame. Day and night are paired for the same bare and mounted states.

## Owner rows

| Owner row | Verdict | Native-resolution finding |
|---|---|---|
| Tier 0 #12 — saddle on the creature's back and character in the saddle | **FAIL** | The saddle/back and hip/seat contacts now pass visually, but the rider fit is not complete. The near thigh disappears into the saddle/flank, no distinct knee-to-shin-to-boot chain survives, and the near stirrup is visibly empty in both three-quarter and side pairs. A live joint receipt cannot substitute for the missing visible fit on this core traversal verb. |
| Tier 2 #7 — visual half of the same saddle/seat fit | **FAIL** | The new bare/fitted state transition is convincing, but the mounted silhouette still reads as an upper body inserted into the tack rather than a rider whose legs wrap the mount and feet meet the stirrups. The defect persists in daylight and under the disclosed night evidence lights. |

## Frame findings

| Frames | Finding |
|---|---|
| `01-unsaddled-three-quarter-day/night` | **PASS component.** The Meadowhart's back is genuinely bare. There is no baked saddle, cinch, pouch, strap, or stirrup silhouette. The night framing crops more of the animal than day, but the broad bare back remains judgeable. |
| `02-mounted-three-quarter-day/night` | **MIXED.** A separate saddle and its hanging stirrups now appear, and the trainer's pelvis is visibly down on the seat rather than floating. The camera-side leg does not resolve into thigh, knee, shin, and boot; the nearby stirrup loop remains empty. |
| `03-mounted-side-day/night` | **FAIL decisive component.** These are the strongest fit views. They confirm the saddle sits on the back and the hips sit on the saddle, but they also most clearly show the missing lower-body silhouette: the thigh is swallowed by the saddle/flank, no readable shin or boot descends, and no foot occupies or meets the visible stirrup. |

## Production-state and contact receipt

The manifest supports the successful half of the repair:

- Both unsaddled frames report `meadowhart_bare_body_present: true`, `saddle_fitted_flag: false`, `saddle_visual_present: false`, and `production_riding_mounted: false`.
- All four mounted frames report the same bare production body plus `saddle_fitted_flag: true`, `saddle_visual_present: true`, `production_riding_mounted: true`, and `production_mount_body_matches: true`.
- Every mounted frame records a complete live right-leg bone chain. The ankle is **0.537003 m below the hip** and **0.556300 m from the saddle origin**. This honestly preserves evidence that the production rig has a physically measured leg and authored seat; it does not prove that the skinned leg or foot is visible or fitted to the visible stirrup.

## Delta from `final-riding-03`

R4 makes substantial, visible progress:

1. The unfitted Meadowhart no longer carries the source mesh's baked tack silhouette.
2. The fitted saddle is a distinct object that appears only after the production mount action.
3. The saddle rests on the back, and the trainer's hips now meet the saddle instead of floating above it.

The remaining blocker is narrower than R3 but still acceptance-critical: the production rider pose/skin must expose the near thigh outside the saddle skirt, bend through a visible knee and shin, and place a recognizable boot at or in the stirrup. Recapture the same four mounted side/three-quarter day/night frames while preserving the now-passing bare-body state, separate saddle, back contact, hip seat, and live contact receipt.
