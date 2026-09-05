# Code-blind visual verdict — round 2, run 6 frames

Judge: a second `opus` sub-agent via the Agent tool, given only the run-6
`_sheet_route_strip.png`, the four run-6 PNGs, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, plus the note that these are llvmpipe
road frames in the Meadows with one fight and a 1.80 m trainer as the ruler.
It was told nothing about round 1, what changed between the rounds, this
lane's existence, or what any answer would mean. Reproduced verbatim.

---

# Visual verdict — Meadows route strip, 4 frames

## 1. Defects, each named to a frame

### Creatures and characters (first, per the rubric)

1. **`band1_fight_galecrest` — the two creatures interpenetrate and merge into one silhouette.** Galecrest's near wing and body pass *through* Terrapup's front leg and muzzle; the blue bird's tail overlaps the pup's chest with no separation. At 30% they are a single beige-and-blue lump. Two creatures fighting must read as two shapes.
2. **`band1_fight_galecrest` — Galecrest does not read as a bird in a fight.** It is splayed flat on the ground, wings spread symmetrically, tail dragging — it reads as a downed/dead bird or a decorative wing prop, not a lunging airborne "AIR" opponent. Its whole body is one blue value band, so the wing, body and tail do not separate from each other either.
3. **`band1_fight_galecrest` — nothing in the frame says combat is happening.** No impact VFX, no dust, no muzzle/claw flash, no ground scuffing, no stance on either creature, no reaction pose on the trainer (arms at sides, standing at rest). Compare `palworld-01`/`palworld-03`: sparks, orange impact bursts, dirt kicked up, the character mid-swing, the boss mouth open. The only thing that says "fight" here is the HUD.
4. **`band1_00000m`, `band1_00040m`, `band1_00080m` — Terrapup's shell plates are a different art language to its body.** The body is soft, low-frequency painted fur; the plates are hard-edged, near-white (value ~245+), flat, untextured slabs. The plates are the highest-value object in every frame they appear in, so the eye goes to the shell, not the face. They also look like a different texel density than the fur.
5. **`band1_00000m` — the second humanoid (dark hooded figure beside the house) is a featureless grey blob.** No face, no readable head shape, no colour, an odd rounded hood that reads as a bulb. Beside a coloured, appealing trainer it reads as an unfinished stand-in, and it is placed at the third-most-prominent point in the composition.
6. **`band1_00080m` — the white rabbits are value-clipped white splotches.** The two left ones are unidentifiable as animals; only the rightmost reads as a rabbit. They are the brightest pixels in the frame and outrank the player character in the value hierarchy. None has a contact shadow.
7. **`band1_00040m`, `band1_00080m` — creature/trainer scale disagrees with the project's own board.** Measured off the 1.80 m trainer in `band1_00040m` (129 px head-to-foot), the crouched quadruped Terrapup is roughly **2.4–2.5 m at the ear and ~3.3 m long** — rhino-sized. The key art "DAY" panel shows the starter companion at roughly the trainer's hip. A Lv 1 starter that is three times the reference companion's mass is a loud scale statement; if intended, nothing else in frame supports it, and it makes the Lv 3 wild Galecrest (`band1_fight_galecrest`) read as the *smaller* creature, which inverts the encounter.

### World, terrain, scatter

8. **All three route frames — one tree asset, one bush asset, one rock asset, repeated at near-uniform scale.** In `band1_00040m` and `band1_00000m` the treeline is a straight belt of near-identical canopies at near-identical heights along the hill crest. No canopy-height variation, no understory layer, no clustering, no clearings, no single hero tree. This is the single loudest "generated, not placed" signal in the set. The key art's oak grove panel is built from three canopy scales and light punching through gaps.
9. **All three route frames — bushes are scattered on an even grid.** In the `band1_00040m` mid-ground you can trace rows. Even scatter with no density gradient. Palworld's fields (`palworld-02`, `palworld-03`) cluster: bare trodden ground, then a thicket, then bare again.
10. **All three route frames — the tree trunks are a uniform saturated terracotta/salmon.** Every trunk, near and far, is the same orange-red. Real oaks in the key art are desaturated grey-brown with value variation. This is also uncomfortably close to the reserved oxblood family and it is currently the second-largest colour mass in the world.
11. **`band1_00080m` — the road texture is mush.** Foreground dirt is a low-frequency blurred noise blob with no gravel, no wheel ruts, no edge transition; it just fades into grass. Pebbles sit on it as flat white lozenges with no shadow and no bedding — literal "props stabbed into dirt."
12. **All frames — grass is single isolated blades, not clumps.** Individual thin green needles standing at intervals out of a painted ground texture. There is no grass *mass* anywhere. `moong-02` and `palworld-02/03` both carry a continuous grass carpet the character wades into. Here the ground plane is visible everywhere between blades.
13. **`band1_00000m`, `band1_00040m` — large dead zones.** The left third of `band1_00000m` (below the treeline) and the left half of `band1_00040m` are empty graded green with nothing but repeated bushes. Roughly a third of each frame carries no information.
14. **All frames — no landmark.** The distant hills in `band1_00040m`/`band1_00080m` are bare rounded lumps with no rock face, no ridgeline, no structure. The key art puts a peaked mountain, a windmill, a tower and a standing stone into its wide shots; `palworld-04` puts a ruin and a tower on the horizon. There is nothing here to walk toward.

