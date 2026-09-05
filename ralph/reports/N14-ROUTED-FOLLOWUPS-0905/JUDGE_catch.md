# Blind visual judgement — catch / seal event (A vs B)

Inputs: `ralph/reports/N14-ROUTED-FOLLOWUPS-0905/_sheet_catch_ab.png` (1240x734, four
tiles), plus `shots/n14/catch_final/04a-catch-seal-clean.png` and
`04-catch-success-clean.png` (both 1280x720 RGBA).

## 0. Method notes and one thing you need to know before reading section 2

**Tile geometry.** Header bars occupy rows 0-17 and 367-384. Row A images are
y 18-366, row B images y 385-733; the column split is x 620. Each tile is
620x349. I verified that the two B tiles are *bit-exact* LANCZOS downscales of
the two supplied full-resolution files (mean absolute difference 0.000, max
difference 0 over all three channels). The A tiles exist only at 620x349.

**A and B are not the same camera.** This is measurable and it matters:

| measurement | row A | row B |
|---|---|---|
| orb centre (tile coords, seal) | (263, 224) | (313, 232) |
| creature's teal eye centroid (tile) | (229, 18), 53 px, fully inside | (218, 3), 22 px, **bbox touches y=0 — clipped by the top frame edge** |
| screen slope of the one long ground-plane straight edge | -0.0745 | -0.0858 |
| distant terrain above the creature's shoulder | visible (dirt patch, props) | absent |
| median frame luminance (seal) | 80 | 58 |

Exposure and tonemapping are *identical* between rows, so the differences are
camera + effect, not grade: creature fur median RGB is (231,224,177) in
seal/A, seal/B and success/A and (231,227,187) in success/B; unlit
bottom-right-corner grass is (48,67,0) in A and (50,62,0) in B.

Because the camera moved, I measure the effect in **units of orb radius**
(orb radius is within 6% between rows: 46.5 px tile in seal/A vs 44.0 in
seal/B) and normalise against the identical base-grass value. Those numbers
are camera-independent. Anything that depends on framing I have called out as
framing.

---

## 1. What is wrong with this event as drawn — ranked, worst first

### 1. In row A the orb has effectively no silhouette. It is a dull hole in its own glow.

Measured around the orb's perimeter, sampling luminance at 0.90x and 1.20x the
orb radius every 5 degrees (72 samples), median absolute Michelson contrast:

| tile | median edge contrast | % of perimeter below 0.05 (invisible) | median L inside | median L outside |
|---|---|---|---|---|
| seal / A | **0.071** | **44%** | 147 | 166 |
| success / A | **0.088** | **39%** | 137 | 150 |
| seal / B | 0.367 | 6% | 176 | 77 |
| success / B | 0.410 | 21% | 221 | 71 |

In row A the orb is *darker* than the ground it sits on (147 vs 166; 137 vs
150). Nearly half its outline has no contrast at all. Radial profiles confirm
it: in seal/A the ground at 1.05-1.6 orb radii sits at L 165-168 while the orb
core is L 176 — an 11-level difference. In success/A the orb core (L 156) is
*darker* than the ring of ground around it (L 159). The object the whole
moment is about is the least contrasty thing near it.

Cause is visible: the ground bloom is brighter than the prop it is supposed to
be lighting. Normalised against the same base grass (L≈38 in both rows), the
glow in row A lifts the ground to **2.15x base at 3.4-4.5 orb radii**; in row
B, **1.26x**. Row A's wash reaches roughly 2.7x further in energy.

Fix is not "add a dark ring". Fix is: cap the ground bloom so its peak is
below the orb's own albedo, and put the brightest value in the frame *on the
orb* (a hot core, a rim, a specular), not on the grass around it.

### 2. There is one long, perfectly straight, unfeathered edge across the ground. It reads as a polygon border, i.e. as a bug.

Full detail in section 3. It is the single longest continuous straight edge in
either frame, longer and in places higher-gradient than the orb's own
silhouette, and it sits ~40 px below the orb, cutting straight through the
event.

### 3. The composition sends the eye to the opposite corner from the subject.

Centroid of the brightest 2% of pixels, and how much of it lands on the orb:

| tile | brightest-2% centroid (of 620x349) | % of that mass in the left 40% of frame | % of it on the orb |
|---|---|---|---|
| seal / A | (144, 90) | 93% | 0.4% |
| success / A | (133, 81) | 94% | 0.8% |
| seal / B | (145, 81) | 93% | 0.4% |
| success / B | (147, 83) | 92% | 0.9% |

