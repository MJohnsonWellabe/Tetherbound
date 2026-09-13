# Independent evidence verdict — `final-companion-23`

**Overall: MIXED — T0 #2 PASS; T0 #13 FAIL.**

I inspected all eight 1280×800 PNGs at native resolution, then reconciled the
visible result with `manifest.json` and the prior R21 verdict. The package is
admissible for these two narrow claims: all 8/8 planned frames are present,
`complete` is true, and the manifest records no failures or warnings. Formation
uses the production gameplay camera and real movement input. Rest uses the
production party, Stronghold bed assignment, follower recall, `RestingCreature`,
and `play_rest` path. The close rest camera is disclosed. The large dark/teal
horizontal HUD strip across `05`–`08` is a visible capture/game presentation
artifact, but it does not obscure the pose enough to prevent judgment.

## Strict 09/12 row verdicts

| Owner row | Verdict | Evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **PASS** | In `01`–`04`, the active brown Terrapup consistently occupies the camera-right flank in settled day/night and both diagonal movement samples. The trainer, route centre, and forward view remain open; the companion never crosses the rear camera axis. The manifest corroborates the frames with `companion_behind_camera: false` and roughly 5.86–6.06 m camera-axis surface clearance. The foreground antlered creatures are world wildlife, not the active companion. |
| T0 #13 — Terrapup lays down correctly when resting | **FAIL** | In `05`–`08`, Terrapup is not unmistakably reclined or lying on the mattress. Its torso is held nearly horizontal in mid-air, the chest and hips visibly clear the bed, the rump is raised/rolled behind the shell, and all four limbs are splayed around the mattress. The huge paw soles dominate the silhouette without reading as relaxed folded or extended limbs. The muzzle approaches the mattress, but the body's mass does not settle onto it; wide-open eyes preserve an alert expression. The result reads as a rigid suspended/falling pose, not sleep. |

## Rest-specific acceptance checks

- **Chest/hip/side contact: FAIL.** Neither side view (`05`, `07`) nor three-quarter
  view (`06`, `08`) shows the chest, belly, hip, or flank carrying weight on the
  mattress. The bed remains visibly below almost the entire torso.
- **Unloaded, relaxed paws: FAIL.** The paws are no longer simply planted as in R21,
  but the replacement is a four-way splay with oversized soles facing the viewer.
  They read as frozen in the air, not softly folded or extended at rest.
- **Rump and spine: FAIL.** The rump remains elevated and the spine forms a rigid
  bridge over the bed instead of a reclined body line.
- **Head and eyes: FAIL.** The lowered muzzle helps bed proximity, but the head still
  hangs unsupported and the large open eye reads awake/alert in every rest frame.
- **Day/night consistency: PASS.** `05`/`06` and `07`/`08` show the same pose and the
  defect remains legible at night.
- **Numeric floor gate: PASS but non-dispositive.** The manifest reports a 0.014 m
  lowest posed point above the bed-anchor plane, zero anchor error, and a 0.816
  height ratio. Those numbers establish one low vertex and a bounded pose; they do
  not establish visible body-weight contact or restful body language.

## Three largest reference gaps

1. **Action silhouette (`05`–`08`):** the reference bar depends on immediately
   readable character poses; R23's level airborne torso and radial limb splay read
   as suspended or falling rather than sleeping.
2. **Physical weight and bed integration (`05`–`08`):** the references ground
   characters through contact and compression. Here the mattress sits beneath the
   creature while its chest, belly, hips, and flank remain visibly clear of it.
3. **Character appeal/deformation (`06`, `08`):** enormous forward-facing paw soles,
   a twisted high rump, and a wide-open eye create a rigid mannequin-like pose rather
   than the soft, relaxed asymmetry expected of a resting companion.

## Bar questions

- **A — Tetherbound Meadows key-art world: Yes.** The stylized creature, palette,
  outdoor Meadows formation views, and warm masonry interior belong to the intended
  world. The failed rest endpoint and the horizontal HUD strip are finish defects,
  not a wholesale art-direction mismatch.
- **B — Same kind of game as the Palworld references: Yes, at category level.** The
  trainer/large companion relationship and colorful creature-world presentation
  communicate the intended game type. The rest pose remains materially below the
  reference character-animation bar and is fixable through pose/rigging, bed
  placement, and expression/presentation work rather than new environment art.

This package continues to support closure of T0 #2 only. T0 #13 remains open until
Terrapup's chest and hip/side visibly settle onto the mattress, its paws read relaxed
rather than radially suspended, its rump follows a reclined body line, and its face
communicates rest in both day and night views.
