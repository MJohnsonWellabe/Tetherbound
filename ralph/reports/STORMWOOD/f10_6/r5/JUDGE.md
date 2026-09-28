# Stormwood f10_6 r5: code-blind visual judgement

Inputs opened: this folder's `_sheet_7inch.jpg`, `explore/*.jpg`, `fight/*.jpg`, `strike/*.jpg`; `.claude/skills/visual-judge/SKILL.md`; the key art, the two Stormheart boards and `palworld-01..05`. Nothing else. Readability calls below come from the 7-inch sheet viewed at native size, one cell treated as the handheld screen. The full-size frames were used only to identify what a detail is.

## Device-profile read

**1. HUD text legible at 7-inch size: NO.**
- Legible: the objective card ("MAIN STORY / Find Ashfoot Waycamp.", every explore cell); the enemy name ("Voltarach", "Staticub" in Hi/H2b/H2e/Ci/C1b); "! incoming — move" (Hi, H2b, Ci, C1b); the team-list names (Hi through C2f).
- Not legible:
  - **Health and food bars.** In every explore cell and H0, "100 / 100" and "100%" are about 6 px tall, white on the bar's own green or ochre fill. The "FOOD" label is dim olive on a dark panel and runs into the start of the bar. You can read that there are two bars, not what they say.
  - **"it's open — hit it" (C2f).** It renders at reduced opacity together with the whole enemy plate ("LEVEL 41 / Staticub / ELECTRIC" have also faded). At 7 inches it is a ghost over grass. This is the one positive cue in the fight, and it is the least legible line on screen.
  - **Move buttons.** In the fight cells, "Spark Bite / Arc Lash / No orbs / Switch" are borderline. The RT/LT/X/LB glyphs above them cannot be read. The "100" cost beside Arc Lash is a smudge.
  - **Explore quick bindings.** RC through FB show five icon-only slots of D-pad glyphs with no labels or items. Their meaning cannot be read.
  - **H0 team rows.** "bond 0/5 Lv 42" cannot be read.
  - **Top-left weather line.** "Calm · Sheltered" / "Break · Sheltered" is small, pale blue on the purple sky (GC, GB). "Day 1 · 08:00" at top centre is grey on grey-purple and nearly vanishes in RC/GC.
  - **Translucent panels.** Rain streaks and grass show through the backgrounds behind the text, which lowers contrast further (Ci and C2f team list; the crown_guardian tell1 enemy plate has a wild Staticub visible through it).

**2. Tells and danger legible: NO (partial).**
- The **lightning ground ring works** (S0 through S12). The magenta circle is faint in S0 but readable. It gains crack lines in S6, turns white-pink by S10 and is unmistakable at S12. The escalation reads.
- The **Staticub tell works** (Ci, C1b). A magenta cone plus a ring around the bear reads as a clean shape.
- The **Voltarach tell fails** (Hi, H2b, H2e).
  - In Hi/H2b it is a tangle of magenta strips (a lane toward the trainer, a second lane and a partial ring). Half of it is under the spider's body and legs, and the lower-left end runs under the active-creature panel. You cannot tell at a glance where it will hit or which way is safe.
  - In H2e the shape has faded to a dim purple smear under the spider and is not readable at all.
- The beige "sunburst" glyph that appears during the tell (H2b over the spider's face, C1b over the bear's head) reads as "something is happening". It also washes the enemy out. In C1b the bear turns into a pale ghost, so the attacker's own wind-up pose is lost behind the warning.

