# Meadows riding R8 — independent 09/12 review

## Verdict

| Owner row | Verdict | Evidence |
| --- | ---: | --- |
| **T2 #7 — riding visual fit** | **PASS** | R8 clears the sole R7 polish blocker. In both mounted bearings, the near thigh now angles forward into a visible knee, the shin changes direction back toward the tack, and the smaller boot lands over the stirrup tread rather than reading as a detached rectangular block beside it. The rider remains seated at the hips and the saddle remains fitted to the Meadowhart's back in day and night. |
| **T0 #12 — saddle/back and character/seat regression check** | **PASS** | The unsaddled pair still exposes a genuinely bare back. All four mounted frames show the distinct fitted saddle contacting that back and the rider's pelvis contacting the authored seat, with no renewed float or body intersection. |

**Overall: PASS.** Promote the strict T2 #7 visual half; T0 #12 remains closed.

## Evidence integrity

- `manifest.json` is complete at **6 / 6**, lists no failures, and all six
  declared 1280x800 PNGs are present and non-empty.
- The evidence contains matched unsaddled three-quarter, mounted
  three-quarter, and mounted side day/night pairs. Every frame receipts a
  clear camera-to-subject sightline.
- The disclosure identifies the production Meadows scene, Terrain3D, trainer,
  party, inventory, EncounterDirector, and RidingController. The canonical
  Meadowhart is audit-added to the ephemeral party, but summon, saddle fit,
  and mount all use the production paths. No rider pose, carrier, tack/body
  transform, creature art, material, geometry, or progression reward is
  injected.
- The bounded night key/rim is explicitly capture-only. It proves geometry
  and contact readability; the two daylight mounted frames independently show
  the same result under production light.
- Every mounted record reports `production_riding_mounted`, matching mount
  body, fitted saddle, visible saddle, and bilateral leg continuity as true.
  The near ankle remains 0.453m below the hip. The revised boot centre is only
  about 0.066m from the authored stirrup anchor, versus about 0.094m in R7.

## Native-frame findings

- `01-unsaddled-three-quarter-day/night`: bare Meadowhart body remains clear;
  no saddle, skirt, cinch, pouch, or stirrup silhouette is baked into it.
- `02-mounted-three-quarter-day/night`: the saddle/back and hip/seat interfaces
  remain settled. The near leg reads as thigh, knee, returning shin, and foot;
  the boot no longer extends sideways as the dominant rectangular shape.
- `03-mounted-side-day/night`: decisive R7 comparison. The old almost-vertical
  tube has become an articulated zig through the knee, while the reduced boot
  sits on/within the visible stirrup interface. Its low-poly block treatment is
  consistent with the trainer model and no longer breaks the riding read.

## Review-only scope

This review adds only `REPORT.md`. It does not modify source, tests, manifest,
PNG evidence, production content, or runtime state.