In every tile, 92-94% of the frame's brightest mass is the creature's
cream/white shoulder plates and chest in the upper-left, and under 1% is on
the orb, which sits at 50% x / 67% y (row B) or 42-44% x / 64-66% y (row A).
Eye goes upper-left; subject is lower-centre.

Worse, that upper-left mass is **flat**: 5.1-5.2% of the frame has all three
channels at or above 228, and the red histogram has a 57,000-pixel spike at
exactly R=231 (6.2% of the frame in one bucket), with the frame maximum at
(242,232,231). So the loudest region of the picture is a texture-less white
slab, and it is not the orb.

### 4. Row B's dark ellipse reads as a scorch decal, not as light or shadow.

Row B places a dark elliptical ring on the grass concentric with the orb.
Radial luminance profile (seal/B), in orb radii: 1.0 → 131, 1.1 → 92,
1.3 → 69, 1.4 → 67, 1.6 → 87, 1.9 → 118. Success/B: 1.0 → 220, 1.2 → 72,
1.3 → 72, 1.5 → 124. So a trough ~45% below the surrounding ground, minimum at
1.3-1.4 orb radii, recovering by ~1.9 radii — an ellipse roughly 350 px across
in a frame where the orb is 182 px across, i.e. **1.9x the orb's diameter and
27% of the frame width**.

Its outer edge is a soft gradient (no signature at all in the gradient map),
so it is not an aliasing fault. But it is concentric and directionless: the
key light in this scene comes from upper-left (fur highlights sit on the upper
and left surfaces), and a real contact shadow would be offset down-right and
would tighten under the object, not ring it symmetrically at twice its width.
As drawn it reads as burnt grass or an over-sized ambient-occlusion blob. It
buys the legibility in row B (see section 2), but by the crudest available
means.

### 5. Grass geometry runs across the orb's face, and in success/A appears to sprout from it.

In `04-catch-success-clean.png` at least four blades are drawn over the white
dome between roughly (560,380) and (700,560). In success/A the effect is worse:
several blades converge on a single point on the dome's face at approximately
tile (300,240), so they read as hairs growing out of the orb rather than as
foreground grass. Nothing displaces, flattens or fades the grass where a solid
object has just landed in it. The orb reads half-buried.

### 6. The ground is blue-clipped, so the palette has nowhere to go.

| frame | fraction of frame with B channel exactly 0 | green-dominant pixels with B=0 | median B of green-dominant pixels |
|---|---|---|---|
| seal / B (1280x720) | **46.4%** | 75.6% | **0** |
| success / B (1280x720) | **51.8%** | 79.4% | **0** |
| `palworld-02-open-field-path.jpg` | — | 0.30% | 60 |
| `palworld-03-field-boss-meadow.jpg` | — | 0.01% | 80 |

Roughly half of these frames is grass with literally zero blue. The reference
the project set has essentially none of that, and the keyart's own swatch strip
carries cool greens and blue-greys. Zero-blue grass is why the shadow side goes
poster-flat olive and why the dark ring reads as soot rather than shade: there is
no colour left underneath it to darken into.

### 7. The orb itself does not read as a sphere or as a sealed container.

At 6x magnification the seal state is a flat tan disc with a concentric grey
core inside a pale flange — reads as a plate, a lens cap or a mushroom, not a
sphere with a lid. There is no specular highlight anywhere on it, no rim light,
no seam or catch line, and the terminator is flat. The success state is a plain
white dome with one tan band; it also carries no highlight. Nothing in the two
frames says "shut" or "sealed" — the difference between the two moments is
read purely as "yellow becomes white".

Minor supporting artefact: faint radial facet lines are visible on the seal
disc (a triangle-fan / low-segment cylinder), measured angular ripple rms 2.1 L,
peak-to-peak 12 L over a circular sample at 0.6-0.75 orb radii. Low amplitude,
but visible in the gradient map as ~8 spokes.

### 8. Large soft warm blobs and one stretched streak read as dirt on the lens.

Row B carries several soft warm discs of 60-90 px diameter (5-7% of frame
width) floating over the grass — e.g. `04a-catch-seal-clean.png` near (790,200),
(830,430), (1245,110). They are strongly out of focus while the whole rest of
the frame is sharp, and grass blades draw over them, so they sit in world space
just above the ground with nothing to explain them. In **success/A** there is
additionally a comet-shaped smear with a bright rounded head, tile extent
roughly x 380-445, y 143-172 (≈130x60 px at 720p), lying well away from the
orb; it reads as a stretched billboard rather than a mote. Row B has no such
streak.

