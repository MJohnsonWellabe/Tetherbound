# Visual judgement — Bramblebun colour pass and Stag Chamber climax

Blind review per `visual-judge` SKILL.md. Compatibility/software renderer — composition, silhouette, colour relationships and scale trusted; fine lighting/shadow not.

---

## PART A — grass-SHIPPED-1.00.png (Bramblebun pair, fenced practice meadow)

**Colour verdict: reads as a designed natural coat, not washed-out, not pink/magenta, not glowing.**

The coat is a warm cream/tan base with irregular dark-brown blotch markings (a mottled/calico pattern) and darker brown thorn-spike protrusions running along the spine — consistent with a "bramble-coated" design intent. Pixel sampling on the two bodies (e.g. (845,485)=(238,192,136), a clean warm tan; the brightest highlight at (840,485)=(229,224,214) is a near-neutral specular hit, not tinted pink or magenta) confirms there is no colour-cast problem. There is real value and hue variation across each creature: cream highlights, mid-tan flanks, dark-brown blotches and near-black shadow creases under the haunch. That is shading and material texture, not a flat placeholder tint.

Two small accent notes, not colour defects: a few thistle-like purple/lavender buds are worked into the thorn tufts on the back — this looks like an intentional "bramble flower" detail, not a stray magenta leak, since it's confined to small points rather than washing the coat. One or two specular hotspots on the rounded haunch of the right-hand creature climb close to (229,224,214), which is on the edge of blown-out for a highlight but is small and localized, not the whole coat going white.

**Legibility:**
- At full size, both creatures separate from the grass adequately: they are noticeably lighter and warmer than the mid-dark olive grass around them, and the dark-brown blotch/spike pattern breaks up their silhouette against the ground plane.
- At a simulated 30% scale, separation weakens considerably. The tan hue sits close enough to the sunlit yellow-green patches of grass that the creatures read as two pale, slightly-fuzzy lumps rather than clearly-shaped animals — legible as "something is there," not confidently legible as "rabbit-shaped bramble creature" at a glance. This is a value/hue-proximity problem (warm tan vs. warm-lit grass), not a hue-error problem.
- The left creature reads better than the right one: it has more visible spike/ear silhouette breaking the crown, while the right creature is a low rounded hump (haunches-only pose) with less silhouette information, and it is additionally cut into by the HUD action-bar panel, losing a further slice of its readable shape.

**Defects, named:**
1. Both creatures sit at a small size-on-screen relative to the frame and use a hue close to the grass's own lit colour — reduces silhouette pop at 30% scale (not a colour-cast bug, a contrast-margin issue).
2. Right-hand creature's rounded pose plus HUD action-bar overlap leaves it with the least silhouette information of the two; if this is the "read the species at a glance" creature, its current pose/placement undersells it.
3. Minor: one or two near-white specular hotspots on the right creature's back are borderline hot for a natural fur highlight, though localized and not a systemic blown-white problem.

No pink/magenta cast, no wash-out, no glow. The colour design is sound; the remaining issue is contrast margin against grass at distance/scale, and pose/occlusion on the right-hand individual.

---

## PART B — C-01…C-05, Stag Chamber (Team Tether machine, bound → freed)

**From the doorway (C-02): is the bound creature visible and readable at a glance?**

Partially, and it degrades badly at distance. At full-frame size the bound stag is identifiable once you look for it: two glowing white/cyan hexagonal restraint rings bracket a dark vertical shape between them, and pale antler-tips and small leg/hoof shapes poke past the rings' edges. But close inspection (crop) shows the creature's body and head are a near-black material that sits almost value-matched against the dark machine core and the dark stone wall directly behind it — the antler tips and a small patch of glowing green chest-fur are the only strongly legible cues. At a simulated 30% scale (the actual "read it from the doorway at a glance" test) the creature collapses into an indistinct dark blob between the rings — recognizable as "something is being contained here" because of the rings' geometry, but not recognizable as a stag, and not identifiable by species. The restraint rings are doing the readability work; the captive itself is not.

**Defect (C-02):** bound creature's body/head value is too close to the machine-core and background-wall values — no rim light or contrasting fill separates captive from container, so it reads as absence-with-antlers rather than a legible creature at hall-doorway distance.

**Room lighting — warm or cold/institutional?**

