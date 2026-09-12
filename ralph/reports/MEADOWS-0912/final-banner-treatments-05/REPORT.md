# Meadows banner treatments — independent visual review

**OWNER-0912 Tier 2 #4 verdict: FAIL.** Round 05 repairs the shared road/Relay
cloth and gives the Hall hanging materially non-flat form, but the marshal
canopy still collapses to an unreadable black roof in both night views. Because
the owner explicitly requires the treatment to hold at night, the complete row
cannot pass yet.

## Evidence integrity

I inspected `manifest.json` and all 16 PNGs at their native 1280 x 800
resolution. The manifest reports 16 expected frames, 16 captured frames,
`complete: true`, and no failures. Each of the four named production subjects
has ordinary and close-oblique day/night coverage. Subject paths and source
receipts resolve to the actual waypost, Relay, tournament canopy, and
Stronghold placements. The disclosed harness uses one unmodified production
Meadows boot and does not spawn, duplicate, retint, repose, or reveal a banner.

## Strict findings

| Subject | Finding | Verdict |
| --- | --- | --- |
| Roadside full standard (`01`–`04`) | The complete authored waypost standard is clear in every view. Its oxblood/red cloth remains legible by day and night, with visible woven response, tonal folds, shaped hems, and an oblique silhouette that no longer reads as a featureless black cutout. | **PASS** |
| Relay-mounted full standard (`05`–`08`) | The actual Relay standard is present in all four views. The ordinary day view has a narrow hot sunlight band, but the close view resolves the red cloth, weave, fold hierarchy, cuff, and dimensional hem; those qualities remain readable at night. | **PASS** |
| Canopy cloth variants (`09`–`12`) | Day views establish layered roof sag and the installed red/blue hanging accents. At night, however, the ordinary view turns most of the roof into a featureless black silhouette, and the close view leaves the roof pitch black around an overbright lantern globe. Portions of the lower red swag, side panel, and blue pendant survive, but the canopy as a treatment does not remain readable. | **FAIL** |
| Hall hanging banner (`13`–`16`) | The actual Stronghold hanging is readable in both lighting states. The broad cloth has alternating folded planes, a dimensional centre roll and shaped lower hems; the oblique views retain those depth cues. The manifest now identifies `BannerCloth` as an `ArrayMesh` with about 0.486 m of depth rather than the prior 0.18 m `QuadMesh`, and foliage no longer materially blocks the subject. | **PASS** |

## Acceptance accounting

| OWNER-0912 Tier 2 #4 requirement | Verdict |
| --- | --- |
| Actual road, Relay, canopy, and Hall production placements shown | **PASS** |
| Complete ordinary / close-oblique day-night receipt | **PASS** |
| Road and Relay cloth has readable colour, weave, folds, and depth | **PASS** |
| Hall hanging is materially non-flat and unobstructed | **PASS** |
| Canopy remains readable as cloth at night | **FAIL** |
| No conspicuous black/paper-cutout result remains | **FAIL** |

## Required closure

Give the production marshal canopy bounded night readability without flattening
the successful daytime treatment or relying on a blown-out lantern. Recapture
the same canopy ordinary and close-oblique night views; the roof's sag, surface
variation, and relationship to both hanging accent colours must remain
judgeable. The accepted road, Relay, and Hall treatments should be preserved.

No Godot run or production edit was performed for this report. This is an
independent judgment of the supplied manifest and native images only.
