# Area 2 — village (Band 0) — blind critique, round 1

Frames: `shots/census/02-village/` — the six live in-engine village stands from
`tools/_capture_locations.gd` (`01-village-{approach,standing,twins,grandpa-yard,
tournament,route-out}-day.png`) plus `shots/_diag/village_npcs.png` from
`tools/capture_village_npcs.gd`. Sanity-checked before judging: the world-build
log shows real content (village structures, 19 village NPCs, grass field bound
and drawing), and this lane inspected `01-village-approach-day.png` directly and
confirmed real grass geometry, real buildings and the trainer in frame — the
"bad shot, not the actual game" failure `tools/capture_check.gd` exists for did
not occur here.

Critic given only the sheet, the frames, `docs/reference/` and the rubric, plus
factual context that six are live world frames and one is a bare-stage line-up.
Verbatim below.

---

I read the rubric, the key art, all five Palworld frames, the reference README, the contact sheet, and all seven PNGs at full size plus zoomed crops. Critique follows.

---

# Visual critique — `shots/census/02-village/`

## 0. The thing to say first: there are no creatures in any frame

Six live world frames of the home settlement of a creature-training game, and there is not one creature in any of them. No pal, no livestock, no chicken, no bird, no dog by a door. `01-village-approach-day.png`, `01-village-standing-day.png`, `01-village-twins-day.png`, `01-village-grandpa-yard-day.png`, `01-village-tournament-day.png` and `01-village-route-out-day.png` are all empty of anything non-human.

Every one of the five reference screenshots has creatures in frame — `palworld-05-base-building.jpg` is a *base management* shot and still has three Pals visible including one two metres from camera. The key art's STARTING SETTLEMENT panel is quieter, but the DAY and NIGHT panels both put a creature beside the player as the first thing you see.

So criterion "creatures and characters are in scope and are the point" can only be half-answered: I can judge the humans, and I do below, but the creature half of the game's look is not in these pictures at all. In a settlement census, that absence is itself the loudest finding.

---

## 1. Silhouette and readability at small size

Judged from `_sheet.png` downsampled to 30%.

- **The player is the hardest thing in the frame to find.** In `01-village-approach-day.png` and `01-village-tournament-day.png` the trainer is a brown-and-desaturated-teal shape standing in mid-green grass of near-identical value, with no cast shadow, no rim light and no saturated hero colour. At 30% he disappears into the field. `palworld-02-open-field-path.jpg` and `palworld-03-field-boss-meadow.jpg` put the player in a saturated blue/white garment with a chartreuse hair silhouette against a desaturated tan path — findable instantly at thumbnail. Fix is a costume value/hue decision plus a contact shadow, not a mesh.
- **Attention hierarchy is inverted.** The single loudest object on the whole contact sheet at 30% is the purple flower clump in `01-village-grandpa-yard-day.png`. A ground weed out-competes both characters and the building. Nothing else in the sheet is that saturated.
- **No landmark anywhere.** At 30% the six frames read as three or four repetitions of the same roofline. Nothing says "this is the centre of the village." The key art STARTING SETTLEMENT panel solves this with a green banner on a tall mast plus a covered well-house; the hero panel uses a windmill and a stone tower; `palworld-04-plateau-landmark.jpg` uses a ruin and a blue spire visible from any distance. `01-village-approach-day.png` is the arrival shot and gives the player nothing to aim at.
- **Prop discrimination fails in the mid-ground.** In `01-village-approach-day.png` at small size the barrel/crate cluster, the dark shrub, and the leafless branch prop are all one indistinct dark blob. Tree-from-rock-from-bush is only reliably readable for the single foreground boulder.
- `village_npcs.png` at 30% is five indistinguishable figures. That is a defect of the cast, covered in §8.

Positive: the buildings themselves have clean, readable gable silhouettes at thumbnail, and the six frames unmistakably read as one place.

---

## 2. Colour and value structure

