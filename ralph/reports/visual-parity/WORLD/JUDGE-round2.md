# Visual Judge — WORLD, Round 2

Blind pass. No code, config, diffs, or prior reports were read — judgment is from
the images only: round 2 locations (15) + survey (5) + sheets, round 1 stands (8)
+ locations (15), the VP0 baseline (9), and the reference board / Palworld shots.

## Specific defects (round 2 frames)

- **`survey/05-spawn-low-sun.png` is solid black, edge to edge.** Not underexposed,
  not silhouetted — there is no image data at all: no horizon, no sky gradient, no
  shape. Whatever else this frame was meant to show (a low-sun read), it isn't
  showing it. This is a capture/render failure, not a style judgment, and it's the
  single worst thing in the round 2 set because it's not a defect to critique, it's
  an absence of a frame.
- **`locations/01-village-grandpa-yard-day.png` and `locations/02-mill-pond-standing-day.png`
  both carry a large, perfectly flat, hard-edged white disc in the daytime sky.**
  It has no warm tint, no bloom falloff, no haze softening at its rim — it reads as
  a UI-less moon sprite left visible during the day rather than a sun. Every other
  day frame in both rounds (e.g. `01-village-approach-day.png`,
  `01-village-tournament-day.png`) has no visible sun disc at all, just directional
  light — so these two frames are inconsistent with the rest of the set, not a
  deliberate "visible sun" choice carried through consistently.
- **`survey/03-rise-overlook.png`: the far two-thirds of the frame is a near-flat
  pale green-gray field with almost no value separation from the sky band above
  it.** The village readable in the middle distance is a small pale cluster with
  no silhouette weight; the mid-ground trees are thin, spindly cone shapes that
  read as sparse pins rather than a canopy. Distance is not "hazy-but-present," it
  is close to erased.
- **`survey/02-valley-floor.png`: the cluster of small bushes running along the
  right edge of frame sits in a visibly regular, evenly-spaced row** — same scale,
  same silhouette, same interval — while the foreground planting on the left is
  varied and clustered. The two halves of the same frame disagree about whether
  scatter is authored or procedural.
- **`locations/01-village-tournament-night.png` and `01-village-twins-night.png`:
  the ground more than a few meters from the player is close to pure black**, with
  the flower/grass scatter only readable in a narrow lit wedge near the camera.
  Night silhouette-at-distance is close to nothing outside the lit windows.
- Character/creature note (rubric requires this be judged, not skipped): no
  creatures appear in any round 2 frame — every location frame is trainer +
  villagers only. The human models are consistent between round 1 and round 2 (no
  regression), stylized-anime proportioned, adequate but generic next to
  Palworld's cast — not a round 2 finding, just flagged because the rubric
  requires it and creatures are entirely absent from this evidence set, so B below
  cannot be answered on creature appeal at all this round.

## Per-axis: round 2 vs round 1, vs baseline

**Sky / clouds** — Better than round 1 stands, same as round 1 locations, same as
baseline. Round 1 stands' dawn/golden/night frames (`01-spawn-outward-dawn.png`,
`-golden.png`, `-night.png`, and all four `03-rise-overlook-*` frames) were a flat
single-hue color wash over the entire image — sky, clouds, ground, characters, all
one tint, with cloud shapes barely differentiated from sky. Round 2 has none of
that: clouds in `01-village-approach-day.png`, `01-village-twins-day.png`,
`02-mill-pond-wheel-day.png` are soft-edged, layered, and read at different
altitudes, closer to the reference board's brushy cumulus. Round 1's *locations*
set (`WORLD-coord-fast`) already had this quality, so round 2 didn't move the
needle there, it moved it against the much worse stands set.

**Sun / moon** — Worse than round 1 locations and baseline (new defect, see
above); about the same as round 1 stands, which had its own sun problem — a
blown-out, over-bloomed disc in `01-spawn-outward-golden.png` — just a different
failure mode (over-bloomed vs. no bloom at all). Night moon rendering (a flat
light disc, no phase/texture) is unchanged between round 1 and round 2 —
`01-village-tournament-night.png` (r1) and `01-village-twins-night.png` (r2) use
the same plain-disc moon. Baseline has no night frames to compare.

