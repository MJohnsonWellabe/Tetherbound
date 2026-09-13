# Independent evidence verdict — `final-companion-24`

**Overall: MIXED — T0 #2 PASS; T0 #13 FAIL.**

I inspected all eight 1280×720 frames at native resolution, then checked the
capture metadata in `manifest.json`. The package is admissible for these two narrow
claims: all 8/8 planned frames are present, `complete` is true, and the manifest
records no warnings or per-frame capture-check failures. Formation uses the
production gameplay camera and movement inputs. Rest uses the production party,
Stronghold rest point, and resting body; its close review camera is disclosed.

## Strict 09/12 row verdicts

| Owner row | Verdict | Evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **PASS** | In `01`–`04`, the active Terrapup holds a lateral flank in settled day/night and both diagonal movement samples. The trainer, route centre, and forward destination remain readable; Terrapup never sits on the rear camera axis. The manifest agrees: `companion_behind_camera` is false in all four frames and the full projected bounds remain inside the frame. The large Mudsnout in the opposite foreground is world wildlife, not the active companion. |
| T0 #13 — Terrapup lays down correctly when resting | **FAIL** | `05`–`08` show a sideways rotation, but not a convincing lay. The torso remains rigid and elevated above the mattress, all four paw soles are presented as if a standing/crouching statue were rolled, and the three-quarter views retain a wide-open alert eye. The body does not visibly settle its flank, chest, or hip into the bed. It reads as tilted/suspended rather than comfortably resting. |

## Rest-specific checks

- **Immediate lay silhouette: FAIL.** Side rotation is visible, but the standing
  anatomy remains intact; the three-quarter silhouette is a diagonal crouch.
- **Weight/contact: FAIL.** The lower paws approach the mattress, while the torso's
  mass remains visibly clear of it. A lowest vertex 0.172 m below the anchor plane
  does not establish flank or chest contact.
- **Relaxed limbs and face: FAIL.** Four large soles face outward and the visible eye
  is open and alert. Neither communicates sleep or relaxed rest.
- **Day/night consistency: PASS.** The same result is readable in both lighting
  states; darkness does not conceal the defect.
- **Capture integrity: PASS.** The manifest records zero anchor error, 15,616 posed
  skinned vertices, no posed-surface failures, and 100% subject-bounds inclusion in
  all four rest frames. This is a judgeable visual failure, not a missing-subject or
  capture-framing failure.

R24 continues to support closure of T0 #2 only. T0 #13 remains open. A passing
Terrapup rest needs its torso/side to visibly carry weight on the mattress, limbs
that read folded or relaxed rather than four-way suspended, and a restful head/eye
presentation from both side and three-quarter views.
