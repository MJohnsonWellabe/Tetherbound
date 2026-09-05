# Code-blind visual verdict — round 1, run 3 frames

Judge: `opus` sub-agent via the Agent tool, given only
`_sheet_route_strip.png`, the four run-3 PNGs, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, plus the note that these are llvmpipe
road frames in the Meadows with one fight and a 1.80 m trainer as the ruler.
It was told nothing about what changed, what this lane did, or what any
answer would mean. Reproduced verbatim.

---

# Visual verdict — Meadows route strip, four frames

## Headline, first, because the rubric asks for it plainly

**The trainer does not hold up against the bar.** In every frame he is a generic stock third-person male: small head, slim unstylised proportions, muddy low-resolution trousers, a muted teal shirt and brown hair that put him in exactly the same value and hue band as the grass and the dirt. In `band1_00040m` and `band1_00080m` he is a brown smudge you find only because he is next to something bigger. Every reference does the opposite — Palworld's players carry a saturated off-palette accent (orange hair, green hair, blue sash) and a strong shape read; the keyart DAY/NIGHT panels give the trainer a bright teal top against a dark treeline. He is the ruler in the picture and he is the hardest thing in it to see.

**The creatures are the better half of the art and still have specific problems.** The Terrapup and the plated deer are cohesive with each other, have real character in the face, and have a readable silhouette. But they are all one colour — warm tan and cream — which is the same colour as the dry grass, the dirt road, the wooden fences, the plank, the villager NPCs, and the enemy. Nothing in this build is coloured to be found.

---

## 1. Addressable defects, by frame

### `band1_fight_mudsnout.png`

- **The fight does not read as a fight.** Both creatures are in static idle poses. No attack pose, no impact, no dust, no sparks, no muzzle of energy, no damage number, no telegraph, no motion blur, no reaction from the six idle NPCs standing around. The only thing in the picture that says "combat" is the HUD. `palworld-01` and `palworld-03` are unmistakable as fights with the UI cropped off.
- **The enemy is invisible.** The Mudsnout is a pale cream ground-hugging shell at roughly 44% of Terrapup's height, lit the same as the sunlit grass, textured in the same mottled cream as the grass highlights, and sitting *below* the grass line. There is a second near-identical pale woolly blob beside the dark rock to its right. At sheet size you cannot tell which one the health bar belongs to, or whether either is a creature rather than a rock or a sheep prop.
- **The nameplate is unanchored.** "LEVEL 4 / Mudsnout" is the largest element in the frame and it floats over a village roofline 300px away from the creature it names. Nothing connects the bar to the body — no ground ring, no outline, no leader.
- **The camera is in the wrong place.** The fight occupies about 8% of the frame area, at mid-distance, from a high angle. The bottom 40% of the frame is empty grass. The trainer is shoved into the lower-left corner, partly overlapped by his own party panel, facing away from the fight. Nothing here is composed as an event.
- **Hard straight-line shading/blend seam.** A razor-straight diagonal edge runs across the left third, separating dark olive ground from a pale mint wash, with a second parallel edge below it. It follows no terrain form. It reads as a shadow-cascade or splat-map boundary — the single clearest artefact in the set.
- **Two leafless dead trees** stand in the middle of the "cozy, welcoming" starting settlement as near-black spidery silhouettes, the darkest objects in the frame. They contradict the keyart's oak groves and they meet the ground with no root, no shadow, no scatter.
- **The charcoal rock beside the enemy** is the darkest solid mass in the frame and steals the eye from the actual combat.
- **UI:** the Terrapup portrait swatch is an empty flat brown square — missing art. "GROUND" is dim olive on grey, near-illegible. "No orbs" reads as a label sitting inside a button slot. The trainer has no state readout at all. Nothing is emphasised; the enemy name is loudest and the enemy is smallest.

### `band1_00000m.png` (settlement)

