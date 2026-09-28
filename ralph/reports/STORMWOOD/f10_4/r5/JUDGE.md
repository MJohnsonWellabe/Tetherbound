# Stormwood F10.4 r5: readability judgement (code-blind)

I judged from the pictures only: the contact sheet (5 views by storm Calm / storm Break / aftermath Calm) and every frame in `r5/` at full size. The trainer (1.80 m) was used as the ruler.

## The five questions

**1. Forest reads as a deep old storm forest, not open parkland? NO.**
`forest_calm`, `forest_break` and `forest_aftermath_calm` show big dark trunks and a closed green canopy, and that part works. The rest reads as a grove seen from a lawn:
- The ground is an even, mown-looking grass carpet with a few scattered flowers. There is no understory: no ferns, roots, fungi, deadfall or shrubs between the trunks.
- The trunks form a ring around the clearing the trainer stands in.
- Through the gaps at eye level a flat, empty purple-grey plain runs to the horizon (left third, and right of centre). That opening says "edge of a wood", not "deep inside one".
- The canopy is saturated generic green, lit evenly. Nothing shows the blue-green moss light from below, copper, glass scarring or black pools.

`giant_*` reads as deeper woodland (the trunks fill the frame and there is no horizon), but it too is only grass and one shrub.

**2. Rod line reads as a line leading somewhere? YES (at full size), weak at sheet size.**
In `rod_line_calm`, `rod_line_break` and `rod_line_aftermath_calm`, three pylons get smaller into the distance along a path, joined by a sagging cable, so it clearly reads as a line. There are two caveats:
- At sheet size only the nearest pylon and its cable survive. The two far pylons shrink to specks against the trunks.
- The line runs to an empty horizon. No destination (Dynamo or Stormheart) is visible at its end in these frames.

The `stormheart_*` frames help: pylons and cable are visible running right from the tower's base. The link is only readable at full size, though.

**3. Aftermath: same place, lighter rain, no lightning, scars and structures kept, clearly distinct from storm? NO overall. Three rows pass cleanly and two do not.**
- `glass_aftermath_calm`, `rod_line_aftermath_calm`, `stormheart_aftermath_calm`: YES. Each is the same composition, rain is almost gone, there is no lightning, and the purple sky stays but turns into a bright, broken cloudscape. Glass spires, pool, dead trees, lanterns, pylons, cable, tower and cottage are all still there. These are clearly distinct from both storm columns, even at sheet size.
- `forest_aftermath_calm` and `giant_aftermath_calm`: WEAK. The only differences are slightly brighter greens and fewer rain streaks. Almost no sky shows in these views, so the restored sky cannot carry the change. At sheet size `forest_calm` and `forest_aftermath_calm` are close to indistinguishable.
- `rod_line_aftermath_calm`: the two bright yellow glowing squiggles on the path, present in both storm columns, are gone. Only a faint ring stain remains. If they are storm or lightning scars, the "scars remain" intent fails here. If they are guidance UI, see defect list. Either way, the most prominent ground mark in the row changes with no visible reason.

**4. Break vs Calm distinguishable in each row? YES, all five rows, but forest and giant only by darkness.**
- `glass_break`, `rod_line_break`, `stormheart_break`: clear. There is visible white-violet lightning, heavier slanted rain and a darker sky.
- `forest_break`, `giant_break`: distinguishable only because the frame is much darker with denser rain. No lightning is visible (there is no sky to show it), so at sheet size these read as "night" as easily as "storm Break".

**5. Trainer findable in every frame at full size? YES, but poorly in the giant row.**
- The trainer is easy to find in the forest, glass, rod_line and stormheart frames. They sit dead centre, and the orange backpack and blue sleeves carry them.
- In `giant_calm`, `giant_break` and `giant_aftermath_calm` a foreground shrub sits between camera and trainer and hides everything below the shoulders. In `giant_break` only a dim head and backpack remain.
- In `forest_break` the dark trousers merge with the dark ground and trunks, and only the backpack reads.

## Readability defects by frame

