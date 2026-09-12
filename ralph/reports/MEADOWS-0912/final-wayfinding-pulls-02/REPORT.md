# Independent visual verdict — `final-wayfinding-pulls-02`

**Overall: FAIL — creature sightlines pass, but the objective and Long Field/off-path pulls do not**

`manifest.json` is complete and internally consistent: 12/12 planned 1280×720
frames, no capture failures, one production Meadows scene load, and the companion
dismissed through the production path. I inspected every PNG at original resolution.
Round 02 removes the giant called-out Terrapup that invalidated round 01, so the
creature frames can now be judged. It does not close the full package: the objective
beam is hidden by ordinary route geometry in the clean evidence, and the Long Field
signal's only production-road pair is almost entirely blocked by foreground foliage.

## Strict requirement verdicts

| Requirement | Verdict | Frame evidence |
|---|---|---|
| T1 #1 — objective beacon is usable without being obnoxious | **FAIL** | At 532 m, `01-objective-road-approach-day` does not expose a legible world-space beam; `01-*-night` shows at most a short, thin cyan remnant behind the horizon/trees. At 66 m, the beam is aligned directly through a large tree in both `02-objective-near-destination-*` frames and does not identify the destination in the world. The minimap distance and large quest card remain usable UI, and the beam treatment is restrained rather than obnoxious, but this evidence does not prove the requested on-screen destination beam works from ordinary travel views. Round 01's near pair showed the beam clearly above the canopy, but that package was invalidated by the giant companion occupying the lower half of the view; round 02 cannot inherit that visual receipt. |
| T1 #6 — Long Field signal | **FAIL** | `03-wayfarer-signal-from-road-day` and `03-*-night` are not usable approach views: dense leaves cover the player and essentially the entire forward center, and neither a signal fire nor a coherent destination silhouette is visible through them. In `04-wayfarer-signal-at-detour-*`, a bright blue pickup at left and a small warm creature/site accent near the distant center can be found, but only after the player is already 15.6 m from the target. They do not read together as a deliberate signal from the road. |
| T1 #7 — south-trail creature sightlines | **PASS** | `05-trailpup-sightline-from-road-*` gives the trail a clear pale creature directly ahead against darker woodland in both presets. `06-bramblebun-sightline-from-road-*` gives the road a large bramblebun silhouette at right and a second creature farther up the route; the face and body remain distinguishable at night. The centered call-out prompt overlaps the lower part of the nearest subjects, but it does not erase their heads, route relationship, or pull. |
| T3 #1 — off-path pull/readability, day and night | **FAIL** | The detour pair `04-*` proves that a glowing pickup and authored wildlife exist off the road, and both survive the night preset. The required pull is not established from travel distance: `03-*` is screened by foreground foliage, with no readable line from the road to the signal, pickup cluster, or creatures. Content that becomes apparent only after reaching the detour does not function as an off-path invitation. |

## Delta from `final-wayfinding-pulls-01`

- **Resolved:** the enormous Terrapup companion no longer fills or crosses the
  objective, signal, Trailpup, and bramblebun compositions. Round 02 is valid
  production evidence for the two south-trail creature pairs.
- **Now proven:** the Trailpup and bramblebun placements produce readable day/night
  encounters from the road without companion obstruction.
- **Still blocking:** no clean frame proves a usable objective beam at either
  requested distance, and the Long Field signal/off-path site has no readable
  road-approach composition. Round 02 exchanges the round-01 companion obstruction
  for a foreground-foliage obstruction in the signal pair.

## Smallest remaining correction and recapture

1. Make the objective beacon survive ordinary tree and terrain occlusion—or raise/
   offset its visible portion enough to clear the canopy—while retaining the current
   narrow, low-impact treatment. Recapture the same 532 m and 66 m day/night pairs
   with the full HUD.
2. Open one modest sightline from the Long Field road to the existing signal site.
   The signal, at least one creature, and one reward accent should form a single
   readable destination from the road in day and night; do not merely move the
   evidence camera through the blocking shrub.
3. Retain the current companion-dismissal path and the accepted Trailpup/bramblebun
   placements unchanged. Recapture all 12 frames so the package remains one coherent
   production receipt.

This report judges visible production presentation only. It does not claim path
collision, navigation, interaction, or objective-state behavior.