**Time-of-day read** — Clearly better than round 1 stands, comparable to round 1
locations. Round 1 stands could not distinguish dawn from golden hour from night
except by which flat tint was laid over everything (`01-spawn-outward-night.png`
is a blue wash, `-golden.png` a pink-white wash, `-dawn.png` a mauve wash — none
of them show a horizon glow, a warm/cool light-direction difference, or graded
sky). Round 2's night frames (`01-village-approach-night.png`,
`01-village-grandpa-yard-night.png`) show real dusk grading — dark saturated blue
overhead easing toward a lighter band near the horizon, lit windows as warm
anchors against cool ambient — which reads as an actual time of day, not a
filter. Round 1 locations already had this (its `01-village-approach-night.png`
is close in quality); round 2 does not clearly exceed it here, it just doesn't
regress from stands to locations quality.

**Distance / haze** — Same as round 1 (still weak), not comparable to baseline
(baseline has no long-distance vista frame). `survey/03-rise-overlook.png` (r2)
and `01-03-rise-overlook-day.png` (r1 stands) share the same core problem: the
far half of the frame desaturates into the sky with no clear horizon value break.
Round 2's distant trees are a modest improvement — dark green cones rather than
r1's pale cyan/white faceted blobs (see canopy axis) — but the ground plane
itself reads no better; if anything `03-rise-overlook.png` (r2) is slightly *more*
uniform/pale across the mid-ground than `03-rise-overlook-day.png` (r1), which at
least had a visible dirt path and darker hillside shading breaking up the green.

**Ground cover** — Same as round 1 and baseline in the frames that are
comparable (dense, varied flower/grass clustering around the village paths in
`01-village-grandpa-yard-day.png` and `01-village-twins-day.png` matches the
baseline's equivalent frames closely — same asset, same density, same
clustering-not-grid look). The one new axis-relevant issue is the regular bush
row in `02-valley-floor.png` noted above, which has no round 1 or baseline
equivalent frame to compare against (round 1's 8-frame stand set didn't cover
this location), so it can't be called a regression — only a defect on its own
terms.

**Tree canopy colour / silhouette** — The clearest, largest improvement round 2
makes. Round 1 had a recurring, severe canopy failure: trees rendering as
pale mint/cyan, faceted, shattered-glass-looking polygon fans with visible gaps
between "leaf" quads, both at distance (all four `03-rise-overlook-*` frames) and
disturbingly at night close to camera (`01-village-approach-night.png`, r1 —
top-right tree is a glowing cyan crystalline mess) and even in a *daytime*
mid-shot in the background of `01-village-grandpa-yard-day.png` (r1 locations —
the tree cluster past the fence on the right is flat pale-mint blobs, not shaded
canopy). Round 2 does not show this failure in any frame reviewed: the
equivalent tree in `01-village-approach-day.png` (r2, same top-right position) is
a properly shaded rounded canopy with light-top/dark-underside value structure;
`01-village-approach-night.png` (r2) shows the same tree as a clean dark
silhouette, no shard artifact; `02-mill-pond-approach-day.png` (r2) is full of
multi-tone, well-lit canopy that is the best single canopy shot in either round
and holds up reasonably against the reference board's grove panel. This is a real
fix, not just a different camera angle avoiding the problem — the same framing
(`01-village-approach-day/night`, `01-village-grandpa-yard-day`) was used in both
rounds and the artifact is simply gone in round 2.

**Overall colour / value** — Better than round 1 stands, comparable to round 1
locations and baseline for day frames. Round 2 day frames carry the saturated
green/blue/terracotta palette the keyart establishes without round 1 stands' wash
problem. Round 2 night frames have a believable value range (dark ground, mid
blue sky, warm window highlights) that round 1 stands' night frame
(`01-spawn-outward-night.png`) did not — that frame was near-uniformly dark with
little to separate ground from sky from character silhouette.

**Composition** — Comparable across all three sets for the frames that share a
location (village/mill-pond stands use the same camera placements as baseline and
read the same way: subject slightly off-center, a tree or building anchoring one
side). The compositional casualty is entirely round 1's, not round 2's: r1
locations' `02-mill-pond-approach-day.png` is not a landscape shot at all — it's
a broken white-clipping mess (camera stuck inside foliage/geometry, mostly
illegible pale polygon shapes) and r1 locations' `01-village-twins-day.png` shows
the same white-geometry-clip failure. Round 2's equivalent frames
(`02-mill-pond-approach-day.png`, `01-village-twins-day.png`) are both clean,
legible, well-composed shots — a large fix, though it corrects a broken capture
rather than improving a working one, so it's better described as "no longer
broken" than "better composed."

## The three biggest gaps vs. the references, ranked

