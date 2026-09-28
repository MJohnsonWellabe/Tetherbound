# Stormwood f10_6 r4 — code-blind visual judge

The only files opened were the ones JUDGE_PROMPT names: the visual-judge SKILL, the three Bar A images, the five Palworld images, `_sheet_7inch.jpg`, and the explore, fight and strike JPGs. Readability calls come from the sheet at 1:1 pixel scale (each cell is about 586 px wide). The full-size frames were used only to identify what a detail is.

Frame keys follow the sheet: RC/RB rod line, GC/GB glass field, FC/FB forest, H0/H2b/H2e Voltarach fight, Ci/C1b/C2f Staticub fight, S0/S6/S10/S12 ground strike.

---

## Device-profile read (7-inch, arm's length)

**1. HUD text legible at 7-inch size: YES, with named exceptions.**
- **Objective card:** "MAIN STORY / Find Ashfoot Waycamp." reads cleanly in every explore frame (RC–FB, H0).
- **Health and food bars:** the bars read in every explore frame. The numerals ("100 / 100", "100%") are about 6–7 px on the sheet and sit on the bar fill. They are just readable. The "FOOD" label, dim gold on a gold bar, is the weakest text on screen (RC, GC, FB).
- **Enemy name and level:** "Voltarach" and "Staticub" are the clearest text in the fight frames (H2b, H2e, Ci, C1b, C2f). "LEVEL 38/41" and "ELECTRIC" are small but readable.
- **Tell text:** "! incoming — move" (H2b, Ci, C1b) and "it's open — hit it" (C2f) are legible, and "it missed you" (C2f) is clear.
- **Team list:** names are legible in all fight frames. **Exception, H0:** the exploration version adds "bond 0/5 Lv 42" at about 5 px, which is illegible at 7 inches.
- **Move buttons:** "Spark Bite / Arc Lash / No orbs / Switch / Orbs 0" are legible. **Exception:** the RT/LT/LB trigger glyphs above them turn into grey blobs (all fight frames).
- **Explore quick bar:** its five slots show only a "B" and four plus-shaped glyphs, which cannot be told apart at this size (RC–FB).

**2. Tells and danger legible: YES.**
- **Enemy attack warnings:** the magenta cone plus ring around the attacker is the most readable element in Ci, H2b and C1b.
- **Ground-strike ring:** readable from S0 (dark ring with a thin magenta rim) through S12 (bright rim and cracks).
- **What competes with the tells:**
  - In H2b, a translucent white star disc sits over Voltarach's face, and soft gold discs float across the frame.
  - In C1b, a gold smoke puff turns Staticub semi-transparent.
  - The tells survive both, but the opponent's head, which is the actual windup, is what gets obscured.

**3. Subjects legible: YES. FB is a near-fail for the trainer.**
- **Fights:** both combatants can be found in under a second in every fight frame. Sparkit's yellow reads against the mud, Voltarach is a big saturated blue mass, and Staticub is a big brown mass. C1b is the weakest because the gold puff ghosts Staticub.
- **Trainer in each fight frame:**
  - **H0:** dead centre, standing inside Voltarach's leg cage, so the two meshes overlap.
  - **H2b:** not visibly on screen. There is a faint shape behind the lower-left Sparkit panel.
  - **H2e:** peeking out from behind the right edge of the team list at left. Partly hidden by the HUD.
  - **Ci:** bottom-right corner under the move panel, with only the boots visible.
  - **C1b:** bottom-right corner, head only, under the move panel.
  - **C2f:** right of centre, fully clear of the HUD.
- **Exploration:** the trainer is found at once in RC, RB, GC and FC. In GB it reads only from the backpack. In FB the figure is a dark shape on a dark trunk and only the backpack gives it away. That is findable in about a second only because the camera always centres it.

**4. HUD keeps a safe area and does not cover key action: YES, marginally.**
- **Safe area:** margins are about 3% on all sides. Both combatants' facing and the attack warnings stay visible in every fight frame.
- **What needs fixing even so:**
  - **Nameplate:** the top-centre plate (about 29% of the width and a quarter of the height) cuts off the top of the opponent in H2e (Voltarach's back) and C2f (Staticub's ears and crown). In Ci and C1b it touches Staticub's head.
  - **Left column:** the team list plus the Sparkit panel covers about 25% of the width and 60% of the height during fights. The tail of the H2b tell cone runs underneath it.
  - **Tell cone vs move panel:** in Ci the cone ends against the move panel's edge.
  - **Trainer vs HUD:** in Ci, C1b and H2e the HUD is what hides the trainer.

---

## Creatures and characters (said first)

- **The three creatures do not share one style.**
  - **Sparkit** is a toon fennec with big ears, painted markings and clean shapes. It is the only creature near the Palworld bar, and it clearly matches the yellow long-eared companion in the key art's Day/Night panels.
  - **Staticub** (Ci, C1b, C2f) is a near-photoreal bear with realistic fur and purple lightning streaks painted over it. It reads as a stock asset set beside a toon one.
  - **Voltarach** (H0, H2b, H2e) is a lumpy, glossy blue mass with camouflage blotches, cyan sphere eyes, and no readable jaws, fangs or leg joints. At 7 inches its texture is noise and its anatomy is "blue thing with legs".
