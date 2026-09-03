# D46 — The river really divides the map, and that costs exactly one spoke

**Date:** 2026-08-16 · **Decided by:** the SE21/SE22 build, against
`docs/specs/MEADOWS_PROGRESSION_SPEC.md` §3 Band 3 and `SC14`'s recorded limit

## The decision

The Meadows' major river (`SE21`) runs from the north-east ring, down the
east side of the map and out through the southern ring — 340m of channel,
10–18m deep, 70–81° walls — and **both of its ends run past
`world_perimeter.gd`'s 235m ring**. There is no walking around either end.
The only ground link between the near Meadows and the far bank is the Old
Mill Crossing (`SE22`), which is shut until the Mill Bridge Gear is in the
satchel.

The price of that is one severed spoke: the **storm road's** collapsed
bridge and its `Storm Country` fingerpost end up 25–40m past the river, on
the far bank. They are visible across the water from the near side and not
reachable until the crossing opens.

## Why a price had to be paid at all

`SC14` recorded the shape of this problem when it cut the south gully:
*"the gully seals the ROAD, not the region… sealing the whole southern half
instead needs a ~360m chord across the 235m disc."* That is exactly what
this is, and the disc turned out to be full.

The candidate courses were searched rather than eyeballed: every bearing at
1° and every offset at 2.5m, subject to keeping the village, Grandpa's
house, the pond, the South Bridge, the Old Quarry, The Rise and all seven
spoke blockers on the **near** side with real clearance. The best course
that satisfies all of it leaves a far side **17m deep** — a verge, not a
region, and nowhere to put `SE23`'s relay station. Relaxing the one
constraint that costs least (one spoke, the storm road, whose blocker sits
at radius 200 on a bearing any dividing chord must cross) buys a far side
**70m deep and 334m long**.

So the choice was never "divide the map cleanly or not". It was "divide it
and pay one spoke, or do not divide it".

## Why the storm road is the right spoke to pay with

- It is the only one whose blocker is a **collapsed bridge** — a big,
  unambiguous silhouette that still reads from the near bank at 25–40m.
  A blocker you can see across a river is not a blocker you have lost.
- Its destination sign stands at the same place, so what is deferred is
  reading two words, not understanding the road.
- Nothing in Bands 0–2 sends a player there. `SC14` refused to seal the
  gorge road because it is how a player reaches The Pond, a Band 0/1
  destination and a named region; the storm road leads to a severed end and
  nothing else.
- The crossing is sited **on that same road**, at the narrows where a mill
  and a bridge would actually stand. So the road is not simply cut: it is
  cut and given a way over, in one gesture, which is the whole grammar of
  `crossings[]`.

## What was rejected

- **A shallower chord**, keeping every spoke: leaves a 17m verge (above).
- **Bending the course around `rises.peaks[2]`** (the southern rise): there
  is no room. The rise's 44m footprint reaches z≈219 and the ring is at
  235; going around its south side means threading a 16m gap.
- **A dry gorge instead of a river**: the spec says river, and
  `R7.1-remainder-2`'s open question — whether water would do more for the
  set's missing middle distance than more vegetation tuning — is answered by
  water, not by another trench.

## The honest remainder

The northernmost ~60m of the course climbs `rises.peaks[0]`'s south flank,
where the ground stands 19.5m above the water level. The channel is capped
at 18m of cut there, so the bed rises above the water and that reach is a
**dry gorge** feeding the river rather than more river. It divides exactly
as well (the walls are the blocker, not the water) and it is recorded in
`terrain_playground.json`'s own `_comment_depths` rather than pretended
away. Lowering the water to fill it would flood the low middle of the
course, which is where the water is meant to be broad.
