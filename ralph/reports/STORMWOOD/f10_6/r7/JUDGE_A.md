# Visual judge, round r7 (explore frames only)

Frames judged: the 7-inch sheet, plus full-size forest_break, rod_line_break and glass_calm. I did not open the other three full-size frames (forest_calm, glass_break, rod_line_calm). I judged those three from the sheet only, and they are mid-sheet cells in the same scenes.

Limits:
- No fight/ or strike/ frames exist this round.
- Bar A files are missing. `docs/reference/tetherbound-meadows-keyart.png` and the stormwood board-a and board-b PNGs are not in `docs/reference/`. Only README.md is in the boards folder, and I did not read it.
- Bar B was judged against palworld-01 and palworld-02 only.

## Device-profile read

1. **HUD text legibility at 7 inch: PARTLY JUDGEABLE.**
   - Legible (sheet, all cells): the objective card ("MAIN STORY / Find Ashfoot Waycamp." is white on dark navy with a gold border), the weather tag, and "100 / 100".
   - Marginal (sheet, all cells): the "Day 1 · 08:00" clock is thin grey and disappears against sky and canopy. It is close to invisible in GC and RC. "FOOD 100%" is tan on a tan bar and reads poorly (FC and all others). The Map/Satchel/Build labels and the quick-bind glyphs are tiny and dim.
   - NOT JUDGEABLE: enemy name and level, tell text, team list and move buttons. None of them appear in explore frames.
   - Verdict: **No.** The explore-HUD text is only partly legible, and the fight-HUD half cannot be judged.
2. **Tells and danger legibility: NOT JUDGEABLE.** There is no fight or strike frame, so there is no attack warning shape and no lightning ring to judge.
   - Only the lightning bolt in the sky (RB, top centre) is visible. It is a sky bolt, not the ground warning.
   - The yellow ground streaks in RB and RC are decorative or path lines. I cannot say whether they are the warning.
3. **Subject legibility: PARTLY JUDGEABLE.**
   - The trainer is found instantly in RB, RC, GC and GB. He is centred and lit, with a blue jacket and orange pack, and no HUD covers him.
   - The trainer in FB (top-left cell) is the exception. He is a dark figure on dark grass and takes about a second to find. The HUD does not cover him. The darkness does.
   - The piloted creature and the opponent: NOT JUDGEABLE. Only a dim brown bear-like shape at the left edge of FB and FC is visible. It is partly clipped by black wedge borders and I cannot say what it is.
   - Verdict: **Yes for the trainer in four of six frames. Not judgeable for creatures.**
4. **Safe area: PARTLY JUDGEABLE.**
   - Explore frames: yes. The HUD hugs the corners and edges, and the centre is clear.
   - The bottom-right quick-bind bar and the Map/Satchel/Build bar sit over the ground and grass in the lower right. They are large blocks, about 26% of frame width, but they do not touch the trainer.
   - The objective card overlaps the tree line and the RB/RC rod-line tower and cable. The card cuts the tower's cable at the right edge, so the landmark and its wire are partly hidden. This is a minor safe-area miss.
   - Fight key action: NOT JUDGEABLE.
   - Verdict: **Yes for explore, not judgeable for fights.**

## Defects by frame

- **forest_break (FB)**
  - It is nearly black. Trunks, canopy and grass sit in one dark value with no separation. At 7 inch the scene reads as a void with rain streaks.
  - Two hard black wedges cut the frame at the left and right (frame edges, lower left up to about x=170 and right of x=1500). They read as rendering bugs. They look like shadow or fog-volume clipping, not a choice.
  - Trunks are huge and smooth with no bark detail. The floor is dark grass with a few small mushrooms.
  - The trainer's figure is low-contrast.
  - Palette: no purple storm reads here. It is green-black, so it does not belong to the same place as the other frames.
- **forest_calm (FC)**
  - It is the same forest with more light. Trunk and canopy separate a little, but the scene is still very dark.
  - The bear-like shape at the left edge is clipped.
- **glass_calm (GC, full size checked)**
  - It reads best as a place: purple sky, sloped meadow, varied trees and a bare dead tree, blue crystal spikes and lanterns.
  - The blue crystal cluster is the focal landmark. It is small at 7 inch, and the flat blue cones look CG-simple next to the tree canopies.
  - The grass is a uniform scatter of similar tufts, which reads procedural. The flowers are evenly scattered too.
  - The horizon fog is smooth and flat. Distant terrain is a grey slab.
- **glass_break (GB)**
  - It is almost identical to GC. The two are hard to tell apart except for the tag. Break does not read as a lightning peak here, because the sky is nearly the same and no bolt is visible.
