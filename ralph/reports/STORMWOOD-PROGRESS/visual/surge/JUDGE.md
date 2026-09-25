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

# Round 2: blind re-judge of the round-2 frames, day and night

A fresh blind judge saw 11 shuffled frames: 4 day phases, 4 night phases, Break telegraph, Break flash and aftermath Calm, together with the same references. Nothing else was said.

## Grouping against the answer key

**Weather state: 10 of 11 correct.**
- The judge paired each day state with its night version: Calm and night Calm; Fading and night Fading; Building and night Building.
- It inferred the order Calm → Building → Break peak → Fading, with the end state last.
- **Miss:** night Break (08) was grouped with night Building as "the same picture at two brightness levels".

**Time of day: weak.**
- Day Break (06, 09) was read as "night or storm darkness". The sky went dark while the grass stayed day-bright.
- Night Break was judged "too dark": the top 60% of the frame is black and the trees are gone.

## New defects

1. **Night Break** is too dark and loses the trees. It is indistinguishable from night Building except in exposure. It needs a floor and a distinct hue.
2. **Ground vs sky mismatch.** Day Break's sky reads as night over bright grass. Ground, grass and exposure should follow the storm.
3. **Telegraph ring (06).** It is now the brightest element and reads first at 30% size, but it signals friendly: "selection circle, camp radius, heal zone". Both judges asked for a warning hue: amber or orange, never oxblood. Other suggestions were a darker interior, chevrons and drawing above the grass.
4. **Rain still reads as a screen overlay.** There is no wind slant, no depth fade and no splashes. In night Building the rain is the brightest element.
5. **Sky artefacts:**
   - bright-blue cloud flecks on the black night sky in night Fading (03);
   - a pale horizon shelf on the left (03, 10);
   - a faint ghost disc near the left horizon in the Break frames (05, 06).
6. **Unchanged, region-wide:** no directional sun or cast shadows in any state; an empty plain with a horizon cutting through the trainer; small creatures.

**Verdict:**
- **A:** key-art world, **no**.
- **B:** same kind of game as the Palworld bar, **yes**.

# Round 3: blind re-judge of the round-3 frames

A fresh blind judge saw 10 shuffled frames: 4 day phases, 4 night phases, the Break telegraph and the Break flash.

## Scored against the answer key

**Day weather.** All four phases were placed in their own groups: Calm, Building, Break (flash frame) and Fading.

**Day Break read as night.** Frames 02 and 03 (the Break telegraph and a Break frame) were read as night. That was also true in round 2. The violet-indigo daytime sky is still too dark.

**Night pairing:**
- Building was correct (08 paired with 07).
- Calm and Fading were swapped, and at 30% size they merge.
- Night Break (09) was not paired with Break.
- Night separation is weak: "only three [states] can be told apart" at night.

