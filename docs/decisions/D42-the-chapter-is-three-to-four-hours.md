# D42 — The Meadows chapter is 3–4 hours, and the terrain does not shrink

**Date:** 2026-08-15 · **Decided by:** the owner, playtest pass — "Also I think
the meadows should only play 3-4 hours. Not the longer end."

## The decision

The Meadows chapter's target first-completion time is **3–4 hours**. This
replaces the **4–7 hours** in `docs/MEADOWS_PROGRESSION_SPEC.md` §0/§3 and the
**4–8 hour** band in `docs/GAME_DESIGN.md` §29/§30, everywhere those numbers
state a target. Longer runs for exploration, team-building, optional trainers,
gathering and catching are still expected and still fine — the target is the
main-line completion time, not a ceiling on play.

"Not the longer end" is the operative half of the sentence. The old range's own
low end was 4 hours; the owner is not trimming the range, he is moving the
whole target below it. A run that lands at 4h30 is now over, not inside.

The band cumulative times in §3 (Band 0 ~20–40 min, Band 1 ~1–1.5h, Band 2
~2–3h, Band 3 ~3–4h, Band 4 ~4–5.5h) are the old arc's shape and now overshoot.
They stay in place as the *relative* weighting of the five bands — Band 0 is
still the shortest, Band 4 still the longest — and get compressed to fit 3–4h
by `SH47`, not rewritten here in the abstract before anything can be timed.

## The carve-out: do NOT resize the terrain

`docs/decisions/D23` argued the map footprint directly from arc length. Its own
words, at the point where it priced what the spec would cost: *"the world does
not fit: `terrain_playground.json` says in its own first line that it is a test
area, not the Meadows, and 512 m on a side cannot hold a 4–7 hour arc. Growing
it costs a terrain rebake, more Terrain3D regions and a real performance
question on the Ally."* That is `R7.3`.

**Cutting the target from 4–7 to 3–4 hours does not license shrinking the map,
reverting `R7.3`, or rebaking the terrain smaller.** Say it plainly, because
the arithmetic is seductive and wrong: the arc got ~40% shorter, therefore the
world should get ~40% smaller. No. The owner asked for a shorter *chapter*, not
a smaller *world*, and those are different things that happen to have been
linked once, in one direction, by one argument in `D23`.

Three reasons the link does not run backwards:

1. **A rebake is the single most expensive thing in the plan.** `D23` called
   it "the single largest unpriced item in this integration." Spending it once
   to grow the world is a cost the owner accepted. Spending it a *second* time
   to shrink the world, in service of a pacing note, is the worst
   effort-to-player-value trade available.
2. **Density, not distance, is what `GAME_DESIGN.md` §30 actually locks.** §30's
   locked direction is "not enormous, dense enough that exploration regularly
   yields something interesting." A world sized for 4–7 hours, played in 3–4,
   is a world with *more* interesting things per minute — which is the
   direction §30 points, not against it. The one sentence in §30 that sizes the
   map from the arc length is the sentence this carve-out suspends.
3. **The long tail is still real.** Exploration, optional trainers, the
   dungeon's deep branch, gathering and catching all still exist and all still
   want ground to happen on. 3–4 hours is the main line, and the main line was
   never the only thing the footprint was for.

## What the answer actually is: `SH47`

The instrument for hitting 3–4 hours is the pacing pass — `SH47`, spec §17 P7 /
§38 Phase H — and its existing levers are exactly the right ones:

- **XP curve** — the largest single lever. Reaching the Warden-ready level band
  has to happen in fewer encounters.
- **Trainer levels and battle count** — §12's 12–17 trainer battles is a
  density target that can move toward its low end.
- **Material costs** — Rootstone and Ironwood gates that each cost a gathering
  session are where an hour silently goes.
- **Travel time** — riding unlocks earlier, or the same routes get shorter
  effective traversal. This is a *speed and routing* lever, not a *distance*
  lever, and that distinction is the whole carve-out above.
- **Spawn density** — more encounters per minute walked, not more minutes.
- **Remove dead walking** — §17 P7's own explicit instruction, and the first
  thing to spend on a shorter target. Dead walking is the failure mode a
  larger-than-needed map produces, and deleting it is cheaper and better than
  deleting the map.

`SH47`'s completion condition changes from "lands inside 4–7 hours" to "lands
inside 3–4 hours." Nothing else about the item changes.

## What does not change

- **Every band, gate, dungeon, mini-stronghold, rescue, captain and act.** The
  spec's Bands 0–4 and Acts I–VI are untouched. This is a pacing decision, not
  a scope cut, and it is emphatically not permission to delete content items
  from Phase 8 to hit a clock.
- **`D23`'s "the Meadows is the first game."** A 3–4 hour first chapter is
  still a chapter, not a tutorial. §18/§39's owner-facing exit criterion —
  *"I had a reason to keep playing for several hours before the first
  Warden"* — reads the same at 3–4 hours as it did at 4–7. "Several hours" was
  always the real test; the range was always an estimate around it.
- **The terrain footprint, `R7.3`, and the Terrain3D region count.** See above.
- **`docs/decisions/D23`'s own text.** Decision docs record history. D23 said
  4–7 hours on 2026-08-11 and that is what it said; it gains a pointer to this
  doc, not an edit.

## Why the number moved at all

Worth recording honestly: nothing in the build failed. The owner played, formed
a view about how long he wants his own first chapter to be, and said so. 4–7
hours came from `D23`'s integration of the progression spec and sat inside
`GAME_DESIGN.md` §29's older 4–8 hour band — an estimate inherited from an
estimate, never a playtested measurement. The first number anyone has produced
by actually thinking about the finished shape of the thing is this one, and it
is the owner's. That makes it better evidence than what it replaces.
