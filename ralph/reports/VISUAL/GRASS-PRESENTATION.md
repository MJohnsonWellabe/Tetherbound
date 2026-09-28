# Cross-region grass presentation experiment

This investigates priority 2 in [the whole-game ranking](AUDIT.md). It is
comparison evidence, not a new acceptance claim or a separate work queue.

## First candidate: reject

The shared grass shader and Cloudreach's grass shader deliberately tilt blade
normals upward. Godot Compatibility reverses the interpolated normal on a
back face before running the fragment shader. A fragment correction restores
the authored direction. [Independent source review](grass-normals/grass-normals-source-review.md)
confirmed the mechanism and identified both Cloudreach material factories.
Cloudreach flowers and bushes were excluded from the experiment.

The technically consistent correction **does not make the pictured grass
better overall**. Independent reviewers preferred baseline in 10 of 24 pairs,
the candidate slightly in one pair (Windscar day), and tied 13. More blade
faces become pale continuous strips, increasing the wiry carpet and competing
with the trainer, flowers and ground. The first candidate is rejected; no
production shader or material change was made.

| Region | Baseline preferred | Candidate preferred | Tie |
|---|---:|---:|---:|
| Meadows | 3 | 0 | 3 |
| Cloudreach | 1 | 1 | 4 |
| Stormwood | 2 | 0 | 4 |
| Tidewake | 4 | 0 | 2 |

The [Meadows/Cloudreach/Stormwood verdict](grass-normals/grass-normals-visual-review.md)
inspected all 36 native images; the [Tidewake verdict](grass-normals/grass-normals-tidewake-review.md)
inspected its 12. Brine Steps has little foreground grass and mainly tests
whole-frame regressions. Occlusion and rain also limit some Stormwood views.
The reviewers did not inspect code or receive the implementation rationale.

## One brightness revision

A second in-memory candidate keeps the correction and scales grass base/tip
colour by 0.65 in linear colour space, including the grass backlight tint.
Drain colour, flowers, shrubs, trees and terrain are unchanged. It was tested
only in Meadows against a fresh baseline, at the same three day/night stands,
to challenge the strongest failed case before expanding the experiment.
Its 12 native frames and exact shader variant are included in this packet.
The [independent revised verdict](grass-normals/grass-normals-balanced-review.md)
prefers it slightly in village and Ironwood daylight, prefers baseline in
village/Ironwood night and quarry day, and ties quarry night. Reducing pale
linework introduces darker, less coherent clumps in shade and leaves pale
straw-like tufts elsewhere. **Reject this revision too.** It was not expanded
to the other regions or installed in production.

Both attempts leave the repeated plant silhouettes, patch distribution,
mottled ground and abrupt verges unresolved. The next intervention must change
plant grouping/shape and ground transitions; it must not be another brightness
or normal adjustment. Keep day, shade and night witnesses and trainer/route
hierarchy in the acceptance comparison. Neither experiment closes priority 2.

## Build, capture and limits

All five runs used owned branch baseline
`b1b2b4254aad076fb1389a9352bd4e487c8f2981`, with main
`94c63b1f221063c2cec7122136bb111f6805bfd7` integrated and fetched again before
the work. Main advanced to `3dad15f417d9538b43cd5d2376ec0c1ab96d991f` during
review and was integrated afterwards as `515601514`. The audit-table conflict
was resolved by preserving both the visual lane's rows and main's new Crown
Guardian/fight-camera findings. Grass shaders and material builders are unchanged
by that merge. These captures still identify their actual pre-merge baseline;
they are not a new full-build witness for the merged gameplay changes.
The original 508-frame ranking remains an immutable earlier snapshot.
The experiment made changes to loaded shader resources only, restored baseline
after each pair and never wrote production files. Claude's checkout was not used.

**60 native 1920x1080 frames / 30 matched pairs:** the first candidate has three
stands in each of four regions, day/night except Stormwood Calm/Break. The
revision repeats Meadows' six pairs. Each pair's recorded camera, feet, target,
yaw and pitch are exactly equal. Wind, water, animation and weather time advance
between variants, so these are not deterministic pixel-difference measurements.

Runtime was Godot 4.7 stable `5b4e0cb0f`, Compatibility/OpenGL3.3 on GTX1060 3GB,
driver560.94. Engine exit was 0 for all five runs. Cloudreach's wrapper fails on
the existing production `unscoped chapter flag: fly_tutorial_completed` error;
all 12 selected frames were produced. The fixture itself removes that obsolete
flag. Other runs have no engine error diagnostics. Each Meadows run logs one
unselected, runtime-resolved Meadowhart-place skip while building the full row
list; all six selected pairs completed. Cloudreach, Stormwood and Tidewake have
no skipped selected frames.

The fixture stages position, party, progression flags and clock/Surge phase,
uses the production scene and CameraRig, hides HUD and parks the companion.
Camera-arm distances are recorded and collapsed arms are rejected. These
fixtures are disclosed under the current owner ruling. This evidence does not
establish ordinary route travel, combat visibility, motion/shimmer, full-region
coverage, packaging or Ally performance. Regional Bar A/B judgments remain open
or failed as specified in the individual verdicts.

The [packet](grass-normals/) contains manifests, engine diagnostics, source and
visual reviews, labelled half-resolution comparison sheets, representative
unaltered native PNG pairs and [SHA256 hashes for all 60 native frames](grass-normals/frame-hashes.json).
Full local natives are under `shots/grass-normals-paired/region/` and
`shots/grass-normals-balanced/region/`. Archived capture scripts retain their
original local dependency paths; they are experiment receipts, not portable
production capture tools.
