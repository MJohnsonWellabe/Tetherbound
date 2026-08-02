---
name: visual-judge
description: Judge Tetherbound's visuals against its actual target (Palworld, Pokemon on Switch) using a contact sheet of real in-game frames. Load when asked to review how the game looks, run a visual pass, check art quality, or verify that a rendering change improved anything. Produces specific, addressable criticism, never a score.
---

# Judging Tetherbound's visuals

Adapted from the adversarial-judge pattern in `achimala/TheLongSilence`, which
held a space game against Starfield screenshots until it matched. The structure
transfers; the target does not.

## The target is Palworld and Pokemon on Switch, not photorealism

This is the whole point and it is easy to get wrong. Tetherbound is:

- **Mobile first.** 60fps on an iPhone 12. Under 150 draw calls, under 300k
  triangles, no post-processing (`ARCHITECTURE.md`).
- **Stylised, not photoreal.** `ASSETS.md`: low-poly, flat-shaded, saturated,
  chunky silhouettes that read at phone size.

A judge that asks for photorealism will push the renderer through the perf
budget toward an aesthetic the design documents explicitly reject. Chasing
Starfield here would make the game worse and slower at the same time.

The right references are **Palworld** and **Pokemon Scarlet/Violet** and
**Legends: Arceus**: readable stylised worlds, appealing creature silhouettes,
warm daylight, cheap-but-intentional lighting, clear UI hierarchy. Those games
are not technically impressive. They are *legible and appealing*, which is a
higher bar than it sounds and the one that matters at 390 pixels wide.

## Running it

The judge looks at real frames from the real build, never a description.

```
npm run build
npm run preview &                       # serves on :4173
node tools/survey.mjs                   # 9 framed shots, fixed spots and hours
node tools/sheet.mjs                    # one labelled contact sheet
node tools/holes.mjs                    # geometry gaps, pass/fail
```

Read `shots/_sheet.png`. The whole survey in one look is the point: you cannot
see that the dusk frame and the night frame disagree about fog when they are
never on screen together.

**Frame times in the sheet are software-rendered and are not a phone
measurement.** Use them for relative comparison between runs, never as a verdict
on performance.

## Delegate the judging

Spawn a subagent to do the criticism, and give it the images and the rubric
below without telling it what you changed or what you hope it says. A judge that
knows the answer you want is not a judge.

Do not soften the rubric to get a pass. If the rubric is wrong, argue that
explicitly with the human; do not quietly rewrite it.

## The rubric

Score nothing. Produce a list of specific, addressable defects, each naming the
frame it appears in. "The grove reads as noise because every tree is the same
height and tint" is useful. "Lighting could be better" is not.

**1. Silhouette and readability at phone size.** View the sheet at 30% and ask
what is still identifiable. Can you tell a tree from a rock from a bush? Is the
player readable against the ground? This is the single most important criterion
and it is the one desktop-sized review always misses.

**2. Colour and value structure.** Is there a value range, or is everything the
same mid-tone green? Do the biomes read as different places? Is the Tether
orange still reserved for danger, or has it leaked into friendly elements?

**3. Intentionality.** Does the world look authored or does it look like noise
output? Repetition at a regular interval, uniform prop scale, and evenly
scattered density all read as procedural. Clustering, variety in scale, and
clearings read as designed.

**4. Lighting.** Does the time of day read? Does the terrain have form, or is it
flat-lit? Are shadows placing objects on the ground or floating them?

**5. Horizon and depth.** Does distance read? Is fog helping depth or eating the
world? Is there a visible LOD or chunk seam?

**6. Interface.** Does the HUD sit in the safe area? Is hierarchy clear at a
glance? Do the accent colours still mean what `tokens.css` says they mean: lime
for act, magenta for party, cyan for orbs, orange for danger only?

**7. Artefacts.** Z-fighting, seams, popping, stretched textures, geometry
poking through geometry, anything flickering between frames.

## After judging

Every accepted criticism becomes work. Re-run the survey after fixing and
compare sheets. If the judge's point was addressed, the frame should show it; if
it does not, the fix did not land, and saying it did is worse than not fixing it.

## Honest limits of this setup

- **Software rendering.** No GPU here. Shading is correct, timings are not.
- **Static frames.** Popping, aliasing in motion and traversal feel are invisible
  in a still. A human on a phone remains the real test.
- **Placeholder art.** Until M5 the props are primitives by design
  (`ASSETS.md`). Judging silhouettes and lighting is still useful now; judging
  model quality is not, and a judge told to review asset fidelity before M5 will
  produce a long list of things already scheduled.
