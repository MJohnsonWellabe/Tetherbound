# MA-03 — blind visual review, round 3, and a calibration test

Run on the build as it stood after MA3, deliberately **before** any of the art
the owner had just proposed was touched.

## Why this round was run before the fixes, not after

The owner made two specific judgements and deliberately withheld them from the
critic:

> the triceratops needs to be way bigger and those trees are unacceptable. I
> would hope the review agent notes some of those things. again if it doesn't we
> need to retrain it.

Fixing the trees first would have destroyed the test — a critic that no longer
sees bad trees because the trees are now good tells you nothing about the
critic. So this round is a calibration test as much as a review.

This is the second time the owner has set one. The first found a real exemption
that had been written into the rubric, protecting sourced creature art from
being judged (`docs/decisions/D10`). It was removed.

## Calibration result: 1 of 2

### Trees — found, unprompted, in more detail than the owner gave

Not a near miss. It led criterion 3 with them and measured the complaint:

> Every tree is the same tree: one straight tapered trunk, one 6–8-face canopy,
> two greens, varied only by uniform scale. No species variation, no lean, no
> dead trees, no undergrowth, no clustering into groves, no clearings.

> Trunks are **pink-mauve** (hue ~10°). Against green they read as flesh.

> The far tree line in `04` is a row of identical cards at near-uniform spacing
> along a contour — a fence of icons.

And it produced a number nobody had thought to take: **mid-distance trees
measure 1.00:1 luminance contrast against the ground behind them**, separated
only by hue. The art direction board's own rule is "silhouettes and landmarks
visible from distance". Measured, they are not visible at all.

It also put "a second and third tree species" in the *not fixable without new
art* column, which is the right call and the one the owner reached
independently.

### Creature scale — missed

The critic never mentioned relative creature size. It had plenty to say about
Bramblit — "a faceted grey low-poly goat", saturation 0.12, "your own pal is the
least readable object in your own fight" — and about the Hopper's pose reading
as "roadkill". All useful. But **nothing about the largest creature in the game
rendering smaller than a frog**, which is what the owner saw immediately.

## The rubric gap this exposes, and the fix

The rubric has no criterion about **scale relationships**. Its seven criteria
cover silhouette, colour and value, intentionality, lighting, depth, interface
and artefacts. Every one of them is about how a thing *looks*; none is about
whether things are the right size relative to each other and to the player.

That is why the miss happened, and it is a real hole: wrong relative scale is
one of the loudest possible errors in a 3D game and one a still frame shows
perfectly well. A human sees it instantly — the owner did.

**Action:** the visual-judge rubric gains a scale criterion. Not "is this
creature big enough", which is a design question the critic cannot answer, but
the checkable version: *do the objects in frame agree about how big a metre is,
and does the player read as the size the game says they are?* The trainer is a
known 1.8m and is in every frame, so there is a ruler in the picture.

## What the round found beyond the calibration

The full text follows. The findings that were new to this round, ranked by the
critic's own leverage estimate:

- **The ground texture reads as cracked rock, not grass.** 65.6% featureless
  tiles in the lower half of `04-three-quarter` against 3.1–9.4% across the
  Palworld references. Called "the single asset doing more damage than anything
  else in the exploration frames" — and it is the Grass005 swap from MA3, so
  this is a regression the local metrics did not catch.
- **The value structure runs backwards.** Every frame is brightest at the sky
  and near-black at the player's feet (`05` measures 0.671 → 0.088 top to
  bottom). Palworld's meadow shots are flat or *inverted*, brightest in the
  foreground.
- **A cyan haze band lies across the terrain and cuts through tree trunks.**
  That is the arena boundary added in MA3 — introduced as a fix and shipped as
  a new artefact.
- **The ally and enemy health bars are the identical colour**, and the ally's is
  transparent enough that its colour changes with the terrain behind it.
- **The sky is a bare gradient**: horizontal variation 0.020 against Palworld's
  0.140–0.289. No clouds, no sun disc. Named the cheapest large win available.

Both bar questions: **no**.

