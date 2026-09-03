# Visual-parity judge — PLACES round 5

Blind review. Read only: `.claude/skills/visual-judge/SKILL.md`, `docs/reference/` (key art +
five Palworld shots), `site/img/page-board.jpg`, and the round 5 / round 4 frames named below.
No code, config, diffs, or history was read. Judged at native exposure; crops below are zoomed
(nearest/Lanczos resample) but never brightened, gamma-corrected, or boosted — pixel-value
sampling is quoted where it substitutes for a claim about brightness.

AFTER = `ralph/reports/visual-parity/PLACES/round5/locations/*.png` (12 frames, 960×540).
BEFORE = same names in `round4/locations/`. Standing owner verdicts taken as given: Warrens
**interior (den)** is GOOD and must stay unchanged; Hall/stronghold and Warrens **exterior**
were BAD at baseline.

---

## Per-frame

### 1. `04-warrens-approach-day`
**r4→r5:** Pixel-identical to the eye; diff against r4 is noise-level (mean 9.2/255, almost
certainly cloud-shader dither, not a scene edit). **Same.**
**Top defect:** This is one continuous sculpted rock mass with faceted, low-poly cuts and a
uniform olive-brown material plus blotchy green "moss" texture stamps — not a set of discrete
half-buried boulders. Zooming on the mouth (native pixels, 3×) shows a flat grey door-frame slab
set flush into the rock with grass running straight up to its base — no dirt apron, no spoil, no
scatter of loose stone. It reads as a stone bunker door cut into a hill, not an animal-dug
warren.

### 2. `04-warrens-den-day`
**r4→r5:** Confirmed unchanged (diff mean 2.1/255, the lowest of all 12 frames — effectively a
no-op, matching the owner's "leave it alone" verdict). **Same, correctly.**
**Top defect:** None that matters — this frame still carries the set (warm tan aggregate stone,
timber beams, sunbeam through the doorway, the badger-creature close and readable). One
stylistic note, not a defect against the brief: the creature's thick black cel-shading outline
sits in a visibly different rendering language than the painterly environment around it.

### 3. `04-warrens-standing-day`
**r4→r5:** This is the frame that actually changed the most of the three (diff mean 15.3/255,
~25% of pixels touched) — but it got *darker*, not better: mean luma dropped from 38.3 to 27.4.
The composition also rotated: r4 showed more of the passage interior at a wider angle; r5 adds a
solid black unlit overhang wedge across the whole top-right of the frame. **Worse** on
legibility, even if the intent may have been a more dramatic threshold shot.
**Top defect:** Rock-family mismatch (see verdict A below) plus the new black overhang eating
roughly a quarter of the frame with zero readable content.

### 4. `10-stronghold-approach-day`
**r4→r5:** Diff mean 8.0/255 — essentially the same composition and lighting; no visible
improvement to the hall silhouette or the dominant dark cloud band. **Same.**
**Top defect:** The flat dark storm-cloud band still occupies roughly the top third of the sky
in every day frame at this location, with vertical "rain shaft" streaks that don't parallax or
thin with distance — it reads as a static, slightly artificial sky layer rather than weather.

### 5. `10-stronghold-approach-night`
**r4→r5:** Genuine exposure lift, confirmed by sampling: mean luma 22.5 → 34.9 (~55% brighter).
Castle towers separate a little better from the tree line. **Better, modestly.**
**Top defect:** Still no lit windows or ground detail readable on the hall itself at this
distance; the castle remains a near-featureless dark mass under a bright moon.

### 6. `10-stronghold-courtyard-day`
**r4→r5:** Diff mean 6.8/255 — near-identical. A Team Tether grunt NPC (cap, mask, chest
emblem, sidearm rack, lit brazier) is present and reads clearly on close inspection. **Same,
and already reasonably good** — this is the day frame that best supports "occupied."
**Top defect:** The banners read as a bright saturated red rather than the muted oxblood of the
key art's stronghold panel.

### 7. `10-stronghold-courtyard-night`
**r4→r5:** The largest and most consequential lift on the sheet: mean luma 3.6 → 8.4 (more than
doubled), and the banner pixels sampled at (345,195)/(615,195) went from ~(90,70,94) to
~(139,96,127). **Better**, but from an almost-unusable baseline. At 4× zoom the grunt NPC is
recognizable (cap, mask eyeholes, armor) standing near a lit brazier — so detail is *recoverable*
by looking closely. **At native, unzoomed exposure it is not**: large regions of the ground and
the whole left half of the frame sample as literal (0,0,0) even in r5.
**Top defect:** Still the darkest frame in the set by a wide margin — nothing in the lower two
thirds of the frame is legible without zooming.

### 8. `10-stronghold-gate-day`
**r4→r5:** Diff mean 9.7/255 — same composition. **Same.**
**Top defect:** Zoomed inspection shows a floating dark object with yellow trim hanging in open
sky above the gate, unattached to any visible cable anchor or structure — reads as a stray prop,
not a lantern or signage. No sentry is visible at the gate; the only figure near the arch is a
low reddish box shape, ambiguous between crate and NPC.

### 9. `10-stronghold-gate-night`
**r4→r5:** Mean luma 23.2 → 33.4 (~44% brighter), matching the approach-night lift. **Better.**
Zoomed, a warm lit window is now visible on the right tower and a small sconce-like point light
sits mid-gate — the first frame in the set with a genuine "someone lives here" cue at night.
**Top defect:** Same unexplained floating object hanging in the sky as the day frame. Still no
sentry figure at the gate itself.

### 10. `11-castle-landmark-hall-100m-day`
**r4→r5:** Diff mean 16.1/255, the largest of the three distance shots, but mostly foreground
foliage/placement noise rather than a hall change. **Same.**
**Top defect:** At the closest distance, dense tree canopy in the lower half of frame covers the
base of the hall, which is backwards from what you'd want up close — the gate/door area (the
part that should read as most detailed and occupied at 100 m) is the most obscured.