Cold and institutional, consistently across all five frames. The palette is teal/cyan machine-glow against dark brown-grey stone with mossy green undertones; sampled wall/ambient pixels are dark and neutral-to-green (e.g. (14,18,13), (0,3,0), (121,129,75)) with no warm (amber/orange) light contributing meaningfully to the room's overall cast — a single small torch flame is visible far in the background of C-03 but does not meaningfully warm the space. If the intent is "an antagonist machine chamber should feel cold and clinical," this succeeds unambiguously. If any warmth was meant to read (e.g. contrast between "prison" cold and a candle-lit stronghold beyond), none of it survives into these frames.

**Machine orientation — does the open side face the viewer?**

Yes, and this is the strongest-composed frame of the set. C-02 (the doorway shot) is symmetric, front-facing, and reads as designed: two floor light-rails converge from the corners of frame toward a central staircase that leads up to the altar/throne holding the captive, with the machine's open archway centered directly above it. Orientation, entry path and focal point are all unambiguous from the doorway. C-03 (corner-bound) confirms the same structure holds up from an oblique angle — full machine silhouette against wall and ceiling, tiered base, arched crown, captive centered within the arch.

**Scale against the 1.80 m trainer:**

No trainer appears in any of C-01–C-05, so the ruler the rubric asks for is not present in this set and scale cannot be verified directly against it — this itself is worth flagging: the climax reveal has no frame that puts the player-scale figure and the ~15 m machine (or the freed stag) in the same shot, which is the single most convincing way to sell "this thing is enormous." Working from the frames actually given: the machine consistently fills the room from floor to near-ceiling and reads as dominating and multi-story in scale relative to the freed stag standing beside it in C-04/C-05 — internally consistent with a legendary creature (visibly larger and more elaborate than a common creature) that is nonetheless dwarfed by the machine that held it. This is a plausible-looking ratio but is an inference, not a measurement, absent the trainer.

**Per-frame defects:**

- **C-01 (chamber-face-bound):** Camera sits essentially inside/against the machine geometry — the frame is wall-to-wall dark spiky mass with no legible read on structure, orientation, or the captive (only a sliver of white restraint-ring geometry and no clearly readable stag). Visible texture stretching/smearing on the angled shard panels near frame-center (streaky vertical smear pattern, a UV-stretch artifact rather than a lighting issue). As an establishing/climax frame this one does not do its job — it reads as clutter, not machine.
- **C-02 (chamber-door-bound):** Best-composed frame of the set (see orientation note above). Weakness is the captive's low contrast against the core, as detailed above.
- **C-03 (chamber-corner-bound):** Good full-silhouette read of the machine; captive is visible as a small pale-antlered shape between the rings but is even smaller in frame here than in C-02, so legibility is lower, not higher, despite the better structural view. A single warm torch point on the far right wall is the only warm light in the whole set and is too small/distant to affect the room's cold read.
- **C-04 (chamber-face-freed):** Same extreme-close, wall-to-wall machine framing problem as C-01 (this looks like the same camera position before/after the free event, which is a reasonable diff pair for a report but a poor "climax" camera on its own). The freed stag is visible bottom-left, small in frame, and its own silhouette (antlers, mottled coat) reads clearly against the darker floor/wall there — better creature legibility than either bound shot, ironically because it is off to the side, away from the machine's core value-clutter.
- **C-05 (chamber-corner-freed):** Clearest and best frame of the freed stag: full body visible, antler shape, black/tan/cream mottled coat, and glowing green mane all read well in close-up, and the machine remains legible in the background at correct relative scale. One compositional artifact: a teal floor/architectural light-beam passes directly across the stag's chest at neck height; occlusion looks correct (the beam is cut by the body rather than clipping through it) but the placement is a distracting coincidence in the hero freed-creature shot.

---

## Summary

**Part A:** Colour is correct and designed — no wash-out, no pink/magenta cast, no glow. The open issue is legibility margin at small scale/distance (hue too close to lit grass) and a pose/occlusion problem on the second creature, not a palette defect.

**Part B:** The chamber is legibly a cold, institutional prison-machine with a correctly front-facing, symmetric design best shown in C-02. The captive is under-contrasted against the machine core at the doorway distance the rubric specifically asks about, so "readable at a glance" is a soft no at that frame's actual scale. C-01/C-04's extreme-close framing fails as a climax shot. C-05 is the strongest single frame for both creature legibility and machine-scale context. No frame in this set includes the trainer, so the mandated 1.80 m scale check could not be performed directly — that is a gap in the frame set, not a verdict on the asset.