**3. Subjects legible: NO.**
- Explore RC/RB/GC/GB: the trainer is centred and found instantly.
- **FB**: the trainer is a near-black figure on near-black grass, found only because the camera centres them. It is not a sub-second read.
- **H2e**: the trainer is wedged between Sparkit and a spider leg, and at 7 inches is only a sliver of backpack.
- **Hi/H2b**: the trainer is pushed to the bottom edge of the frame with the feet cropped. In Hi the fading-in active-creature panel ("Sparkit / Lv 42 / WIND / Energy", partly transparent) overlaps the trainer's backpack.
- **H0**: the trainer stands under the boss's body, framed by its legs. The "Engage Voltarach" prompt sits across the spider's front-right leg.
- **C1b**: the opponent is bleached by the burst overlay.
- Sparkit (the piloted creature) is always findable because of its yellow/black colours, and that is the strongest subject read on the sheet.

**4. HUD keeps a safe area and does not cover the key action: NO.**
- The edge margins are fine: all panels sit about 3% in from every edge.
- In combat, however, the left column (the "TEAM 5/5" list plus the active-creature panel) occupies roughly x 55–485 and y 415–1020, about a quarter of the screen, in every fight frame.
- In Hi and H2b the Voltarach attack lane runs under that column, so the HUD covers attack geometry.
- In Ci the Staticub cone's right edge runs up to the move panel.
- In H0 the interaction prompt covers the boss.
- The UX rule (do not cover the trainer, the active creature, the target or the attack geometry) is broken in Hi, H2b and H0.

## Defects by frame

### Creatures and characters (said first, as the rubric asks)
- **Three unrelated creature styles on one screen (Hi, Ci, C2f).**
  - Sparkit is a bespoke stylised creature with an expressive face, and it is the best asset here.
  - Staticub (Ci, C1b, C2f) is close to a realistic brown bear with photographic fur and a purple streak painted on. It belongs to a different game from Sparkit and the chibi-proportioned trainer.
  - Voltarach (H0 through H2e) is saturated royal blue with a blotchy camouflage texture. It is lumpy, with no readable face beyond three cyan eye-balls. Its dark side does not pick up the scene's purple ambient, so it looks pasted over the scene rather than lit by it.
  - The spiky red toad in Hi/H2e looks flat-shaded and untextured.
- **The red toad (Hi, H2e, and the red smear behind the "Bramblebun" row in H0)** is saturated crimson/scarlet, close to the red the palette reserves for Team Tether. If it is a wild creature, it is leaking the danger colour. The rod-line cables are a dark rust-red (RC, RB, S0–S12) and are also creeping toward it.
- **Repeated background wildlife (C2f, crown_guardian tell1).** At least four identical Staticubs dot the field behind the fight, some in near-identical poses. The eye reads them as copies.
- **Scale mostly agrees.**
  - Against the 1.80 m trainer: Sparkit stands at about waist height, Staticub on all fours reaches about trainer height at the shoulder, Voltarach is about 2.5× the trainer, and the forest trunks (FC) are appropriately huge. The larger fight creatures are bigger than the companion, as their roles imply.
  - One point is odd, though it may be framing: in H0 the trainer stands fully inside the boss's leg span before engaging.

### Interface
- Health and food bars are too small and low-contrast, with numbers printed on the fill (all explore cells, H0).
- The team list and active-creature panel take a quarter of the fight screen and cover tell geometry (Hi, H2b). The ghosted half-opacity active panel in Hi is an intermediate state that should never be captured on screen: it both covers the trainer and is unreadable.
- The enemy plate fades out at exactly the moment it says "it's open — hit it" (C2f).
- Quick bindings are icon-only glyphs with no labels (RC through FB).
- Panel backgrounds are translucent enough for rain and grass to read through behind the text (Ci, C2f, crown_guardian tell1).
- In RB the lightning bolt in the sky tucks behind the minimap, so the one Break event in that frame is partly hidden by the HUD.

### Colour and value
- The whole chapter sits between dark and mid values, with a purple ceiling and brown-green floor. Nothing goes bright except the path glow (RC/RB), the tells and the strike bolt.
- **FB** is almost entirely below 15% value.
- **Break reads as a darker Calm with heavier rain** (RB vs RC, GB vs GC, FB vs FC), not as a lightning peak. Lightning never lights anything: the bolts in RB and GB are white strokes in the sky or across canopies, and the ground, trees and trainer receive no flash.
- The magenta tells are strong enough to separate from the purple world. At S0, though, the first warning ring is dim magenta on purple-brown dirt, and the chapter hue works against it.

