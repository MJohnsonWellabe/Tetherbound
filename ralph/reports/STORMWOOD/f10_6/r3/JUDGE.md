# STORMWOOD f10_6 r3: code-blind visual judgement

Judge inputs: `_sheet_7inch.jpg` (readability read at 100% only), full-size `explore/`, `fight/` and `strike/` frames (to identify what a detail is), Bar A (`tetherbound-meadows-keyart.png` plus the two Stormheart boards) and Bar B (`palworld-01..05`). I opened no other repository files.

Scale used for the sheet: each cell is about 585 px wide for a 1920 px frame (x0.305). Text drawn at 24 px in a 1080p frame lands at about 7 px in the cell, and 28 px text lands at about 8.5 px.

---

## Device-profile read (7-inch, arm's length)

**1. Is all HUD text legible at 7-inch size? NO.**
- Pass: the objective card ("MAIN STORY / Find Ashfoot Waycamp.", all explore cells) is the clearest text on the sheet. The enemy name ("Voltarach", "Staticub" in H2b to C2f) and "ELECTRIC" also read. Team list names read in H0 and H2b to C2f.
- Fail: the tell text "! incoming — move" (H2b, Ci, C1b) is about 6 to 7 px of thin amber on a translucent panel. You can make it out when you know it is there, but it does not read at a glance. "it's open — hit it" (C2f) is thinner still: teal on a translucent panel that sits over the bear's brown head. It is the lowest-contrast gameplay text on the sheet.
- Fail: "LEVEL 38" and "LEVEL 41" (H2b to C2f) are grey small caps and borderline.
- Fail: the health "100 / 100" and "FOOD 100%" readouts (RC to H0) are about 5 px. FOOD is gold text over a gold bar and turns to mush. "Day 1 · 08:00" is faint grey over grey-purple sky and fails.
- Fail: move buttons. "Spark Bite" and "Arc Lash" just read in H2e and Ci. In H2b and C1b the whole panel is dimmed grey-on-slate and does not read. "No orbs" is dim in every frame. The RT, LT, LB and X glyphs cannot be read in any cell.
- Fail: the explore quick-bind bar (RC to FB) is five glyph-only boxes (B plus four d-pad crosses). At 7 inches it reads as five identical grey tiles with no meaning.

**2. Are tells and danger legible? YES, with defects.**
- The lightning ground ring (S0, S6, S10, S12) is the best-read element on the sheet. The hot-magenta circle stands apart from everything in the world. The crack pattern growing inside it (S6) and the fill brightening to pale pink (S10) carry the countdown without any text.
- The enemy attack shapes also read: the magenta lane in H2b, and the magenta cone plus foot ring in Ci and C1b.
- Defects: in H2e the Voltarach telegraph has faded at impact to a dim purple quad close to the ground's value, so the "where did it land" frame is the weakest. In H2b a translucent beige sunburst glyph is laid over the spider's body. In C1b large beige bokeh blobs are laid over the bear. Both read as a lens smudge rather than a warning, and they hide the enemy's pose, which is the part of a tell a player should learn.

**3. Can each subject be found in under a second, unhidden by the HUD? NO.**
- Ci: the trainer is effectively off-screen. Only a boot shows at the bottom-right, under the move panel.
- C1b: only the top of the trainer's hair shows, in the bottom-right corner beside the move panel.
- H2e: the trainer is jammed between a spider leg and Sparkit and partly occluded by both. It takes well over a second to find them.
- FB: the trainer is a near-black figure on near-black grass.
- The piloted creature (Sparkit) and the opponent pass everywhere except C1b, where Sparkit is half-buried in the beige VFX blobs.

**4. Does the HUD keep a safe area and stay off the key action? NO.**
- Edge margins are about 3% (roughly 55 px at 1080p), which is acceptable. Coverage is the problem. In fights, the team list plus the Sparkit card take about the left quarter of the frame from 40% to 95% height. The move panel takes the lower-right quarter, and the enemy card takes the top-centre 30% by 25%.
- Ci and C1b: the move panel covers the trainer.
- C2f: the enemy card overlaps Staticub's head and ears, so the opponent sits under the panel at the moment the text says "hit it".
- H2e: the enemy card covers the top of Voltarach's back.
- H2b: the team list sits on top of the start of the magenta danger lane.
- C2f: the move buttons disappear entirely at the punish window. Only "Orbs 0" remains, so the one moment the player is told to act, the actions are gone.

---

## Specific defects by frame

**Silhouette and readability (small size)**
- FC and FB: the trunks are flat black slabs with no rim or value separation, and the trainer and the forest merge. In FB the frame is mostly black at 7 inches.
- GC and GB: the glass field reads as four blue cones and a thin white line at the horizon. At sheet size it does not read as a place or as "glass".
- H0: Voltarach's legs straddle the trainer, so the first read is "spider on the player", not "player facing spider". Sparkit sits behind both and does not read.
- RC and RB: good. The trainer is centred on a warm-lit path, the pylon line leads the eye, and this is the strongest explore composition.

