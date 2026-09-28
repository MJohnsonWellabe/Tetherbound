FUNCTION A (settlements): PASS (marginal)   B (cliffs as routes): FAIL   C (night cues): PASS (marginal)

# F08#4 r1 — first code-blind functional verdict (prompt: judge-prompt.md)

Frames: r1 (regions), r1c (Galefoot, terrapup out), r1d (Cliffhold from 30 m). All 37 opened.

**A. Settlements.** Galefoot, day and night: A1 occupied YES (several villagers in the square and by the
stall/workshop; one visible from the approach), A2 activity YES (campfire, tents, cart, stall, benches, wash
tub, lights), A3 navigable YES (a path between the cottages to a central ring; from 37 the road leads to the
fire), A4 reads as its place YES (cottages and tents under a watchtower; at night firelight and windows mark
it). Cliffhold, day and night: PARTLY on all four (two small figures, crates and a fenced plot but no hearth
seen; the companion clips the top-right quarter; same tower/cottage kit as Galefoot, so only moderately
distinct; few night lights).

**B. Cliffs as routes and landmarks.** gate_lower_cliffs YES/YES/PARTLY; broken_causeways PARTLY (07: "the
dirt road stops dead at a steep grass slope"); windscar_ravine PARTLY (14's beacon out of frame);
high_roost_sky_shrine NO route ("no walkable road in any frame" — the judge was not told it is glide-only),
17 no landmark, 19/20 cramped between pillars; upper_cloudreach YES; summit YES/YES/PARTLY (26 faces a wall).

**C. Night.** 30 gate YES; 31 causeways PARTLY (same slope as 07); 32 upper YES; Galefoot YES; Cliffhold PARTLY.

Worst five: 17 (no road/landmark at the shrine plateau), 07/31 (road dead-ends in a grass slope), 14 (beacon
not in frame), 20 (camera against a pillar), 25 (companion clips the lens; thin occupation). Also: companion
hides the trainer in 09 and 29; 26 frames a sheer wall.

**Follow-up.** 07/31 was a real defect: broken_causeway_main climbs inside the Broken Causeways crown
(top y 390) for its last ~100 m, so the road vanished into a grass wall and the crown's grass floated over
it. Fixed by giving the region the summit's crown_cut (data/config/cloudreach_world.json); re-rendered in
r1f. B and C were re-judged by a fresh judge (judge-prompt-r2.md, verdict-r2.md), told the one design fact
the first judge lacked: High Roost has no walking road by design and is reached by gliding.
