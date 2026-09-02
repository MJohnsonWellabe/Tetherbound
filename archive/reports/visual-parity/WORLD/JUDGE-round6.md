# WORLD visual-parity — round 6 judge report

Blind review. No code, diffs, or change history was read — only the rubric
(`.claude/skills/visual-judge/SKILL.md`), the references
(`docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`,
`site/img/page-board.jpg`), and the frames themselves.

- **BEFORE** = `ralph/reports/visual-parity/WORLD/round4/stands/*.png`
- **AFTER** = `ralph/reports/visual-parity/WORLD/round6/stands/*.png` (9 stands;
  contact sheet `round6/_sheet_stands_fixed.png`)

## Per-stand findings

### 01-spawn-outward-day
No meaningful change from round4 — this stand was never washed. Reads fine:
legible grass, fenced garden plot, two NPC silhouettes readable against sky,
soft cast shadows placing both figures on the ground. Distance is short in
this composition so it doesn't test depth. **Top remaining defect:** ground
is a single flat mid-green with almost no texture/prop density close to
camera — noticeably emptier than any Palworld reference at the same framing.

### 01-spawn-outward-golden
Unchanged from round4. Warm lighting on grass and fence reads correctly, cast
shadows are long and warm-tinted (good). **Top remaining defect:** the sun is
still a large, vertically-stretched, fully blown-out **white oval**, clipped
by the top frame edge — not a disc, no visible limb/edge, no colour (should
be warm gold/orange at this altitude). Identical defect to round4; this stand
was not part of the fix.

### 01-spawn-outward-dawn
Unchanged from round4. Sky is a plausible cool lavender-grey pre-dawn tone,
ground and figures are underexposed toward silhouette, which is a reasonable
dawn read at ground level. **Top remaining defect:** no warmth anywhere in
the frame — a dawn key light usually leaks at least a rim of warm tone onto
upper grass/fence tips even before sunrise; here it's uniformly cool-grey,
so it's hard to distinguish from an overcast dusk.

### 01-spawn-outward-night
Unchanged from round4, and this is the strongest night frame in the set:
deep navy sky with visible cloud silhouettes sits clearly above near-black
grass and legible dark silhouettes of the two NPCs and the rock. Ground and
sky are tonally separated — this is what "night ground reads while sky stays
dark" should look like. No defect worth flagging beyond generally low
geometric density.

### 03-rise-overlook-dawn — RED WASH REMOVED
**Before:** solid, flat maroon-red monochrome over the entire frame — sky,
haze band, and ground all one hue, no legible dawn character at all.
**After:** the solid wash is gone. The frame now shows a lavender-grey sky
over a warm tan/beige hazy plain, with the distant village and plateau
landmark faintly visible through the haze. This is a real improvement — it
now reads as a hazy morning rather than a colour-grade error.
**But it does not read as a pink-gold dawn.** Compared to the keyart's own
dawn/sunset panel (the standing-stone overlook, vivid saturated orange-pink
sky with a warm-lit foreground), this frame is desaturated dust-brown with a
cool grey sky cap — closer to a dust storm or overcast haze than a sunrise.
**Top remaining defect:** missing colour temperature contrast (no pink/orange
in the sky) — the wash is gone but the "dawn" hasn't been repainted in behind
it.