- **The composition is a wall, not a settlement.** The right third is a flat cobble house face with a uniform grey tile, zero wear, zero value variation. The keyart STARTING SETTLEMENT panel has a well, a banner, layered rooflines, canopy shade, and depth. Here: one wall, cropped.
- **The tree trunk grows directly out of the trainer's head** and the canopy is cropped by the frame top. Accidental framing.
- **The dark hooded figure at the right edge is unreadable and unexplained.** A featureless charcoal cowl, the darkest silhouette in the frame, standing motionless in the friendly starting settlement, half-cropped by the frame, feet nearly intersecting the Terrapup's hind leg. If it is a villager, its value and cowl read as a threat. If it is a threat, everything in frame is ignoring it.
- **Terrapup material defects at close range:** the stone plates are flat quads pasted onto the fur with no bevel, no depth, no contact shadow — stickers, not armour. The plate row ends at the hip with a straight cut. There is a visible straight UV seam across the shoulder. The mint-green back wash ends in a hard edge on the flank. The fur texture is a low-frequency blur.
- **Hard, aliased grass/dirt boundary** behind the trainer, with no transition scatter, no trodden edge, no stones.
- **A pale radial lightening disc** sits on the terrain centred near the player, visible again in `band1_00080m`. It looks like a baked texture blotch or a camera-following blend, not like light.

### `band1_00040m.png`

- **A 3.5m plank ramp lies in the foreground going nowhere,** spanning nothing, tilted on flat ground, with a visible gap under its left end. It is also the brightest and most saturated object in the frame, so it owns the bottom-left corner for no reason.
- **The fences are broken.** Two disconnected runs; the far-right panel's bottom rail floats roughly 40cm clear of the dirt with daylight under it; a third fence fragment sits isolated mid-field connected to nothing. No post is blended into the ground — no scuff, no grass tuft, no dirt mound.
- **The pebbles are white marshmallows.** Pure-white untextured rounded blobs, the same asset at the same scale, repeated in all four frames.
- **The dirt path texture is very low texel density** — a smeared brown mottle — and meets grass along a hard aliased line.
- **The bottom 35% of the frame is empty dirt.**
- **Distant treeline reads as a fence of trees:** near-identical canopies, near-identical heights, near-even spacing along the ridge. No clustering, no gaps, no hero tree.

### `band1_00080m.png`

- **Four identical deer creatures, same pose, same tint, same scale, evenly spread** across the right mid-ground. No juveniles, no variation, no grouping, no facing variety. This reads as a spawner grid, not a herd.
- **Those deer are also scale-suspicious.** They sit at a depth where a 1.80m person would be 20–25px tall and they render 70–90px tall. Either they are 3m+ quadrupeds or the depth is not resolving.
- **The bottom 45% of the frame is an empty smeared brown road** with no edge definition, no ruts, no verge, no debris.
- **The Terrapup nearly merges into that road** — same warm tan, same value.
- **Grass cards render as bright white streaks** in the shadowed lower-left, reading as scratches on the lens rather than as grass.
- **The brown slab rocks at the left mid-ground read as cardboard crates** — flat brown, hard-edged, unlit. They do not belong to the same rock family as the charcoal faceted rock in the fight frame or the near-black rock in `00040m`. Three unrelated rock languages across four frames.
- **The landmark hill is the same green as the near ground** with no aerial perspective, so the only landmark in the whole strip reads flat and close.

### Across all four

