# Code-blind visual judge: storm-phase legibility (8 stills)

All eight stills use the same framing: the trainer on a path with glowing gold cracks, a companion at left, a teal-lit pylon at right, and a purple sky. The glowing path cracks look the same in all eight, so they give no phase information. Only the sky, the rain and the lightning change.

## 1. Pairs and phase names

| Pair | Phase | Confidence | Deciding cue |
|---|---|---|---|
| pic_1 + pic_3 | **Calm** | medium-high | Fewest raindrops in the set: sparse streaks falling almost straight down. The overcast is flat and even, grey-violet, with no cloud structure. Nothing is moving hard. |
| pic_2 + pic_6 | **Building** | high | Rain is much denser than Calm and falls on a clear slant, so it reads as wind-driven. The sky is darker and heavier indigo, with a lower, bruised cloud mass. There is no lightning yet. |
| pic_4 + pic_8 | **Break** | high | A large forked, glowing white-violet lightning bolt fills the upper centre and right of the sky, with smaller forks at the far left edge. Rain is the heaviest in the set. Tree silhouettes have a cold rim light. |
| pic_5 + pic_7 | **Fading** | medium | The sky is clearly brighter and more saturated lilac. Distinct broken cloud shapes appear with pale, lit edges, so the cloud deck is opening. Rain is moderate: less than Building and Break, more than Calm. |

Pairing confidence is high overall. Within each pair the two stills are close to identical in sky treatment and rain density.

## 2. Break-only cue from a single still

- **pic_4: YES.** The forked lightning bolt is on screen. No other phase shows any lightning, so one still is enough to name Break.
- **pic_8: YES.** Same cue: the forked bolt in the upper centre and right, plus small forks at the left edge.

Caveats:
- **The bolt does not strike the ground in either still.** It forks across the sky and ends mid-air around the height of the pylon and treetops. There is no ground impact, flash, spark or scorch on the ground. The brief says "lightning strikes the ground", and these stills do not show that. What they show is sky lightning.
- **The bolt is identical in pic_4 and pic_8:** same shape, same screen position, same small forks at the left. If a player always sees this one fixed bolt, it may start to read as a painted sky decal rather than a live strike.
- The small left-edge forks sit over the dead tree's branches. At this resolution I cannot tell whether the bolt draws in front of the foliage (a depth error) or behind it. This is minor and low confidence.

## 3. Could Calm and Fading be swapped by name?

**YES, the risk is moderate.** Within the set the pairs separate cleanly. Fading has a brighter lilac sky with visible, breaking cloud shapes and more rain. Calm has a flat, dull grey-violet overcast and very light, vertical rain.

The trouble is that names map intuitively onto looks, and here they cross over:
- Fading (pic_5 and pic_7) is the brightest and most pleasant-looking sky in the set. A player seeing one of these alone could reasonably call it "the storm at rest", which is Calm.
- Calm (pic_1 and pic_3) is dimmer and drearier than Fading. With its sparse drizzle it could equally be read as "thinning after the storm", which is Fading.

The cue that best separates them is cloud structure: a flat deck for Calm, broken clouds with lit edges for Fading. Rain density is the weaker cue. That split is learnable, but from a single still I expect players to confuse these two often.

## 4. Strobe, white-out or UI-like element in the Break stills?

**NO strobe and NO white-out.** Exposure stays normal in both Break stills. The scene is not washed or blown out, and the characters, grass and path read clearly. Nothing looks like a HUD element.

One qualification: the bolt is a crisp, even-width, glowing line with a soft halo. It is also placed identically at both hours. That makes it read slightly as a 2D graphic laid over the sky rather than a volumetric strike. It still reads as weather, not UI.

## 5. Overall verdict

**PARTIAL**

- Break can be named from any single still, because lightning appears only in Break.
- Building can be named reliably from a single still, because of its dense, slanted rain and dark indigo sky.
- Calm and Fading pair correctly when compared, but can be swapped when seen alone. Fading's clearing sky is brighter and friendlier than Calm's, which pushes players toward the wrong name.
- Break does not show the "lightning strikes the ground" cue the brief describes. The bolt ends in the sky.

To reach PASS:
1. Make Calm visibly the most settled phase: lightest, gentlest rain with a clear sky that is not dreary. Alternatively, give Fading a clear "departing" cue, such as drifting cloud breaks with light shafts, a rain curtain pulling away, or distant receding flicker.
2. Bring at least one bolt down to the ground or treeline, with an impact flash on the ground.
3. Vary the bolt's shape and position between strikes.
