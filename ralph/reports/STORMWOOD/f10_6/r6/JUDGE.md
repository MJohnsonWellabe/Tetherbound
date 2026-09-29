# Stormwood f10_6 r6: code-blind visual judgement

Inputs I opened: `.claude/skills/visual-judge/SKILL.md`, the Bar A references (Meadows key art, Stormheart boards A and B), the Bar B references (Palworld 01 to 05), `_sheet_7inch.jpg` (also cropped at native pixels, with no scaling), and the full-size `explore/`, `fight/` and `strike/` JPGs. I made the readability calls from the 7-inch sheet at 100% only. I used the full-size frames only to identify what a detail is.

Reading distance is 450 mm. On the sheet, a 1.8 mm cap height is roughly 7 px, which is the limit of comfortable reading. Text below about 6 px on the sheet counts as illegible below.

---

## Device-profile read

### 1. HUD text legible at 7-inch size? **No.**

Legible:
- Objective card body "Find Ashfoot Waycamp." (RC, GC, FC, H0).
- Enemy name "Voltarach" / "Staticub" (Hi, Ci).
- Tell lines: "! DIVE — step out of its line" (Hi, H2b), "! incoming — move" (Ci, C1b) and "it's open — hit it" (C2f). These are small but readable, about 7 px.
- Move names "Spark Bite / Arc Lash / Switch" (Ci), just barely.
- "it missed you" (C2f).

Not legible:
- **Health and food bars:** the "100 / 100" and "100%" numerals and the "FOOD" label are about 5 px in every explore cell (RC to FB, H0). The FOOD label is gold on a gold-brown bar, so it has almost no contrast. The bars read as two coloured strips, and nothing more.
- **Enemy level and type:** "LEVEL 38", "LEVEL 41" and "ELECTRIC" are about 5 px (Hi, H2b, H2e, Ci, C1b, C2f). The type is also yellow on dark grey at that size.
- **Team list:**
  - In H0 the "bond 0/5 Lv 42" columns are about 4 px and do not read.
  - In all fight cells (Hi to C2f) the list has no text at all: five colour swatches with identical full bars. Mudsnout and Terrapup are both brown swatches and look the same, so the list shows "five, all healthy" but not *who*.
- **Move buttons:** the controller glyphs (RT, LT, X, LB) above the move names are about 4 px (Hi, Ci). "Arc Lash 100" (the cost) and "No orbs" are marginal.
- **Other chrome:**
  - The quick-slot bar in every explore cell is five unlabeled roughly 4 px glyphs.
  - Status "Calm · Sheltered" and "Day 1 · 08:00" are about 5 px.
  - The objective header "MAIN STORY" is letter-spaced to about 4 px.

### 2. Tells and danger legible? **Yes, with two caveats.**

Every tell reads at 7 inches, in the saturated magenta/pink family, which is the best readability work on the sheet:
- the Dive line with chevrons and target ring (Hi, H2b);
- the cone and ring of Staticub's slam (Ci, C1b);
- the lightning ground ring (S0 to S12).

The ground strike escalates cleanly: a thin dim ring at S0, cracks at S6, a bright pink-white fill at S10, and the bolt at S12.

Caveats:
- **S0:** the first-warning ring is a thin, dim magenta line on a dark wet path, and it is the weakest frame of the sequence. It reads, but not at a glance.
- **Hi, H2b and H2e:** a saturated red/pink frog in the background sits in the same hue family as the tell decals, next to the enemy card. It competes with the danger colour.

### 3. Subjects legible (trainer, piloted creature, opponent found in under 1 s, none hidden by HUD)? **No.**

Failing frames:
- **H2b:** the trainer is at the extreme left edge, half off-frame, *behind* the companion status panel. That panel fades to a ghost over them, so the trainer cannot be found in a second.
- **Hi:** the trainer is cut by the bottom-left frame edge, under the same ghosted panel.
- **H2e:** the trainer is squeezed between the team list and a Voltarach leg, and is a few pixels wide at 7 inches.
- **H0:** the trainer stands *inside* Voltarach's leg cage, dead centre. Sparkit is half-hidden behind a leg on the right.
- **FB:** the trainer is a dark silhouette on dark grass, the weakest explore frame for finding the player.
- **C1b:** the beige hit-burst disc covers the opponent's head and eyes for the whole frame.

Passing frames: Ci, C2f, RC, RB, GC and all S cells.

### 4. HUD keeps a safe area and doesn't cover the key action? **No.**

The edge margins are kept: no element touches the panel edge. The failure is coverage of the action, not the edges.
- **Hi and H2b:** the companion status panel sits over the trainer. The response is to ghost the panel, which makes it illegible *and* still covers the trainer.
- **H0:** the named team list takes the whole left third down to the grass line.
- **Explore cells:** the empty five-slot quick bar plus the Map/Satchel/Build prompt row together take about a quarter of the lower-right quadrant, in every explore frame.
- **C1b and C2f:** the enemy card covers a background bear, which is harmless, but the card is translucent, so scene content shows through behind the text.
- **H0:** a pink smear bleeds through the translucent team-list row behind "Bramblebun".