1. **forest_calm / forest_break / forest_aftermath_calm**: open, flat, empty plain visible through the trunks at eye level. Close the far background with more trunk layers, understory or terrain rise so the forest has no visible outside.
2. **forest_* (all three)**: no understory at all, just a uniform grass carpet with even flower scatter. Add roots, fungi, ferns and wet root clusters between the trunks so "old forest floor" reads.
3. **forest_break / giant_break**: Break is conveyed only by darkness and rain density, with no lightning read under the canopy. Add a readable lightning cue that reaches the forest floor (flash lighting on trunks, a violet rim, or bolts visible through canopy gaps) so Break does not read as night.
4. **forest_aftermath_calm / giant_aftermath_calm**: barely distinct from storm Calm at sheet size. The under-canopy views need their own aftermath signal (light shafts, dripping or wet sheen, visible sky patches), because the sky change cannot be seen from here.
5. **giant_calm / giant_break / giant_aftermath_calm**: a foreground shrub blocks the trainer from the chest down. The camera or the shrub placement needs fixing. There is also a large pale foreground flower directly under the trainer that competes with them. In `giant_aftermath_calm` its stem renders as two diverging white lines.
6. **giant_***: no single trunk reads as *the* giant. The frame is three or four equally dark, big trunks with no one landmark tree whose size you can measure against the trainer. There is no base or root flare in frame to give scale.
7. **glass_calm / glass_break / glass_aftermath_calm**: the "glass" is five flat, untextured cyan cones, evenly spaced. They read as markers or placeholder primitives, not glass-fused scars. The pool is a thin dark sliver that barely registers. They sit on an open grassy hillside with the flat plain on the right, which reads as parkland, not storm forest.
8. **rod_line_calm / rod_line_break**: the bright saturated yellow squiggles on the path read as a UI guide line or a paint stroke, not as a physical feature. Their disappearance in `rod_line_aftermath_calm` is unexplained (see Q3).
9. **rod_line_***: the far two pylons are too small or too low in contrast to read at sheet size, and the line ends in empty horizon with no destination silhouette. A distant Dynamo or tower silhouette at the end of the line would make the destination read.
10. **stormheart_calm / stormheart_break / stormheart_aftermath_calm**: the Stormheart reads as a faceted grey octagonal silo or tower, not a tree. It has straight vertical walls, no root flare, no branching crown, only small leaf tufts at the top, and flat grey-violet shading. The cyan dashed line up the cleft reads as a zipper or UI marker, not an energy core. The cleft and spiral stair do read as "split trunk", which is the right idea.
11. **stormheart_* (all three)**: the cottage at the tower's base has a saturated red roof. That is red on a friendly, safe structure, which conflicts with red being reserved for Team Tether. At distance it is the only warm accent in the frame and pulls the eye.
12. **stormheart_break**: a straight thin white diagonal line runs from the right-hand bolt down to the ground (right of the tower, around mid-height to the horizon). It reads as a render line or artefact, not lightning.
13. **All rows (chapter identity)**: none of the intent's material cues are readable. There is no copper (vines or highlights), no blue-green uplight from moss, no black reflective pools (apart from the sliver in glass) and no Stormglass arches or scaffolds. Take away the purple sky and the forest and giant rows could be any temperate forest. The canopy green is the same saturated green as a meadow biome.
14. **forest_calm / forest_aftermath_calm**: a brown creature is cut off by the left frame edge at the tree line. It is a half-visible silhouette that reads as a cropping accident.

## Bars (one line each; these belong to the later polish phase)

- **Bar A (belongs with the Meadows key art and the Stormwood boards): NO.** The boards' Stormheart is a colossal branching tree with platforms, walkways, banners and warm lanterns, and the in-game Stormheart is a bare grey prism. The forest lacks the key art's layered undergrowth and material richness.
- **Bar B (same kind of game as the Palworld shots): YES, weakly.** The stylised trainer, grass density and bright creature-adventure framing read as the same genre. The flat primitives (glass cones, prism tree) and empty horizons sit well below Palworld's density and finish.
