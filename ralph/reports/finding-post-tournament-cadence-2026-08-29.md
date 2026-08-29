# Finding — post-tournament cadence measurement, 2026-08-29

Track 3 (content/fun) measurement pass, `ralph/T3-CADENCE`. Scope: measure
whether the required post-tournament traversal (South Bridge → Lower Meadows →
Burrow Warrens → River/Relay → Upper Meadows) meets the owner's cadence
target — a meaningful reason to fight, catch, gather, investigate, prepare,
change direction, or anticipate something visible ahead, roughly every
60-90 seconds of required travel. **This pass is measurement only. Nothing
below was authored or implemented.**

## Method

`tools/gate_f/`'s full operator harness (S05-S08, the segments that cover
exactly this route) could not be run to completion in this environment this
session. Two blockers, both environmental rather than about the game:

1. No Godot binary existed in this container; one was fetched fresh
   (4.7-stable, matching `GODOT_VERSION` in CI) and the project re-imported.
2. With that in place, the harness's own capture pre-flight hard-blocks
   *any* non-xvfb invocation right now: the committed candidate freeze
   record at `ralph/reports/gate-f-candidate/RUN_METADATA.json` declares the
   active candidate validated under xvfb, and CD-8b's cross-check refuses to
   run a segment when the freeze record and the live process disagree about
   display-server capability — by design, not a bug to route around here.
   Running for real under xvfb is priced, by that same record's own
   measurement, at ~12.7 s per rendered physics frame; S05-S08 alone are
   ~400 scripted steps with hundreds of metres of `move_to` walking each,
   which would cost many hours — out of this pass's ~60-90 minute budget and
   not this lane's to spend (`ralph/GATE-F-RUN-3` owns that full run).

So this pass reused the lighter existing instrument instead of building a
parallel one: `tools/_probe_gate_f_corridor.gd`. It boots the real
`meadows_playground.tscn` once, headless, and walks the **authored corridor
spine** (`data/config/terrain_playground.json`'s `trail.bands[].points`,
band1 through band5 chained end to end — the same line the world is built
around) as geometry, not physics, logging every point-of-interest the route
line passes within 30 m of (`NOTICE_M`, the same radius already codified in
`gate_f_probe.gd::POI_RADIUS_M` for the harness's own dead-travel meter — not
a threshold invented for this pass). It classifies POIs the same way the
harness does: trainer, wild (visible only), gather node, camp/rest, landmark,
TM, key item.

**Honest limits of this instrument, stated up front:**

- It steps the spine as points, not through physics at walk speed with
  combat/dialogue holdup — it measures **content spacing along the intended
  route**, not lived traversal time with fights and detours folded in.
  Actual play time between beats will be longer than the raw metres imply
  once fights, gathering stops, and captains' dialogue are counted.