### Intentionality
- **The fight arenas (Ci, C1b, C2f, H2e)** are flat, dark mud with evenly scattered sprigs and flowers at regular spacing. The backdrop is a row of evenly spaced trunk bases cut off by the top of the frame. This reads as procedural scatter, not an authored place.
- **The glass field (GC, GB)** is four translucent blue cones and a thin white line on a slope. It reads as a placeholder primitive, not a designed landmark.
- The rod line (RC/RB) is the most authored-looking thing on the sheet: a winding glowing path, pylons with lanterns and a cable leading off.

### Lighting
- There is no readable light direction in any frame. It is overcast, which is defensible for a storm, but terrain has little form: the GC/GB slope reads only from grass density.
- Creatures sit on the ground adequately (Ci), but Voltarach's lighting does not match the scene (see above).
- **Strike impact (S12)** is a thin, wiry bolt with a small spark splash at the feet. There is no ground flash, no bloom on the ring, no sky brightening and no scorch. The trainer's hair tints pink, which reads as a colour bug more than a hit. For "one lightning ground strike", the payoff is smaller than its own warning ring.

### Horizon and depth
- **GC/GB**: the right half of the horizon is a flat grey slab that ends in a hard edge. A faint dotted line runs along the upper-left slope. The world visibly stops.
- **Every frame** lacks a landmark. The Stormheart tree, which both boards describe as "visible across the Electric Forest… draws you in", appears in none of the thirteen cells.
- The fight camera (Hi through C2f) pitches down so steeply that the sky and canopy leave the frame. The fights happen on a brown carpet with no sense of place.