### 03-rise-overlook-day
Unchanged in character from round4 (both look near-identical; this stand was
not part of the fix and didn't need it). Sky is blue with soft clouds, ground
has a workable near/far separation — foreground rocks and moss are darker and
more saturated, the plain lightens and greys out toward the horizon, the
distant plateau and village cluster (visible red roofs) are legible landmarks
at range. This is the best-reading of the six overlook/moon frames and the
closest any AFTER frame gets to the keyart's "landmarks visible from
distance" note. **Top remaining defect:** the mid-ground is a single flat
olive tone with no grass/tree scatter — depth comes entirely from fog
lightening, not from any density gradient, so it still reads thinner than the
keyart or Palworld equivalents.

### 03-rise-overlook-golden
**Before:** same solid maroon-red wash as the dawn stand.
**After:** wash removed; now a warm tan/brown haze under a pale sky, with the
oversized white sun-oval (same shape defect as the spawn-outward-golden
stand) low over the horizon. There is a value gradient (dark foreground
rocks, lighter hazy midground) but almost no colour-temperature gradient —
the whole ground is one brown, not a near-warm/far-cool split.
**Top remaining defect:** same sun problem as above — a blown white oval, not
a golden disc — plus a ground colour that reads as dust/dirt rather than the
gold-lit meadow grass the keyart's low-sun panels show.

### 03-rise-overlook-night — RED WASH REMOVED, PARTIAL FIX
**Before:** solid saturated blue wash, comparable in severity to the red wash
elsewhere — no separable sky/ground read.
**After:** genuinely cooler and darker — a navy sky sits over a blue-grey
foggy plain, and a small cluster of warm orange lights is now visible at the
distant village (a nice touch that echoes the keyart's night panel, which
uses exactly this warm-light-in-the-dark accent).
**However, two problems remain:**
1. The ground fog and the sky are close to the same value and hue — unlike
   the spawn-outward-night stand, there isn't a strong dark-ground /
   lighter-sky (or vice versa) split, so the frame reads as one uniform
   dark-blue haze rather than a place with a horizon.
2. There is a hard **black horizontal band** running the width of the frame
   right at the horizon line, with no gradient into it — reads as a
   render/fog-plane seam, not a horizon. This is a bug-shaped artefact, not a
   lighting choice.

### 06-moon-stand-night — RED WASH REMOVED, CLEAR WIN
**Before:** solid dark-maroon wash; the moon itself was rendered as a barely-
lighter pink disc with almost no separation from the sky around it —
essentially unreadable as "night."
**After:** this is the single best fix in the set. The sky is a convincing
deep navy blue with legible drifting cloud silhouettes, and the moon reads as
an actual **disc** with a soft, contained glow — not an oversized blob. This
is the one frame in the round that would not look out of place near the
keyart's night panel.
**Top remaining defect:** the same hard black horizon seam seen in
03-rise-overlook-night appears here too, and everything below it is a flat,
textureless dark plane — fine for a sky-focused moon shot, but worth fixing
before this seam shows up in a frame where the ground matters.

## Ranked: three biggest remaining gaps vs. the keyart panels (sky/light)

1. **The low sun is still an oversized blown-out white oval, not a disc.**
   Present, unchanged, in both spawn-outward-golden and rise-overlook-golden
   in round6 — this was not touched by the red-wash fix. The keyart's
   sunset panel shows a compact warm orange orb with a soft graduated glow;
   these frames show a clipped, colourless highlight shape roughly the width
   of a house at this distance. This is the most visually loud remaining
   defect because a sun this shape reads as a bug on sight, the same way the
   red wash did.

2. **Dawn/golden colour is desaturated dust-brown, not the keyart's
   pink-gold.** The red wash is gone, but nothing warm or saturated was put
   back in its place — 03-rise-overlook-dawn and 03-rise-overlook-golden are
   both a flat tan/beige-brown across the whole ground with a cool grey sky
   cap. The keyart's equivalent panel is a saturated orange-to-pink gradient
   sky with the landscape lit warm all the way to the foreground stone. The
   fix removed the defect but has not yet delivered the target mood — these
   frames currently read as an overcast haze, which is a different (and less
   inviting) read than either "dawn" or "golden hour."

3. **A hard black seam sits at the horizon in both night frames
   (03-rise-overlook-night, 06-moon-stand-night), and the overlook's ground
   fog is nearly the same value as its sky.** The keyart's night panel keeps
   a clear line between a dark sky (with visible moon/stars) and a still-
   legible, if dim, ground with a warm accent light in the distance. The
   moon-stand nails the sky half of that; the overlook doesn't nail the
   ground half — the plain is too uniform and too close in tone to the sky
   above it, and the seam between them looks like a fog-plane clipping bug
   rather than a horizon.

## Sub-question answers

1. **Is the red wash gone at dawn/night overlook and the moon stand — do
   they now read as pink-gold dawn and cool blue night with a legible
   horizon?** The wash is gone at all three. Night: yes, both read as cool
   blue now — the moon stand cleanly, the overlook more weakly (ground and
   sky too close in value) and both carry a black-seam horizon artefact.
   Dawn: no — it reads as a desaturated tan/dust haze under a cool grey sky,
   not pink-gold.
2. **The low golden/dawn sun: oval/halo or disc?** Still an oversized,
   vertically-stretched, blown-out white oval/halo in every golden frame
   (spawn-outward-golden and rise-overlook-golden, both rounds). Unaddressed
   by this fix. The moon, by contrast, now renders as a proper disc — so the
   technique exists in the build, it just isn't being applied to the sun.
3. **Does distance separate (near warm / far cool / haze) at the overlook by
   day, golden, night?** Day: weakly yes — foreground darker/more saturated,
   distance lighter and hazier, landmark still legible. Golden: no — one flat
   brown value from near to far, separation is fog-density only, not colour
   temperature. Night: no — ground and sky converge to nearly the same
   blue-grey with little value spread.
4. **Does night ground read while the sky stays dark?** At ground level
   (01-spawn-outward-night) yes, clearly — this is the model to match. At
   distance (03-rise-overlook-night, 06-moon-stand-night) no — the ground
   plane is a flat, low-contrast haze that doesn't separate from the sky
   except at the artefact seam.

## Bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?** **No.** The landmark
language matches (rolling hills, a standing-stone/plateau overlook, a small
village with red roofs, a moonlit night with distant warm windows), and the
red-wash bug that would have made this an automatic no is fixed. But the
keyart's identity is built on saturated, richly graded colour at every time
of day — the dawn/golden panels are vividly pink-orange, the day panels are
deeply saturated blue-and-green, the night panel is a rich cobalt with warm
firelight accents. These AFTER frames, once you remove the wash, are mostly
desaturated tan, olive, and grey-blue. The composition and landmarks say
"this world"; the palette says "not yet."

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would
someone say these are trying to be the same kind of game?** **No.** Palworld's
references are dense in every frame — thick grass carpeting the ground,
scattered trees and rock clusters at multiple depths, creatures and
characters filling a third or more of the frame, strong saturated colour even
in an overcast shot. These WORLD stands, especially the three overlook and
the moon frame, are large stretches of near-empty rolling terrain with a
single flat ground tone and no creatures or characters in view at range. The
gap here is density and population of the frame, not the sky-fix that this
round targeted.

## What's fixable by changing the scene vs. what needs new art/assets

**Fixable by scene/lighting work (no new art required):**
- The sun's oval/blown-white shape — the moon in this same build already
  renders as a clean disc with a contained glow, so the same shader/billboard
  approach almost certainly applies directly to the sun.
- The horizon seam/black band at the overlook and moon stand — reads as a
  fog-plane or skybox clipping issue, fixable in the fog/sky setup.
- Dawn/golden desaturation — a colour-grade / sky-gradient and directional-
  light-colour pass at those times of day, the same category of fix that
  already worked for the moon-stand night sky.
- Overlook night ground-vs-sky value separation — a lighting/ambient tuning
  problem, same family as the above.

**Likely needs asset/content work, not just scene tuning:**
- Frame density at the overlook stands (near-empty rolling plain vs.
  Palworld's dense, layered terrain) — this is a scatter/prop-density and
  vegetation-variety gap, which is scene-buildable but is content work
  (placing and varying assets across the whole visible plain), not a
  one-line lighting fix.
- Creature/character presence in the WORLD stands relative to Palworld's
  frames — outside this round's scope (these are empty-world survey shots by
  design) but relevant to the bar-B "same kind of game" question; closing it
  needs frames that actually include creatures, not just terrain.
