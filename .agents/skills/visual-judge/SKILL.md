---
name: visual-judge
description: Judge Tetherbound's visuals from a contact sheet of real in-game frames, against the project's own art direction board. Load when asked to review how the game looks, run a visual pass, or verify that a rendering change actually improved anything. Produces specific, addressable criticism plus a score out of 10; 8.5 or above is done, and an item stops after two rounds gaining under 0.5; three averaged judges on fixed camera sets.
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

## Before/after verdicts and scores (all visual work, proof rules v2)

Most visual work is now one catalog item at a time (board Visual catalog tab,
`ralph/reports/COORDINATOR/dashboard/visual_catalog.json`). For each item:

1. Capture matched before and after frames: same stands, cameras, time and
   weather, covering the item's catalog sightings. A Low/Compatibility capture
   is enough (WORKFLOW §8.1); judge High/Medium only where the criterion asks.
2. Build one sheet with neutral labels (A/B, sides shuffled) and withhold which
   side is the change. The judge gets the sheet, the item's defect text and
   `docs/reference/`, nothing else.
3. Score with **three independent code-blind judges** on the item's **fixed
   camera set** (`tools/visual_judge/camera_sets/<item>.json`, the same stands,
   cameras, time and weather every round). Each judge scores both sides out of
   10. The round's score is the mean; record the spread. Score first against
   our own key art and ART_DIRECTION (Bar A); report Bar B (Palworld/Valheim)
   alongside. **8.5 or above on Bar A is done** (owner, 13 Oct 2026). Use
   Medium/High GPU captures whenever available. Low/Compatibility cloud
   captures are for iteration only and can't park an item on their own.
4. Record one row in `ralph/reports/EVIDENCE/F38-F41/JUDGE.md` (or the
   criterion's evidence file): time in US Central, item, sheet path and
   branch, renderer, the three scores, mean and spread, and remaining
   defects. Keep one `_sheet*.png`. Ask each judge which 2–3 changes would
   add the most points, and whether each gap is fixable in the scene or
   needs new art (a Meshy hero asset).
5. **Gain rule.** Each round should gain at least 0.5 over the best mean. An
   item stops only after **two consecutive rounds** gain less. Then take one
   clearly different approach (a look-pass change or a Meshy hero asset), or
   park it at its best score (WORKFLOW §8.1 rules 10–11).

Codex lanes run this as a self-check before posting READY; the coordinator's
code-blind judge decides.

## The target

Two references, used for different things.

**`docs/reference/tetherbound-meadows-keyart.png`** — the project's own art
direction board, and the primary reference for palette and mood.

**`docs/reference/palworld-0*.jpg`** — five screenshots of Palworld, and the
explicit **bar the owner set for this project**. These are the comparison that
decides whether the work passes.

`docs/GAME_BIBLE.md` §4.1: stylised realism between Valheim and Palworld. Vibrant,
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

This is acceptance criteria, not commentary. Finish with all three of these.

**1. The three things that most separate these frames from the references**,
ranked, each saying concretely what a reference does that these do not, and
naming the frame.

**2. A score out of 10** for the whole sheet against the bar (8.5 or above
is done; owner, 13 Oct 2026). Score both sides of a before/after pair on the
same scale.

**3. The two bar questions, answered directly.** The owner's gate names both
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

- **Compatibility renderer — as of 2026-08-11 (RB4, `D01`), this is also
  what the game ships**, not a stand-in for a different shipped pipeline.
  The Ally freeze root-caused to a Forward+/Vulkan render-thread stall;
  switching the shipped renderer to Compatibility fixed it, so this survey
  now judges the same pipeline players actually see. Still worth knowing
  it's software rendering here (Terrain3D also segfaults under software
  Vulkan on this box, which is *why* Compatibility was already the
  survey's choice before it became the shipped choice too): no SSAO, no
  volumetric fog, and fine lighting/shadow judgements are still safer made
  on real hardware than through llvmpipe. (D06)
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
