# Visual Critique Log

Per the critic loop in `docs/02_ART_BIBLE.md`. One entry per system per round:
system, what was fixed, what was left, round count.

Scored against `docs/reference/`, which holds the five Palworld frames the
owner supplied as the bar. Never against photography.

---

## Terrain, vegetation, lighting and atmosphere — the Meadows, 4 rounds

Run together rather than one system at a time, against
`docs/06_VISUAL_SYSTEM_PHASING.md`'s stated order. That was the owner's call:
the session had a single bar ("it looks like Palworld or we stop") and the
defects were entangled, since ground colour, foliage colour and the grade all
multiply into the same pixel and none of them can be judged with the other two
wrong. Noted as a deviation, not as a precedent.

**Before.** Ground read as brown dirt. Foliage was a cold cyan-green that
belonged to a different game from the ground it stood in. Ground cover reached
5% coverage and stopped at 72m against a 384m view. The spawn point sat in a
19m circle with no ground cover at all, on terrain flattened to a literal
plane. The sky was a two-colour vertical band. Nothing existed past 384m. The
whole frame was dim, because the renderer had no headroom to be anything else.

**Round 1 — the grade, the ground colour, density, the clearing.**
Overshot hard: exposure 1.5, contrast 1.32 and globalSaturation 62 over
already-raised albedo produced neon foliage, mustard ground, blown walls and
crushed shadows. Grass tufts scaled to person height. Recorded because the
lesson generalises: the grade multiplies whatever albedo is under it, so the
two cannot be tuned independently.

**Round 2 — pulled back to roughly a third of those values**, plus the sun disc
and the far ridge. The ridge is the single biggest win in the whole pass; it is
what every reference frame is anchored by and the game had nothing out there.
Colour landed close to natural. Foliage still wrong.

**Round 3 — the assets.** The owner's intervention: the bushes look horrible
and are a huge part of the problem. Correct, and no value in `scatter.json`
could have reached it. Vegetation moved to Quaternius Stylized Nature (D64).
Three of the six bushes in that pack bake to black or near-black, so models
were chosen on measured vertex colour and height-to-width ratio.

**Round 4 — the fern.** Large flat rosettes had survived four bush swaps
because they were never bushes: `reed_a` is nine metres wide natively and was
planted along every riverbank including the one Hollowbrook stands on.

**Outcome.** Green rolling meadow under a blue sky, warm light, hazy ranges on
the horizon, trees with real silhouettes, ground cover the player stands in.

**What is still weak, honestly:**

1. **The ground has no macro variation.** One flat vertex colour per biome
   under one 9m-tiling desaturated photo, and biome transitions snap over a
   single 2m quad. This is the largest remaining gap to the reference and the
   obvious next system.
2. **No clouds.** Every reference frame has them.
3. **One mesh per family.** `propPlan.ts` still takes `variants[0]`, so every
   oak in the world is the same tree. Per-instance colour hides this far better
   than before, but it is not fixed.
4. **Grass reads as separate tufts, not a carpet**, and the near field thins
   out faster than the reference does.
5. **The survey's `meadow-open` viewpoint is underwater**, so two of nine
   frames are mostly water plane and the contact sheet reads worse than the
   game does. Fix the viewpoint before reading the sheet as a verdict.

**Not yet run:** a blind sub-agent critic on the final sheet. The rounds above
were judged by the author against the reference, which is weaker than the
process the art bible specifies and should not be recorded as equivalent to it.
