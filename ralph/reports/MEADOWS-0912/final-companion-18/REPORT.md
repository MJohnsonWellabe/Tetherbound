# Independent evidence verdict — `final-companion-18`

**Overall: MIXED — T0 #2 PASS; T0 #13 FAIL.**

I inspected all eight 1280×800 PNGs at native resolution before consulting any
implementation source, then reconciled them with `manifest.json`. The package is
admissible: 8/8 planned frames are present, `complete` is true, and there are no
capture failures or warnings. Formation uses the production gameplay camera and
real movement input. Rest uses the production party, bed assignment, recall,
`RestingCreature`, and `play_rest` path with a disclosed close audit camera.

## Strict 09/12 row verdicts

| Owner row | Verdict | Evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **PASS** | In `01`–`04`, the active brown Terrapup consistently holds the camera-right flank in settled day/night and both movement samples. The trainer, route centre, and forward view remain readable; the active companion never crosses behind or fills the camera axis. The manifest supports the pixels with `companion_behind_camera: false`, 5.76–6.02 m camera-axis surface clearance, and 0.04–0.28 m station error. The grey Trailpups in the foreground are world creatures, not the active companion. |
| T0 #13 — Terrapup lays down correctly when resting | **FAIL** | `05`–`08` show a lower head and grounded forepaws, but the pose is not unmistakably lying/resting. Terrapup remains propped over two very large, round forepaws with its torso and hindquarters elevated, eyes wide, and a planted rear foot visible in the three-quarter views. It reads as an alert crouch or play-bow leaning onto inflated paws, not a relaxed body settled onto the bed. Day/night remain readable and the bed contact is numerically clean (`0.020 m` low point above the anchor plane; `0.816` height ratio), but those measurements do not override the visible body language. |

## Three largest reference gaps

1. **Resting body language (`05`–`08`):** the references rely on instantly readable
   silhouettes; here the high rump/torso and load-bearing forequarters leave the
   action ambiguous between crouching and resting.
2. **Limb deformation (`05`–`08`):** the forepaws read as two inflated spheres rather
   than relaxed folded or extended limbs, making the authored pose look mechanically
   deformed.
3. **Bed integration (`06`, `08`):** the paws touch the bed, but the body's weight does
   not visibly settle across it; a clear chest/belly or side contact silhouette is
   missing.

## Bar questions

- **A — Tetherbound Meadows key-art world:** **Yes.** The creature palette, warm built
  interior, and outdoor Meadows context belong to the established world, though the
  rest animation does not meet its character-appeal finish.
- **B — Same kind of game as the Palworld references:** **Yes, at category level.**
  The large stylized companion beside a third-person trainer carries the intended
  game type; the rest-pose deformation remains visibly below the reference character-
  animation bar and is fixable in the rig/pose rather than requiring new scene art.

This evidence continues to support closure of T0 #2 only. T0 #13 remains open until
the torso visibly settles onto the bed and the limbs read relaxed rather than propped
or inflated in both day and night views.