---

## Full visual-judge verdict

### Creatures and trainer (said first)

- **Sparkit** (Ci, H2e, C2f) holds up against the Palworld bar. It is expressive, has a clear silhouette (big ears, bolt tail, yellow and black mask) and reads instantly at 7 inches. It is the best asset on the sheet.
- **Staticub** (Ci, C1b, C2f) is a semi-realistic brown bear cub with painted fur and purple vein decals. It is more realistic than Sparkit and the trainer, so the two do not look like one game's cast.
  - Worse, the *named* fight's opponent is **the same model at the same size as the herd grazing behind the arena**: three to five identical bears are visible in Ci, C1b and C2f.
  - A named fight whose opponent is indistinguishable from the herd fails "does a fight look like an event".
- **Voltarach** (H0 to H2e) has a flat saturated royal-blue body with blotchy purple camo. Its legs are single curved blades with no joints or feet, and its eyes are three plain cyan spheres. It reads as a toy or a generic sourced asset, not as a bespoke boss. At 7 inches it is a big blue mass, and nothing about it says "electric".
- **Red frog** (Hi, H2b, H2e) is a flat, untextured-looking crimson and magenta. It looks like a material fallback, and it uses the reserved red.
- **Trainer:** chibi-leaning proportions, backpack and blue jacket, consistent with the Stormheart board's trainer. It is fine at full size but small in the explore framing (RC, GC, FC).

### Scale (the trainer is 1.80 m)

- Sparkit is about 1.1 to 1.3 m to the ear tips (Ci, standing beside the trainer). The piloted companion is shorter than the trainer.
- Staticub's head is at about 1.5 m and its body length is about 2.5 m (Ci).
- Voltarach stands about 2.5 to 3 m and spans about 5 m (H0).
- Relative scale is internally consistent: rods, trees and mushrooms are all plausible beside the trainer.
- The noted issue is the Staticub herd: background bears at the same scale as the named opponent (Ci, C2f) remove any size hierarchy for the guardian.

### Defects by frame

**RC / RB (rod line):**
- The Calm-to-Break change reads: a sky bolt, heavier rain and a brighter ground seam.
- The bolt in RB is a thin line tucked behind the minimap and objective card, so the "lightning peak" happens under the HUD.
- The cable between the rods is dark oxblood-red at 7 inches, as is the minimap's route stroke. Red is meant to be reserved for danger, and this reads as a leak.
- The cobble path texture tiles visibly in the foreground (RC).

**GC / GB (glass field):**
- The "glass" is five plain translucent cyan cones in a row, next to a flat pale plane with a hard straight edge. It reads as placeholder primitives, not crystal.
- The two floating lantern orbs by the dead tree have no visible support.
- In GB the Break lightning is short white crescents and hooks pinned to the sky around the tree crowns. At 7 inches they look like floating decal fragments, not bolts.
- The hillside is an even carpet of identical grass and flower tufts (procedural read).

**FC / FB (forest):**
- **Artefact:** hard-edged pure-black polygons at the lower left and down the right side of both frames, most visible in FB. This looks like the camera near-plane clipping a trunk. It reads as a bug.
- FB (Break) is FC darkened with more rain. There is no lightning, flash or rim light, so the peak reads as "the screen got darker", and the trainer nearly vanishes.
- The trunks are identical dark cones with no bark light. The only value in either frame is the grass.

**H0:**
- The trainer is inside Voltarach's leg cage.
- The named team list is too large and too small-texted at once.
- A pink smear bleeds through the translucent "Bramblebun" row.
- The "Engage Voltarach" prompt sits on the same row as a five-item prompt strip, so the call to action competes with Map, Satchel, Build, Put Away and Change.

**Hi / H2b / H2e:**
- The trainer is at the frame edge under the ghosted companion panel (see device items 3 and 4).
- **H2b:** the hit burst is a flat, semi-opaque beige disc with a star cutout, plus beige bokeh blobs. It is an electric hit rendered as a sticker: it hides the target's face and has no spark, arc or blue-white energy.
- The fight ground is flat with an evenly scattered sprig pattern. No sky is visible because the camera is high and pitched down, so the purple-storm identity is gone from every fight frame. Hi could be any biome.
- Voltarach has almost no contact shadow; it sits on the grass rather than in it.

**Ci / C1b / C2f:**
- The herd bears share the arena backdrop with the named opponent (see Creatures).
- The C1b burst is the same beige stamp as H2b.
- The arena boundary (thin teal translucent wall) is fine.
- The ground is the same flat, evenly speckled plane as the Voltarach fight. The two named fights look like the same place.

**S0 to S12:**
- The strike is the clearest sequence on the sheet.
- Impact (S12) has no flash: sky, trees and ground receive no light from the bolt, and there is no scorch or bloom. Only the trainer's hair tints pink.
- The bolt is a thin one-pixel-feel line. The event lands visually as a line drawing over an unchanged scene.
- The NPC at the left edge is unlit and reads as a cutout.

