# Procedural cover bush identity 01

Status: **DIAGNOSTIC CLOSED — hypothesis disproved.** No production shader or vegetation change is justified by this result.

The diagnostic tested whether the prominent leafy form at the right side of the ordinary South Bridge view was the shared procedural `Cover_bushes` tier. It captured the production view, a process-local variant hiding only that tier, and a process-local variant setting only tier backlight to `0.28`, at the same day and night catalogue pose.

The first two invocations are preserved failures: each hit a Variant inference parse error at line 83 before capture. The explicit typed loops fixed that diagnostic defect. `cover-bush-identity-third` then ran from 10:15:36 to 10:17:33, produced all six frames cleanly, and reported that live materials, raw Terrain3D RIDs and visibility were restored before exit. The frames and manifest are in `shots/diagnostics/cover-bush-identity01/`.

Root's direct inspection found that the prominent right-hand leafy tree remains present when `Cover_bushes` is hidden. The hypothesized identity is therefore wrong. The absence test establishes only that this object is not the hidden procedural bush tier; it does not identify the imported object. A prior near-camera `CommonTree5` report is separate evidence and is not promoted into an identity conclusion here.

Every variant mounted while the held point-tip grass candidate was applied. That taper was identical across production, hidden-bush and backlight frames, so it does not confound the within-run identity comparison, but these frames are not retained-baseline grass evidence. The pointed-tip candidate was restored afterward. The previously retained shared blade arc and grounding remain in place.

This was an identity diagnostic rather than an appearance acceptance round. Since the target survived complete removal of the suspected tier, another blind judgment or a `Cover_bushes` shader adjustment would not answer the observed object. Investigation should resume only from direct scene-node/material evidence for the actual prominent form.
