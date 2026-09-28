# Galecrest visual judgement — final supplied evidence

Date: 2026-09-27. Independent image review using `.claude/skills/visual-judge/SKILL.md` and the visual criteria in `docs/design/ART_DIRECTION.md`. No implementation, capture manifests, previous verdicts or repository history were inspected. The art-direction document itself includes historical dispositions; those statements were not used as evidence of acceptance.

## Evidence inspected

All twelve individual 1920×1080 production frames were inspected, plus the six small frame-matrix sheets for reduced-size readability:

| Folder below `world-final/` | Individual frames |
|---|---|
| `vivid-day` | `12_windscar_ravine_route_day.png`, `13_windscar_ravine_reverse_day.png` |
| `vivid-night` | `12_windscar_ravine_route_night.png`, `13_windscar_ravine_reverse_night.png` |
| `shiny-day` | `12_windscar_ravine_route_day.png`, `13_windscar_ravine_reverse_day.png` |
| `shiny-night` | `12_windscar_ravine_route_night.png`, `13_windscar_ravine_reverse_night.png` |
| `alpha-day` | `12_windscar_ravine_route_day.png`, `13_windscar_ravine_reverse_day.png` |
| `alpha-night` | `12_windscar_ravine_route_night.png`, `13_windscar_ravine_reverse_night.png` |

Also inspected all eighteen `clips-final/galecrest-{idle,walk,run,attack,hit,faint}-{25,50,75}.png` samples, and all six `variants-r2/{vivid,shiny,alpha}-{000,135}.png` material views. References viewed as images: Meadows key art; all five `palworld-0*.jpg`; Cloudreach Sky Aviary and Cloudreach creature-roster boards; `assets/creatures/tetherbound/galecrest/reference/rebuild/galecrest.png`.

The world frames are production-camera evidence. Studio material views and sampled animation poses are diagnostic. Three stills per clip do not demonstrate timing, continuous foot locking, transitions or motion quality. No UI is visible to judge. These two route orientations do not establish whole-chapter acceptance.

## Scoped creature verdict

**Galecrest's anatomy, recognisable silhouette, face/neck readability and basic production-camera separation pass in these supplied world views. Its finish is still a polish item, especially alpha at night. Complete animation and ground-contact acceptance remain open.** This is an identifiable, designed large bird with a clear face, not an unreadable creature-shaped mass. It is also more detailed and expressive than much of the environment around it.

The spread primaries, upright feather crest, hooked dark beak, cream throat and two substantial taloned legs agree with the supplied Galecrest reference. Head and neck join continuously; the face is not buried in the shoulder plumage. `variants-r2/vivid-000.png` shows an eye socket and brow with a definite expression. In `world-final/vivid-day/12_windscar_ravine_route_day.png`, the crest, beak direction, chest and wing bands remain recognisable without zooming. At sheet size, the bird stays distinct from the terrain and trainer. The reference's amber eye is less prominent in-game, but the face region survives. No gross missing limb, detached head, collapsed neck or body-scale mismatch is visible. Beside the trainer it convincingly reads as the larger creature.

**Finish needs restraint.** `variants-r2/vivid-000.png` has hot white chest/crest highlights beside a muddy, softly mottled belly. The same variation in feather treatment is visible at production scale in `world-final/vivid-day/13_windscar_ravine_reverse_day.png`: the throat reads as sharp overlapping plates while the lower torso reads much softer. `variants-r2/alpha-135.png` adds bright silver edge streaks over the back and tail, with very dark primary feathers. It looks closer to lacquered or metallic feather armour than the softer natural plumage in the reference. Reduce the hard highlight contrast and make the large feather groups share a more consistent surface response. This is material/art finish work; a new species silhouette is not indicated by these pictures.

**The colourways remain anatomically organised.** Vivid's cream wing bands and dark slate primaries preserve the reference's natural palette. Shiny's cyan tips, cool wing bands and blue belly read as a deliberate alternate design; the pale face, natural feet and dark beak remain intact (`shiny-day/12...`, `shiny-day/13...`). No obvious whole-body colour wash or colour spill onto the eyes, beak or feet is visible.

**Alpha is distinguishable, but loses too much wing form at night.** In both `alpha-night/12_windscar_ravine_route_night.png` and `alpha-night/13_windscar_ravine_reverse_night.png`, the primaries become nearly black/navy blades with saturated blue edges, beside a much brighter silvery torso. The outline remains readable, but feather volume is less legible than vivid's or shiny's. The small gold motes are restrained; they do not repair the loss of wing midtones. Preserve the dark identity while recovering a little broad feather value and reducing the electric edge emphasis. This is not a reason to brighten every body part.

**Day/night readability is otherwise successful for this subject.** Vivid remains slate-and-cream in day and blue-gray-and-pale at night; shiny stays visibly different from vivid in both. All six night/day pairings keep the face region, chest, overall wings and legs identifiable. Night itself is unmistakable. The trainer's lower body and route also remain visible.

**Production grounding is plausible in the shown stills, but not certified in motion.** In the day route frames, visible talons approach the grass surface and the large attached cast shadow gives the body weight. The reverse frames retain a contact shadow around the feet. I do not see a clear, large production-camera hover gap or gross foot burial that warrants rejecting those world stills. Darkness makes precise claw contact less certain in night frames.