- **The value range is compressed into the upper-middle.** Across `01-village-approach-day.png`, `01-village-twins-day.png` and `01-village-tournament-day.png` there is essentially nothing below mid-grey and nothing above light-grey except the sky and the chimneys. There are no dark accents because there are no shadows (§4). Every Palworld frame, even the flattest, holds deep near-black under canopies and at building bases; `palworld-01-boss-fight-forest.jpg` runs from black foliage to blown gold sparks in one image.
- **The one deep value present is wrong.** The foreground boulder in `01-village-approach-day.png` is near-black with a flat high-frequency noise skin and no large-form facets. It is darker than anything else in the frame by a wide margin, so it punches a hole in the composition, and it does not belong to the same rock family as the pale grey rocks mid-field or the smooth tan lumps on the hill in the same frame. Three rock families, none matching.
- **The chimneys and the well are the brightest things on the ground plane and are nearly pure white.** The well parapet in `01-village-route-out-day.png` and the chimney in `01-village-standing-day.png` clip toward white. In the key art, village stone is warm grey-ochre and never brighter than the sky.
- **Palette drift from the board.** The key art's settlement runs warm ochre plaster, weathered brown beams, mossy terracotta and grey-green foliage. The build's houses are cream-white plaster, near-black beams, and a pure vermilion roof. `01-village-twins-day.png` puts two roofs side by side at two clearly different hues and saturations (strong red left, salmon-orange right), which reads as two unmatched assets rather than as authored variety.
- **Oxblood reserve:** technically intact — the roof red is a bright vermilion, not the maroon on the Team Tether banners in the key art. But it is worth saying that the highest-saturation, most eye-grabbing colour in every friendly frame is a red, which erodes the reserve's effect long before the stronghold shows up. `01-village-standing-day.png` is the worst case: the red roof owns half the frame.
- Foliage is a single green. Grass, shrub cards, tree canopies and the ivy are all within a narrow yellow-green band, with no dry grass, no blue-green shade, no autumn tint. `palworld-02-open-field-path.jpg` gets a lot of its readability from bleached tan ground against saturated green scatter; here the ground under the grass is the same green as the grass.

---

## 3. Intentionality — does this look authored or generated?

Mostly generated.

- **Buildings are a kit at regular intervals.** In `01-village-approach-day.png` four houses stand in a near-straight line at similar spacing, all facing roughly the same way, all from the same timber-frame family at three sizes. `01-village-twins-day.png` names the problem in its own filename: two near-identical houses, same footprint, same orientation, differing only in roof tint. There is no barn, no workshop, no market stall, no smithy, no communal fire, no laundry, no woodpile, no crop bed, no animal pen.
- **The scatter is uniform.** One tall grass blade and one broadleaf shrub card, distributed at a constant density over the entire terrain in every frame, with no clustering, no clearings, no bare trodden ground, no density falloff around structures. `palworld-02-open-field-path.jpg` has grass massing in clumps, thinning to bare dirt on the path, and thickening at the cliff base — clear authored variation.
- **The settlement has no negative space.** Waist-high meadow grass grows to the doorsteps in `01-village-twins-day.png` and `01-village-grandpa-yard-day.png`, and grows *through the paving* in `01-village-route-out-day.png`. A settlement is defined as much by what has been cleared as by what has been built; nothing here has been cleared. The key art settlement panel has a wide beaten earth square with grass pushed to the edges.
- **Fences are decoration, not enclosure.** In `01-village-tournament-day.png` and `01-village-approach-day.png` fence runs start and stop in open meadow, dead straight, evenly posted, enclosing nothing and gated nowhere.
- **Signs of life are near zero.** One cart in `01-village-route-out-day.png`, one bucket on the well, one barrel-and-crate pair in `01-village-approach-day.png`. `palworld-05-base-building.jpg` is dense with crates, a workbench, a chest, a fire, a produce barrel, ropes and a palisade in a single small frame.
- **Two dead leafless branch props** stand in `01-village-approach-day.png` (one centre-right between houses, one at far right) in high summer beside fully-leafed trees. They read as broken or unloaded assets rather than as a designed touch, and they are the second time a "dead tree" reads as an error — the same prop repeats at the right edge of `01-village-twins-day.png`.

---

## 4. Lighting — the single biggest structural failure

**There are no cast shadows anywhere in any of the six world frames.** Not from buildings, not from characters, not from trees, not from props.

Concretely:
- `01-village-standing-day.png`: a two-storey house with a deep eave overhang throws no shadow band on its own wall, and nothing at all on the ground or on the neighbouring cottage. The chimney throws nothing on the roof.
- `01-village-route-out-day.png`: the trainer stands on a pale flagstone in full daylight with zero contact shadow — he is a cut-out pasted onto the ground. The well's roof posts are directly above the parapet and darken nothing beneath them.
- `01-village-twins-day.png`: the left gable is clearly lit and the right side is in shade, so a directional light exists — and still nothing falls on the grass to the right of the building.
- `01-village-approach-day.png`: crates, barrel and boulder all float for the same reason.

