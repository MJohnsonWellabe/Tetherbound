# Stormwood f10_6 r2: code-blind visual judgement

Inputs: `_sheet_7inch.jpg`, which I read for readability at its native 1778 px width (each cell is about 586 px, a 0.305 scale of 1920). I opened the full-size `explore/*.jpg` and `fight/*.jpg` only to confirm what a detail is. References: Meadows key art, Stormheart boards A and B, and Palworld 01–05. I read no code, config or reports.

Frame keys: RC = rod_line_calm, RB = rod_line_break, GC = glass_calm, GB = glass_break, FC = forest_calm, FB = forest_break, H0 = hollows_alpha-00-before, H2b = hollows_alpha-tell2-b-mid, H2e = hollows_alpha-tell2-e-impact, Ci = crown_guardian-i05, C1b = crown_guardian-tell1-b-mid, C2f = crown_guardian-tell2-f-recovery.

---

## Device-profile read (7-inch, about 450 mm)

**1. HUD text is legible at 7-inch size: YES for the primary items, NO for the secondary labels.**
- **Legible:**
  - The objective card ("MAIN STORY / Find Ashfoot Waycamp.", all explore frames and H0).
  - The enemy name, "Staticub" and "Voltarach" (Ci, C1b, C2f, H2b, H2e).
  - The tell text "! incoming — move" (Ci, C1b, H2b). It is amber and about 7–8 px tall on the sheet: small, but it reads.
  - The team-list names (all fight frames).
  - The move names "Spark Bite / Arc Lash / Switch" when active (Ci, H2e), and "Orbs 0".
  - The hint bar "Map / Satchel / Build" (all explore frames).
- **Marginal:**
  - "LEVEL 41 / LEVEL 38" is roughly 6 px of light grey.
  - "it's open — hit it" (C2f) is teal on a translucent card, with lower contrast than the amber "incoming" line.
  - "100 / 100" and "100%" on the health and food bars.
- **Fail:**
  - The weather/state tag "Calm · Sheltered" or "Break" (every frame) is about 4 px on the sheet and unreadable.
  - The element tag "ELECTRIC" is about 5 px.
  - The "FOOD" label is dim gold sitting on the start of its own bar (all explore frames and H0).
  - The explore team rows "bond 0/5 Lv 42" (H0) are gold on translucent.
  - The RT/LT/LB trigger glyphs on the move buttons are about 3–4 px and unreadable.
  - The quick-slot glyphs "1–5" are unreadable (RC through FB).
  - During tells the move buttons dim to grey-on-grey, and "Spark Bite / Arc Lash" become hard to read (C1b, H2b), right when the player needs them.

**2. Tells and danger are legible: YES for the enemy attack shapes, NO for the lightning ring.**
- **The attack shapes read instantly at 7 inches.**
  - Staticub: the saturated magenta cone plus foot ring (Ci, C1b).
  - Voltarach: the magenta lane with an arrow chevron (H2b).
  - The magenta holds against the brown fight floor.
- **The lightning ground-warning ring cannot be identified in any frame.** The only ring-like shape besides the magenta foot ring is a faint teal translucent band around the arena (H2b, H2e, Ci, C1b, C2f). At 7 inches it reads as an arena boundary or water edge, not as danger. It has low contrast against the grass, no pulse or edge definition visible in a still, and a hue far from the danger magenta.
- **The in-body tell hides the anticipation.** The gold sunburst disc on the enemy's chest (C1b, H2b) partly covers the body pose. In C1b the whole Staticub model also goes semi-transparent.

**3. Subjects are legible: NO.**
- **The opponent is always found instantly.** Voltarach and Staticub are large and centred.
- **The piloted creature is found instantly.** Sparkit's yellow and black pops in Ci, H2e and C2f, but in C1b it disappears into the bear's jaw under the sunburst.
- **The trainer fails.**
  - In Ci and C1b the trainer is hidden behind the move panel at bottom right: only hair or boots show at the panel's lower edge.
  - In H2e the trainer is buried behind Sparkit inside Voltarach's leg cage.
  - In FB the trainer is a near-black shape on near-black grass and takes well over a second to find.
  - In H2b the trainer stands at the very bottom edge, clipped by the frame and crowded by the Sparkit card.