### 11. `11-castle-landmark-hall-200m-day`
**r4→r5:** Diff mean 8.6/255 — same. **Same.**
This is the best-reading of the three: towers and red gate doors sit clear of foreground trees,
with a pale haze band separating the dark hall from the darker storm band above it.

### 12. `11-castle-landmark-hall-400m-day`
**r4→r5:** Diff mean 6.3/255 — same. **Same.**
Zoomed inspection shows the hall silhouette actually sits *against the pale haze strip below*
the dark cloud band, not against the band itself, so contrast holds up — small but identifiable
as a castle (turret, red banner dot) at this range.
**Top defect:** The dark cloud band above still eats roughly 40% of the vertical frame at this
distance, which is a lot of dead, flat sky for a landmark shot whose whole job is showing the
hall reads from far away.

---

## Answers to the four questions

**(A) Warrens exterior — dug earthwork, and rock family consistent with the interior at the
standing frame?**
No to both parts, on this evidence.
- It does not read as an animal-dug warren. The exterior mound is one continuous, uniformly
  brown-olive, low-poly rock sculpt with moss-texture blotches; the entrance is a flat door-frame
  slab with grass running to its edge — no spoil pile, no dirt apron, no individually
  distinguishable half-buried boulders. It reads as a rock bunker, not a burrow.
- Rock family is **not** consistent across the standing/threshold frame. Sampled pixels: exterior
  approach rock ≈ (74,61,43)/(67,56,39) — warm olive-brown; den interior wall ≈ (70,59,41)/
  (138,114,78) — warm tan, matching the exterior; but the standing/transition frame's rock ≈
  (53,59,55)/(33,37,34) — a distinctly cooler, desaturated grey with no relation to either warm
  material. The seam frame is the one place the mismatch is most visible, and it uses a third,
  unrelated material.

**(B) Does the Hall silhouette read against sky at 100/200/400 m, and is the horizon band still
dominant?**
Silhouette: yes at 200 m and 400 m (clear tower/turret shapes against a paler haze strip beneath
the dark cloud band); weaker at 100 m, where foreground trees cover the base of the hall — the
one distance where you'd expect the *most* legibility, not the least.
Horizon band: yes, still dominant, unchanged from r4 in all three shots (diffs 6–16/255, no
directed change visible). It's a flat, non-parallaxing dark band with static vertical streaks
occupying roughly a third to 40% of the sky in every day frame at this location — present at
every one of the three landmark distances and at the stronghold approach/gate day frames too, so
it reads as a skybox layer rather than weather that would thin or shift with viewing distance.

**(C) At native exposure does the courtyard night read (banners, ground, people, faces), and do
the gate/approach night frames show detail?**
Courtyard night: partially and only where light already falls. Banners: yes, now visibly red
rather than pure black (139,96,127 sampled, up from ~90,70,94 in r4). Ground: no — most of the
floor and the entire left half of frame sample as literal black (0,0,0). People: the grunt NPC is
recoverable only by zooming into the lit pocket near the brazier; at a normal glance across the
full 960×540 frame it is not distinguishable from the dark background. Faces: not readable even
zoomed — the mask/eyeholes are the only readable feature.
Gate/approach night: yes, more so than the courtyard. Both got a genuine, measured exposure lift
(≈45–55% brighter mean luma). The gate frame now shows a lit window and a sconce point-light on
close inspection — real progress — but the hall body itself is still a near-silhouette with no
other window lighting, and no sentry is visible at either distance.