---

# Visual review — Tetherbound Meadows survey

## Leading with the creatures and the trainer, because that is the problem

**These three assets are not from the same game.** In `shots/combat/03-closing-in.png` you can see all three at once:

- **Meadow Hopper** is a naturalistic tree frog. Smooth organic normals, observed anatomy, splayed toes, thin limbs, one flat mint colour with a dorsal stripe and a red eye. It has no design in it — no exaggeration, no colour blocking, no readable personality shape, nothing that says "this is a creature from a world." It is an animal model. Worse, its idle pose is belly-flat with all four limbs splayed; in `combat/02`, `03` and `04` it reads as roadkill, not as a combatant. Compare `palworld-03`: Grintale is a magenta blimp with a hard cartoon silhouette, and you know what it is at 40px.
- **Bramblit** is a hard-faceted low-poly quadruped with flat sharded normals and visible triangles. Different shading language entirely from the frog — the frog is smooth-shaded, this is flat-shaded. Measured colour in `combat/02`: RGB (0.57, 0.60, 0.65), hue 219°, **saturation 0.12**. It is a grey rock standing on olive ground. Contrast against ground is **3.0–3.4:1**, lower than the trainer's, lower than the enemy's, lower than the ground's own internal contrast range. Your own pal is the least readable object in your own fight.
- **The trainer** is a Mii. Not "chibi like Palworld" — Palworld's humans are semi-realistic anime with normal head-to-body ratios and visible gear. This is an Animal Crossing villager. And the survey camera shows him almost exclusively **from behind**, where the silhouette is a bald flesh-coloured egg. Across `01-spawn-outward`, `02-valley-floor` and `05-spawn-low-sun` skin pixels outnumber clothing pixels by **1.36:1, 2.01:1 and 4.50:1**. In `05` the character is, numerically, mostly a floating head. The diagonal object on his back (`combat/01-approach`) is the same flesh hue as his skin and reads as an anatomical growth rather than gear.

They also physically occupy each other. In `combat/02`, `03`, `04` and `06`, Bramblit's head and horns are **inside** the Hopper's flank with no contact resolution — in `03` the horns emerge through the frog's shoulder.

Three style languages, no shared design rules, intersecting geometry. This does not clear the bar, and no amount of scene work fixes it.

---

## 1. Silhouette and readability at small size

This is where the survey fails hardest, and it is measurable.

- **`01-spawn-outward`: mid-distance trees have a luminance contrast of 1.00:1 against the ground behind them.** They are separated only by hue (94° vs 68°) — the weakest channel. At 30% on the contact sheet the entire mid-field of `01` and `04` collapses into undifferentiated mush. The art direction note says "silhouettes and landmarks visible from distance." Measured, they are not.
- **`01-spawn-outward`: the player's head against the ground behind it measures 1.01:1.** The character reads only because of the blue tunic (5.10:1). At sheet scale the player is a blue tick mark with no head.
- The player occupies **0.11%–0.21% of the frame** in the three exploration frames he appears in. At 30% that is 15–25 pixels.
- You cannot tell a tree from a rock from a bush at distance. In `03-rise-overlook` the scattered rocks are pale domes with a **yellow-green lit top face** — the same hue as grass — so they read as dollops of moss, not stone. In `01` the whole mid-field is pale rectangular slabs that read as headstones.

## 2. Colour and value structure