**4. The HUD keeps a safe area and doesn't cover the key action: NO.**
- **The safe area is borderline.** Panels sit about 3 % in from the edges. The weather tag is about 1.4 % from the left edge.
- **Coverage is the real failure.**
  - In C2f the enemy card (top centre, about 560 × 230 px at full size) sits over Staticub's head and ears, and the tell text is drawn on the bear's ear. In Ci it covers the bear's back and the target diamond.
  - The move panel covers the trainer in Ci and C1b.
  - The translucent team list lets world detail through: in H0 a red creature behind the panel smears across the "Bramblebun" row like a damage or highlight stripe.
  - In fight frames the four HUD blocks (team list, active card, enemy card, move panel) take roughly a quarter of the screen. They crowd the arena's left and right thirds while the action sits in the centre and lower middle.

---

## Specific defects by frame

**Interface**
- **All explore frames, H0: the health and food bars read as about 40 % full.** The fill ends where the numeric plate begins: the lighter green fill runs to about x=158 of 300, and the gold fill to about x=205. At a glance a full bar looks mostly empty.
- **All explore frames, H0: the "FOOD" label overlaps its bar in low-contrast gold.** The health bar has only a tiny heart icon.
- **Mixed input glyphs in a controller-first build.** RC through FB show keyboard glyphs (M, I, B, 1–5), while H0 and the fight frames show pad glyphs (X, Y, LT, RB, LB, RT).
- **Empty quick-slot boxes** (RC through FB) take a 560 × 110 px block in the lower right with nothing in them. In H0 they show only D-pad arrows.
- **C2f: the whole move panel disappears.** Only "Orbs 0" remains, at the exact moment the tell says "it's open — hit it". This invites the player to act while showing no actions.
- **C1b, H2b: the move buttons dim to low contrast during tells.** RT and LT fade out, and a stray "···" sits under "Arc Lash".
- **H0: the translucent team panel shows a red world object through the Bramblebun row.**
- **Minimap colour switches without apparent reason:** parchment tan in FC and FB, green elsewhere.
- **Break versus Calm is signalled almost only by the unreadable 4 px tag** (RC/RB, GC/GB, FC/FB). See lighting.

**Artefacts**
- **FB, FC: flat black near-camera trunk geometry.** It shows as a hard black wedge down the left edge and a flat black slab across the right fifth, and reads as clipping or unlit geometry, not shade.
- **C1b: the Staticub model goes semi-transparent and ghosted** during the tell. It reads as a rendering bug.
- **C1b: Sparkit's head clips into Staticub's mouth.** In H2b Sparkit clips into Voltarach's face. In H2e the trainer stands inside Voltarach's legs.
- **H2b: large soft yellow discs float across the frame** (upper right and around the spider). They read as lens smudges or unexplained sprites, not sparks.
- **RB: a dark red cable crosses behind the objective card**, and a matching red-brown stripe appears on the minimap.

**Colour and value**
- **All explore frames: the value range is crushed.** The sky is one flat mid-violet, the tree masses are near-black green and the ground is mud brown. There is no light source, and no warm or cool split except the gold path crack in RB.
- **FC/FB are about 40–60 % pure black.**
- **Oxblood reservation at risk.**
  - H2e has a saturated crimson spiky wild creature at the top left.
  - RB has the dark red cable, and the red trace on the minimap.
  - If neither belongs to Team Tether, red has leaked onto neutral or friendly elements.
- **The magenta telegraph is hue-adjacent to the purple storm world.** It works on the brown fight floor. It would fight the violet sky if a telegraph ever sits against it.

