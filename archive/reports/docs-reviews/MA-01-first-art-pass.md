# Visual review — first art pass

**Date:** 2026-08-03
**Verdict on the bar question: NO.**
**Frames:** `shots/*.png` (5 exploration), `shots/combat/*.png` (8 combat)
**Harness:** `.claude/skills/visual-judge`, blind sub-agent, Compatibility
renderer under software rendering.

The critic saw only the rendered frames, `docs/reference/`, and the rubric. It
did not see the code, the conversation, what changed, or what anybody hoped it
would say.

## The question it was asked

> Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone say
> these are trying to be the same kind of game?

## The answer

**No.** In its words: *"the frames read as a terrain greybox with two stock
meshes and a Minecraft skin standing in an empty field."*

## What it led with, unprompted

> **The trainer is a Minecraft player model.** A cube head with a painted 2D
> face texture, a slab torso, Steve/Alex proportions… it is in a **different art
> language from the creatures in the same frame**… they read as assets from two
> unrelated packs dropped into one scene. No amount of scene work fixes that.

> **The Meadow Hopper is not a creature.** A faceted white blob with two pale-blue
> slabs where ears would be, no visible legs, no face, no eyes. At contact-sheet
> size it is indistinguishable from a rock or a discarded sack.

> The game is named after these things. Right now the roster is one adequate
> stock mesh, one blob, and a Minecraft skin.

The owner predicted this verdict before the run and asked that the rubric not
let the critic excuse it. The exemption that would have — *"only 'is this
creature appealing as a design' is out of scope"* — was removed beforehand. The
critic was never told what to conclude.

## Measurements worth keeping

Featureless flat fill, lower half of frame:

| frame | flat fill |
|---|---|
| `02-valley-floor` | 90.6% |
| `04-three-quarter` | 86.2% |
| `01-spawn-outward` | 77.9% |
| `palworld-02` | 13.2% |
| `palworld-03` | **2.8%** |

Value range, ground band:

| frame | darkest 1% | ground band |
|---|---|---|
| `03-rise-overlook` | 129 | 178–203 |
| `05-spawn-low-sun` | 52 | 64–164 |
| `palworld-04` | **5** | **20–220** |
| key art | **4** | 13–182 |

`05-spawn-low-sun` is the only exploration frame with real darks and is by a
wide margin the best-looking one — which shows the gap is a lighting decision,
not a fidelity ceiling.

## Defects found that are not about art

- **`combat/07` and `08` are unusable.** The camera is inside a bush; both
  creatures are invisible and the orb in flight cannot be seen at all. There is
  no camera collision and no occluder fade. Introduced by the vegetation scatter
  in this same pass and missed on review of those exact frames.
- **`combat/04`** puts a tree trunk through the centre of frame, occluding both
  fighters during the enemy wind-up — the one moment the player most needs to
  read.
- **`03-rise-overlook`** has a hard fog/sky seam across the full frame width;
  the terrain rises out of a white void.
- **`04-three-quarter`** shows the world edge as a flat white strip.
- **The player casts no shadow** while trees in the same frame do.
- **HUD**: white text with no scrim on light green; keyboard glyphs in a
  controller-first game; the enemy's bar is top-centre while the enemy is
  bottom-left.

One correction: the critic called the empty `[ ] Charged` bracket "a straight
bug". It is the deliberate rendering for *unavailable*. That it read as broken
to a fresh eye is still fair feedback about the presentation.

## The split, which is the deliverable

**Fixable by changing the scene — no new art:** cast shadows and a sun angle on
the exploration frames (highest leverage, and `05` already proves the setup
works); ground detail density; scatter clustering and scale variety; camera
collision and occluder fade; the fog seam and the world edge; atmospheric
perspective; contact shadows; HUD scrim, controller glyphs and bar placement;
palette breadth; the path needs a verge or removal.

**Needs art that is not in the build:** the trainer, the creature roster, and
landmark props (ruins, standing stones, fences, wells, bridges — the things the
key art panels are built around; there are none in the project to place).

> The lighting, scatter, density, fog and camera work is real, bounded
> engineering that would move these frames a long way, and is worth doing now.
> The character and creature gap is a purchasing decision, and until it is made
> no amount of scene work will make `combat/02` look like it belongs beside
> `palworld-01`.
