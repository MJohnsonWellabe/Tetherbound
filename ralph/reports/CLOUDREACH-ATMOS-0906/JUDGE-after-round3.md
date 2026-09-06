# Cloudreach Cliffs — blind visual judge, ROUND 3 (interim)

The round that caught a regression this lane had introduced: the island mist collar was
drawing *through* the island it was meant to anchor. Kept because that is the evidence for
the round-4 fix.

Frames: `shots/atmos_after3/`, stands 01, 02-broken-causeways, 04, 11.

The three questions this judge was asked by name, and its answers:

> **1a. Is there a haze band?** "Partially, and inconsistently. `11` has a real one ... `02`
> has a mild one on the far ridge. `01` has effectively **none**. `04` has none that does
> any work."
>
> **1b. Is there a cloud layer below the player's eye level?** "**Yes, in two frames.**
> `02-broken-causeways.png` is the clearest — the entire left third below the grass horizon
> is a cloud deck. `01-arrival-first-reveal.png` has white cloud slabs sitting at and below
> the grass line on the left. `11` has a marginal one ... `04` has **no** below-eye-level
> cloud at all."
>
> **1c. Is there any terrain lower than the ground the player stands on?** "**Barely, and
> never where the player is.** `02` is the only frame with a real answer ... `11` has a
> grass ledge dropping away at the far right and distant lower cliffs behind the monolith,
> both small and hazed. `01` and `04` have **nothing** below the player."
>
> **2. Does this read as a high, vertical place?** "**No, and no.** ... There is not one
> frame where the camera or the player is near an edge, and not one frame where a void is
> visible in the lower half of the image. ... Altitude is asserted by props, never by
> ground."
>
> **3. Objects that read as broken** — the list that mattered to this lane:
> "**The floating island — `04`.** A flat, uniformly dark grey silhouette ... Worse, the
> white cloud puffs draw *through* it — cloud sprites intersect its body front and back. It
> reads as unrendered geometry, not as a distant island."

Other defects it raised that belong to this lane:

- "The cloud sea is two different things in one frame, and neither reads as cloud ...
  hard-edged scalloped billboards with no soft alpha falloff, and the same crescent
  silhouette repeats about six times in a row."
- "Haze is applied inconsistently and in the wrong places ... in `11` the monolith is hazed
  until it sits at almost exactly the sky's value, losing all form and most of its
  silhouette."
- "The bridge in `02` crosses nothing ... Grass continues unbroken under and around the
  deck."

Defects it raised that belong to other lanes (ground cover density and single-species
vegetation, the trainer's A-pose and costume, creature materials and relative scale, prop
dressing, the gate's missing approach, the green gem's glow quad, the timber poles at 11)
are recorded here only so the next reader does not re-derive them.

## Bar questions, round 3

**A. Belongs to the key art?** No. **B. Same kind of game as Palworld?** No.