1. **Distance still doesn't hold up against the reference's readable-from-afar
   landmark language.** The keyart board's sunset panel and mountain panels keep
   a legible horizon, a colored value band, and a landmark silhouette (standing
   stone, distant peak) visible through the haze. `survey/03-rise-overlook.png`
   gives up that legibility a few hundred meters out — the village becomes a pale
   smear with no silhouette weight, and the terrain past the foreground rise loses
   almost all value contrast against the sky. Palworld's `palworld-04-plateau-landmark.jpg`
   keeps its distant plateau readable at a comparable distance; this frame does
   not do the equivalent for the Meadows' hills.
2. **The day-sky white disc is a visible bug sitting in what should be a clean,
   confident daylight shot.** `01-village-grandpa-yard-day.png` and
   `02-mill-pond-standing-day.png` are otherwise two of the stronger frames in the
   set — good canopy, good structure readability, good ground cover — undercut by
   a flat cutout-looking circle in the sky that neither the keyart nor any
   Palworld reference shows. It reads as an artifact, not art direction, and it's
   the kind of thing that's instantly visible even at thumbnail size.
3. **Night ground falls to near-black past the lit radius, losing the "cozy but
   with hints of mystery" read the design notes ask for.** The keyart's night
   panel keeps grass, hillside, and the distant stronghold's glow all visible
   under moonlight — mysterious, not opaque. `01-village-tournament-night.png` and
   `01-village-twins-night.png` lose almost everything past the immediate lit
   windows to pure black, which reads as underlit rather than nocturnal.

## Fixable-by-scene vs. needs-new-art

**Fixable by changing the scene** (lighting, exposure, fog, scatter density,
camera/capture — no new assets required):
- The day-sky white disc (`01-village-grandpa-yard-day.png`,
  `02-mill-pond-standing-day.png`) — a light/sky-shader or moon-visibility-at-day
  setting, not a modeling problem.
- The black `survey/05-spawn-low-sun.png` frame — almost certainly a capture or
  exposure/lighting-setup failure for that specific sun angle, re-run and inspect
  rather than treat as art direction.
- Night ambient floor being too dark past the lit radius
  (`01-village-tournament-night.png`, `01-village-twins-night.png`) — a moonlight
  ambient/fill value, not new geometry.
- Distance haze/value flattening on `survey/03-rise-overlook.png` — fog color,
  distance fog density curve, or ground-shader far-value grading; the geometry
  and scatter density already exist, they're just losing contrast at range.
- The regular bush row on the right of `survey/02-valley-floor.png` — a
  placement/scatter-seed fix, not a new prop.

**Not fixable without new art, based on what's visible in this set:**
- Nothing in round 2's actual frames points to a needs-new-art gap the way round
  1's shattered-canopy trees did — that failure is gone in round 2's equivalent
  shots. The remaining gaps above are all lighting/scene/capture issues on
  existing assets, not asset-quality shortfalls. The one caveat is character/
  creature appeal against the Palworld bar, which this round's frames cannot
  speak to either way since no creature appears in any of them — that comparison
  still needs a set that includes creatures in frame.

## Bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?**

**Yes**, for the day frames — timber-frame village silhouettes, terracotta roofs,
saturated green/blue palette, and (in `02-mill-pond-approach-day.png` especially)
canopy quality that would sit reasonably next to the keyart's grove panel.
Weaker but still a yes for night, once past the near-black ground-falloff issue —
the moonlit-blue grading and warm window glow are the right idea even where the
midground goes too dark. The one place this answer strains is
`survey/03-rise-overlook.png`, whose washed-out distance would look out of place
stitched next to the keyart's sunset/mountain panels, which keep depth legible at
a comparable range.

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone
say these are trying to be the same kind of game?**

**Yes, on environment** — ground/foliage density, building silhouette language,
and color saturation in the village frames are in the same register as
`palworld-02-open-field-path.jpg` and `palworld-05-base-building.jpg`. **Cannot
be answered on the creature/character axis this round** — Palworld's screenshots
are built around pals and combat, and every Palworld reference frame has at least
one creature in it; none of these 20 frames do. A same-kind-of-game verdict that
only covers empty environments, with the thing the game is named after absent
from the evidence, is an incomplete yes.

## What carried it / what sank it

Round 2's canopy fix and the resolution of round 1's white-clipping-geometry and
flat-color-wash failures carried this round — those were the loudest, most
"looks broken" problems in round 1 and none of them reappear here. What holds
the round back from a clean pass is a short, genuinely fixable list: one solid-
black frame, one recurring day-sky artifact, night ground going too dark past the
lit radius, and distance still losing the plot on `03-rise-overlook.png`. None of
these need new art — they're lighting, fog, and capture fixes on assets that are
already doing their job elsewhere in the same set.