**Global:**
- The clock says "Day 1 · 08:00" over a scene that reads as night in every frame.
- Value range is one dark mid-tone: sky mid-purple, ground dark green-brown, no highlights except the HUD and the tells.
- No warm light source appears anywhere on the sheet.

### Three biggest gaps from the references (ranked)

1. **The fights do not look like events, and the opponents do not hold up.**
   - Palworld 01 and 03 fill the frame with a bespoke, characterful boss in daylight, with orange-gold sparks, contact dust and a camera close enough to feel weight.
   - Here the camera is high and far, the ground is flat, the hit VFX is a beige stamp (H2b, C1b), and Voltarach reads as a toy (Hi).
   - The named Staticub is the herd's bear at herd size (Ci, C2f).
2. **Light and value structure.**
   - The key art and both Stormheart boards run from sunlit highlights to deep shade, with warm lantern and wood light against cool blue-white lightning.
   - These frames are one dim purple-green band (FC, FB, GB, Hi) with no warm accent, no rim light and no light from the lightning itself (RB, GB, S12). Break reads as darker, not as a peak.
3. **No landmark and no lived-in world.**
   - The Stormheart boards are built around one colossal split tree with platforms, bridges, banners and lanterns, visible across the region. Palworld 02 and 04 show cliffs, caves, towers and a far horizon.
   - No frame shows a landmark, a structure other than the rods, or a horizon with layered depth.
   - The fight arenas are empty, evenly scattered planes (Hi, Ci). The glass field is five cones (GC).

### Bar A (belongs to the key art / Stormheart boards)? **No.**

What carried it partly:
- The trainer matches the board's trainer.
- The trees share the stylised broadleaf language.
- The glowing rod line (RC, RB) and the ground-strike ring are a coherent "electric forest" idea.

What sank it:
- The boards are daylight, vivid, warm-lit living wood with blue-white energy. These frames are a dim, permanently purple storm with no Stormheart landmark, no warm light, no banners, platforms or lanterns, and near-black forest interiors (FB).
- Even granting the purple-storm choice, the frames lack the board's materials and light, so they do not read as that place at night. They read as an unlit version of a generic forest.

### Bar B (same kind of game as Palworld)? **Yes.**

What carried it:
- The composition is Palworld's genre grammar: a third-person trainer with a backpack, a creature companion fighting beside them, a large named opponent with a name and health card, and a team list (Hi, Ci are directly comparable to Palworld 01 and 03).
- Sparkit is at the Palworld bar in appeal.

What holds it back from looking like the same *quality*:
- Voltarach's toy read.
- The realistic bear against the stylised cast.
- Dim, flat lighting.
- Sticker hit VFX.
- Empty arenas.

### Gap split

Scene-fixable (density, palette, lighting, composition, VFX, UI, camera):
- HUD text scale and contrast; team-list names and icons in fights; removing the ghost fade.
- Fight camera framing and a safe box for the trainer.
- Forest near-plane clip.
- Key and rim lighting with warm accents; lightning flash lighting the scene at Break and on strike impact; scorch decal.
- Hit-burst VFX recolour and reshape (blue-white arcs, not a beige disc).
- Clearing the herd from the named arena, and a visual distinction for the named guardian (scale, aura, lighting) using the existing mesh.
- Recolouring the red frog, the rod cable and the minimap route away from reserved red.
- Scatter clustering on the fight ground; showing sky in fight framing.
- Hiding the empty quick-slot bar; the clock/sky mismatch.

Needs new art:
- A Voltarach remodel (jointed legs, feet, a readable electric identity, less toy-plastic material).
- A Staticub restyle to match the Sparkit and trainer style, or a distinct guardian variant.
- Glass-field crystal meshes to replace the cones.
- The Stormheart landmark tree and its platforms, banners and lanterns.
- A proper red frog texture.

---

## TOP FIXES

1. **HUD scale for the 7-inch panel.**
   - Raise the minimum HUD text to at least 7 px on the sheet (about 1.5x now) for health and food numerals, enemy level and type, team names and levels, button glyphs and status.
   - Give the fight team list names or creature icons instead of bare colour swatches.
   - Stop ghosting the companion panel when something is behind it; move the subject instead (fix 2).
   - Hide the empty quick-slot bar in explore. Frames: RC to FB, H0, Hi, H2b, Ci.
2. **Fight camera framing and subject safety.**
   - Keep the trainer, the piloted creature and the target inside a central safe box clear of the left panels and the right move grid. In Hi, H2b and H2e the trainer is at the edge under the panel.
   - Pull the camera lower so the storm sky shows in fights.
   - Keep the trainer out of the opponent's leg span on engage (H0).
   - Fix the forest near-plane black wedges (FC, FB).
3. **Make fights and the Break peak read as events, using existing art.**
   - Replace the beige hit-burst disc with blue-white electric arcs and sparks that do not cover the target's face (H2b, C1b).
   - Have lightning actually light the scene at Break and at strike impact: a sky and ground flash plus a scorch (RB, GB, FB, S12).
   - Separate the named Staticub from its herd: clear the backdrop bears and give the guardian a scale or aura distinction (Ci, C1b, C2f).
   - Take the red frog, the rod cable and the minimap route out of the reserved red.