- **Measured, not guessed: there is no light in these frames.** 95th-percentile value is 0.71–0.80. Every reference reaches 0.88–0.96 (`palworld-04` 0.95, keyart settlement panel 0.88). At the same time mean saturation is 0.61–0.68 against 0.37–0.46 in the references. The build is simultaneously over-chroma'd and under-lit — crayon green with no sun on it. Nothing in frame is a highlight; the sky is the brightest thing and it is dull.
- **No accent colour exists anywhere.** Zero percent of pixels in any of the four frames fall in blue/violet/magenta/pink. `palworld-03` spends 5–6% of frame on the magenta boss; `palworld-04` 6% on azure. The keyart palette strip carries slate, blue, violet, mauve and plum, and none of it is on screen.
- **One bush, one flower, one grass blade, one pebble, one fence, one tree silhouette,** each at one scale, scattered at even density. That is the procedural read the rubric names.
- **Almost no cast shadow grounding anything** — flagged with the caveat that this is llvmpipe and belongs on hardware. But the *geometric* grounding failures (floating rails, floating plank, unblended prop bases) are real in a still and are not a lighting excuse.
- **The oxblood is clean.** No Team Tether red has leaked onto friendly elements. The saturated red-brown tree trunks are terracotta and are a separate (mild) issue: they are the strongest warm note in frame and they are spent on foliage.

---

## 2. The three things that most separate these frames from the references, ranked

**1. There is no sunlight, so nothing has form.** The keyart settlement panel and every Palworld shot carry a real value range — deep shade under canopies, blown highlights on roofs and rock faces, a bright sky reading as a source. These frames sit in a compressed 0.22–0.80 band with high chroma and no highlight anywhere. Most visible in `band1_00040m`, where a hill, a treeline, a dirt path, a fence and a creature are all lit identically and the terrain has no readable form; and in `band1_00080m`, where the landmark hill is the same value as the grass at the player's feet.

**2. The ground is a painted surface with props stabbed into it.** `palworld-02` and `palworld-03` and the moong meadow reference all give a continuous grass carpet that meets the character's shins and hides the ground plane. Here — clearest in `band1_00040m` and `band1_00000m` — the grass is isolated 2px alpha spikes at even density over a low-resolution mottle, prop bases meet terrain along hard unblended lines, the plank and the fence rails float, and 35–45% of every frame is empty flat ground.

**3. Everything is the same colour, so nothing is findable.** `palworld-03` puts a magenta boss on green grass; `palworld-01` puts a green-and-gold boss against a dark forest. Here, in `band1_fight_mudsnout`, the enemy is cream on cream and the player creature is tan on tan, and in `band1_00080m` the companion merges into the road. The trainer, the creatures, the NPCs, the fences, the props and the dry grass all live in one warm tan-to-olive band, and there is no accent colour in the entire strip.

---

## 3. The two bar questions

### A. Do these frames read as belonging to the world of `tetherbound-meadows-keyart.png`?

**No.**

*What carries:* the terrain shape language is right — rolling hills, a dirt road with a horizon, scattered oaks, wildflower ground, half-timber cottages, a distant plateau in `band1_00080m`. The genre and the biome are unmistakably the ones on the board. The oxblood discipline holds.

*What sinks it:* the board's own note is "cozy and inviting, but with hints of mystery," and the board delivers that with light — canopy shade, warm interior windows, sun through leaves, a value range. These frames are flat-lit and desaturated-of-light while over-saturated in hue, which reads as neither cozy nor mysterious, just plain. The board's landmark language (windmill, tower, glowing rune monolith, stone bridge, streams and ponds) is entirely absent — `band1_00080m` has a green hill and that is the whole landmark budget for 80 metres of road. The keyart palette's cool half — slate, blue, violet, plum — appears nowhere. And two leafless dead trees standing in the welcoming starting village in `band1_fight_mudsnout` actively contradict the board.

*Fixable by scene changes:* the value range and chroma balance (sun angle, sky energy, ambient, material saturation — this is a config-level change and it is the single highest-leverage one); ground cover density and clumping; removing the dead trees from the settlement or moving them somewhere they mean something; clustering trees and adding scale variety and clearings instead of even spacing; blending prop bases into terrain; sinking the floating fence rails and either purposing or deleting the foreground plank; giving the distant hill aerial perspective; putting a cool accent — water, a rune stone, a banner, a painted door — somewhere in every frame; composing the shots so the frame is not 40% empty ground.