**(D) Does the gate read as occupied (sentries, lit windows/sconces, banners oxblood rather than
poster red)?**
Mixed, better at night than by day. No sentry NPC is identifiable in either gate frame — the one
figure near the arch in the day shot reads as a crate, not a person. Lit windows/sconces: absent
by day (expected) but present and legible at night (one lit window, one sconce glow) — the
strongest "occupied" cue in the set. Banners: not oxblood — sampled and by eye they read as a
bright, fairly saturated red both in the gate and courtyard day frames, closer to the poster-red
end than the muted maroon of the key art's Team Tether stronghold panel. The courtyard *does*
carry a standing grunt NPC in the day frame, which is the best "occupied" evidence anywhere in
this set — it's just not at the gate itself.

---

## Ranked: the three biggest remaining gaps vs. the references

1. **The Warrens exterior is architecture, not a warren.** The key art doesn't show this location
   directly, but the design brief for it (and Palworld's own dug/rock den framing in
   `palworld-02-open-field-path.jpg`, which shows an irregular dark cave mouth in a broken rock
   embankment with visible strata) both imply an irregular, dug-looking opening. What's on
   screen is a single faceted rock sculpt with a flush architectural doorway and no spoil —
   closer to a bunker entrance than a creature's home. This is a scene/asset-placement problem,
   fixable without new art: break the monolithic rock mass into distinct boulder pieces, add a
   dirt spoil apron and displaced earth at the mouth, and irregularize the opening silhouette.

2. **Night exposure at the stronghold, especially the courtyard, still doesn't clear the bar.**
   Round 5 measurably brightened all three night frames, and the gate now shows a lit window and
   a sconce — real, verifiable progress. But the courtyard interior remains the darkest frame in
   the whole set (mean luma 8.4/255) with most of its floor area literally black. Against the key
   art's own NIGHT panel — a moonlit scene with silhouettes, firelight, and legible ground —
   this reads as under-lit rather than moody. Fixable in-scene: more/brighter point lights at
   ground level (the existing brazier proves the fixture exists), not a new asset problem.

3. **The rock material seam at the Warrens threshold, and banner hue project-wide.** The
   standing/transition frame introduces a third, colder grey rock material that belongs to
   neither the warm exterior nor the warm interior — the exact kind of "world doesn't agree with
   itself" defect the rubric flags under Colour and value structure. Related: banners at both the
   gate and courtyard read as bright poster red rather than the oxblood the reference README
   calls a reserved colour, in both day frames. Both are palette/material fixes, not new art.

## Bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No.** The key art's Meadows Hall panel is a mossy, ivy-grown ruin with oxblood banners set
into rolling green hills under a clear sky, with a soft warm haze at distance. These frames carry
the right idea (moss-textured stone, red banners, a ruined-castle-through-trees approach) but two
things break the match on sight: the dominant, static dark storm band across every day sky, which
has no analogue in the key art's clear or golden-hour skies, and the saturated poster-red banners
in place of the muted oxblood the reference explicitly calls out as a reserved colour. The
Warrens frames read even further from the board — there's no equivalent panel to compare against
directly, but the "cozy, natural, hint of mystery" note the board states in words is not what a
flush architectural door in a brown rock sculpt delivers.

**B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to be the
same kind of game?**
**No**, on the two axes the rubric says are fair to compare: how lived-in the world reads, and
whether an encounter/base location looks occupied. Palworld's shots (particularly `-04` and
`-05`) show creatures and NPCs mid-activity, dense foreground detail, and buildings that read as
inhabited at a glance. The Tetherbound stronghold frames get one genuine NPC in the courtyard day
shot and a couple of night-time light cues at the gate, but most locations here — the gate day
frame, both approach frames, all three landmark-distance frames — show an empty field/path with
no creatures, no other characters, and a landmark sitting alone in the frame. The Warrens frames
have no creature-in-habitat feeling at all outside the den (which is the one place the owner
already confirmed as good). Ground/foliage density and "does an encounter look like an event" —
the specific things the rubric says are fair Palworld comparisons — are not met by these 12
frames as a set.

What's fixable by changing the scene: sky/cloud band prominence and shape, banner hue, NPC
population density and placement (put a couple more grunts and a sentry at the gate itself, not
just the courtyard), night point-light placement and radius in the courtyard, and the Warrens
mouth's geometry/material breakup and spoil dressing. None of that needs new meshes under the
CLAUDE.md constraints — it's placement, lighting, and material work on what's already installed.

What isn't fixable this way: the creature's cel-shaded outline style sitting in a different
rendering language than the painterly environment (a stylistic mismatch inherent to the sourced
asset, not a scene setting) is a genuine art-cohesion gap that scene changes won't close.