### Artefacts
- **FC and FB** have hard black wedges at the lower-left and upper-right edges. These look like near-plane clipping into tree trunks. They read as a bug.
- **C1b and H2b**: the burst overlay renders the enemy semi-transparent (the bear's body turns pale pink and translucent).
- **S12**: the trainer's hair turns magenta-pink at impact.

## The three biggest gaps from the references (ranked)

1. **A fight does not look like an event, and the creatures do not look like one game's creatures.**
   - Palworld 01 and 03 fill the frame with the enemy: an expressive face, saturated signature VFX (sparks, speed lines, leaf swirl), and a creature style shared with the player's companion.
   - Hi, H2b, Ci and C1b show three mismatched creature styles (toon Sparkit, realistic bear, blotchy flat-blue spider), a single beige sunburst that hides the enemy's face, and flat magenta decals.
   - Nothing in C2f or H2e reads as a hit, a dodge or a climax.
2. **The world is empty and ends.**
   - Palworld 02 and 04 have varied ground (worn paths, rocks, cliffs, ruins, distant spires) and a landmark on the horizon. The Stormheart boards build the whole region around a colossal lit tree.
   - Here the fight ground is uniform mud with even scatter (Ci, C2f), the glass field is four cones (GC), the horizon is a flat plane edge (GC, GB) and the Stormheart never appears.
3. **The value range collapses, and Break subtracts light instead of adding it.**
   - The references, including the boards' own lightning, use a full range: bright sky, warm lanterns, lit bark, glowing crystal against dark bark.
   - Here everything is dark mid-purple. FB is nearly black. The chapter's peak moment (RB, GB, S12) never lights the scene.

## Bar verdicts

**Bar A (key art and Stormheart boards): NO.**
- *Carried:*
  - The stylised oak silhouettes in RC and RB are the same family as the key art's oak grove.
  - The trainer and Sparkit are recognisably the boy-and-yellow-fox pair from the key art's Day/Night insets.
  - The rod line's glowing path and lantern pylons echo the boards' "crystal / warm light" material language.
- *Sank:*
  - The key art's promise is "vibrant, readable colours, silhouettes and landmarks visible from distance, cozy with hints of mystery". The frames are dim, one-hue and landmark-less.
  - The Stormwood boards' defining elements are all absent: the split Stormheart tree, warm lanterns against lightning-blue, wood platforms and banners.
  - The glass field is a placeholder.
  - This reads as the right cast standing in an unfinished level, not in the world on the boards.

**Bar B (Palworld): YES.**
- *Carried:* H0, Ci and Hi are unmistakably the same kind of game: a trainer next to a companion creature, a large named creature with a level plate, telegraphed attacks, a team list and a move panel. Someone seeing these beside palworld-01/03 would say they are aiming at the same game.
- *Sank (quality, not genre):*
  - The creature-style mismatch.
  - Fights without spectacle.
  - Empty, dark ground.
  - A HUD that covers the action on a small screen.
- It is the same kind of game at a visibly lower finish.

### Gap split

**Scene-fixable** (camera, HUD, lighting, materials, scatter, installed assets):
- Fight HUD layout, sizes, opacity and contrast; quick-binding labels.
- Voltarach tell drawn as one clean shape readable over and through the body; tell-time overlay that does not bleach the enemy.
- Fight camera pitch and trainer framing, so the trainer is off the bottom edge and never inside the boss's legs.
- Forest exposure/ambient floor (FB, FC) and the near-plane clip wedges.
- Break lighting: lightning that flashes the sky, ground and characters; bloom and ground flash on the strike impact (S12); the pink hair tint.
- Ground material variety, and scatter that clusters with clearings instead of an even grid (Ci, C2f).
- A distant tree line or fog layer to hide the flat horizon edge (GC, GB).
- Glass-field dressing using installed crystal and rock families.
- Recolouring the red toad and the rust cables off the reserved red.
- Matching Voltarach's material response to scene lighting (drop the unlit/emissive look).
- Breaking up duplicated background Staticubs (count, placement, pose offsets).
- A Stormheart silhouette on the horizon, only if one can be kitbashed from the installed tree family at scale.

**Needs new art:**
- A stylised Staticub that matches Sparkit and the trainer (the current one is near-photoreal).
- A properly modelled and textured Voltarach with a readable face and material breakup.
- A finished model for the red toad creature.
- A bespoke Stormheart landmark mesh, if kitbashing cannot reach the boards' silhouette.
- Authored glass-field formations, if the installed crystals cannot stand in for them.

## TOP FIXES

1. **Rebuild the combat HUD for a 7-inch screen.**
   - Collapse the "TEAM 5/5" list during combat to the active creature plus four compact pips, and shrink or move the active-creature panel. Nothing on the left may overlap tell geometry or the trainer (Hi, H2b).
   - Keep the enemy plate and "it's open — hit it" at full opacity (C2f).
   - Enlarge the HP/food numbers and move labels, and put the text off the bar fill.
   - Label the quick bindings, and use solid panel backgrounds so rain does not show through the text.
2. **Make every tell a clean shape over a visible enemy.**
   - Draw the Voltarach tell as one bold shape visible through or around the body (Hi, H2b, H2e).
   - Stop the tell overlay from bleaching the attacker (C1b, H2b).
   - Reframe the fight camera: pitch up enough to show some canopy/sky, keep the trainer clear of the bottom edge and out from under the boss (H0, H2e, Hi). Give the trainer a subtle rim or outline so they stay findable.
3. **Give Stormwood a value range and a peak.**
   - Lift the forest ambient floor and fix the black clip wedges (FB, FC).
   - Make Break lightning light the world: sky flash, ground and character flash, and bloom and ground flash on the strike (RB, GB, S12).
   - Hide the flat horizon edge with a distant tree line or fog, and put the Stormheart silhouette in view (GC, GB) so the region has the landmark its boards promise.
