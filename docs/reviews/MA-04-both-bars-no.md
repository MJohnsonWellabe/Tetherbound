# MA-04 — blind critic round 4: no on both bars

**Date:** August 2026
**Frames:** 5 exploration, 8 combat, `_creatures`, `_trainer_front/side`
**Method:** blind sub-agent, shown only the frames and `docs/reference/`. Told
nothing about what changed.

## Verdict

> **A. Do these frames read as belonging to the key art board?** **No.**
>
> **B. Beside the Palworld screenshots, would someone say these are trying to be
> the same kind of game?** **No.**

Both were no in round 3 as well. What changed is the *reason*: round 3 led with
the ground and the creatures; round 4 leads with **scale** and with the cast
being two incompatible art styles.

## What it found that the numeric harness could not

`tools/frame_stats.py` had every headline metric inside the reference band when
this round was spent — near-field luminance 0.41 against Palworld's 0.28–0.60,
saturation 0.44 against 0.41–0.47, chroma 45.8 against 31–74. **The frames were
in band and the verdict was still no.** That is the finding about the harness,
and it is worth more than any single defect below: these metrics measure the
distribution of light and colour in an image, and none of them can see that the
grass is taller than the player.

The scale criterion added after round 3 is what caught it, exactly as designed.

## Ranked gaps, in its words

1. **The cast is two incompatible art styles, and one of them is missing.**
   *"`combat/04` puts a semi-realistic 7-head adult male with a modelled ear and
   separated fingers next to a 2-head untextured plush teddy bear."* And
   `_creatures.png` — the shot meant to let it judge the roster — **rendered
   blank**: three 1.8m reference bars and nothing beside them. It checked the
   pixel data at 4× contrast before saying so.
2. **No landmark, no vertical event, one hue.** `03-rise-overlook` puts *"84% of
   its colour in a single 30° hue bin"* against the references' four to five hue
   families, past 40% depth flattens to one cream value, and there is nothing to
   walk toward.
3. **The ground is wrong at the material level and scaled wrong.** *"The 'grass'
   material is a flat untextured colour fill"* — no albedo, no normal — which is
   why the hills have no form under any lighting.

## The scale failure, measured

Using the 1.80m trainer as the ruler:

| subject | measured | should be |
|---|---|---|
| grass tufts | **1.9 m** | 0.2–0.5 m |
| wildflower | **2.1 m** | 0.2–0.5 m |
| Bramblit (partner) | 1.5 m | — |
| Meadow Hopper (opponent) | 1.0 m | — |
| tallest tree | 9.8 m | key art wants 15–25 m |

Confirmed independently from the source models: `Grass_Common_Tall` is **1.87m
native** and the layer scales it 0.26–0.78, so it renders 0.49–1.46m;
`Flower_4_Group` is **2.49m native** and renders up to 1.99m. The pack is
authored at roughly 4× the size a meadow needs and `base_scale` — which exists
precisely to correct a pack's authoring scale — was left at 1.0.

Its reading of the consequence: *"it makes the world read as a miniature
diorama, it makes the trainer read as a doll, and it lets very few instances
cover the ground — which is part of why the density looks thin."*

**And the cast spans 1.0–1.8m, a 1.8× range, against Palworld's ~6×.** Nothing
is small enough to be cute-underfoot or large enough to be threatening.

## Defects, all named and all reproducible

- **No character casts a shadow.** Trainer, Bramblit and Hopper all sit on the
  terrain with no shadow and no contact darkening, in frames where trees beside
  them cast clearly. *"All three figures read as pasted onto a photograph."*
- **Hard fog band slicing the tree canopy**, `combat/07`/`08` at y=440: RGB
  (210,124,85) at y=442 to (110,0,14) at y=443. One scanline, 5.8× luminance
  drop, green channel to zero.
- **Trunk and branches render on top of the canopy** — alpha sort failure.
- **The trainer is barefoot in `combat/01`** while `_trainer_front` shows boots.
- **`_trainer_side` poses 1 and 5: feet penetrate below the ground plane.**
- **Water is opaque**, with a dead-straight shoreline on the right — *"a flat
  quad clipped by terrain rather than a basin shaped to hold it"*.
- **Hit VFX is grey, mis-sorted and desaturating**, drawing in front of the
  creature it lands on. `combat/06` shows no effect at all with the enemy off
  the bottom of frame.
- **`Orbs 15` touches the right screen edge at x=1279**, 0px margin against a
  64px title-safe boundary.
- **Raw keycodes in a controller-first game** — `[X] / [E]`, `[A] Quick`.
- **Aliased alpha-cutout edges on all foliage.**
- Scatter ignores the terrain paint: grass at uniform density over bare rock in
  `04`, and none at all on the flat green areas in `combat/06`.

## The split it was asked for

**Fixable by changing the scene:** grass and flower scale; the terrain palette
(off lime, onto the board's olive/moss); the flat-colour grass material needing
a real albedo; character shadow casting; the fog ramp and its band artefact; hit
VFX colour and sort order; the combat camera; scatter clustering; vegetation
draw distance; every HUD item.

**Not fixable without art that does not exist:** the creature designs and the
trainer, oak-scale canopy trees, a settlement or stronghold or any landmark on
the board, and water that reads as water.

Its closing line, which is the decision in front of the owner:

> *"Until that art exists, the scene fixes above will produce a much better-
> looking empty meadow, and the answer to question B will still be no."*

## Two findings that were about the harness, not the game

Checked before acting, because acting on a false finding fixes nothing.

**`_creatures.png` was a STALE FILE, and that is my error, not the critic's.**
It was written at 02:37; the roster changed at 05:47. `tools/survey.sh`
regenerates `0*.png` and `contact_sheet.gd` globs everything in `shots/`, so a
five-hour-old artefact went into a blind review as the roster shot. Regenerating
it revealed the tool is *also* genuinely broken: `preview_creatures.gd`
preloaded `pal_body.gd` and called `BODY.new()`, attaching the script to a bare
Node3D with none of the scene's children, so every `@onready var _head := $Head`
resolved to null and `_ready` aborted before a creature was ever built. Changed
to instantiate `pal.tscn`; that gets past the node errors but the tool now
exceeds its render budget and still has not produced a populated card. **Still
broken, and the roster remains unjudged.**

**"No character casts a shadow" is REAL, and was worth checking.** Every mesh
involved reports `cast_shadow=1`, and the only structural difference between a
tree and a trainer is MultiMesh versus Skeleton3D — so the obvious suspicion was
that Compatibility does not put skinned meshes in the shadow map, which would
have made this a D06 harness artefact. `tools/_shadowprobe.gd` puts one skinned
character and one static box of the same size under one light: **13,140 shadow
pixels against 13,131.** Skinned meshes cast normally. The finding stands; the
in-scene cause is not yet identified.

## What was fixed in response

- **Vegetation scale**, which was the largest quantified failure. `base_scale`
  existed precisely to correct a pack's authoring scale and had been left at 1.0
  for every ground-cover layer. Grass now renders 0.16–0.47m and flowers
  0.22–0.52m, against 1.46m and 1.99m before.

Everything else on the list above is open.