- 30 m is a "could the player choose to walk to it" radius, not a sightline
  check. A landmark or creature silhouette visible from 100 m+ away (which
  satisfies the owner's cadence definition on its own — "anticipate something
  clearly visible ahead" needs no proximity) is not counted unless the route
  passes within 30 m of it. So this measurement likely **understates** true
  experiential cadence for anything designed to be seen at range rather than
  walked to.
- Wild creatures are bucketed as one undifferentiated `wild` kind — the
  probe does not distinguish common/Alpha/Elder or nest/feeding-patch/rare
  habitat. Nothing below claims band 4's captains route delivers "stronger
  Alpha or Elder" beats; it only shows ordinary wildlife density is high.

Full raw output: `ralph/reports/gate-f-corridor-probe-2026-08-29.txt` (renamed from
`.log` — this repo's `.gitignore` excludes `*.log` chapter-wide).

## Headline result: raw dead-travel is not a problem, chapter-wide

| band | length | worst gap (any POI) | ~seconds at 4 m/s |
|---|---|---|---|
| band1_lower_meadows | 2,403 m | 106 m | 27 s |
| band2_stone_and_root (incl. Burrow Warrens) | 2,653 m | 165 m | 41 s |
| band3_the_river_lock | 2,375 m | 163 m | 41 s |
| band4_upper_meadows_ironwood | 3,436 m | 156 m | 39 s |
| band5_stronghold_approach | 651 m | 64 m | 16 s |
| **chapter-wide worst** | 11,519 m | **165 m** | **41 s** |

Zero gaps anywhere in the 11.5 km corridor reach the 240-360 m band that
corresponds to the 60-90 s target, let alone exceed it. 567 POIs were met in
total; the full distribution is 512 gaps under 60 m, 44 between 60-120 m, 11
between 120-180 m, none above that. **By this measure alone, every region
already passes** — this is not a region to scatter more content into on the
strength of this number, and the report says so rather than manufacturing
work.

## The real finding: that number is almost entirely wildlife

494 of the 567 POIs met (87%) are ambient wild creatures. Landmarks and
rest/camp beats are **entirely absent** — zero instances of either kind
anywhere across all five bands, over the whole 11.5 km. TM spheres: 2 total,
both within the first few metres of band 1. Key items: 1, also at the very
front. Stripping wildlife out and counting only the categories that are
actually authored/purposeful (trainer, gather node, TM, key — the "is there
a reason to change course" content, not ambient fauna) changes the picture:

| band | length | authored POIs | avg. spacing | worst authored gap |
|---|---|---|---|---|
| band1_lower_meadows | 2,403 m | 27 | 89 m (~22 s) | 670 m (~2.8 min) |
| band2_stone_and_root | 2,653 m | 21 | 126 m (~32 s) | — |
| band3_the_river_lock | 2,375 m | 9 | 264 m (~66 s) | 641 m (~2.7 min) |
| band4_upper_meadows_ironwood | 3,436 m | 11 | **312 m (~78 s)** | **1,064 m (~4.4 min)** |
| band5_stronghold_approach | 651 m | 5 | 130 m (~32 s) | — |

Ten of the 73 authored-content gaps chapter-wide exceed the 90 s-equivalent
(360 m) threshold. The worst five:

1. **1,064 m (~4.4 min)**, ending 7,869 m along — spans the band3→band4 seam
   (River/Relay into Upper Meadows/Ironwood), the biggest gap in the run.
2. **852 m (~3.5 min)**, ending 10,971 m along — spans the band4→band5 seam
   (Ironwood into the Stronghold Approach).
3. **818 m (~3.4 min)**, ending 8,743 m along — interior to band4, between
   two of the three captains.
4. **768 m (~3.2 min)**, ending 10,119 m along — interior to band4, before
   the third captain.
5. **679/670/641 m (~2.7-2.8 min)** — one each in band3 interior, band1
   interior, and the band2→band3 seam.

**Band 4 (Upper Meadows/Ironwood) is the one region this pass flags.** It has
both the sparsest authored-content density of any band relative to its
length and hosts four of the run's five worst authored gaps, including both
ends of the biggest one. Bands 1, 2, and 5 are fine on both measures — do not
add content to them on the strength of this pass. Band 3 (River & Relay) is
borderline: its raw metric is fine but its authored density is the
second-sparsest, and it has one real multi-minute gap. Worth a light pass if
band 4 is prioritised first.

## Proposal — smallest additions, not implemented

In order of impact, fitted to each region's own identity per the owner's
vocabulary:

1. **Band 4, band3→4 seam (~7,400-7,900 m along):** one **special
   grove/rare-habitat beat** at the actual tree-line where Ironwood begins —
   this is the natural "the ground itself just changed" moment for the
   region's identity and closes the run's single biggest gap for free,
   without inventing new mechanics.
2. **Band 4, band4→5 seam (~10,100-11,000 m along):** one **landmark with
   visible reward** — the Sigil Gate or a stronghold watchtower silhouette,
   visible well before the player reaches it. This double-counts as both a
   landmark beat and the "anticipate something visible ahead" cadence this
   pass's own instrument cannot detect (30 m proximity vs. sightline), so it
   is likely to close more of the felt gap than its metres alone suggest.
3. **Band 4 interior, between the three captains (~8,700-10,100 m):** one
   small beat — a **shortcut** (band 4 is also where mounted travel is
   introduced, per S08's own segment title) or a **creature in distress**
   moment reads as native to "increasingly demanding Meadows" pacing between
   trainer fights.
4. **Chapter-wide categorical gap, not a single-region fix:** zero rest/camp
   beats and zero landmarks exist anywhere in bands 2-5. One authored camp
   per band (the `camp.gd` mechanic already exists and does double duty with
   the light-satiety system) would be the cheapest fix that also serves a
   second system already in the game, not a new one.
5. **TM distribution:** both of the chapter's two TM spheres sit in band 1.
   Bands 2-5 — the higher-level half of the chapter, exactly where the "make
   my five more versatile" directive bites hardest — have none. This is a
   content-design gap distinct from traversal cadence and worth flagging to
   whoever owns TM placement.

Band 3 (River & Relay) would benefit from one similar beat (an overlook or
environmental-storytelling moment near its 641 m gap) if band 4 is addressed
first and there is remaining budget.

## What this pass did not do

It did not touch `tools/gate_f/segments/` or any `ralph/GATE-F-RUN-3` run
report, per this lane's scope. It did not author or place any content — the
proposal above is a punch list for a future authoring pass, not a diff. The
one artefact left from setup is four `.uid` sidecars Godot generated on
import for scripts that lacked one (`tools/_diag_golden_hour.gd.uid`,
`tools/_diag_survey_black.gd.uid`, `tools/_probe_den_door_sightline.gd.uid`,
`tools/capture_constructed_interiors.gd.uid`), committed per CLAUDE.md's
standing instruction to commit `.uid` siblings Godot generates.
