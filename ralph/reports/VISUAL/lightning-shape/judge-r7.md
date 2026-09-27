# Lightning visual review r7

**Scoped lightning still-image verdict: PASS in normal and reduced modes. Whole-frame Bar A: NO. Whole-frame Bar B: NO.** These are separate judgments. The surrounding scene's failures do not make the branching lightning silhouette an intrinsic art failure.

## Evidence and limits

Reviewed the visual-judge skill and ART_DIRECTION.md, the Meadows key art, all five `palworld-01` through `palworld-05` screenshots, and both `stormwood-stormheart-tree-stronghold-board-a/b.png` boards. The boards establish electrical silhouette and nature/material relationships, not a demand for painted-image fidelity or their exact lighting. Stormwood's prescribed purple storm is valid.

Individually inspected all 19 PNGs in each of `shots/vis_f10_3_motion/art-shape-normal-corefinish` and `art-shape-reduced-corefinish`, normal first: t000, t010, t020, t030, t040, t050, t060, t070, t080, t090, t100, t110, t120, t125, t130, t140, t150, t160, t170. All are native 1920×1080. Also inspected the selected-frame 25% contact sheet `lightning-r7-sheet.png` beside this report. No source, git history, prior verdicts, or engine were inspected.

Frame shorthand below is exact: **N120** means `art-shape-normal-corefinish/art-shape-normal-corefinish_h12_t120.png`; **R120** means the corresponding reduced-mode file. Other numbers use the same naming pattern.

These stills establish depicted stages and relative visual clarity. They cannot prove animation timing, electrical flicker, warning duration, transitions between captures, audio, comfort in motion, or performance. A small sheet is a legibility check, not a substitute for a native low-resolution capture. No creatures are visible clearly enough for creature-art acceptance; this sequence cannot close that part of the game's presentation.

## Scoped acceptance

| Criterion | Normal | Reduced | Evidence |
|---|---|---|---|
| Warning footprint | PASS | PASS | N000/R000 show a wide magenta ground ellipse with a clear interior and centre beneath the trainer. It remains distinguishable from the gold ground bands and survives the small sheet. It does not obscure the body. |
| Depicted warning progression | PASS | PASS | N000→N060→N110 and R000→R060→R110 show magenta leaders extending inward until they join beneath the feet. The perimeter holds its position; the spatial change is readable without relying only on brighter colour. This passes the sampled-stage test, not a timing test. |
| Sky-to-ground silhouette | PASS | PASS | N120/N125/N130 and R120/R125/R130 have a connected, irregular main channel entering from the top edge, substantial asymmetric forks, finer subsidiary branches, and a ground termination at the warned centre. Main channel versus branch hierarchy is clear. At small size it remains a lightning strike, not a column, beam, or floating zigzag. |
| Intrinsic lightning material finish | PASS | PASS | In those six strike frames, the narrow pale core and soft violet-white edge read as luminous discharge. Finer branches taper into hairline ends. There are no conspicuous opaque slabs, broad shaded faces, blunt caps, or detached segment blocks in the visible bolt. The restrained finish belongs to the intended stylized electrical language. It is less forceful than the reference boards, but a larger painted halo is not required for this local strike to pass. |
| Contact and depicted recovery | PASS | PASS | N120/R120 connect into a concentrated foot-level discharge with upward and outward filaments, white ground leaders, and the footprint changing to pale white. N140/R140 remove the vertical channel and retain a faint footprint; N150–N170/R150–R170 clear it. The hit location and end of the temporary event are legible. Normal also shows stronger local illumination at contact. Smoothness and actual duration remain unproven. |
| Retained reduced-mode information | — | PASS | R000–R110 preserve warning area, centre, and convergence; R120–R130 preserve the main channel, branches, contact cluster, and pale perimeter; R140–R170 preserve recovery. Reduced illumination does not erase the required geometry. This is information-retention acceptance only. |

There is **no blocking intrinsic lightning-shape or lightning-material defect visible in this submitted view**. This does not certify other strike variants, viewing directions, gameplay compositions, or temporal behavior.