**Intentionality**
- **Ci, C1b, C2f: four or more identical Staticub-style bears in the background**, all in the same pose, with the same purple stripes and the same scale. They read as spawned copies, not a pack.
- **Fight arenas (all fight frames): a flat plain carpeted with evenly spaced identical grass sprigs and flowers.** There is no clearing, rock or root to stage the fight against. It reads as generated.
- **GC/GB: the "glass" landmark is six flat-shaded cyan cones and a thin light strip.** They read as primitive placeholder shapes, not crystal.

**Lighting**
- **No frame reads as 08:00, the time the HUD shows.** Everything reads as dusk or night.
- **The trainer and the creatures have no rim or key light** to separate them from the ground. The one exception is Sparkit's own yellow.
- **Contact shadows are faint or absent** under the trainer (RC, GC) and the creatures (C2f). They sit on the ground, not in it.
- **Break, the lightning peak, reads as *less* event than Calm.**
  - RB adds one sky bolt and a brighter path crack.
  - GB adds a bolt behind a tree and gets darker.
  - FB is simply darker than FC.
  - There is no flash-lit terrain, no charged sky gradient and no lit silhouettes.

**Horizon and depth**
- **GC/GB: the horizon is an empty flat violet plain.** No landmark shows in any of the 12 frames. The Stormheart tree, the whole point of both Stormwood boards, is absent.
- **RC/RB have the best depth**, a path receding past pylons. Fog carries no colour gradient, so distance reads only through size.

**Scale** (trainer = 1.80 m)
- **Voltarach is about 2× the trainer's height** (H0, H2e) and correctly dominates.
- **Staticub on all fours is roughly trainer height at the shoulder** (C2f), which is plausible.
- **Sparkit, the piloted creature, stands at about the trainer's chest** (H2e, C2f). It is the smallest body in every fight. That is not a relative-scale error between the frames, but it reads underpowered beside the opponents.
- **Mushrooms are knee-high and the pylons are about 2× the trainer.** Both are consistent.

---

## The three biggest gaps from the references (ranked)

1. **No landmark and no event in the storm** (GC, GB, RB, FB). Boards A and B are built around a colossal split tree, visible across the region, with blue-white lightning running through warm-lit wood, lanterns and banners. Palworld 04 frames a tower landmark on the horizon. None of these frames shows a landmark. Break, the lightning peak, shows a single thin bolt in the sky and otherwise darkens the scene.
2. **Value and light collapse** (all explore frames, especially FC and FB). The key art and both boards are high-key: bright skies, sunlit terrain, strong warm/cool contrast. Palworld 02 and 03 have full daylight value ranges. These frames sit in a narrow dark band, with black trunks, flat violet sky and unlit characters. Silhouettes vanish at 7 inches.
3. **Fights don't look like staged events, and the HUD competes with the subjects** (Ci, C1b, C2f, H2b). Palworld 01 and 03 fill the frame with the creature, big hit sparks and dense foliage. Their HUD stays thin at the edges and never covers the boss. Here the arena is an empty sprig-carpet plain with cloned background bears. The heavy translucent HUD blocks cover the trainer and the boss's head, and the one impact effect (the sunburst disc) hides the pose instead of selling it.

---

## Bar verdicts

**Bar A: do these frames belong to the world of the Meadows key art and the Stormheart boards? NO.**
- **What carried it:**
  - The trainer's proportions and outfit sit close to the key art's "Day/Night" hero.
  - Sparkit echoes the key art's yellow fox companion.
  - The green grass and purple flowers belong to the same natural palette.
  - The gold path crack in RB is the one moment of the boards' warm/cool storm-light language.
- **What sank it:**
  - The Stormheart landmark is absent.
  - The value range is crushed, with a flat violet sky and black trunks.
  - There are no warm lantern or wood accents.
  - The black clipping wedges in FB and FC.
  - The placeholder cone "crystals" in GC and GB.
  - Board B's purple/blue electric palette survives only as a flat sky tint.

**Bar B: beside Palworld, are these trying to be the same kind of game? YES.**
- **What carried it:**
  - A third-person trainer beside a piloted creature, facing a much larger named, levelled electric creature.
  - A top-centre boss plate with level, name and HP bar, plus a party list on the left and moves on the right.
  - Readable magenta telegraphs.
  - Sparkit and Staticub are expressive, appealing creature designs that sit in Palworld's register.
