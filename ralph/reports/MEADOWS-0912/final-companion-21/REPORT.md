# Independent evidence verdict — `final-companion-21`

**Overall: MIXED — T0 #2 PASS; T0 #13 FAIL.**

I inspected all eight 1280×800 frames at native resolution and reconciled them with
`manifest.json`. The package is admissible: all planned day/night and movement/rest
views are present, the manifest reports no capture failures or warnings, formation
uses the production gameplay camera and real movement input, and rest uses the
production party, bed assignment, recall, `RestingCreature`, and `play_rest` path.
The disclosed close camera changes only the rest framing.

## Strict 09/12 row verdicts

| Owner row | Verdict | Evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **PASS** | In `01`–`04`, the active brown Terrapup stays lateral to the trainer during settled day/night and both diagonal movement samples. The trainer, road centre, and forward view remain readable; Terrapup does not occupy the rear camera axis. The very large cropped creature at the far-right edge of `01`/`02` is world wildlife, not the active companion. The manifest corroborates the intended formation with `companion_behind_camera: false` and roughly 5.8–6.0 m camera-axis surface clearance. |
| T0 #13 — Terrapup lays down correctly when resting | **FAIL** | `05`–`08` lower the muzzle substantially, but the whole-body silhouette is still not unmistakably lying on the bed. Terrapup remains symmetrically propped on two oversized, round, load-bearing forepaws; the chest and rump remain elevated, a planted rear paw is visible in `06`/`08`, and the wide-open eye reads alert. The mattress supports mostly the muzzle/forequarter area rather than a visibly reclined chest, belly, or side. This reads as a deep bow/crouch over the bed, not relaxed sleep. |

## Rest-specific acceptance checks

- **Floor contact: PASS.** No visible sinking or floating seam is apparent, and the
  manifest places the lowest posed point 0.020 m above the bed anchor plane with zero
  anchor error. The defect is body language, not gross floor placement.
- **Day/night admissibility: PASS.** `05`/`06` and `07`/`08` are readable and mutually
  consistent; the night treatment does not conceal the pose defect.
- **Relaxed limbs/paws: FAIL.** The forepaws remain inflated spherical supports rather
  than folded or extended resting limbs.
- **Restful head/eyes/body: FAIL.** Lowering the muzzle helps, but open eyes plus the
  elevated torso and planted limbs still communicate alertness and load bearing.
- **Bed integration: FAIL.** The creature leans over the mattress instead of visibly
  settling its body weight onto it.

## Three largest reference gaps

1. **Readable action silhouette (`05`–`08`):** the key art and Palworld references use
   immediately legible creature poses; this silhouette remains ambiguous between a
   bow and a crouch rather than reading as sleep.
2. **Character appeal/deformation (`05`–`08`):** the paired spherical forepaws dominate
   the front view and look mechanically inflated instead of softly folded at rest.
3. **Physical staging (`06`, `08`):** the bed is visually under the head and between
   planted feet, while the mass of the torso remains behind/above it; the reference
   bar expects convincing weight and contact.

## Bar questions

- **A — Tetherbound Meadows key-art world: Yes.** The palette, stylized creature, and
  warm stronghold interior belong to the established world. The failed rest pose is a
  character-animation/rigging defect, not an art-direction mismatch.
- **B — Same kind of game as the Palworld references: Yes, at category level.** The
  third-person trainer/large companion relationship is recognizable, but the rest
  endpoint is below the reference character-animation finish and remains fixable in
  pose/rigging without new scene art.

This package supports closing T0 #2 only. T0 #13 remains open until Terrapup's torso
and rump visibly settle onto the bed, its limbs stop reading as planted spherical
supports, and its face/body communicate sleep in both day and night views.