### 9. Nothing grounds the orb.

There is no tight contact shadow under the orb in either row — row A has none
at all (radial profile is monotonically brighter toward the orb), and row B
substitutes the oversized ellipse of defect 4. In row A the orb consequently
floats: a grey disc lying on a lighter ground with no darkening anywhere along
its base.

### 10. The bloom flattens the ground texture it lands on.

Local contrast (median |L − 9px box blur|) relative to local luminance:
seal/A near-glow 5.27/135 = 3.9% versus far ground 5.70/51 = 11.2%; seal/B
4.16/99 = 4.2% versus 3.89/43 = 9.0%. Both rows lose about two thirds of the
grass's relative texture modulation inside the glow, and the hue flips from
green-dominant (48,67,0) to red-dominant (172,158,44). The effect erases the
ground it is standing on.

---

## 2. A vs B

**Yes — the difference is large, obvious, and measurable. It is not a null result.**

Two things changed, and they pull in opposite directions.

**(a) The effect. B is decisively better and I would ship B's effect.**

Row B introduces a dark elliptical ring on the ground (trough at 1.3-1.4 orb
radii, L 67-72 in seal/B, 72-99 in success/B) that row A does not have at all
(A's ground at the same radii sits at L 165-168 and 151-162 — *brighter* than
the orb). Row B also reins in the ground bloom by roughly a factor of 2.7 in
reach (ground at 3.4-4.5 orb radii: 2.15x base grass in A, 1.26x in B).

The consequence, measured on the orb's perimeter:

| | seal | success |
|---|---|---|
| row A median edge contrast | 0.071 | 0.088 |
| row B median edge contrast | **0.367** | **0.410** |
| row A perimeter with contrast < 0.05 | 44% | 39% |
| row B perimeter with contrast < 0.05 | 6% | 21% |

That is a 4-5x improvement in the legibility of the one object the shot is
about. Downscaled to 30% (186x105) the difference is unmistakable by eye: in
row A the orb is a grey-tan smudge easily mistaken for a rock; in row B it
reads as a distinct disc/dome with a defined rim.

**(b) The camera. A is better and I would keep A's framing.**

Row B's camera sits lower and closer. The creature's eye moves from tile
(229,18) — fully inside frame, 53 px of teal — to (218,3), with its bounding
box reaching y=0, i.e. **clipped by the top edge of the frame**. All background
depth cues visible in row A (distant dirt patch and props above the creature's
shoulder) are gone in B, so B's backdrop is an unbroken grass field. And B
centres the orb at 50.9% of frame width — dead centre horizontally — against
A's 42.4%.