*Needs art not in the build:* landmark hero props (windmill, tower, rune monolith, stone bridge, well, settlement banner); a second and third tree species with a real hero canopy; a clumped multi-species grass and flower set instead of one blade and one daisy; a coherent rock family to replace the three unrelated ones; house exterior variation and dressing (thatch, moss, wear, smoke, laundry); a higher-resolution terrain and path material set; water.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**Yes — trying to be, clearly. Landing it, no.**

*What carries:* the answer is yes on genre read. A person-scale trainer on foot with a large plated companion in an open meadow, wild creatures at mid-distance, a creature nameplate with a level and an element, a party panel and an ability bar with a resource counter — nobody would mistake the intent. `band1_00040m` in particular is the same picture as `palworld-02` in structure.

*What sinks the execution:* the fight. `palworld-01` and `palworld-03` are legible as boss fights with the HUD removed — the boss fills a third of the frame, is off-palette against the ground, is mid-animation, and throws sparks and dust. `band1_fight_mudsnout` with the HUD removed is a picture of two animals sitting in a field near a house. Then: the empty lower half of every frame against Palworld's shin-high grass; the missing highlight range; the identically-cloned herd in `band1_00080m` against Palworld's varied encounter groups; and the trainer, whose bespoke, expressive, colour-accented equivalent is the first thing you notice in four of the five reference shots and is the last thing you notice in three of these four.

*Fixable by scene changes:* combat camera (get low, get close, put the enemy at a third of frame height); combat VFX, hit reactions and attack poses; anchoring the enemy nameplate to the enemy; keeping the trainer in frame and facing the fight; ground cover density; lighting range; encounter composition — vary pose, spacing, facing and scale within a group.

*Needs art not in the build:* a trainer character with actual shape design and a colour accent — the current one is a stock asset and no amount of scene work fixes that; combat effect assets (impacts, dust, ability VFX, hit flashes); creature attack and hit animations; a Mudsnout silhouette and palette that separates from grass, or a different wild opponent for this encounter; higher-resolution creature textures — the Terrapup's plates and fur do not survive close range.

---

## 4. Per-frame: creature presence, readability, and the fight

| Frame | Creature present | Readable beside the 1.80m trainer |
|---|---|---|
| `band1_00000m` | Yes — Terrapup, plus a hooded humanoid | **Mostly.** Terrapup is ~2.5m at the head, ~3.2m long, clearly larger than the trainer, and its silhouette holds against the stone wall. It loses its lower half against the dry grass. Close-range texture, plate seams and the flank hue edge do not survive this distance. The hooded figure is **ambiguous** — half-cropped, unlabelled, dark, and reading as a threat in a friendly location. |
| `band1_00040m` | Yes — Terrapup only | **Yes — the best of the four.** Full profile against the bare dirt path, clean silhouette, scale unmistakably legible next to the trainer. This is the frame to keep. |
| `band1_00080m` | Yes — Terrapup, plus four deer creatures | Terrapup: **marginal** — same tan as the road it is standing on, so the silhouette breaks at the bottom. The four deer: **not readable as individuals.** Identical pose, tint and scale at even spacing; they read as a repeated prop, and their apparent size disagrees with their apparent depth. |
| `band1_fight_mudsnout` | Yes — Terrapup and Mudsnout | Terrapup: **readable but too small in frame.** Mudsnout: **not readable.** Too small, too pale, too low to the ground, camouflaged against sunlit grass, ambiguous with a second near-identical pale blob beside the dark rock. At contact-sheet size it disappears entirely. |

**Is the fight frame recognisably a fight between two creatures with the trainer watching?**

**No, on all three counts.** It is not recognisable as a fight — nothing is attacking, nothing is reacting, there is no effect of any kind. It is barely recognisable as *two creatures* — the enemy reads as terrain dressing and there is a decoy blob competing with it. And the trainer is not watching: he is in the lower-left corner, partly occluded by his own HUD panel, turned away from the action, at a distance and angle that make him a bystander in someone else's screenshot rather than the person commanding the fight.
