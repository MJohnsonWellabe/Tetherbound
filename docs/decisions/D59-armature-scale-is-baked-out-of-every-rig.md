# D59. The armature scale is baked out of every rig, and D56 was wrong about the cause

Kind: implementation

Supersedes the diagnosis in D56. The owned-container and skip-geometry-passes
parts of D56 stand; the "six species are irreparable" conclusion does not.

**What D56 concluded:** six species (cindercub, sparrowick, grazehorn,
thistleback, cragpup, ashmane) explode into screen-filling shards from their
poly.pizza sources even loaded raw, so they were recast onto Kenney Cube Pets.
The owner has since rejected that look: the pals must match Palworld, and
blocky voxel pets in a world of proportioned Quaternius humanoids and monsters
was a style clash on top of that. One of the six, cindercub, is a starter, so
it was the first pal a new player ever chose.

**What is actually wrong with those files.** Quaternius exports carry the FBX
unit convention: an armature node scaled 100x sitting over centimetre-sized
geometry. Babylon handles that correctly when the skeleton has exactly one root
joint. The Animated Animals rigs do not. They park IK targets and pole targets
directly under the armature as additional root joints (grazehorn has five roots:
`Body`, `IKBackLeg.L/R`, `IKFrontLeg.L/R`), and every primitive skinned to one
of those secondary roots gets the 100x applied a second time. Sorted by root
count, the split is exact: all nine working species have one root joint, all six
broken ones have two or more. That is not a coincidence, it is the bug.

`skeleton.needInitialSkinMatrix` was tried and does not help.

**The fix, in the pipeline rather than the runtime.**
`normalizeArmatureScale()` in `scripts/lib/glbtool.mjs` bakes the armature scale
S into the data by conjugation. Descendant node translations, inverse bind
matrix translations, translation animation tracks and skinned vertex positions
all multiply by S, and the armature scale becomes 1. Every joint world matrix
becomes `W * S^-1`, so the skinning product `W' * IBM' * v'` reproduces
`W * IBM * v` exactly. There is no scale left for Babylon to double-apply, and
nothing about the rendered result changes for models that were already fine.

**The check that this is exact and not merely close:** the nine species that
already worked come out of `tools/rigcheck-bounds.mjs` with bounding extents
identical to before the change (bramblit 3.3m, tuftmoth 3.7m, voltvole 6.8m,
player 0.8m). If the conjugation were wrong anywhere, those would move.
`rigcheck-bounds` goes from 6 of 20 broken to 20 of 20 passing.

**What comes back with them.** The Cube Pets have no attack, hit or faint clips
at all, so those verbs were mapped to null and three of the six played no
animation for any of them, for the whole game. The restored rigs have the full
clip set again.

**Why D56 got it wrong.** Its evidence for "broken even raw" was
`tools/_oracle.mjs`, which loaded `/models/creatures/<id>.glb` from `public/`.
That is pipeline output, not a raw file. The raw sources were never actually
tested in isolation, and the prose claim outran the probe. Worth remembering
before writing "irreparable" into a decision record: name the file the probe
opened, not the file you meant it to open.
