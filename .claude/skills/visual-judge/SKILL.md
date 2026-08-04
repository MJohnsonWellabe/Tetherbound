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

Two references, used for different things.

**`docs/reference/tetherbound-meadows-keyart.png`** — the project's own art
direction board, and the primary reference for palette and mood.

**`docs/reference/palworld-0*.jpg`** — five screenshots of Palworld, and the
explicit **bar the owner set for this project**. These are the comparison that
decides whether the work passes.

`GAME_DESIGN.md` §25: stylised realism between Valheim and Palworld. Vibrant,
readable colours on a natural palette. Silhouettes and landmarks visible from
distance. Cozy and inviting with hints of mystery.

### How each may be compared

The Palworld shots are a **real-time game at shipping quality**, so comparing
against them is fair in a way comparing against concept art is not. Judge
against them on: ground and foliage density, how much of the frame is empty,
colour saturation and value range, silhouette clarity of creatures against
terrain, how lived-in the world reads, and whether a fight looks like an event.

**Creatures and characters are in scope, and are the point.** The bar this
project set is Palworld, whose creature and character art is bespoke and
expressive. If the creatures or the trainer in these frames do not hold up
against that — if they look sourced, generic, mismatched in style with each
other or with the world, wrong in proportion, or simply not good enough to be
the thing a game is named after — **say so first and say it plainly.** An
asset being a stand-in is a reason it might be inadequate, never a reason to
excuse it.

Do **not** compare against them on: UI design, or anything requiring a budget
or a frame rate the images cannot show.

Never score per-pixel fidelity against the **key art**: it is painted concept
work with per-leaf canopy detail and painterly global illumination, and no
real-time stylised game reaches it. Judge palette, composition, landmark
language, silhouette and mood.

Never score against photography.

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
8. **Scale agreement.** Do the objects in frame agree about how big a metre is?
   **There is a ruler in the picture: the trainer is 1.80m.** Measure against
   them. Is each creature the size its role implies — is the one you fight
   alongside bigger than the one you practise on? Are trees, rocks and props
   plausible beside a person? Two things that should differ in size by three
   times and differ by a tenth is a defect you can see in a still.

   This criterion was added after a round where the owner spotted, instantly,
   that the largest creature in the game rendered smaller than a frog — and this
   rubric had no question that would have found it. Every other criterion asks
   how something *looks*; none asked how big it is. Wrong relative scale is one
   of the loudest errors a 3D game can make and a still frame shows it perfectly.

   Judge relative scale, which is checkable. Do not judge whether a species
   *should* be large — that is a design decision and not yours.

## The verdict

This is acceptance criteria, not commentary. Finish with both of these.

**1. The three things that most separate these frames from the references**,
ranked, each saying concretely what a reference does that these do not, and
naming the frame.

**2. The two bar questions, answered directly.** The owner's gate names both
references, so both need an answer.

> **A.** Do these frames read as belonging to the world in
> `docs/reference/tetherbound-meadows-keyart.png` — the project's own art
> direction?
>
> **B.** Shown these frames beside `docs/reference/palworld-0*.jpg`, would
> someone say these are trying to be the same kind of game?

Answer each **yes** or **no** separately — they can differ, and it is useful
when they do. Then say what carried it or what sank it. If the
answer is no, say which of the gaps are fixable by changing the scene — density,
palette, lighting, composition, scatter — and which are not, because they need
art that is not in the build. That split is the deliverable: the fixable half
becomes work, and the rest becomes evidence for what has to be bought or made.

Do not soften the rubric to obtain a pass, and do not soften it to be kind. A
"no" with three specific reasons is worth more than a "yes" with none. If the
rubric is wrong, argue that with the human; do not quietly rewrite it.

## Honest limits of this setup

- **Compatibility renderer, not the Forward+ the game ships.** Terrain3D
  segfaults under software Vulkan, so the survey runs on OpenGL. Different
  pipeline: no SSAO, no volumetric fog, different shadows. Trustworthy for
  composition, terrain shape, colour and framing; not for fine lighting
  judgements. On a real GPU, switch `tools/survey.sh` to `vulkan`. (D06)
- **Software rendering.** Frame times are meaningless. Never quote them.
- **Creature and character art is judged, not excused.** `CLAUDE.md` says
  creature appeal must not be judged on *placeholders* — that rule exists so
  nobody condemns a design on the strength of a grey capsule. It does not
  protect sourced art that is being proposed as the real thing. The creatures
  and the trainer in these frames are being offered as the game's look, so
  judge them as the game's look.

  This caveat used to say the harness was for rendering defects and not for art
  direction. That was true while everything was a coloured capsule. It is not
  true now, and a critic that hides behind it is not doing the job.
- **Static frames.** Popping, aliasing in motion and traversal feel are
  invisible in a still. A human on the Ally remains the real test.

## After judging

Every accepted criticism becomes work. Re-run the survey and compare sheets. If
the point was addressed the frame should show it; if it does not, the fix did
not land, and saying it did is worse than not fixing it.