## Named defects and scope split

1. **Gold ground bands compete with the actual strike — scene/VFX integration.** In N120/N125 and R120/R125, broad saturated gold zigzags cover the lower foreground and contain hotter, wider white patches than the sky bolt. Their near-parallel repeated paths resemble luminous paint on a road. The bolt is identifiable, but the eye is pulled down and out of the impact. Narrow and break up the environmental bands, reduce their peak area/value, and give their contact with soil a more natural material transition. Preserve the magenta warning footprint. This is not a demand to thicken the accepted bolt into a beam.

2. **The landscape opens onto a largely empty straight horizon — scene composition.** N000/N170 and R000/R170 show strong near trees framing a flat purple-brown middle distance with a few isolated rocks. The sequence reads as a small dressed foreground in front of a sparse expanse. Both Stormheart boards make the electric forest feel enclosed by layered trunks, canopy, landform, and a destination; the Meadows board similarly provides near/middle/far structure. Add authored middle-distance masses and a meaningful route/destination silhouette. Do not solve this with a uniform grass carpet.

3. **Ground and vegetation have a coarse, disconnected material register — scene materials and some asset work.** N040/N150 and R040/R150 show blurred dark soil, individually sharp ribbon grass, repeated small angular flowers, and very dark canopy clumps. Large trunks read smoothly streaked rather than as wet old bark and roots. The references join paths, moss, roots, ground cover, and larger vegetation into coherent masses. Improve ground transitions and clump scale/value organization; material work can help bark, but more convincing root/trunk and canopy forms may require mesh work. This cannot all be repaired by tinting the scene.

4. **A straight foreground surface discontinuity remains visible — scene artifact.** N070/N120 and R120/R140 show a horizontal band near the bottom of the path where texture/light treatment cuts across the otherwise continuous soil and gold marking. Inspect the rendered surface/material boundary and remove the straight cut. These stills show the artifact but do not establish its implementation cause.

The trainer's blue sleeves, brown pack, dark trousers, and pale collar form a readable adventure silhouette throughout, including contact frames. The left NPC is legible as a person, but fine facial or character-quality conclusions are limited by distance. Character readability is a strength here; absent close creature evidence is not a creature pass.

## Largest three reference gaps, ranked

1. **World depth and authored destination:** N000/R170 lack the layered forest and meaningful middle-distance mass of both Stormheart boards and the terrain/landmark staging of Palworld 04. Primarily scene composition; suitable landmark/trunk silhouettes may need art if unavailable.
2. **Ground/material cohesion:** N040/R150 have blurred soil, sharp grass ribbons, and gold painted bands; Palworld 02/05 and the Meadows board use convincing ground-cover transitions and material scale. Primarily scene/material work, with root/canopy geometry needs where silhouettes are inadequate.
3. **Event hierarchy and context:** N120/R120 communicate a strike, but environmental gold markings take much of its visual emphasis, while Palworld 01/03 make the action and its creature subjects the designed focus. Scene/VFX hierarchy can fix this shot's competition; these captures provide no evidence to certify creature presentation.

## Whole-frame bars

**Bar A — NO.** There is a recognizable shared direction in the trainer, natural green foliage, purple storm, and white-violet branching electricity. However, the bare middle distance, lack of an enclosing old-forest structure, weak wet-root/moss/material relationships, and gold road-strip read prevent these complete frames from belonging convincingly to the Meadows/Stormheart family. Scene dressing, composition, and material integration are actionable; substantial trunk/root/canopy silhouette deficiencies need actual art work rather than global grading.

**Bar B — NO.** The captures communicate a third-person fantasy adventure and a readable hazard. Beside the five Palworld shots, the sparse depth, coarse ground/vegetation cohesion, and visually dominant environmental bands do not yet reach the intended polished creature-adventure register. This is a whole-frame rejection, not a rejection of the local lightning silhouette or its material. The missing creature presentation remains unassessed, not excused or inferred to fail.