**Ship: B's effect, A's camera.** If forced to pick a row as-is, ship **B**,
because a legible subject beats a legible background: an event frame where the
orb cannot be found has failed at the only thing it has to do. But B is not
"the fix" — it is the right direction achieved with a scorch-ring decal, and
it costs the creature's face. The combination worth building is B's contrast
discipline (bloom capped below the orb's albedo) with A's camera, and the dark
ring replaced by a directional contact shadow plus a hot core on the orb
itself.

**What did *not* change:** exposure and tonemapping (fur median RGB identical
to the unit in three of four tiles), the blue-clipped ground palette, the
hard-edged ground quad (present in all four tiles), the grass-over-orb
intersection, and the fact that 92-94% of the frame's brightest mass is on the
creature and under 1% is on the orb. Those defects are common to both rows.

---

## 3. The hard straight edge that ought to be a soft gradient

**Yes. One, and it is in all four tiles — both rows, both columns.**

**What it is:** the near border of a large translucent ground-hugging quad that
carries the warm ground wash. Above the line the ground is washed warm and
bright; below it, untouched grass. The transition is a polygon border with no
feathering.

**Row B** (measured natively at 1280x720, both `04a-catch-seal-clean.png` and
`04-catch-success-clean.png`, which agree to within a pixel):

- Line fit: **y = 683.6 − 0.0871·x**, i.e. 4.98 degrees off horizontal.
- RMS residual **2.1 px** over 114 samples spanning x = 250-1010. It is
  geometrically straight, not a curve.
- Traceable extent **x ≈ 250 → 1010** (760 px, **59% of frame width**);
  the section carrying a step larger than 10 L runs **x ≈ 450 → 880**,
  i.e. from about **(450, 644) to (880, 607)**.
- At frame centre (x=640) it sits at **y ≈ 628**, 87% of the way down the
  frame and about 43 px below the bottom of the orb.
- Sharpness, seal/B at x=700 (5-px horizontal average):
  y619 (131,126,21) → y620 (77,85,3) → **y621 (56,70,0)**.
  A 57-level luminance drop across **two pixel rows**, one of which is a single
  intermediate anti-aliasing value. Success/B at the same x: 131 → 85 → 67.

**Row A** (only available at 620x349; figures below in tile pixels, with the
1280-wide equivalent in brackets):

- Line fit: **y = 320.9 − 0.0745·x** in seal/A, **y = 320.7 − 0.0766·x** in
  success/A. [1280-wide equivalent: y ≈ 662.5 − 0.0745·x]
- RMS residual 2.25 px (seal/A) and 2.91 px (success/A) over 114 samples,
  x = 30-600 [x ≈ 62-1240].
- **Row A's version of the edge is far more violent.** seal/A at x=260 [537]:
  y301 (183,163,37) → y302 (71,75,4) → **y303 (29,42,0)**. That is a
  **154-level luminance drop across two rows of a 349-row image**, which is a
  60%-of-full-range step and would be about 4 rows at 720p. At x=340 [702] the
  step is 145 levels: (228,213,102) → (180,175,66) → (83,99,7). Across the
  whole line the median step in seal/A is −28.8 L versus −5.8 L in seal/B, and
  the median colour above versus below the line is (109,106,8) versus (59,72,0)
  in A but only (77,85,1) versus (72,82,0) in B.

**Which row it appears in:** both. It is present and geometrically identical in
kind in seal/A, success/A, seal/B and success/B. It is **worst in seal/A**,
where the quad's interior is a bright yellow slab and its border reads
unmistakably as the edge of a rectangle lying on the grass.

**Verified as the only such edge.** A line search over slope −0.35 to +0.35 and
all intercepts, on median-filtered frames restricted to the ground right of the
creature, returns this line as the only strong straight step in either B frame
(next-strongest candidates are the same line re-detected at ±0.02 slope). The
gradient map of `04a-catch-seal-clean.png` confirms it visually: one long bright
straight line from about (330,655) to (1080,590), and nothing else straight in
the frame that is not creature geometry or the orb's own circular silhouette.

**What is *not* a hard edge**, for completeness, since it might look like one:
the dark ellipse in row B has a genuinely soft outer falloff (recovers over
~0.5 orb radii ≈ 22 px, no gradient-map signature), and the pale radial "spike"
slivers under the orb ramp over 6-20 px at only 20-35 L above background. Those
are soft. The quad border is the only unfeathered straight boundary.

**Fix:** feather the quad — a radial or distance-based alpha falloff on the
decal, or a soft-particle depth fade — so its extent is defined by falloff
rather than by where the polygon happens to stop. As drawn, the shape of the
lighting is the shape of a mesh, and a viewer sees the mesh.

---

## Appendix — the two bar questions

The skill's gate asks these against `docs/reference/`. These are close-up VFX
frames rather than survey frames, so several rubric criteria (horizon, depth,
landmark language, scale against the 1.80 m trainer, who is not present) cannot
be judged here. On what *is* visible:

**A. Do these read as belonging to the world in
`tetherbound-meadows-keyart.png`?** **No.** The keyart's meadow is a
mid-green with cool, blue-carrying shadows and a full value range from sky to
shade. These frames are 46-52% zero-blue: the grass has no blue channel at all
over half the image, which collapses the shadow side to flat olive and pushes
the lit side to a yellow-orange the board's swatch strip does not contain. The
creature reads as belonging (its palette and cel-shaped forms are close to the
board's creature silhouettes); the ground does not.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be
the same kind of game?** **Yes, but weakly, and the VFX is what weakens it.**
The creature holds up: bespoke-looking, expressive, cleanly shaded, correct
family. What does not hold up is the event: Palworld's ground is dense, layered
and colour-varied where this is a single grass blade type scattered evenly at
one height over a flat texture, and Palworld's capture and combat effects have
shaped, feathered, directional forms where this one has a visible quad edge, a
concentric soot ellipse, and a subject with 0.07 edge contrast in row A.

**Fixable by changing the scene:** the bloom ceiling (defect 1), the quad
feathering (2), the framing and where the brightest value sits (3), the shadow
shape and offset (4), grass displacement or fade around the orb (5), the
blue floor in the grass shader and lighting (6), and the stray sprites (8).
That is most of the list.

**Not fixable without new art:** the orb asset itself (defect 7). No amount of
lighting will make a flat disc with no specular and no seam read as a sealed
container. That needs a mesh and a material with a highlight, a rim and a
visible closure line.