### Lighting, colour, depth

15. **All four frames — no cast shadows from anything.** Verified by zoom: the trainer, Terrapup, every tree, every rock and every pebble sits on the ground with zero contact darkening. Everything floats. `band1_00080m` has a large diagonal dark band on the road that belongs to no visible caster and reads as a terrain shading artefact, not a shadow.
16. **All four frames — the time of day does not read.** Sky is high-noon blue, but there is no directional key: terrain hills are flat-lit, and the value difference between a lit slope and a shaded slope is small. Nothing tells you where the sun is.
17. **Colour is over-saturated and the highlights are missing — measurable.** Mean HSV saturation: build frames **154–175**, Palworld references **103–118**, key art **104**. Luminance 95th percentile: build **169–188**, references **216–234**. Concretely: the world is a third more saturated than the bar and has no bright end at all. The greens are acid, and nothing in frame is sunlit-white. `band1_00080m` is the worst offender (sat 175, p95 169).
18. **All frames — zero aerial perspective.** Trees at 100 m+ in `band1_00040m` are the same saturation and value as trees at 15 m. No haze, no desaturation with distance, no fog. Depth is carried only by perspective, so the world reads as a flat backdrop. Every reference — key art and all five Palworld shots — uses distance haze heavily.
19. **`band1_00000m` — three incompatible art languages in one frame.** The half-timber house is crisp, detailed, near-realistic stone and timber; the trees are flat-shaded cartoon lollipops; Terrapup is soft painted plush. They look sourced from three different packs, and the house is by a wide margin the highest-fidelity object in the game.
20. **`band1_00000m` — the paving slabs at the house door sit on top of the grass as a hard-edged flat plane** with no blend, no dirt scuff, no worn transition.

### Fight-frame interface

21. **`band1_fight_galecrest` — the Galecrest nameplate is oversized and badly placed.** It occupies ~30% of the frame width at top-centre and covers the only landmark (the boulder). Palworld's equivalent boss bar is a compact strip that leaves the boss and the scenery visible.
22. **`band1_fight_galecrest` — the Terrapup party panel crops the player character's legs.** The panel's top edge cuts the trainer at mid-thigh. The player is the one thing that must never be occluded by the HUD.
23. **`band1_fight_galecrest` — the ability bar reads as prototype.** Two of four buttons are greyed ("Stone Rush", "Switch"), "No orbs" is an error state rendered as a button, and there is no icon language — just text on grey slabs. `palworld-01`'s HUD is small, iconographic and stays out of the picture.
24. **`band1_fight_galecrest` — the boulder behind the fight is a soft green-grey potato** with visible faceted/hex shading bands and no clear ground contact. It is the arena's only set piece and it is the weakest asset in the frame.

### Readability at 30%

25. **On the contact sheet the three route frames are indistinguishable from one another.** Same camera height, same trainer-plus-Terrapup blocking at the same screen position, same green/tan split, same treeline band. A route strip should show the region changing; these show the same shot three times.
26. **At 30%, tree, bush and rock are not separable in `band1_00040m`.** They are all mid-green blobs at similar scale. Only the fence and the dirt path survive.

---

## 2. The three things that most separate these frames from the references, ranked

**1. Nothing casts a shadow, and there is no aerial perspective — so the world has no form and no depth.**
Every Palworld reference and the key art place objects on the ground with a shadow and push distance back with haze. `band1_00080m` is the clearest case: a trainer, a 2.5 m creature, a mountain and three rabbits, and not one of them is attached to the ground; the mountain is the same saturation as the grass six metres away. The result is a diorama of decals rather than a place.

**2. The scatter is a generator's output, not a designer's.**
`band1_00040m` — one tree asset in a straight belt at one height, one bush asset on an even grid, one rock asset, and a third of the frame empty. The key art's oak grove panel and `palworld-02` both build a field out of density *changes*: a trodden bare patch, a thicket, a clearing, a hero tree. Here the density is constant everywhere, so the eye has nowhere to go and there is no landmark to walk toward.

**3. The fight does not look like an event.**
`band1_fight_galecrest` — two static models parked inside one another, no VFX, no poses, no camera emphasis, the opponent lying flat, and the only landmark hidden behind an oversized nameplate. `palworld-01` and `palworld-03` sell a boss with sparks, dust, an open mouth, a mid-swing character and a framed silhouette. This is the frame the whole game is named after and it is currently the flattest one in the set.