- **The value structure is inverted relative to the reference.** Mean luminance from 20% frame height down to 80%: `01` 0.633→0.238, `03` 0.741→0.304, `05` **0.671→0.088**. Every frame is brightest at the sky and near-black at the player's feet. Palworld's meadow shots are flat or inverted (`palworld-02`: 0.315 far → 0.662 near, brightest in the foreground). The ground you actually walk on is the darkest, flattest region of every single frame.
- **The near ground is dark and over-saturated at the same time.** Foreground band: build val 0.155–0.389 / sat 0.51–0.82; Palworld 0.329–0.662 / sat 0.48–0.62. `05-spawn-low-sun` measures sat **0.822 at val 0.155** — a maximally saturated near-black olive. That colour does not occur in sunlit grass. It reads as swamp mud, and it fills the bottom 40% of the frame.
- **The palette is one narrow wedge.** 60–90% of pixels in every frame fall in yellow + yellow-green. Palworld carries 8–37% warm orange (dirt paths, wood, rock, skin) and 18–30% desaturated grey (stone, ruins, structures) in every shot. `02-valley-floor` has **0.7% desaturated pixels** — there is literally no stone, no wood, no built thing, no path anywhere in that frame.
- Frames do read as one place, with one exception: `03-rise-overlook` desaturates its mid-field to **0.16** while `02` holds **0.41** at comparable screen height. `03`'s middle distance is grey dust; the others are green. The fog model does not agree across the set.
- **Oxblood is clean.** Measured at 0.004–0.07% across all world frames; the 1.6% in `combat/07`–`08` is the trainer's brown hair, not the reserved red. No leak onto friendly elements. This one is holding.

## 3. Intentionality

Reads as generator output, and `04-three-quarter` is the exhibit.

- Every tree is the same tree: one straight tapered trunk, one 6–8-face canopy, two greens, varied only by uniform scale. No species variation, no lean, no dead trees, no undergrowth, no clustering into groves, no clearings. The keyart's whole third panel is an oak grove built on trunk-thickness variation and canopy overlap.
- Trunks are **pink-mauve** (hue ~10°). Against green they read as flesh.
- The far tree line in `04` is a row of identical cards at near-uniform spacing along a contour — a fence of icons.
- Nothing is placed. There is no path, no landmark, no built structure, no water anywhere in eight frames. The biome legend on the keyart board lists "Streams & Ponds" and "Settlements" as two of its five pillars. Zero of both.

## 4. Lighting

*(Flagging honestly: this survey is OpenGL, so no SSAO and different shadows. Some of this is pipeline, some is not.)*

- **No contact.** Every trunk in `04` and `01` meets the ground with a straight cut — no root flare, no AO darkening, no grass tuft. Props are stabbed into the terrain. This is the exact finding `docs/reference/README.md` records against the previous prototype.
- **Shadows are holes, not shade.** In `03-rise-overlook` the two hero trees' shadows cover **44% of the bottom 280 rows** and drop luminance 2.52x. The shadowed grass shifts from hue 87°/sat 0.62 to hue 76°/sat 0.52 — it goes *browner and duller*, when a sky-lit shadow should go *bluer*. There is no ambient bounce in them.
- **Visible shadow-distance cutoff.** In `04-three-quarter` (crop x 560–1120, y 120–320) the near trees have hard black shadow ellipses and the trees one band further back have none at all. The boundary is a horizontal line across the frame.
- The shadow blobs are soft ellipses that do not match their canopy shape, and at least one (left of centre, `04`) has no visible caster.
- Time of day reads in `05-spawn-low-sun` — warm horizon (hue 38°), long shadows, 23.7% orange. That one works as a mood. But it also has the worst black-foreground problem in the set.

## 5. Horizon and depth

- **The sky is a bare vertical gradient.** Horizontal variation within the sky band: `03` = **0.0201**, `05` = 0.0253. Palworld = 0.140–0.289, i.e. 7–14x more. No clouds, no sun disc, no distant peaks, no birds. The keyart has large cumulus in seven of eight panels; the mountain in the top-left panel and the peak in the top-right are the two clearest landmarks on the entire board. The build sky contributes nothing.
- Fog is eating the world in `03`: distant terrain at sat 0.11–0.13 and val 0.71–0.75 is a flat grey-beige with no green in it. A "rolling meadow" overlook where the meadow is grey.
- **Hard LOD boundary, lateral not radial.** In `04-three-quarter` around x 990–1120, flat pale untextured canopy cards stand immediately beside fully shaded 3D canopies at the same apparent distance. One tree has a visible internal seam line across its billboard.

## 6. Interface

Legibility only, per the rubric.