- **The named Staticub fight has no named opponent.** The opponent is the same bear model as the three or four identical bears roaming just outside the arena (Ci, C1b, C2f, top of frame). Nothing in size, colour or silhouette says this one is special.
- **H2e wild frog:** saturated hot crimson and pink with a noisy texture, top right. It reads as a texture error and puts the reserved red on a non-Team-Tether creature. The same model appears green in H0 and H2b.
- **Trainer:** a chibi-proportioned boy who matches Sparkit's style and the key-art kid. Fine.
- **Strike NPC (S0–S12, left):** a coated, hatted figure. Acceptable.

## Specific defects by frame

**Silhouette and readability at small size**
- **FC, FB:** forest trunks are uniform near-black cones with no bark, roots or rim light. At 7 inches they read as black wedges, not trees, and FB goes almost entirely black.
- **GC, GB:** the "glass" field is five smooth cyan cones on a white line. At sheet size they read as primitive placeholder cones, not glass or crystal.
- **H2b, C1b:** the gold soft discs (bokeh-like sprites) read as smudges on the lens, not as an effect with a shape.

**Colour and value structure**
- **All explore frames:** value is compressed into dark mid-tones. The only highlights are the HUD and, in RC/RB, the gold path crack.
- **Break frames are darker than Calm:** GB is darker than GC and FB darker than FC. The chapter's lightning peak reads as "dimmer", not as flashes of light.
- **RB:** one sky bolt, but the ground and trees take no light from it.
- **Oxblood leaks:**
  - the crimson wild frog (H2e, and dark red behind the nameplate in H2b);
  - a red smear across the "Bramblebun" row of the team list (H0);
  - the rod-line cable, a dark red-brown line in RC, RB and S0–S12;
  - the red-brown stripe on the RC/RB minimap.

  The magenta tell colour is distinct from oxblood and is correctly reserved for danger.
- **"Day 1 · 08:00" on every frame:** in a permanently purple chapter the clock and the image disagree. The label is also low-contrast grey on the sky and collides with branches in GC and GB.

**Intentionality**
- **Ci, C1b, C2f, H2e:** the arena floor is flat brown mud with small tufts at near-regular intervals, which reads as procedural scatter.
- **RC:** the path is lined with same-height oaks at regular spacing, like a corridor.
- **GC:** flowers are sprinkled evenly across the slope.
- **Named fights:** there is no clearing edge, cluster, rock or log to make either arena feel like a place.

**Lighting**
- **All frames:** flat ambient light and no readable sun or key light. Objects barely have contact shadows; the trainer and creatures sit on the ground by position only.
- **No warm accent lights anywhere,** apart from the two small lantern glows on the dead tree in GC and GB. The Stormwood boards are built on warm lanterns against blue lightning.
- **"Sheltered" is not shown:** GC is marked "Calm · Sheltered" under open sky, and rain falls straight through the canopy in FC and FB.

**Horizon and depth**
- **RC, RB, GC, S0–S12:** the horizon is a flat, featureless purple-grey band. The Stormheart tree, which the boards call "a landmark visible across the Electric Forest", appears in no frame.
- **Fight frames:** the camera pitch hides the horizon and sky entirely, so the fight has no sense of place.

**Interface**
- **Nameplate and fight left column:** covered under device answer 4 (they clip the opponent and hide the trainer).
- **Explore quick bar:** five indistinguishable glyph slots (RC–FB).
- **H0:** bond and level sub-text is too small.
- **Trigger glyphs:** unreadable (all fight frames).
- **H0 prompt row:** "Engage Voltarach" plus five button prompts sit centre-bottom over the grass and the trainer's feet. This is the densest text row on screen.

**Artefacts**
- **FC, FB:** a hard black diagonal wedge fills the lower-left corner and a black slab fills the right third. This looks like the camera clipping into trunk geometry or near-plane clipping.
- **H0:** the trainer stands inside Voltarach's legs (mesh overlap) before the fight starts.
- **H2e:** Sparkit's body intersects Voltarach's front legs.
- **C1b:** Sparkit's head sits inside Staticub's mouth, and Staticub renders semi-transparent under the puff.
- **H2b:** the star disc overlaps Voltarach's face.
- **H2e is labelled "impact" but shows no impact:** only a faint magenta outline remains, with no hit flash or reaction.
- **S12:** the bolt is a thin white line. There is no ground flash, scorch or scene light pulse, and the only change on the trainer is a pink tint.

**Scale agreement** (ruler: the trainer is 1.80 m)
- **Voltarach (H0):** about 4 m tall against the trainer standing under it. Plausible for a boss.
- **Staticub (C2f):** on all fours it stands about the trainer's height or a little more, larger than Sparkit.
- **Sparkit (H0, C2f):** roughly 1.5–1.8 m against the trainer.
- **Environment:** RC/RB pylons are about 2× the trainer, the GC/GB cones about 1.5–2 m, the FC mushrooms about knee to waist height. Trees are plausible.
- **Verdict:** no gross relative-scale error in these frames.