**Colour and value**
- The whole chapter is one mid-dark band: purple sky at mid value, dark foliage, dark brown ground. Only the gold ground cracks (RC, RB) and the magenta tells climb into the highs.
- FC and FB crush the floor and trunks to black.
- Break barely differs from Calm. RB is RC with more rain and thin bolts behind the canopy. GB is GC slightly darker. FB is darker still, which inverts "lightning peak" into "lights out". A peak should be brighter and more contrasty than Calm, not dimmer.
- Red leak: in H2e a saturated crimson creature (top-left, over the "Calm" label) and the pink-red smear behind the "Bramblebun" row in H0 put strong red on a wild creature and around a friendly HUD row. If red is reserved for Team Tether, this breaks it.
- The rod-line cable (RC, RB, S0 to S12) is a dark oxblood-brown line. Check that it is intended as Tether red.

**Intentionality**
- Ci, C1b and C2f: the arena floor is scattered with the same small shrub at near-even spacing, which is plainly procedural.
- H2b and H2e: tree trunks at the top edge stand in a regular row with pylons between them.
- GC and GB: the grass is uniform clumps at uniform density across the whole slope, with no paths, clearings or clustering.
- RC and RB: the path, pylon line and trees reads as authored.

**Lighting**
- No frame shows a key light direction. Terrain has no form shading and objects have little contact shadow. RC's trainer sits on the path without a readable shadow, and the creatures in Ci and C2f float slightly.
- S12: the bolt strikes the trainer but lights nothing. There is no flash on the ground, trees or sky and no cast shadow. The strike is a thin white line pasted on the frame. Only the trainer tints pink.
- FB is marked "Sheltered" yet shows the heaviest rain of the explore set under a closed canopy. FC also rains under the canopy. The weather state and the visual disagree.

**Horizon and depth**
- RC, GC, GB, S0 and S12: past the tree line the world ends in a flat, featureless grey-purple plane with a hard horizontal horizon. There is no far forest, no ridge, and no Stormheart tree anywhere in any frame.
- The fog is an even band that erases the distance rather than layering it.

**Interface** (besides device answers 1 and 4)
- The explore HUD stacks three boxes bottom-right (quick-bind bar, Map/Satchel/Build) plus the minimap and objective top-right. That leaves the right third heavy and the left mostly empty.
- The minimap changes from green (RC, GC) to tan (FC, FB) with no legend.
- "Sheltered" and "Calm" at top-left are small, low-weight cyan and easy to miss (all explore frames).

**Artefacts**
- FC and FB: a large flat-black wedge from the bottom-left corner up to about mid-height, and a flat-black vertical slab on the right (x > 1500). This looks like the camera clipping inside a trunk, or an untextured near surface. It reads as a bug.
- GC and GB: the glass field's edge is a hard white line with a floating slab look.
- H0: pink-red smear behind the Bramblebun HUD row.
- H2e: the trainer's body intersects a Voltarach leg.
- H2b: the Sparkit tail and body clip the telegraph and the yellow VFX.
- The ground crack emissive (RC, RB) is flat decal paint with no glow bleeding onto nearby grass.

**Scale** (trainer = 1.80 m)
- Voltarach (H0, H2b, H2e) is about 2.5 to 3 times the trainer's height and reads correctly as the big threat.
- Staticub (Ci, C2f), on all fours further back, is taller than the trainer standing nearer. That is plausible.
- Sparkit (H2e, C2f) reaches roughly the trainer's shoulder with ears up.
- Pylons are about twice the trainer's height, and glass spikes about 1.5 times.
- Mushrooms (FC) are at knee height. Trees are properly massive.
- No gross scale error is visible.

**Creatures and characters**
- Sparkit and the trainer are the best art on the sheet. They form a coherent stylised pair, and they match the boy-with-yellow-fox pairing in the key art's Day and Night panels.
- Staticub does not match them. It uses near-realistic mottled brown fur with purple streaks, the same photo-ish texture as the ambient bears, and it looks sourced next to Sparkit. The named crown fight (Ci to C2f) is also visibly the same bear as the three or four identical bears wandering in the background. The "guardian" does not read as unique or important.
- Voltarach is a glossy, saturated royal-blue body with black camouflage blotches and unjointed tube legs. It reads as a plastic toy rather than a bespoke creature, and it lacks the facial and material detail of Palworld 01's Mammorest.
- The spiky green toad (H2b, H2e) is fine.
- The NPC in a tricorn coat (S0 to S12) is fine.

---

## Three biggest gaps from the references (ranked)

