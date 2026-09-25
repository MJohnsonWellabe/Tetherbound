# Blind judge: Stormwood Surge phases (visual-judge rubric)

The judge saw 13 "after" frames, copied under shuffled neutral names, plus
`docs/reference/tetherbound-meadows-keyart.png` and `palworld-01..03`. It was told
only that the region has a recurring weather cycle and a state after the storm ends. It
did not see source code, this branch, the before frames or the answer key.

## Blind grouping (the F10 "readable without HUD text" test)

The answer key was revealed only after the verdict.

| Judge's group | Frames | Actual |
|---|---|---|
| A. Clear, no rain; "the storm-ended state" (medium confidence) | 03 | aftermath Calm |
| B. Flat overcast with drizzle; "the calm state" | 05, 07, 10 | Calm ×2, forest view Calm |
| C. Broken, lifting cloud with a warm horizon; "clearing" | 09, 11 | Fading ×2 |
| D. Dark charcoal build-up | 01, 04 | Building ×2 |
| E. Near-night navy peak, dense rain | 02, 13, 06, 08 | Break ×2, Break telegraph, rod-line Break |
| Unplaced ("between C and D") | 12 | Break flash frame; the flash lifts the sky |

- **Grouping:** 12 of 13 frames were grouped correctly with no labels.
- **Order:** the judge inferred Calm → Building → Break → Fading. It was highly confident that Building precedes Break, and medium-low that Fading is clearing rather than gathering.
- **Limit:** within a phase, frames 5 s apart are not separable. Nothing was expected there, since the phase is constant.

## Defects raised (condensed)

**In Stormwood scope and fixable:**
1. **Break telegraph ring (frame 06):** it reads as a selection circle, not a hazard. It is an opaque, matte, pale-lavender tube matching the harmless flowers, with no glow, pulse or edge falloff, and it sits on the grass instead of projecting onto it.
2. **Ground in storm states (02, 13, 06):** the ground does not respond. The grass stays saturated sunlit lime under a night-navy sky, so the storm looks composited behind a daytime field. Calm (05, 07) is mid-tone mush.
3. **Rain:** uniform, equal-length white streaks drawn over everything read as film scratches. There are no splashes and no depth fade.
4. **Aftermath clear sky (03):** no visible cast shadows.

**Scene and region, beyond this branch:**
- The capture stand (Cinder Verge marked clearing) is an empty flat plain with a ruler-straight horizon. No woodland massing, relief or landmark layering: "Stormwood shows no woodland".
- Grass tufts are evenly spaced on bare soil, with flowers evenly sprinkled.
- The player is nearly invisible on brown ground at small size.
- Creatures read smaller than the trainer.
- Frame 10 (Lantern Hollow) has a translucent "ghost shape" between the trees.
- Oxblood: none on friendly elements. The judge flagged, for checking, the dusty-rose bears in frame 10 and pinkish flowers in the Building and Fading frames.

## Verdict

- **A. Belongs to the key-art world:** no. Frame 10 is a near miss. It was sunk by flat and empty composition, no light direction or shadows, and bare-soil ground cover.
- **B. Same kind of game as the Palworld bar:** yes, "but clearly a tier below". Creatures are tiny, the lighting is flat and the terrain is empty.

**Judge's split:**
- **Scene-fixable:** grove density, distant massing and relief, flower drifts and grass coverage, key light and shadows, the storm darkening the ground, rain variation, the hazard ring's hue, glow and projection, creature placement, and landmark framing.
- **Needs new art:** turf and ground material, rock meshes, higher-poly foreground flowers, a bark material, Stormwood-specific landmark pieces, a hazard-marker VFX asset, and identifying frame 10's ghost shape.
