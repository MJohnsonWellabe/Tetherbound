# Blind settlement comparison — rejected candidate

Reviewer `settlement_blind_comparison` had no source, diff, implementation
context or version order. It read the visual-judge rubric and ART_DIRECTION,
then the Cloudreach board, keyart and Palworld references, and opened all six
individual native frames under neutral A/B labels. Mapping revealed afterward:
A = retaining-arcade trial; B = baseline 5c886d80f. Pair1 = C2 row21 day,
pair2 = row25 day, pair3 = row32 night.

**Architecture: tie in all three pairs. Whole-frame preference: B, narrowly,
in all three. Bar A NO / Bar B NO for both versions.**

The houses and lookout retain the same generic village silhouette. A2's
projecting rectangular foundation/terrain shelf looks less integrated than
B2's continuous slope. The reviewer found no convincing architectural
improvement: the settlement remains timber houses and a lookout on a grassy
platform, lacking the board's supported terraces and layered cliff occupation.

Other findings: A1/A3's ram face is buried behind the foreground bird; B1/B3
have two superimposed birds. The route view is less blocked in B, but this
pose/spawn difference is not evidence about the architectural change. The
right cliff wall is too straight and featureless, foreground depressions have
angular cuts, grass strips end abruptly, and the night lookout lacks a warm
inhabited focal point. Fencing disappears in coarse grass.

Ranked gaps: (1) readable creature separation, with possible feather-art work;
(2) architecture integrated with cliffs through legible arrival and occupied
terraces; (3) coherent ground/verge transitions and night settlement lighting.
Placement can address composition, but supporting architecture and coherent
cliff forms need suitable art. No motion or performance conclusion.

Disposition: **rejected and reverted from the game**. Candidate source,
integration patch, geometry smoke and raw before/after evidence are retained
here to prevent repeating an ineffective below-floor decoration approach.

Source review `settlement_structure_review` found no blocking geometry or
route/collision change, but predicted the old cliff surface could hide the
recess backing. Geometry smoke passed:168 closed individual solids, finite
normals, no degenerate triangles, no collision additions, highest point y=0.
These checks did not establish architectural visibility; native review won.

Shortcuts disclosed: stationary production camera, scripted progression,
hidden HUD, fixed60fps, native Windows NVIDIA Compatibility1920x1080. Wild and
companion poses differ between runs. Six frames are a subset, not full C2 or
ordinary-play proof. No full unit suite or Ally telemetry.
