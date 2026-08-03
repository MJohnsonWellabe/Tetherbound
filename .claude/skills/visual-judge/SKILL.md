---
name: visual-judge
description: Judge Tetherbound's visuals from a contact sheet of real in-game frames, against the project's own art direction board. Load when asked to review how the game looks, run a visual pass, or verify that a rendering change actually improved anything. Produces specific, addressable criticism, never a score.
---

# Judging Tetherbound's visuals

A blind sub-agent looks at rendered frames and says what is wrong with them.
It never sees the source, the conversation, or what just changed. That
separation is the whole mechanism: a critic who knows the answer you want is
not a critic.

## Running it

```bash
apt-get install -y xvfb mesa-vulkan-drivers    # once, on a fresh machine
tools/survey.sh                                # 5 framed shots -> shots/
godot --headless --path . --script tools/contact_sheet.gd   # -> shots/_sheet.png
```

Read `shots/_sheet.png`. Seeing the whole survey at once is the point: two
frames disagreeing about fog, or a palette that drifts between locations, are
invisible one image at a time.

Then spawn a sub-agent, hand it the sheet, the individual frames, and
`docs/reference/`. Tell it nothing about what changed or what you hope it says.

## The target

`docs/reference/tetherbound-meadows-keyart.png` is the primary reference — the
project's own art direction board. `docs/reference/README.md` explains what
each image is for and, importantly, how they may not be used.

`GAME_DESIGN.md` §25: stylised realism between Valheim and Palworld. Vibrant,
readable colours on a natural palette. Silhouettes and landmarks visible from
distance. Cozy and inviting with hints of mystery.

Never score against photography. Never score per-pixel fidelity against the key
art: it is painted concept work with per-leaf canopy detail and painterly
global illumination, and no real-time stylised game reaches it. Judge palette,
composition, landmark language, silhouette and mood.

## Two things the critic must NOT be told

**The performance budget.** The previous version of this rubric quoted draw
calls and triangle counts, and the critic policed them from screenshots —
rejecting work on grounds it could not see, against a budget that had already
been superseded. Performance is measured with a profiler on the Ally. A critic
looking at pictures judges pictures. (D06)

**What changed.** No "I just fixed the shadows, does it look better." That
produces agreement, not criticism.

## The rubric

**Score nothing.** Produce specific, addressable defects, each naming the frame
it appears in. "The grove reads as noise because every tree is the same height
and tint" is useful. "Lighting could be better" is not.

1. **Silhouette and readability at small size.** View the sheet as if at 30%.
   What is still identifiable? Can you tell a tree from a rock from a bush? Is
   the player readable against the ground? Most important criterion, and the one
   a full-size review always misses.
2. **Colour and value structure.** Is there a real value range or is everything
   one mid-tone? Do the frames read as one place? Is the Team Tether oxblood
   still reserved for danger, or has it leaked onto friendly elements?
3. **Intentionality.** Authored or generator output? Regular intervals, uniform
   prop scale and evenly scattered density read as procedural. Clustering,
   scale variety and clearings read as designed.
4. **Lighting.** Does the time of day read? Does terrain have form, or is it
   flat-lit? Are shadows placing objects on the ground or floating them?
5. **Horizon and depth.** Does distance read? Is fog helping depth or eating the
   world? Any visible LOD or chunk seam?
6. **Interface.** Safe area, hierarchy, legibility at a glance.
7. **Artefacts.** Z-fighting, seams, popping, stretched textures, geometry
   poking through geometry, anything that reads as a bug rather than a choice.

Finish with **the three things that most separate these frames from the
reference**, ranked, each saying concretely what the reference does that these
do not.

Do not soften the rubric to obtain a pass. If the rubric is wrong, argue that
with the human; do not quietly rewrite it.

## Honest limits of this setup

- **Compatibility renderer, not the Forward+ the game ships.** Terrain3D
  segfaults under software Vulkan, so the survey runs on OpenGL. Different
  pipeline: no SSAO, no volumetric fog, different shadows. Trustworthy for
  composition, terrain shape, colour and framing; not for fine lighting
  judgements. On a real GPU, switch `tools/survey.sh` to `vulkan`. (D06)
- **Software rendering.** Frame times are meaningless. Never quote them.
- **Placeholder art.** `CLAUDE.md` is explicit that biome look, creature appeal
  and combat readability must not be judged on placeholders. Before M7/M11 this
  harness is for catching rendering defects, not for art direction — its first
  run found the ground rendering as a grey checkerboard while every data-level
  test passed.
- **Static frames.** Popping, aliasing in motion and traversal feel are
  invisible in a still. A human on the Ally remains the real test.

## After judging

Every accepted criticism becomes work. Re-run the survey and compare sheets. If
the point was addressed the frame should show it; if it does not, the fix did
not land, and saying it did is worse than not fixing it.