**Telegraph (amber #ffb040).** It is very readable, but it reads as "quest objective, pickup zone or summoning circle". The judge's reason: "gold is reward or objective colour in this genre". The black interior reads as a hole.

**Lane decision on the telegraph colour.** Round 2 asked for amber, and round 3 reads amber as reward. `data/config/combat.json`'s `telegraph._why_colour_0905` records the same finding from an earlier lane: warning amber sat 3° from the reward gold and read as "a dropped coin". The game's hazard colour is therefore the combat telegraph's own magenta #ff40e6 (hue 308): the complement of the meadow green, used nowhere else in the world or the reward layer, and clear of oxblood.

The Stormwood lightning telegraph will read that single config value instead of choosing its own. The whole game then shares one "move off" colour, and the judge-to-judge colour swings stop.

## Unchanged, region-wide
Carried from the earlier rounds and outside this branch:
- no directional light or shadows;
- an empty plain with a hard horizon;
- no creatures at genre scale;
- oversized flowers;
- rain drawn with unlit sprites and no wetness.

## Verdict
- **A: yes (narrowly).** The key-art trainer, the tree language and the violet storm fit the board's swatches.
- **B: no.** No creature or action appears in 10 frames, and the grass cards are coarse and unshadowed.

# Round 4: blind re-judge of the round-4 frames

A fresh blind judge saw 9 shuffled frames: 4 day phases, 4 night phases and the Break telegraph, with the same references.

## Scored against the answer key: 9/9

| Judge's state | Day | Night | Actual |
|---|---|---|---|
| S1 grey overcast, light drizzle | 09 | 02 | Calm / night Calm |
| S2 dust / brown haze | 01 | 04 | Fading / night Fading |
| S3 olive pre-storm | 08 | 03 | Building / night Building |
| S4 purple thunderstorm | 06, 07 | 05 | Break (+ telegraph) / night Break |

- **Time of day:** 9 of 9 correct. Day Break now reads as day; it had been misread as night in rounds 2 and 3.
- **Weather state:** 9 of 9 frames grouped and day/night paired correctly.
- **Order:** the judge inferred Break as the peak with medium confidence. It placed Fading (S2) before Building and noted it "could also be a post-storm aftermath". That is correct: nothing in a still shows direction.
- **At 30% size, night Calm, Building and Fading merge** into "dark with a green floor". Only night Break separates.

## Telegraph (combat hazard magenta #ff40e6)
The ring is readable as a shape at 30% size. It communicates "a zone boundary", but not unambiguously "move out", and the magenta sits close to the lilac flowers and the violet storm.

The colour is the game-wide combat telegraph decision in `combat.json` (`_why_colour_0905`), so the lane keeps it. A still also cannot show the ring's charge pulse (2 → 7 Hz over 1.2 s).

For the owner: if magenta-on-violet is judged too close in play, the change belongs to the shared combat telegraph colour, not to a Stormwood-only colour.

## Unchanged and region-wide
Outside this branch; carried from earlier rounds:
- The world is an empty flat disc with a horizon band.
- No shadows, and the grass stays self-lit under dark skies.
- The rain has no wetness, splashes, curtains or wind response.
- No companion creature is readable at genre scale.
- The red-brown soil sits near the oxblood swatches; desaturating it toward umber is suggested.

## Verdict
- **A: no.** No layered landscape, no warm sun, no depth haze, no blue night.
- **B: yes.** Same kind of game, a tier below on quality.

**Lane conclusion for ACCEPTANCE F10 "Calm/Building/Break/Fading readable without HUD text":**
- Met by blind grouping at full size, day and night: 9/9 in round 4. Rounds 1–3 scored 12/13, 10/11 and a partial.
- Night separation at 30% size remains a known weakness.

# Round 5: rain frames (WO-F10-07)
Run by the coordinator on the rain-camera frames.
- **Finding:** the foreground was dry in `rc_night_break` and `rc_day_break`, and the near streaks read as sticks.
- **Verdict:** NO.
- **Fix:** the ground-anchored near band. Drops now spawn 0.2–6.5 m above the ground around the camera, as tapered, fading spindles. Measured drops in the bottom 45% of the frame went from 122 to 387 (`sheet_rain_foreground_measure.jpg`).

# Round 7: pale purple set (WO-F10-08, round 1)
Run by the coordinator on the first always-purple set.
- 3 of 5 phases identified correctly; Calm and Fading were swapped.
- Break showed no evidence of lightning.
- The foreground ignored the storm: the ground did not darken with the phase.

# Round 8: deep purple set plus motion strips (WO-F10-08, round 2)
Run by the coordinator on the 10 deep-purple stills and 5 motion strips, shuffled and with labels cropped.
- **Identified:** Break (high confidence), Building (high) and the aftermath (medium-high). Calm and Fading were swapped again ("close to a coin flip").
- **Clock:** time of day was invisible, so the pin works.
- **Break:** no real lightning in stills or strips. A thin white sliver on the horizon (`break_h12`, strip frames 1–2) read as a low sun breaking through, a sunset cue.
- **Aftermath:** a flat, blank lavender card that reads as overcast dusk.
- **Building:** brighter and greyer than Calm, so the tension reads as falling.
- **Break rain:** still "sparse thin streaks".
- **Coordinator direction:** a second failed attempt to separate Calm and Fading by tuning values. Change approach and give each phase a structural signature (WO-F10-08, round 3).
