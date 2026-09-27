# F03#0 lure judge, round 11 (code-blind; juno, gameplay camera only)

Judge input: the 4 frames in `r11-judge/` (`juno_01_lure-first-seen-160m.jpg`, `juno_02_lure-first-readable.jpg`, `juno_03_approach-30m.jpg`, `juno_04_prompt-offered.jpg`) plus the ACCEPTANCE F03 lure criterion and the visible-from-road / readable-on-approach ruling. No code, data, config, tests or scripts were opened. Frames are 1280x720; positions below are pixel coordinates in those frames.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| juno | PASS (marginal) | PASS | PASS (marginal) |

## Evidence

**01, first seen at about 160 m, on the road, no deliberate look.** The only lure element on screen is the smoke column, upper right at about x 845-885, y 75-165: roughly 25 x 90 px, an opaque warm-brown column against blue-grey sky with thin cloud. It rises about 80 px clear into open sky above the horizon and the tree line, which is the only vertical man-made-looking shape in the sky, so a player running the road could notice it without looking around. That makes it a pass.

It is marginal for two reasons:
- The companion (Tup, walking at the player's right) covers the base of the column. The column comes straight up out of Tup's head, between the ears. At a glance it reads as part of the companion's silhouette (an antenna or tail) rather than something in the distance.
- The column is rigid and pill-shaped, with a hard rounded top and no drift, spread or wisps. Enlarged, it looks more like a solid post than smoke.

Nothing else is readable at this range. No oxblood, no banner and no Meadowhart can be seen; there is one sub-10 px white post near x 740, y 245. The gold bolt glyph on the path (x 688, y 297) is not identifiable as belonging to this activity.

**02, first readable.** The lure now reads as a place:
- An oxblood banner on a white gantry, left (x 270-340, y 105-190, about 70 x 85 px).
- A large dark smoke column at top centre (x 575-625, y 0-150).
- A Meadowhart silhouette standing on the crest (x 660-695, y 98-148). It is small but clearly a large deer with antlers.
- A tiny standing figure beside the smoke base (about 8 px) and a second small red element to the right (about x 735, y 165).

Red standards, a camp column and a big deer are enough to read "Team Tether camp with a Meadowhart" for a player who knows the faction colour. One minor misread risk: the dark column tapers toward the bottom behind the hill crest, which could briefly read as a tornado or funnel.

**03, about 30 m.** The frame matches 02 at a larger scale. The Meadowhart is about 45 x 65 px (x 662-712, y 110-178), the oxblood banner on its gantry is at the left edge, the smoke is centred and the red camp elements are behind the crest. Readability holds.

**04, interaction prompt.** Everything is unambiguous:
- Two white gantries with oxblood banners (x 445-495 and x 790-850).
- A campfire glowing at the base of the smoke column (x 555, y 295).
- A dark-clad patrol member facing the player (x 620-660, y 290-360).
- White supply crates.
- The Meadowhart large at right (x 800-1000, y 180-500).
- The prompt "Challenge Tether Patrol".

What and who are clear. Two soft gaps:
- Nothing visible marks the Meadowhart as held or stolen: no tether, rope, pen or handler contact. That reading depends on the prompt.
- The patrol member wears near-black, not oxblood. The faction read comes from the banners, not the person.

## Most important fix (non-blocking; the round passes)

Make the smoke read as smoke from the road, and stop it merging with the companion. At long range, give the plume a soft, drifting, widening top and a slightly lean, instead of the rigid opaque pill. Also make it tall or wide enough that its visible part is not swallowed by the right-side companion silhouette on the normal road line. Optional follow-up for the approach: add a visible tether or rope from the Meadowhart to a stake or handler so that "stolen" reads without the prompt.