- **rod_line_break (RB, full size checked)**
  - It is the strongest frame. Purple storm sky, a real bolt, the dirt path with glowing yellow cracks, the rod tower with a cable, and layered trees give depth and a clear focal line.
  - The yellow path cracks are the loudest thing in the frame, and they pull the eye off the tower and trainer.
  - The bright yellow ground streak vs the dark path is a lovely value contrast, but it is far more saturated than everything else.
  - The path texture is a generic brown noise. The rain streaks are bright and long, and some cross the trainer.
  - The distance is hazy purple, so depth reads well.
  - The HUD card sits over the tower's cable.
- **rod_line_calm (RC)**
  - It is the same scene with a duller sky. Trees are dark green blobs with no purple rim light.
  - The calm sky lacks the storm's drama, so the biome loses its "permanently purple" identity. The frame reads as an overcast meadow.
- **All frames, HUD**
  - The clock is too faint.
  - The FOOD label and bar are tan on tan.
  - The health bar's "100 / 100" is white on mid-green and readable, but its fill is thin.
  - The minimap tile is bright orange (FB/FC) or bright green (GC onward). It is the brightest thing in every frame and pulls the eye to the corner.
  - The orange map tile in FB/FC comes close to the reserved oxblood/red family. It is amber, not oxblood, so I do not call it a leak.

## Scale

- The trainer (1.80 m) against the trees in RB is plausible: trees are 6 to 10 times his height, which is fine for a forest.
- The FB trunks are far too wide and smooth, more like walls than trees. Against the trainer they read as 4 to 5 m across. This is a scale defect.
- The crystal spikes in GC are about 2 to 3 times the trainer at distance. That is plausible.
- The creature scale check is NOT JUDGEABLE. No creature is legible.

## Three biggest gaps from the references (ranked)

1. **Creatures and characters are absent, and the trainer is the only cast member.** Palworld-01 has a huge, bespoke, expressive creature filling the frame, plus the trainer and a pal. Palworld-02 shows enemies in mid-ground, with health bars and names. These frames show no creature at all, so nothing here says "creature expedition". The trainer also looks like a small sourced humanoid next to Palworld's stylised protagonists, and his model is a little flat and stiff (RB, GC).
2. **Value range and readability in the forest frames (FB, FC).** Palworld's forest fight is bright and saturated, and every element separates. FB is nearly black with only rain highlights, so the biome's main location fails the handheld test. RB and GC show that the palette can work.
3. **Ground and world density and authorship.** Palworld-02 has varied terrain, rock formations, a cave, a dirt path and clustered foliage. Here the grass is an even scatter, the path is a plain noise texture, and the horizon is a fogged flat plane (GC, GB, RC). The world does not feel lived-in outside the rod-line tower.

### Split

- **Scene-fixable:**
  - Raise forest lighting, ambient and fog value so trunks separate from canopy and grass (FB, FC).
  - Remove or explain the black wedges.
  - Cluster the grass and flowers instead of an even scatter.
  - Vary path texture and edge treatment.
  - Make Break visibly different from Calm in GB and RC (sky, rim light, bolts).
  - Add rock and terrain variety at the horizon.
  - Reduce the saturation of the yellow path cracks.
  - HUD contrast fixes (clock, FOOD bar).
- **Needs new art:**
  - Bespoke creature models and readable opponents.
  - A more expressive trainer.
  - Tree bark and trunk detail for the giant trunks.
  - Distinct landmark meshes such as the crystals.

## Bar questions

- **Bar A: NOT JUDGEABLE against the named files** (the keyart PNG and boards A/B are not present at the paths given). My provisional read, from the palette and mood language only, is **no for FB/FC** (too dark and too green) and **yes-leaning for RB and GC** (purple storm, layered trees, landmark).
- **Bar B: No.**
  - What sank it: no creature, no fight, and no cast beyond the trainer; the forest frames are near black; the ground is generic.
  - What carried what it could: RB and GC have decent tree canopies, rain, a bolt and a clear path and landmark. In palette and composition they are trying to be the same sort of third-person exploration game.
  - Someone shown these beside palworld-01 and 02 would see a similar camera and HUD layout, but not the same energy.

## TOP FIXES

1. Fix the forest value structure: lift ambient light and fog so trunks, canopy and floor read as three values; remove the black wedge borders; give the trainer a rim light. (FB, FC)
2. HUD contrast and clutter at 7 inch: make the clock and the FOOD label high-contrast and larger; make the minimap tile darker and less saturated; keep the objective card off the tower and cable.
3. Make Break visibly different from Calm, tame the path cracks, and break up the scatter: stronger purple key and rim light with bolts in Break (GB, RC); turn the yellow path glow down to a guide, not a headline; clump grass and flowers around rocks and trunks (GC, RC).
