# Band 2 (Stone & Root) — round 3

**What changed since round 2.** One small, targeted change: round 2's critic
named the ranger camp's missing element specifically — seating ("three props
dropped at a way-point, not a camp anyone lives in"). Added a `Bench` and an
`Anvil_Log` (both already-used `quaternius_fantasy` models) facing the
collapsed cot, so two people reads as having sat there. Nothing else
changed — same 8 viewpoints, same vegetation/lighting state.

This round is a test of whether Band 2's *content* still has cheap, in-scope
moves left, or whether round 2 was close to the ceiling for what a content
author can do without touching vegetation density (still `HARVEST-ALL`'s),
night lighting (a global, not-Band-2 question), or the materials/textures on
shared assets (the quarry's rootstone deposits, the Warrens' wall) that two
rounds of critique have now named directly.

**Critic's verdict, in its own words.** Bar A/B: still **No/No**, and this is
the first round that reads as genuinely flat. Ranked top-3 gaps are the
*same three*, in the *same order*, as round 2: night illegibility, ground
density in 01/03/05, unfinished-looking materials at the two close landmark
shots (quarry boulders, Warrens wall). Checked with `tools/frame_stats.py`
against round 2's frames, not just eyeballed: chroma/saturation/hit-rate on
the ranger-camp frame moved by less than 0.03 on every axis — noise, not
signal.

One real soft positive: the camp cluster's *intentionality* read flipped —
round 2 called it "three props dropped at a way-point, not a camp anyone
lives in"; round 3 calls it "the one cluster in the set that reads as
authored." Direct result of the bench/log addition. Per
`ralph/conventions.md`'s own rule, a wording change on an already-named axis
doesn't reset the flat-round counter by itself, but it's worth recording as
the one thing that moved.

**Round 4, one more attempt before treating this as the wall**: added three
`berries` harvest nodes (the two bare stretches critique keeps naming —
early forest, late ridge), the kind of content the coordinator's own
guidance says `harvest.json` should carry now that wood/stone are the
scatter's job. If round 4 repeats the same three top-ranked gaps again,
that's two consecutive flat rounds and the stopping rule says stop —
recorded as a wall, not a failure, per the owner's own "with our current
terrain system and assets" bound.