---

## 3. The two bar questions

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?

**No.**

What carried it: the *subject matter* is right — rolling hills, a dirt road, wildflower meadow, post-and-rail fence, a half-timbered settlement, a companion beside the trainer. The house asset in `band1_00000m` genuinely could have come off the STARTING SETTLEMENT panel. The trainer himself (close crop of `band1_fight_galecrest`) is on-model: stylised, coloured, appealing.

What sank it: the board's own notes are "vibrant, readable colours with a **natural** palette" and "silhouettes and landmarks visible from distance." The build is not natural-palette — it is 50% more saturated than the board with no highlight range, so the greens go acid and the trunks go terracotta. And there are no landmarks: the board's every wide shot has a peak, a windmill, a tower or a standing stone; `band1_00040m` and `band1_00080m` have bare green lumps. Third, the board's canopies are massive, layered, and light passes through them; the build's are a repeated lollipop belt.

Fixable by scene changes: the saturation/value grade (pull saturation ~30%, open the highlight end), the terracotta trunk tint, the flat sky (the board has cumulus, the build has thin streaks), aerial-perspective haze, enabling and tuning cast shadows, clustering the scatter with real clearings and density gradients, tall-grass clumping instead of isolated blades, road texture and edge blending, adding a landmark to the horizon from existing rock/building assets, and moving the fight-frame nameplate off the boulder.

Needs art not in the build: canopy variety (at least two more tree silhouettes and a hero-scale oak — one asset cannot make a grove), a distinctive horizon landmark mesh, a grass-clump card that is not a single blade, and a face for the hooded humanoid in `band1_00000m`.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**Yes — genre-wise, and only barely.**

What carried it: the read is unmistakable. Third-person trainer, an oversized companion creature at his shoulder, a named levelled opponent with a health bar, a party panel and an ability bar, wildflower meadow, fences and a settlement. Anybody shown `band1_fight_galecrest` next to `palworld-03` would name the same genre without hesitation, and Terrapup's design — chunky quadruped, big eye, plated shell — sits in the same design space as a Pal, which is more than most projects at this stage can claim.

What sank it as a *quality* comparison (the answer is yes to the question asked, but do not read it as a pass on the bar): ground cover density is not close — Palworld's fields are a continuous grass carpet the character wades through, these are isolated blades on a visible ground plane; the fights carry no VFX at all; the value range is compressed with no sunlit whites; and nothing is shadowed onto the ground.

Fixable by scene changes: grass density and clumping, shadows, colour grade, scatter clustering, HUD sizing and the panel that crops the trainer, framing the fight camera so the two creatures do not overlap.

Needs art not in the build: **combat VFX** — impact bursts, dust, ability telegraphs, hit flashes. There is currently none, and no amount of scene tuning creates it. Also: a fight-appropriate pose/animation set (Galecrest needs an airborne or lunging pose; both creatures need a combat stance), and the shell-plate material on Terrapup needs to be reauthored to match the fur rather than read as white cardboard.

---

## 4. Per-frame: creature presence, readability, and the fight

| Frame | Creature present? | Readable beside the trainer? |
|---|---|---|
| `band1_00000m` | Yes — Terrapup, plus a second humanoid (hooded figure) | **Partly.** Terrapup is large and near, but it is pressed against the house's grey stone wall, so its beige body and white plates fight the masonry behind it. Its rear half is lost against the wall. The hooded humanoid is **ambiguous** — a dark blob with no face, unidentifiable as friend, foe or villager. |
| `band1_00040m` | Yes — Terrapup | **Yes, best of the set.** Clean profile against sky and open grass, head and shell both read, clearly bigger than the trainer. This is the only frame where the creature's silhouette is unambiguous. |
| `band1_00080m` | Yes — Terrapup, plus three white rabbits | **Terrapup yes; rabbits no.** Terrapup reads, though its rear is cropped by the frame edge. The rabbits are white specks — the two left ones are not identifiable as animals, and they out-brighten the protagonist. |
| `band1_fight_galecrest` | Yes — Terrapup and Galecrest | **No.** They occupy the same volume and merge into one silhouette; Galecrest's blue is one flat value so its own wing/body/tail do not separate; the trainer is small, static and has his legs cropped by the HUD panel. |

**Is the fight frame recognisably a fight between two creatures with the trainer watching?**

**Only because the HUD says so.** Strip the nameplate, the party panel and the ability bar and you have two toys placed inside each other in a field, one of them lying flat with its wings out, and a boy standing thirty feet away with his arms down. There is no impact, no motion, no stance, no separation, no camera emphasis. The subjects are not too small and not hidden, but they are **ambiguous** — the overlap is the killer, and it is the first thing to fix.