Consequence: the time of day is unreadable, terrain has no form (the hills in `01-village-tournament-day.png` are a smooth green wash with no modelling), and every object sits *in front of* the ground rather than *on* it. Every reference frame does the opposite — `palworld-02-open-field-path.jpg` and `palworld-04-plateau-landmark.jpg` both use hard sun shadows on the path and grass as the main depth cue, and the key art's whole read depends on dappled canopy shadow on the ground.

Second lighting defect: **visible point-light hotspots on the ground in daylight, with no emitter.** A yellow-white circular glow blob sits on the grass at the base of the right house in `01-village-twins-day.png`, at the base of the right-hand tree in `01-village-approach-day.png`, and again at the left edge of `01-village-grandpa-yard-day.png`. These read as debug/placement lights left switched on.

Third: no ambient occlusion of any kind. No darkening in the timber-frame recesses in `01-village-standing-day.png`, none where walls meet ground, none under the trainer's chin or backpack in `01-village-route-out-day.png`. Characters and buildings both read as flat-lit stickers.

---

## 5. Horizon and depth

- **Visible scatter-cull horizon.** In `01-village-tournament-day.png` grass and shrub scatter stops abruptly at roughly the fence line, and everything past it is bare untextured green shell all the way to the hills. The same hard line is visible in `01-village-approach-day.png` and `01-village-twins-day.png` at a similar distance. The world reads as ~40 m of dressed terrain surrounded by a green cyclorama.
- **Hard-edged terrain splat artefact.** In `01-village-tournament-day.png`, right of the mountain, there is a tan rectangular patch with 90° corners painted on the hillside. It is unambiguously a paint/blend square, not a feature.
- **The one distant landmark is weak.** The mountain in `01-village-tournament-day.png` is a low-poly grey-green cone with a smeared noise texture, no strata, no treeline, no silhouette interest, sitting alone on an otherwise empty horizon. Compare `palworld-04-plateau-landmark.jpg`, where layered plateaus, a ruin and a tall spire build three depth planes; the key art always stacks at least two ridge lines behind the settlement.
- **Aerial perspective is a flat grey wash.** Distant hills lose saturation but do not shift toward the sky's blue, and near/far greens sit at nearly the same value, so distance is signalled only by blur. The horizon in `01-village-approach-day.png` is a hard green-meets-sky edge with nothing beyond it.
- **Tree LOD alpha breakup.** The tree behind the far-right house in `01-village-approach-day.png` renders as a jagged, hard-aliased alpha card cluster with stair-stepped edges — clearly visible at 1:1 and readable as green mush at thumbnail.
- **The sky is the weakest large area.** In `01-village-approach-day.png` and `01-village-tournament-day.png` the cloud layer is a low-resolution smeared texture in muddy brown-tan streaks, occupying 40–50% of frame. The key art uses crisp white cumulus against a clean blue gradient in every panel, and it is a substantial part of why the board reads "cozy and inviting."

---

## 6. Interface

No HUD is present in any frame, so hierarchy and safe area cannot be judged (and per the rubric I am not comparing HUD design against Palworld anyway). What is judgeable is the diegetic signage, and it fails:

- `01-village-standing-day.png`: the four signpost labels are near-white cards that read as floating UI, not painted wood. Their text is at four different sizes; "The Rise" is large and crisp while "Practice Meadow" is small, blurred and unreadable at 1:1. The "Grandpa's House" label is clipped by, and intersects, the cottage's door frame.
- `01-village-tournament-day.png`: a white notice board plane stands directly behind the trainer, its text illegible at any size, and the trainer's hair renders over/through it. It reads as a UI panel dropped into the world at the wrong scale and depth.

---

## 7. Artefacts

Each of these reads as a bug, not a choice:

- **Grass intersecting hard surfaces.** Blades grow straight through the flagstone paving in `01-village-route-out-day.png` (right of the trainer's boots) and through the dirt path in `01-village-grandpa-yard-day.png`.
- **Floating paving.** In `01-village-route-out-day.png` the stone walkway is a set of discrete rectangular slabs with a raised ~10 cm lip standing proud of the dirt and a visible dark gap beneath the right edge; the cobble pattern is cut off mid-stone at the slab seams and does not align across them.
- **Floating plinth.** In `01-village-twins-day.png` the right house sits on a thin grey slab that hovers above the terrain with grass overlapping it and no foundation blend.
- **Ivy alpha cards.** In `01-village-route-out-day.png` and `01-village-standing-day.png` the wall ivy is a hard-cut alpha plane floating several centimetres off the masonry, with jagged stair-stepped edges and green fringing.
- **Roof/chimney junction.** In `01-village-standing-day.png` the white chimney sits on top of the tiles with a visible gap and a protruding pale flange instead of flashing; a second, much smaller pale angular object sits further along the same ridge at roughly a third the size, reading as a duplicated or mis-scaled prop.
- **Texel-density mismatch on one façade.** Also `01-village-standing-day.png`: the ground-floor cobble, the small white brick panels, and the plaster all run at three obviously different texture resolutions on the same wall, and the two roofs in frame run at two different tile densities.
- **Tiling.** The roof tile strip repeats with regularly-spaced green moss speckles at an obvious interval in `01-village-twins-day.png` and `01-village-standing-day.png`; the ground-floor cobble repeats visibly in `01-village-twins-day.png`.
- **Untextured/broken plant.** The orange spiky fan at bottom-left of `01-village-tournament-day.png` has no leaves, no texture variation and flat unlit orange — it reads as a broken asset or a stuck particle, not a flower.
- **Blurred low-res ground.** The dirt path in `01-village-route-out-day.png` and `01-village-grandpa-yard-day.png` is a soft beige wash with visible blur and no gravel, ruts or edge treatment at close range, right next to a character rendered at much higher detail.
- **Painted-on shading on the character.** In the `c_pave` region of `01-village-route-out-day.png` the trainer's trousers carry painted highlight streaks that do not correspond to the scene light — an asset-store texturing tell, visible at gameplay distance.

---

## 8. Scale agreement — using the 1.80 m figures

- **Grass is ~0.9–1.0 m everywhere, uniformly.** Measured against the standing villager in `01-village-tournament-day.png`, blade tips reach his hip. Every blade in the world is that length: in the meadow, in the yards, against the doorsteps in `01-village-twins-day.png`, and on the village square. A real meadow varies from ankle to waist; a settlement's interior is trodden to nothing. `palworld-02-open-field-path.jpg` and `palworld-03-field-boss-meadow.jpg` run ankle-to-shin field grass, which is why creatures stay readable in them. Here, waist grass would swallow any small creature entirely — which is a scale problem with direct gameplay consequence.
- **The purple flowers in `01-village-grandpa-yard-day.png` are 4–6× oversized.** Individual petals measure roughly the length of the trainer's boot (~0.28 m), making the clump ~1.2 m across. As violets or crocuses those are wrong by a large factor, and it is why they dominate the contact sheet.
- **The elder in `01-village-route-out-day.png` does not agree with the rest of the cast.** He stands *further from camera* than the trainer yet his head tops out around the trainer's shoulder line, which puts him near 1.3–1.4 m. His proportions are also different in kind — oversized head, short limbs — so he reads as a dwarf character rather than an old man, and he does not match the villagers in `village_npcs.png` or the trainer.
- **Masonry is at cartoon scale on otherwise semi-realistic buildings.** The ground-floor cobbles in `01-village-twins-day.png` measure ~35–40 cm per stone against the 1.8 m ruler, and the white boulders read as smooth river pebbles the size of a human head, set beside timber joinery detailed at near-realistic scale. The two halves of the same wall disagree about what kind of game this is.
- **Trees are saplings.** In `01-village-tournament-day.png` the canopies top out around 2.5× the standing villager — roughly 4–5 m — and each is a single ball of leaves on a bare, unbranched trunk. The key art's defining feature is oak groves whose canopies dwarf the cottages and fill the upper third of frame (see the STARTING SETTLEMENT panel and the oak-grove panel). Nothing in these frames is more than a little taller than a house.
- **The well is the right height and the wrong object.** In `01-village-route-out-day.png` the parapet reads ~0.9 m against the trainer, which is correct, but it is a solid capped stone box with no shaft, no rope, no winch and no opening — a bucket simply rests on the lid.
- Consistent and fine: the villager in `01-village-tournament-day.png` at ~1.5 m; the foreground boulder in `01-village-approach-day.png` at ~2.6 m × 1.2 m; the paving slabs at ~1.2 m; doorways at plausible human height.

### `village_npcs.png` — the cast itself

Judging only the figures, not the empty stage:

- **Five slots, two characters.** Three instances of the green-hood/white-tunic female and two of the brown-vest male, unaltered. That is a line-up presented as a settlement's population.
- **Every figure shares one hair mesh in one brown, one face shape, one pair of boots, one belt-and-pouch rig.** No variation in age, build, height, skin tone or hair colour. The elder in `01-village-route-out-day.png` and the yellow-dress woman in `01-village-grandpa-yard-day.png` are not represented here at all, so the village's visible variety is smaller than five.
- **The two head textures do not match each other in style.** The female's eyes are large hard-edged black anime ovals; the male's are smaller and more naturalistically shaded. Side by side at 3× they read as two different art pipelines.
- **Hands are undifferentiated mitten forms** with no separated fingers, visible on all five and again on the trainer in `01-village-route-out-day.png`.
- **Silhouette collision with the player.** The villagers share the trainer's proportions, boots, belt and vest cut, so at the distances of `01-village-approach-day.png` and `01-village-twins-day.png` there is nothing that distinguishes an NPC from the player character. Palworld's NPCs are separated from the player by silhouette and colour at any distance.
- **Flat shading.** No self-shadowing, no occlusion under the chin, jaw or backpack, so the figures read as flat cut-outs rather than as forms. This is a lighting/material property of the characters, not an artefact of the bare stage.

These are competent, cohesive, cheerful low-poly figures. They are not at the level of `palworld-01-boss-fight-forest.jpg`'s player character, whose hair, cloth and leather are individually authored with real form and real material separation. Judged as the game's look — which is what they are being offered as — they read as a licensed stylised-villager set, not as this game's cast.

---

# VERDICT

## 1. The three things that most separate these frames from the references, ranked

**1. No cast shadows and no ambient occlusion — nothing is attached to the ground.**
The trainer on the flagstone in `01-village-route-out-day.png` has no contact shadow at all; the eaved house in `01-village-standing-day.png` darkens neither its own wall nor the ground; the props in `01-village-approach-day.png` float. `palworld-02-open-field-path.jpg` and `palworld-04-plateau-landmark.jpg` both build their entire sense of ground, form and time of day out of hard sun shadow, and the key art's cosiness is largely dappled canopy shadow on beaten earth. This one absence flattens terrain form, compresses the value range (§2), destroys character readability at small size (§1), and makes the world read as a diorama of pasted objects. It is the highest-leverage single fix in the set.

**2. Nothing has been authored — the settlement is a kit on uniform scatter, with no landmark and no cleared ground.**
`01-village-approach-day.png` is the arrival shot and offers four instances of one house family in a row, uniform waist-high grass across the whole terrain, and no focal point to walk toward. `01-village-twins-day.png` is two copies of one building. The key art's STARTING SETTLEMENT panel answers this with a banner mast, a covered well-house, garden fencing, a beaten square and a great oak; `palworld-05-base-building.jpg` answers it with density of purposeful objects. And no settlement in any reference has knee-to-waist meadow grass growing up to its doorsteps.

**3. The game's subject is missing, and the cast that is present is thin.**
Zero creatures across six frames of a creature-training game's home village, while all five Palworld references and two of the key art panels place creatures front of frame. Alongside that, `village_npcs.png` fills five slots with two repeated characters that share one hair, one face and one silhouette with each other and with the player.

## 2. The two bar questions

### A. Do these frames read as belonging to the world of `tetherbound-meadows-keyart.png`? — **No.**

The genre, era and building language are right: timber-frame cottages with tiled roofs, a stone well, a wildflower meadow, rolling hills, a signpost. Read as a thumbnail, `01-village-approach-day.png` is aiming at the board's STARTING SETTLEMENT panel and you can tell.

What sinks it: the board's four defining features are all absent or inverted. **Oak groves** — the build's tallest tree is a 4–5 m lollipop (`01-village-tournament-day.png`); the board's canopies dwarf the cottages and fill the top third of every panel. **Dappled light and deep shade** — the build has none at all. **Landmarks visible from distance** — the board's own art note, and there is no landmark in any of the six frames. **Warm natural palette** — the board runs ochre plaster, weathered brown beam and mossy terracotta under crisp white cumulus; the build runs cream-white plaster, near-black beam, pure vermilion tile and a muddy brown smeared cloud layer. Plus the board's ground is beaten earth with grass at the margins, and the build's ground is uniform waist grass everywhere including the square.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game? — **Yes, weakly.**

The shared stylisation reads: cel-adjacent characters with painted textures in a semi-realistic environment, saturated greens, third-person over-shoulder camera, a chunky adventurer with an oversized backpack. Nobody would file these as a different genre. `01-village-tournament-day.png` and `palworld-02-open-field-path.jpg` are recognisably attempting the same shot.

But the answer is weak, and it is weak for a specific reason: **every Palworld frame is an event and none of these is.** `palworld-01`, `-03` and `-04` all have creatures at combat distance, VFX, and something happening. `palworld-05` is a base with fifteen purposeful objects and three Pals in it. These six frames are a quiet, empty, evenly-grassed village with a handful of idle humans and nothing to do. Put the sheets side by side and the honest reaction is "same genre, much earlier and much emptier."

## 3. The split: fixable in the scene vs. needs art that is not in the build

**Fixable by changing the scene, lighting, palette and scatter — no new art required:**
- Enable directional shadow casting and any AO. Single highest-value change; fixes §4 entirely and much of §1 and §2.
- Turn off or find the emitters for the daylight ground-glow blobs in `01-village-twins-day.png`, `01-village-approach-day.png`, `01-village-grandpa-yard-day.png`.
- Cut grass height and mask grass out of the settlement interior, paths, doorsteps and paving; vary blade length and add bare/trodden ground. Fixes the doorstep grass in `01-village-twins-day.png` and grass-through-flagstone in `01-village-route-out-day.png`.
- Reduce the purple flower prop by roughly 4–5× in `01-village-grandpa-yard-day.png`.
- Break the building line in `01-village-approach-day.png`: vary rotation, spacing, and cluster the houses around the well rather than parading them.
- Re-tint roofs to a consistent, less saturated terracotta and warm the plaster/beam pair toward the board; bring the chimneys and well stone down off white.
- Give the trainer a saturated hero garment value that separates from mid-green — costume material change, not a mesh.
- Remove or replace the two dead leafless branch props in `01-village-approach-day.png` and the flat orange spiky plant in `01-village-tournament-day.png`.
- Sit the building plinths and paving into the terrain (`01-village-twins-day.png`, `01-village-route-out-day.png`); re-seat the chimney and remove the undersized duplicate on the ridge in `01-village-standing-day.png`; push the ivy cards flush to the wall.
- Fix the terrain splat rectangle in `01-village-tournament-day.png`; extend scatter distance or add a distance-scatter/impostor band so the cull line stops being a visible ring.
- Re-author the signage: wooden material, one text size, no plane intersecting the cottage door in `01-village-standing-day.png`; move or resize the notice board clipping the trainer's head in `01-village-tournament-day.png`.
- Reconcile the three texel densities on the façade in `01-village-standing-day.png` and pick one rock family among the three visible in `01-village-approach-day.png`.
- Dress the settlement from props that presumably already exist: more crates, tools, a woodpile, drying laundry, a fire, crop beds.

**Needs art that is not in the build:**
- **Creatures in the settlement.** Nothing in these frames can be rearranged into a creature.
- **A landmark asset for the village centre** — banner mast, tower, windmill, or a hero tree. The board specifies it; the kit does not contain it.
- **Real trees.** A branching oak with a layered canopy at 3–5× the current height, and at least one second species. The current tree is a bare pole with a leaf ball and cannot be scaled up into what the board shows.
- **Building variety beyond the one timber-frame family** — a barn, a workshop, a stall, a shed roof.
- **A cast that is more than two characters.** New heads, hair, body types and heights; at minimum, distinct hair meshes and colours and a second body proportion, plus one reconciled eye-rendering style across the set.
- **A sky.** The current cloud layer is low-resolution and muddy in `01-village-approach-day.png` and `01-village-tournament-day.png` and is a large fraction of every frame.
- **A rock set with consistent stylisation and real large-form facets**, replacing the black noise blob in `01-village-approach-day.png`.
- **A real well** with a shaft, winch and rope, replacing the capped box in `01-village-route-out-day.png`.
- **Hands with fingers** on the humanoid rigs (`village_npcs.png`, `01-village-route-out-day.png`).
