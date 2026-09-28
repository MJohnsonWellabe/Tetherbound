# P2-037 independent paired review

Reviewer: `stormwood_grounding_pair_judge`, fresh code-blind agent.
Inspected all 22 native images (six exterior pairs and five route pairs),
contact sheets at small size, Meadows key art, both Stormheart stronghold
boards and all five Palworld references. No source, configuration, change
narrative or previous verdict was supplied. The rejected location fixture
was excluded.

**Specific route-wall grounding improvement: YES. Complete landmark
acceptance: NO. Bar A: NO. Bar B: NO.**

The trainer's hair, blue sleeves and orange backpack remain identifiable at
sheet size. Rear views cannot establish facial appeal; distant or obscured
creatures cannot establish creature quality or relative scale.

The broad daylight slits beneath the trunk walls close in all five route
pairs. The difference is especially clear in Walk 01, Walk 02 and Walk 03:
the baseline suspends long wall sections above the landscape, while the
candidate brings them into contact with grassy ground. The correction is
also visible in Route Day and Vista Dusk. No clear new geometry defect is
visible in these pairs.

The exterior silhouette is effectively unchanged. `stormheart100_calm` loses
a purple light pool below the trainer and reads flatter, but these stills
cannot establish whether that difference persists. Rain, lightning, path
glow and distant creature positions also differ between captures and are
not reliable before/after conclusions.

The three largest remaining gaps are:

1. `stormheart400_calm` and `stormheart400_aftermath_calm` still show an
   enormous split wooden cylinder, straight sides, twig-like crown and small
   foliage tufts. Both boards use broad, organically divided branching.
   Substantial landmark geometry and foliage work remain.
2. Both 100 m calm/aftermath views show huge smooth bark sheets, stretched
   grain and regular dark rings. All five route views remain dominated by
   a black overhead band and repetitive walls. Root flares, irregular
   contact geometry, platforms, railings and human-scale architectural
   detail need art/geometry; planting and lighting can help integration.
3. The 400 m aftermath view spreads similar grass and flowers across a broad
   field with isolated trees and an empty horizon. Walk 03 continues that
   lawn under the black ceiling. Scene composition, clustered vegetation,
   ground hierarchy and lighting need stronger depth and separation.

Bar A fails because the cylindrical landmark and repetitive close surfaces
do not convincingly extend the reference world. Bar B fails because exposed
construction, repetitive terrain and weak creature presence do not carry
the gameplay-reference comparison. This does not condemn unseen creature art.

Exact exterior IDs, each in both sets: `stormheart400_calm`,
`stormheart400_break`, `stormheart400_aftermath_calm`, `stormheart100_calm`,
`stormheart100_break`, `stormheart100_aftermath_calm`.

Exact route IDs use prefix `stormwood__dynamo__12__the_stormheart_tree` with
suffixes `__route_day`, `__walk_01_day`, `__walk_02_day`, `__walk_03_day`,
`__vista_dusk`, each in both sets. Motion, collision, traversal, temporal
effects and unseen sides are unjudged.

## Corrected location addendum

The same code-blind reviewer inspected all sixteen native location images
and eight corresponding thumbnails from `catalog-baseline-01` versus
`p2037-after-locations-r2`. All eight pairs meet the unchanged position and
orientation tolerances. The two unrelated Crown Arch approach pairs are
excluded from comparison, as recorded in `comparison-coverage.json`.

All four `stormwood__landmark__dynamo_core` pairs (day/night, approach/close)
clearly close the long purple slits under the walls. Walls meet the grassy
slope; the larger opening beside the curved central structure remains and
reads as an opening rather than a continuous under-wall seam.

All four `stormwood__dynamo__12__the_stormheart_tree` location pairs show
little conspicuous change because terrain or grass already screens their
wall bases. Paths, openings and structures remain visible. No clear new
geometry, composition or character defect appears. Rain and path-glow
differences remain temporal and do not establish regressions.

The location views reinforce the earlier failures: broad black undersides,
oversized wall surfaces, harsh horizontal joins and uniform grass do not
read as a rooted, inhabited living tree. Closing the seam does not resolve
the missing organic form, bark scale or architectural composition.

**All six required original catalog sightings are covered.** Including
supplementary locations/routes and the six exterior pairs, this review
inspected 19 pairs / 38 native images. The floating-wall seam is visibly
corrected wherever the baseline exposes it, with no clear new defect.
**Full P2-037 acceptance remains NO; Bars A/B remain NO/NO.** The presentation
flag remains off while the broader landmark work continues.