---

## The three biggest gaps from the references (ranked)

**1. Value and light structure (all frames; worst in FC, FB, GB).**
- **What the references do:**
  - Every Palworld shot and the key art have a full range from bright sky to shadow, with a clear key light.
  - The Stormwood boards (A/B) show a sunlit blue sky, with lightning and warm lanterns as the brightest things in frame.
- **What these frames do:** they sit in dark purple-green mid-tones with no key light. Forest frames crush to black, and the lightning peak (Break) makes the scene darker, not brighter.
- **Split:** scene-fixable.

**2. The fight is not an event and the world is empty (Ci, C1b, C2f, H2e, H2b).**
- **What the references do:** Palworld 01 and 03 frame the fight low, with trees, sky, grass density and big directional VFX, and the boss fills the frame as an event.
- **What these frames do:**
  - The camera looks down on a flat mud disc with evenly spaced tufts and a ghostly cyan boundary band.
  - The VFX are soft gold smudges.
  - The "named" opponent is a copy of the herd outside.
  - Across the explore frames there are no built or lived-in elements (camps, walkways, banners, lanterns), only pylons.
- **Split:**
  - Camera pitch, arena dressing from installed foliage and rock families, and replacing the VFX are **scene-fixable**.
  - A distinct named-opponent variant is **scene-fixable** if it is only scale, tint or an accessory. It **needs new art** if it needs its own model.
  - Stormheart-style structures **need new art** unless an installed wood-and-banner kit exists.

**3. Creature art is not one family (H2e, C2f, H0).**
- **What the references do:** Palworld's creatures share one bespoke, rounded, expressive style, and the boss reads as a designed character.
- **What these frames do:** a toon fennec, a photoreal bear and a blobby blue spider sit in the same fight. Voltarach has no readable anatomy at handheld size.
- **Split:** needs new art for the Staticub restyle and a stronger Voltarach model. The hot-red frog tint is scene-fixable.

## The two bar questions

**Bar A (the project's own art direction: meadows key art and Stormwood boards A/B): NO.**
- **What carried it:**
  - The oak tree family matches the key art's oak groves.
  - The trainer and Sparkit match the key art's kid and yellow companion almost exactly.
  - The blue crystal pylons echo the board's "Crystal (Subtle)" swatch.
- **What sank it:**
  - The boards' Stormwood is a bright, sunlit forest lit by blue and gold lightning and warm lanterns, with wooden walkways, banners and the Stormheart tree on every horizon. None of that language is in these frames.
  - The frames are a dim purple monochrome with no landmark and no warm light.
  - FC and FB show no readable place at all.
- **Scene-fixable:** value and exposure, Break-flash lighting, warm lantern accents from installed props, a distant landmark placeholder silhouette, clustered dressing.
- **Needs new art:** a Stormheart landmark and walkway/banner kit, if none is installed.

**Bar B (beside Palworld, the same kind of game?): YES, as a genre read, not as quality parity.**
- **What carried it:** H2e, Ci and C2f have the genre's grammar. A piloted companion faces a level-tagged wild creature, with a team list, move buttons, and a wild herd visible in the world. Anyone would call it a creature-collector action RPG trying to be in Palworld's space.
- **What holds it back from matching the shots:**
  - the dark, flat value structure;
  - empty mud arenas seen from above;
  - VFX that smudge instead of punch;
  - creature styles that disagree with each other.
- **Split:** the first three are scene-fixable. The creature-style mismatch needs new art.

---

## TOP FIXES

1. **Make the forest and the Break peak readable.**
   - Fix the black wedge and slab in FC/FB, which looks like camera clipping into trunks.
   - Raise the value floor under the canopy so the trainer and trunks separate.
   - Make Break brighter at its peak: a lightning flash should light the ground and trees for a beat (RB, GB, FB, S12).
   - Add a few warm lantern point lights from installed props for the board's warm-versus-blue contrast.
2. **Re-stage the fight frame for the handheld.**
   - Shrink the enemy nameplate, or anchor it so it never overlaps the opponent (H2e, C2f).
   - Slim the left column (team list plus Sparkit panel).
   - Lower the camera pitch so some tree line or sky is in frame.
   - Give the trainer a bystander spot outside the HUD footprint (Ci, C1b, H2e).
   - Dress the arena edge with clustered installed foliage and rocks instead of evenly spaced tufts.
3. **Make the tells and hits crisp.**
   - Remove the gold soft-disc sprites and the translucent star disc (H2b, C1b) that ghost the opponent. The windup should read on the creature's body plus the magenta ground shape.
   - Give impacts a real moment: a flash, a hit reaction and a short scorch or decal on H2e-type impacts and at S12.
   - In the same pass, fix the oxblood leaks: the crimson frog tint, the red smear on the H0 team row, and the red-brown rod cable and minimap stripe.