- **The enemy HP bar and your pal's HP bar are the identical colour.** Measured in `combat/02`: both (0.349, 0.620, 0.278). Top-centre and bottom-left, same green. In a fight where both are draining you cannot tell at a glance which one moved.
- Your pal's bar is semi-transparent over the world, so its colour changes with the terrain behind it — (0.349,0.620,0.278) in `02`, (0.471,0.486,0.247) in `06`. An HP bar whose colour is decided by grass.
- The **Energy** bar is empty black in all eight combat frames. It reads as broken, not as zero.
- `combat/05`'s prompt reads "missed — too far, or facing the wrong way." That is developer voice in the player-facing row.
- Margins are 45px / 40px on 1280×720 (3.5% / 5.5%) — fine for handheld, tight for a 5% safe area.

## 7. Artefacts

- **A blue-cyan haze band lies on the terrain and cuts across objects.** ~4,000 saturated cyan pixels spanning the full frame width in a narrow row band in `combat/02`, `03`, `05` and `06`. Zoomed (`combat/06`, x 250–750, y 150–280) it visibly crosses tree trunks: the same trunk is pale blue above the band and brown below, with a hard boundary. A depth-based effect intersecting geometry with no soft fade. It also tints ground cyan on a hillside, where in a meadow biome it is easily misread as water.
- **The ground texture is cracked lichen-covered rock, not grass.** Brightened crops of `01` (x 400–900, y 400–700) and `04` show fractured plates with dark fissure lines between them. Measured: 1–2px dark filaments persisting over 300 rows at multiple x positions in every frame (`01` x=710, 742–745; `04` x=583, 778, 1003, 1033). It is a stone texture tinted green and stretched over the terrain at one scale with no variation. This single asset is doing more damage than anything else in the exploration frames.
- Fine near-vertical 1px threads in `04`'s ground — sub-pixel grass geometry aliasing into hairlines rather than reading as grass.
- Bramblit/Hopper geometry interpenetration in four combat frames (see above).
- Hit VFX is a beige disc on olive ground: **2.47–3.10:1** contrast in `combat/05` and `06`. A landing hit should be the highest-contrast event in the frame; it is currently lower-contrast than the trainer standing still.

---

# Verdict

## The three things that most separate these frames from the references

**1. The creatures and the trainer are three unrelated asset styles, and none of them is a designed creature.** Palworld's entire proposition is that its creatures are drawn characters — bold silhouette, hue-opposed to the environment (`palworld-03`: magenta on green; `palworld-04`: saturated yellow and teal on green), exaggerated proportion, expression. `combat/03-closing-in` puts a naturalistic tree frog, a faceted grey low-poly goat, and a Nintendo Mii in the same 300 pixels, intersecting each other. This is the gap, and it is first.

**2. The ground is dark, over-saturated cracked rock, and it fills the frame.** `04-three-quarter` has **65.6% featureless tiles** in its lower half; `05-spawn-low-sun` 56.2%. Palworld's field shots measure **3.1–9.4%**. Every Palworld frame has a dense mesh grass field catching light in the foreground, and `palworld-02` and `05` route a warm dirt path through it as a compositional line and a hue break. Here the foreground is a mean luminance of 0.09–0.39 of one olive texture, with the value structure running exactly backwards from the reference.

**3. There is nothing to look at.** No clouds (sky horizontal variation 0.020 vs 0.14–0.29), no water, no path, no structure, no ruin, no rock formation, no landmark of any kind in eight frames. `02-valley-floor` contains 0.7% desaturated pixels — no stone, no wood, no built thing exists in it. The keyart board carries a windmill, a watchtower, a mountain, a standing stone and a fortified hall, and lists "landmarks visible from distance" as an art-direction rule. `palworld-04` builds its entire composition around a plateau and a tower. These frames have a tree as their tallest object.