1. **No landmark and no depth.** The Stormheart boards (A and B) are built around a colossal split tree "visible across the Electric Forest", with lit platforms, banners and waterfalls. Palworld 04 puts a tower landmark on the horizon to pull the player forward. Every Stormwood explore frame (RC, RB, GC, GB, S0) ends in a blank grey plane with nothing to walk toward. In the forest frames (FC, FB) the eye has nowhere to go at all.
   - Split: a Stormheart silhouette with an emissive split-trunk glow and distant layered tree-line cards can be kitbashed from installed tree families (scene-fixable). A faithful Stormheart with platforms and banners needs new art.
2. **Lighting and value have no structure, and Break is not a peak.** Palworld 01 to 05 run a strong sun key with shadowed undersides and a full value range. The boards pair cold blue lightning with warm lantern light (the "Warm Light" swatch). These frames are flat-ambient purple with no key light, no warm counterpoint and crushed blacks (FC, FB). The lightning (RB, S12) lights nothing, and Break is darker than Calm.
   - All scene-fixable: key or rim light, a lightning-flash light pulse, lifted floor, warm lanterns on the pylons or waycamp, and Break exposure and sky flashes.
3. **Creature art is inconsistent, and the named fight is not an event.** Palworld 01 and 03 make a boss fight an event: a bespoke, expressive boss, sharp spark and impact VFX, and a boss-only name bar. Here the crown fight's Staticub (Ci to C2f) is a realistic-textured bear duplicated in the background. Voltarach (H2b, H2e) is a glossy blob. The hit and tell VFX are soft beige blobs (H2b, C1b) rather than bright, sharp sparks.
   - Split: clearing ambient Staticub clones from the arena, a crisper spark VFX, and a boss-style name treatment are scene-fixable. A stylised Staticub re-texture that matches Sparkit and a better-detailed Voltarach need new art.

---

## Bar A: NO

**What carried it:** the foliage family and grass match the key art's stylised-realism oak groves. The trainer and Sparkit pair is almost the key art's Day and Night panel duo. The gold path cracks and purple sky sit inside the key-art palette swatches (gold, violet).

**What sank it:**
- None of the board's defining features are present: no Stormheart tree, no warm light, no banners or settlement.
- The mood reads as oppressive and dim (FC, FB) rather than "cozy and inviting with hints of mystery".
- The world ends at a grey horizon, so the key-art notes' "silhouettes and landmarks visible from distance" fails in every frame.

**Split:**
- Scene-fixable: landmark silhouette kitbash, warm lantern light, exposure and value lift, Break lighting.
- Needs new art: the full Stormheart structure, and a stylised Staticub.

## Bar B: YES

**What carried it:** H0, H2e, Ci and C2f have the Palworld fight grammar.
- A stylised trainer and a cute piloted creature face a leveled, named wild creature bigger than the player in an open meadow.
- A team list, a creature card and a move panel sit on screen.
- Readable ground telegraphs are present.

Shown beside Palworld 01 and 03, someone would say these are trying to be the same kind of game.

**What holds it back** (does not sink it):
- Lower ground density and less life. Palworld 02 and 05 show structures, props and other creatures in every frame.
- Flat lighting against Palworld's sunlit value range.
- Soft blob VFX against Palworld 01's sharp spark bursts.
- Staticub's realism mismatch.

---

## TOP FIXES

1. **Resize and re-contrast combat HUD text for 7 inches.**
   - Raise the tell line to at least 34 px at 1080p on a solid, opaque backing. Give "it's open" a high-contrast colour that is not over the enemy.
   - Raise the enemy level, HP/food numerals and move-button labels to at least 28 to 30 px.
   - Keep the RT, LT and LB glyphs visible, and keep dimmed or on-cooldown move buttons at at least 4.5:1 contrast (H2b, C1b).
   - Put the food label outside its bar.
   - Label or enlarge the explore quick-bind slots.
   - Collapse the fight team list to icon plus bar only, to recover the left quarter of the screen.
2. **Frame the fight and keep the HUD off it.**
   - Keep the trainer, the piloted creature and the opponent inside a central box that excludes the HUD panels. The trainer is lost under the move panel in Ci and C1b and occluded in H2e.
   - Stop the enemy card overlapping the enemy (C2f, H2e): slimmer card, or pitch the camera so the enemy sits below it.
   - Keep the move buttons visible during the punish window (C2f).
   - Replace the beige tell and hit blobs (H2b, C1b) with sharp, bright spark shapes that do not veil the enemy's pose.
3. **Give Stormwood structure in light and landmark.**
   - Add a cold key or rim light and a real lightning flash that lights ground, trees and characters (S12, RB).
   - Make Break brighter and more contrasty than Calm, not darker (FB).
   - Lift the forest floor and trunks out of black, and fix the black wedge and slab clipping in FC and FB.
   - Add warm lantern points on the pylons and the waycamp route.
   - Put a kitbashed Stormheart silhouette with an emissive split on the horizon, with layered far tree lines instead of the empty grey plane (RC, GC, S0).