- **Why it does not reach Palworld's quality:**
  - Empty, procedural-looking arenas.
  - Dark murky world value.
  - A weak impact effect.
  - Cloned background creatures.
  - HUD over the subjects.
  - Voltarach's single-material blue plastic look.

---

## Gaps split: scene-fixable vs needs new art

**Scene-fixable (code, lighting, layout, scatter):**
- **Lighting and sky:**
  - Raise the exposure and value range.
  - Add a sky gradient and a cool key light.
  - Add a rim light on the trainer and creatures.
  - Add stronger contact shadows.
- **Break:**
  - Flash-light the terrain.
  - Brighten the sky toward the bolt.
  - Light the forest ground during strikes.
  - Make Break a *brighter, sharper* state than Calm.
- **Forest:** fix the camera or near-occluder clipping that produces the flat black wedges and slabs (FC, FB). Fade near trunks instead.
- **HUD layout:**
  - Move or shrink the enemy card so it cannot overlap the target.
  - Keep the move panel from covering the trainer, or pull the fight camera back.
  - Keep the move panel visible in the recovery window (C2f).
  - Show active colours during tells.
- **HUD bars and labels:**
  - Fix the health and food fill so a full bar reads full.
  - Enlarge the weather/state tag, level, element and trigger glyphs.
  - Use one controller glyph set.
  - Hide the empty quick slots.
  - Make the team panel opaque enough that world colour can't bleed through.
- **Lightning ring:** give it a high-contrast pulsing edge in the danger family, clearly distinct from the teal arena boundary.
- **Tell effects:**
  - Remove the model transparency on Staticub (C1b).
  - Shrink or move the sunburst so the anticipation pose stays visible.
  - Remove the lens-blob sprites (H2b).
- **Arena dressing:** use existing rocks, roots and stumps. Cluster the grass. Vary the pose and scale of the background bears, or thin them out.
- **Colour:** audit the red cable and the red wild creature against the oxblood reservation.
- **Landmark:** if a Stormheart asset or any tall existing tree asset is in the build, place it so it reads on the horizon.

**Needs new art:**
- **A Stormheart tree landmark**, if none exists in the build.
- **The glass/crystal formation (GC, GB)**, which needs a real crystal mesh and material in place of the flat cones.
- **Voltarach's material**, which needs a textured, multi-material pass to hold up against Palworld creatures.
- **The forest trunks**, which read as untextured cones and need bark-textured trunks to match the boards' tree bark and moss swatches.
- **Warm props:** lanterns, banners and wood walkways from the boards' material palette, if not already installed.
- **A proper lightning-strike VFX** (bolt plus ground scorch). A shader change alone may be enough, but the current single sprite bolt is not.

---

## TOP FIXES

1. **Get the HUD off the subjects.**
   - Keep the enemy card from overlapping the target (C2f, Ci).
   - Stop the move panel from covering the trainer (Ci, C1b).
   - Keep the moves visible in the "hit it" window (C2f).
   - Make a full health or food bar read full.
   - Enlarge or cut the unreadable 4–5 px labels (state tag, ELECTRIC, trigger glyphs) and unify the glyphs to the controller set.
2. **Rebuild the storm's light so Break is an event.**
   - Lift the exposure and value range.
   - Add a sky gradient and rim light so the trainer reads in FB and FC.
   - Fix the black near-camera trunk clipping.
   - Make Break flash-light the ground and sky, so it is visibly brighter and sharper than Calm without reading the tag.
3. **Make danger and arenas read as designed.**
   - Give the lightning ground ring a strong, pulsing danger-family edge, distinct from the teal arena band.
   - Stop the Staticub ghosting and shrink the sunburst so tells show the pose.
   - Dress the arena with clustered existing rocks and roots instead of the even sprig carpet and cloned bears.
   - Put a landmark on the horizon.