## The two bar questions

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`? — **No.**

The board's own five notes are the test. "Vibrant, readable colours on a natural palette": the palette is a single yellow-olive wedge with a near-black foreground. "Silhouettes and landmarks visible from distance": measured at 1.00:1 in `01`, and there are no landmarks. "Cozy and inviting": a black mud foreground under a cloudless empty sky is neither. "Rolling hills, oak groves, clear streams, wildflower meadows" — the hills are there and genuinely good, the groves are one repeated tree, and there is no water at all.

What carried: the terrain silhouette. The rolling forms in `03-rise-overlook` and the hill in `combat/01-approach` have real shape and real scale, and they match the board. The oxblood discipline is intact. `05-spawn-low-sun` proves the day/night mood note is achievable.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game? — **No.**

Someone would say this is trying to be a different kind of game — a soft toy-box game in the Animal Crossing / early-Wii register. The trainer alone decides that read before anything else in the frame is considered. Palworld's frames are dense, warm, high-contrast, and full of authored objects; these are sparse, cold-olive, and empty. The one place it comes closest is `combat/02-arena-opens`, which has the right camera and the right HUD idea for a creature fight — and then the two combatants in it are a grey rock and a dead frog.

## What is fixable by changing the scene, and what is not

**Fixable with scene, lighting, palette, scatter and material work — no new art required:**
- The inverted value structure. Raise the ambient/GI floor, lighten and desaturate the ground albedo, stop the near-field from crushing to 0.09.
- Replace the ground diffuse. The cracked-rock texture is the single highest-leverage change in the exploration set.
- Sky: clouds and a sun disc. Cheapest large win available.
- Fog: pull the aerial perspective back so `03`'s mid-field keeps its green, and reconcile it with `02`.
- The cyan haze band crossing geometry — a bug, fix or remove it.
- The lateral LOD boundary and the visible shadow-distance cutoff in `04`.
- Scatter: cluster the trees, cut clearings, vary trunk thickness and lean, retint trunks off pink, add contact AO/tufts at bases.
- Hit VFX contrast; the identical ally/enemy HP bar colour; the empty Energy bar; the debug-voice prompt string.
- Bramblit's hue — a saturated non-green would fix its 3.0:1 readability without touching the model.
- The Bramblit/Hopper interpenetration (spacing/collision, not art).
- Camera: pull in and lower for exploration so the player is more than 0.2% of the frame.

**Not fixable without art that is not in this build:**
- **The creature roster.** The Hopper is an animal model, not a designed creature, and no lighting change makes a naturalistic tree frog read as a pal. The board's six-silhouette row (rabbit, boar, deer, raptor, turtle, canine) is the acceptance test and neither of these two creatures is on it or in its style.
- **The trainer.** Wrong genre of character design, and the from-behind silhouette — which is the silhouette the game shows 95% of the time — is a bald flesh egg. This needs a new character, not a new shader.
- **A shared creature style guide.** Flat-faceted and smooth-organic cannot be reconciled by scene work; one of the two has to be rebuilt.
- **Landmarks and structures.** There is no windmill, tower, ruin, hall, bridge, fence or well in the build. The board's whole "landmarks visible from distance" pillar is unbuilt content.
- **Water.** Streams and ponds are one of five named biome pillars and there is no water surface in any frame.
- **A second and third tree species,** plus bushes and ground plants that aren't 1px threads.

**Re-run the survey after the fixable half and compare sheets.** The two measurements to check first are the foreground luminance profile (should stop dropping top-to-bottom) and the far-tree-vs-ground contrast in `01` (currently 1.00:1). If those two numbers do not move, the fix did not land.

---

## What this becomes

Three of the round's findings are **regressions introduced by MA3**, which is
worth stating plainly rather than burying:

1. The Grass005 ground swap reads as cracked rock, not grass.
2. The arena boundary added as a fix is the cyan band cutting through trunks.
3. The near-field is now *darker* relative to the sky than before, and in the
   wrong direction against the reference.

MA3's local metrics said all three of those moved the right way. They measured
sky fraction, seam magnitude and mean near-field luminance — none of which
catches "the texture looks like stone" or "the value gradient runs backwards".
`tools/frame_stats.py` gains a top-to-bottom luminance profile so the second one
is checkable without a critic round.