There is an apparent clearance issue in the studio: `clips-final/galecrest-idle-25.png` shows light floor between the lower claws and their shadow, and `variants-r2/vivid-135.png` similarly reads elevated at the feet. The studio floor/capture relationship cannot establish the same defect on production terrain. Check it with a close production side view and a continuous idle/walk sequence; do not treat this diagnostic as proof that production grounding is solved or broken.

## Sampled pose findings

The eye/beak/neck shape remains coherent in idle, walk, run and the visible attack/hit phases. No conspicuous neck tear is visible in these eighteen samples. Walk and run show alternating leg positions and different wing attitudes; the stills cannot establish whether their timing communicates weight or whether feet slide. In `galecrest-attack-50.png`, the near wing hides almost the entire head, so the action's expression is unavailable from this side angle. Review the strike from the production camera before accepting combat readability. The head is visible again at attack-75.

`galecrest-faint-50.png` and `galecrest-faint-75.png` communicate a fall, but the latter spreads a large wing across the floor and brings the head very close to it. There is no unequivocal large body penetration visible from this angle; it does not prove the final resting pose is clean because the sample ends at 75%. Several idle/walk/attack samples also crop the high wing tip at the image border, limiting checks of that extremity. These are explicit evidence limits, not inferred rig defects.

## Full-scene findings

The route is easy to identify, the creature flanks it without hiding the trainer, and the sky/cloud layer establishes altitude. However, the location does not yet sustain the reference's authored, inhabited cliff-world impression.

- In every `12_windscar_ravine_route_day.png`, the left cliff occupies a very large area as a broad tan slab with sparse shelf protrusions. The thin pale spikes in the distance and low cloud bank do supply depth, but the near landform lacks the broken buttresses, substantial strata and vegetation pockets that make the Sky Aviary board's geology feel natural.
- Every `13_windscar_ravine_reverse_day.png` exposes a long almost straight grass-topped wall in the upper right, repeated coarse block faces on the left, and broad empty green slopes around the path. The path reads as a painted strip over a smooth surface; its edges have little wear, rock, bank or ecological transition. Palworld's open-field/path and plateau references join ground, grass, rocks and landform more convincingly.
- Large flat angular grass blades in the right foreground of `12...` and on both sides of `13...` clash with Galecrest's many layered feathers and the textured trainer. The small shrubs/flowers form dense strips farther along the path while the near ground remains mostly a blurred green material with widely separated tufts. This variation reads as a change of asset treatment more than coherent ecology.
- In all night reverse frames, the dark upper wall becomes a large almost featureless wedge. The brighter distant white creatures remain readable lures, but this does not supply a distinct authored destination or inhabitance. There is no combat-event evidence in the supplied world frames, so fight staging is unjudged.

## Three largest gaps from the references, ranked

1. **Environmental material and shape coherence.** `vivid-day/13_windscar_ravine_reverse_day.png` places a finely feathered hero beside broad flat grass blades, smooth green ground and coarse cliff walls. Palworld-02 and Palworld-04 use a compatible level of shape/material finish across creature, ground and cliffs. Repair needs both scene/material treatment and better-shaped vegetation/cliff art; scatter alone cannot change the visible flat blades or wall silhouette.
2. **Authored cliff-route integration.** `vivid-day/12_windscar_ravine_route_day.png` and its reverse have a clear route but large unmodulated slabs/slopes and abrupt path edges. The Cloudreach board makes grass, rock shelves, ledges and built routes belong to one vertically layered place. More thoughtful ground transitions, clusters and framing are scene-fixable; inadequate cliff shapes need geometry/art work. This is not a demand to place the Aviary landmark in an unrelated ravine view.
3. **Feather finish and alpha night values.** `alpha-night/13_windscar_ravine_reverse_night.png` loses primary-feather volume into dark blades while the chest stays sharply bright; `variants-r2/alpha-135.png` shows the corresponding hard silver/cobalt finish. The supplied bird reference and Cloudreach roster use cleaner broad plumage groups with readable internal volume. Targeted material/value work is appropriate; replacing the readable face or core anatomy is not supported by this evidence.

## Full-scene bar answers

**A — No.** These frames contain the correct ingredients—open sky, pale distant stone, green cliff ledges, a substantial winged companion and distinct night colour—but do not yet read as a sufficiently coherent realization of the Meadows key art's world translated through the Cloudreach board. The slab-like near geology, bare smooth slopes and incompatible foliage treatment sink the scene-level identity/finish judgement. Route dressing, material transitions, clustering and value separation are scene-fixable. The current visible blade and cliff shapes also require art/geometry work, not just a tint or density increase.

**B — No.** The creature-adventure genre is obvious, and Galecrest itself contributes a credible designed subject. Beside the five Palworld gameplay references, however, these full frames still read as an assembled environment below the intended polished production register. Terrain-to-foliage integration, landform authorship and consistent asset finish are the decisive gaps. This is not a claim that the games must have identical assets or pixel fidelity. Scene composition/material work can address part of the gap; unsuitable environmental shapes need improved art. This scene-level no does not overturn the scoped anatomy/face readability pass above.
