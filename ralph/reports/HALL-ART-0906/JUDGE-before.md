# Blind visual judge — `shots/hall_before/` (3 night interiors, 1280x720)

Frames judged: `_sheet.png`, `T-01-approach-room.png`, `T-02-warden-arena.png`,
`T-03-legendary-side-wall.png`.
References: `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-01..05*.jpg`.

All luma figures are Rec.709 Y on 0–255. All coordinates are pixel coordinates in the
named 1280x720 frame, origin top-left. Every number below is re-measurable.

---

## 0. Calibration used throughout

The two cyan wall strips in **T-01** fit `y = 0.3482x + 136.7` (left, x 0–398) and
`y = -0.3490x + 582.7` (right, x 881–1279). They intersect at **(639.7, 359.4)**, so the
camera has no roll and no pitch and row **y = 359.4 is the eye-height horizon**.

The humanoid in T-01 spans **x 542–567, y 355–433** (78 px tall). Taking it as the 1.80 m
trainer-scale humanoid the rubric names, camera eye height = 1.80 × (433 − 359.4) / 78 =
**1.70 m**. For anything standing on the floor:
`H = 1.70 × (y_base − y_top) / (y_base − 359.4)` and
`W = w_px × 1.70 / (y_base − 359.4)`.

---

## 1. Silhouette and readability at 30 %

Downsampled to 384×216 (30 %), what survives per frame:

- **T-01** — the cyan strip, the pale rectangle of the doorway, a faint ellipse on the
  floor. **The human figure does not survive.** It is a smudge; I could not identify it
  as a person from the sheet.
- **T-02** — the red banner, the olive ivy mass, the cyan strip, the grey machine. Better
  than T-01, but the banner's lower two-thirds reads as a hole (see §7.2).
- **T-03** — one grey pile on the left, one cyan line. The pile is not identifiable as
  anything.

**Defect 1.1 — T-01, the only character in the survey is invisible.**
Figure body (x 548–568, y 355–435) Ymean **42.9**. Wall immediately right of it
(x 575–600, y 360–430) Ymean **43.6**. Weber contrast **1.6 %**. There is no rim light, no
value separation, no colour accent, and no contact shadow to anchor him. A luma map of
rows 348–441 across x 525–600 shows the figure and the wall occupying the same tonal band
throughout.

**Defect 1.2 — the three frames read as one thing at 30 %: "brown stone tunnel with a cyan
stripe."** Nothing distinguishes the approach room from the arena from the legendary wall
except the presence of a red rectangle (T-02) or a grey pile (T-03). None of the three
frames has a subject.

**Defect 1.3 — in all three frames the brightest cluster is at a margin or is an artefact.**
Top-0.1 % luma centroid: T-01 **(19, 360)** RGB 238/228/238 — the grey machine, half off
the left edge; T-02 **(961, 387)** — the grey machine at right; T-03 **(76, 109)** RGB
229/236/229 — an untextured white polygon (Defect 7.4). The strongest value in every frame
points at nothing the player is meant to look at.

---

## 2. Colour and value structure

Fraction of chromatic pixels (S > 0.15, V > 0.10) falling in each hue band:

| frame | red-orange 340–40° | yellow-olive 40–75° | green 75–160° | cyan 160–200° | blue 200–260° |
|---|---|---|---|---|---|
| **T-01** | **96.9 %** | 0.1 % | 0.2 % | 0.9 % | 0.1 % |
| **T-02** | **88.6 %** | 7.1 % | 0.6 % | 0.1 % | 0.2 % |
| **T-03** | **83.3 %** | 0.9 % | 0.3 % | 6.2 % | 2.8 % |
| palworld-01 | 55.0 % | 19.5 % | 24.0 % | 0.6 % | 0.3 % |
| palworld-04 | 10.8 % | 49.4 % | 16.6 % | 8.7 % | 13.5 % |
| palworld-05 | 46.7 % | 37.9 % | 8.5 % | 6.4 % | 0.5 % |
| keyart NIGHT panel (crop 1070,758–1536,912) | 6.7 % | 0.6 % | 4.5 % | 13.4 % | **73.5 %** |
| keyart STRONGHOLD panel (crop 525,605–1063,912) | 23.4 % | 36.6 % | 6.7 % | 4.6 % | 28.3 % |

**Defect 2.1 — there is one hue.** T-01 is 96.9 % red-orange. The project's own key art
paints its night as a **blue** night (73.5 % blue) with warm fires punched into it at
6.7 %; these frames invert that exactly. The key art's own Team Tether stronghold panel is
grey stone + green moss + a blue-lit arch with **red used only for the banners**.

**Defect 2.2 — the Team Tether oxblood has leaked onto everything.** The T-02 banner
(x 0–310) sits in the same 340–40° band as 88.6 % of the frame — the walls, the floor, the
ceiling and the crates share its hue family. A danger colour cannot signal danger when it
is also the architecture.

**Defect 2.3 — simultaneously over-saturated and under-lit.**

| | mean per-pixel saturation | median Y | % below Y=8 | % above Y=180 |
|---|---|---|---|---|
| T-01 | **0.772** | 35.3 | **12.5 %** | 0.75 % |
| T-02 | **0.775** | 23.1 | **23.7 %** | 0.89 % |
| T-03 | **0.676** | 15.4 | **29.9 %** | 1.09 % |
| palworld-01 | 0.469 | 126.0 | 0.4 % | 28.6 % |
| palworld-03 | 0.406 | 129.9 | 0.0 % | 21.3 % |
| palworld-05 | 0.432 | 109.4 | 0.0 % | 28.2 % |
| keyart (full) | 0.424 | 66.3 | — | — |
| keyart NIGHT panel | 0.713 | 27.4 | 7.5 % | — |

The frames are ~1.7× more saturated than any reference **and** far blacker. T-03 has
**51.3 % of its pixels below Y=16**. Even the key art's own night panel, at a comparable
median (27.4 vs 23.1), crushes only 7.5 % to black against T-02's 23.7 %.

**Defect 2.4 — the shadows are red.** Shadow-tier mean RGB: T-01 12.7/0.8/0.9 (R/B = 13.8),
T-02 12.8/0.6/1.3 (R/B = 10.2), T-03 9.5/1.4/1.9 (R/B = 4.9). The blue channel is
effectively zero in shadow, so there is no cool counterweight anywhere in frame. Cool-luma
share is 2.2 % (T-01), 1.4 % (T-02), 16.2 % (T-03).

---

## 3. Intentionality

**Defect 3.1 — T-01 is bilaterally symmetric to within measurement error.** The left and
right wall strips have slopes 0.3482 and −0.3490 (matched to 0.2 %), the vanishing point is
at x = 639.7 in a 1280-wide frame, and the wall sconces sit at x = 345 and x = 940 both at
y = 345, with mirrored pilaster spacing and mirrored alcoves. This reads as an extruded
corridor from an array modifier, not a room anyone occupies.

**Defect 3.2 — T-01 is empty.** The block **x 300–1000, y 470–720** — 19 % of the frame —
is bare cobble at Ymean 16.5. Across the whole frame the union of prop bounding boxes
(machine, figure, arena ring, wall pipes) is under 10 % of the image. There is no rug, no
crate, no barrel, no debris, no scorch, no wear path, no second figure, no creature.

**Defect 3.3 — T-02's only floor clutter is two identical crates in a line** at
x 520–680, y 395–425: same size, same tint, same spacing. Uniform prop scale and even
spacing is the signature the rubric calls procedural.

**Defect 3.4 — T-02's ivy is one leaf card repeated at one scale.** No trailers, no
clustering, no long/short variation, and one flat tone: meanRGB **74.2 / 54.6 / 27.2**
(blue channel 27) — olive, not green. Green as a hue is **0.6 %** of T-02's chromatic
pixels; palworld-01 is 24.0 % green.

**Defect 3.5 — T-01's arena/fire ring** (outer ellipse x 768–1003, near edge y ≈ 462) is a
chain of identical kerb segments at regular angular intervals around a **two-triangle flat
sand quad with a visible diagonal Gouraud seam** running corner to corner across it.

---

## 4. Lighting

The wall sconces do work locally — T-03's sconce at (690, 352) lights the floor beneath it
to Ymean **57.0** against **6.4** for the same rows 300 px to the right; T-01's right sconce
gives floor Ymean 51.8 vs 18.3. So the failures below are the global/ambient term, not the
fixtures.

**Defect 4.1 — the ceiling is the brightest large plane in a room lit from head height.**
T-01: ceiling (x 200–1000, y 0–60) Ymean **120.5**; floor (same x, y 600–700) Ymean
**11.7** — a **10.3×** inversion. T-02: ceiling 74.9 vs floor 10.7 — **7.0×**. Nothing in
either frame emits from above. The light is coming from a hemisphere/ambient setting, not
from the sconces and the floor strip that are actually in the shot.

**Defect 4.2 — nothing casts a shadow onto the ground.** T-01, floor at the figure's feet
(x 542–568, y 435–445) Ymean **23.1**; the same rows 40 px to the right Ymean **17.6** —
the floor is *brighter* under him. Arena ring: floor at its near edge (x 820–960,
y 468–480) Ymean **41.6** vs **15.2** for the same rows 300 px left. No contact shadow, no
AO at the kerb, no shadow from the wall pipes, no shadow from the T-03 hero prop onto the
wall behind it. Every object is a decal lying on the floor.

**Defect 4.3 — the emissive floor strip emits no light.** T-03 at y = 600: strip RGB
(85.8, 163.3, 164.1), Y = **146.9**; floor 10 px to its left RGB (26.3, 11.4, **3.4**),
Y = 14.0. Same at y = 560 (strip Y 144.8, floor Y 14.3, floor blue 2.1) and y = 640 (strip
Y 147.2, floor Y 6.3). T-01 y = 460: strip RGB (142, 192, 168), floor 40 px away RGB
(53.9, 15.3, **2.2**). A Y≈147 cyan emissive lying on a Y≈14 floor puts **zero** blue into
the surface it touches. This single fault is why the cyan reads as a sticker and why the
frames have no cool note at all.

**Defect 4.4 — the time of day does not read as night; it reads as "orange".** There is no
moonlight, no window shaft, no cool fill, and the only non-warm element (the strip)
contributes nothing. Compare the key art NIGHT panel, which is blue at 73.5 % with the
campfire as a 6.7 % warm accent — the exact opposite ratio.

---

## 5. Horizon and depth

Interiors, so no horizon to judge; depth cues instead.

**Defect 5.1 — T-01's depth is legible only because of the one-point perspective.** There is
no atmospheric term, no dust, no haze, no value grouping. The far wall is the same
material at the same saturation as the near wall.

**Defect 5.2 — T-03 deletes distance instead of receding it.** The right wall
(x 950–1250, y 100–400) sits at Ymean **16.5**, max 84.3. 29.9 % of the frame is below
Y = 8 and 51.3 % below Y = 16. Geometry beyond the last sconce pool does not fade — it
disappears. The room has no far end; it just stops.

---

## 6. Interface

No HUD is present in any of the three frames, so safe area, hierarchy and legibility cannot
be assessed. Noted so the gap is visible; I have not used the Palworld HUD as a comparison
point.

---

## 7. Artefacts

**Defect 7.1 — T-01, the doorway is a flat matte quad.** Bounding box **x 591–710,
y 257–408** (120 × 151 px), colour RGB **100 / 58 / 51**, standard deviation over a
50 × 100 sample = **0.94**. It is the second-brightest large element in the frame and it
has no threshold, no depth, no light beyond it, and no falloff. **T-02 repeats the same
defect** at x ≈ 618–700, y ≈ 200–425 with a cream fill.

**Defect 7.2 — T-02, a flat unlit maroon plane fills the left of the frame.**
Sample **x 20–300, y 330–560**: Ymean **22.0**, Ystd **1.56** — 280 × 230 px, **7.0 % of
the frame**, at one value. Its right edge is a perfectly vertical hard step: row y = 450
reads Y = 24, 24, 24, 21, 12, 5, 3 across x = 300 → 320. Whether it is the banner's lower
half with a missing material or a stray occluder, it reads as a hole in the render.

**Defect 7.3 — T-02, a hard-edged near-white wedge at the bottom-right corner**,
x ≈ 1245–1280, y ≈ 490–560, peak Y **235–240** (rows 500–530 at x = 1270 read a flat 235).
It is the single brightest thing in a frame whose median is 23.1, it is clipped by the
frame edge, and it has no source and no falloff.

**Defect 7.4 — T-03, untextured white polygon slivers.** A hard triangular edge at
**x 0–45, y 40–105** peaking at Y **240** — the brightest pixel in the frame — plus pale
wedges around x 0–120, y 340–400 and near x 300, y 300. These read as flipped normals or
faces that lost their material.

**Defect 7.5 — T-03, the camera is clipping the hero prop.** The object is cut by the left
frame edge and its lower geometry crosses in front of the floor strip at x ≈ 340–500,
y ≈ 480–530 with no space between. The composition's entire foreground is an object the
camera is inside.

**Defect 7.6 — T-03, the hero prop's texture is from a different pipeline.** Object
(x 80–380, y 30–480) vs the stone wall right of it (x 900–1250, y 60–420):

| | mean sat | mean Y | high-freq energy |
|---|---|---|---|
| legendary object | **0.395** | **40.6** | **16.13** |
| stone wall right | 0.741 | 15.8 | 4.79 |
| stone wall centre | 0.645 | 34.3 | 12.83 |

Half the saturation, 2.6× the brightness, 3.4× the local high-frequency energy of the wall
it stands against. Brightened 3×, the texture is visibly photographic and mottled with
blocky compression artefacts, against flat hand-painted stone. It reads as an asset dropped
in from another game.

**Defect 7.7 — T-03, the hero prop has no readable silhouette.** At 30 % it is a grey pile.
At 100 % I cannot say what it is: spires, arches, struts and a broken ring, no dominant
shape, no clear base, no symmetry, nothing that says shrine, machine or landmark.

**Defect 7.8 — T-01 and T-02, the grey machines are not lit by the room.** T-01's machine
(x 0–180, y 240–520) meanRGB **104.9 / 59.4 / 50.9** against the wall beside it (x 190–300)
at **77.3 / 32.0 / 19.2** — blue channel 51 vs 19. It stays neutral grey-lavender in a
saturated orange room, and its brightest pixels are the brightest in the whole frame while
sitting half off the left edge. T-02's machine (x 840–960, y 290–440) is the same:
meanSat 0.525 and Ymean 101.5 against a wall at 0.786 / 37.5.

**Defect 7.9 — T-02, the two "stools" at x 1050–1160 are pure silhouette.** Ymean 43.8 with
an internal max of 118 confined to a rim, in a frame where every other surface is warm-lit.
They read as black cut-outs, not objects.

---

## 8. Scale agreement

Using the T-01 calibration in §0 (camera 1.70 m, horizon y = 359.4):

| object | pixels | measured size |
|---|---|---|
| humanoid, T-01 | y 355–433, x 542–567 | **1.80 m** (the ruler) |
| doorway, T-01 | x 591–710, y 257–408 | **5.28 m tall × 4.20 m wide** |
| arena / fire ring, T-01 | outer x 768–1003, base y ≈ 462 | **3.89 m across**, kerb **0.13 m** high |

**Defect 8.1 — the architecture and the furniture disagree about the metre by about 3×.**
The doorway is 2.9× the height of the person who walks through it and 4.2 m wide, and the
hall behind it is proportionally tall, while every fixture in the survey is life-size: a
0.13 m kerb, an ordinary table and two ordinary stools in T-02, crates a person could
carry. Nothing in the room is built at the scale the room is built at.

**Defect 8.2 — the consequence: the only human in the survey occupies 0.9 % of the frame
area** (25 × 78 px out of 1280 × 720). Palworld-01 puts its boss creature at roughly 40 %
of frame height and its character at roughly 90 %; palworld-04 and -05 both put a character
and a creature in the near foreground. Scale here is not just inconsistent — it makes the
character insignificant in his own frame.

**Defect 8.3 — no creature appears in any of the three frames**, including the one framed
as **warden arena** and the one framed as **legendary**. The Warden is not in the frame
named for him. Every one of the five Palworld references contains at least one creature and
a character reading clearly at foreground scale; four of five make a named creature the
compositional subject. Creature appeal cannot be judged here because there is nothing to
judge — and that absence is itself the loudest gap against the bar, since the creature is
what these frames are supposed to be about.

---

# The verdict

## 1. The three things that most separate these frames from the references

**1 — The references have a colour system; these frames have one hue.**
The project's own key art paints its night blue: the NIGHT panel is **73.5 % blue,
13.4 % cyan, 6.7 % red-orange**, with the campfire as the warm accent. **T-01 is 96.9 %
red-orange** with a single cyan line, and its shadows are red too (shadow-tier R/B = 13.8,
blue channel 0.8). The key art's *own* Team Tether stronghold panel is grey stone, green
moss and a blue-lit arch with **red reserved for the banners**; **T-02** hangs a red banner
on a red wall over a red floor under a red ceiling, so the faction colour signals nothing.
Palworld never runs below three hue families in a frame; these run one.

**2 — The references have both a bright end and a black floor; these have neither.**
Palworld puts **21–29 % of its pixels above Y = 180** and **0.0–0.4 % below Y = 8**.
**T-01/02/03 put 0.75–1.09 % above Y = 180 and 12.5 / 23.7 / 29.9 % below Y = 8**; T-03 has
**51.3 % of the frame below Y = 16**. There is no highlight to look at and no readable
shadow — just a fall from an unmotivated bright ceiling (**T-01, ceiling Ymean 120.5 vs
floor 11.7**) straight into crush. And the one element that could have carried a highlight,
the cyan floor strip, is an emissive at Y ≈ 147 that puts **zero** blue into the floor
10 px away (**T-03, y = 600: floor RGB 26.3 / 11.4 / 3.4**).

**3 — The references are full and have a subject; these are empty and have none.**
**T-01** devotes **19 % of the frame** (x 300–1000, y 470–720) to bare cobble at Ymean 16.5,
carries under 10 % prop coverage overall, is bilaterally symmetric to within 0.2 % on the
wall-strip slopes, and its only character occupies **0.9 % of the frame at 1.6 % contrast**
against the wall behind him. Palworld-05 fits a base, crops, a working creature, a
character, terrain scatter and a landmark into the same 1280 × 720. Palworld-01 makes a
fight look like an event with sparks, a rim-lit boss and a foreground character.
**T-02 contains no warden. T-03 contains no legendary.** Every reference frame has a
subject; none of these three does.

## 2. The two bar questions

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?

**No.**

What carries: the architectural vocabulary is right — rounded stone blocks, arched
openings, timber pilasters, ivy over the arch, wall sconces throwing real pools
(T-03 sconce: floor Y 57.0 beneath vs 6.4 at 300 px). That is recognisably the key art's
Team Tether stronghold.

What sinks it: the palette is inverted against the board's own night (96.9 % red-orange
against the key art's 73.5 % blue), the faction oxblood is the wall colour rather than an
accent, and the density is nowhere near it — the board's stronghold panel is crowded with
scaffolds, fences, banners, crates, moss and figures, and T-01 is an empty symmetric
corridor. The board's line "cozy and inviting, but with hints of mystery" is not what a
96.9 %-orange corridor with 12.5 % crushed black delivers.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

There is no creature and no character reading as a subject in any of the three frames; the
one humanoid present is 0.9 % of the frame at 1.6 % contrast. There is no bright end
(0.75–1.09 % above Y = 180 against 21–29 %), no scatter, no clutter, and the hero prop in
T-03 is visibly from a different art pipeline than the room it stands in (sat 0.395 and
high-freq 16.13 against the wall's 0.741 and 4.79). Shown these three beside the Palworld
shots, the honest guess is a dungeon-corridor lighting test, not a creature-training game.

### Which gaps are fixable by changing the scene

Density, palette, lighting, composition, scatter — all of the following need no new art:

- **Cool the ambient/environment term.** Give the night a blue base so the sconces read as
  fire against it. Target ratio is the board's own NIGHT panel (73.5 % blue / 6.7 % warm),
  not a literal copy. Fixes Defects 2.1, 2.4, 4.4.
- **Lift the black floor and tint the shadow tier cool.** 12.5 / 23.7 / 29.9 % below Y = 8
  is a shadow tier crushed to nothing, and what survives is red (R/B up to 13.8). Defects
  2.3, 2.4, 5.2.
- **Cut saturation.** 0.68–0.78 mean against 0.41–0.47 in every reference. Defect 2.3.
- **Invert the ceiling/floor relationship.** T-01's ceiling is 10.3× its floor in a room
  lit from head height. Defect 4.1.
- **Make the emissive strip actually light the floor.** Defect 4.3 — the single highest-value
  fix for the cool/warm dialogue, because the cool light source is already in the frame.
- **Turn on shadow casting for props and characters, or at minimum add contact darkening.**
  Currently the floor is brighter *under* the figure's feet than beside them. Defect 4.2.
- **Break T-01's symmetry and fill it.** Clustered, scale-varied clutter in x 300–1000,
  y 470–720; a wear path; scorch; a second figure. Defects 3.1, 3.2, 3.3.
- **Put something behind the two doorways** (T-01 x 591–710 y 257–408; T-02 x 618–700).
  A flat quad at Ystd 0.94 is not a door. Defect 7.1.
- **Reframe T-03** so the camera is not clipping the hero prop, and give the shot a subject.
  Defects 7.5, 1.2.
- **Compose for a focal point.** Put the frame's strongest value on what the player should
  look at, not on an off-centre prop at x = 19 or an artefact at (76, 109). Defect 1.3.
- **Resolve the architecture/prop scale disagreement** — a 5.28 × 4.20 m doorway over
  life-size furniture. Per the standing directive, resolve upward: build fixtures at the
  room's scale rather than shrinking the room. Defects 8.1, 8.2.
- **Fix the four things that read as bugs**: T-02's flat maroon plane (x 20–300, y 330–560,
  Ystd 1.56), T-02's white wedge (x 1245–1280, y 490–560, Y 235), T-03's white polygon
  slivers (x 0–45, y 40–105, Y 240), and T-01's diagonal Gouraud seam across the arena's
  sand quad. Defects 7.2, 7.3, 7.4, 3.5.

### Which gaps need art that is not in the build

- **A creature, in frame, at foreground scale.** No lighting change puts a subject in
  T-02 or T-03. The bar reference makes a bespoke creature the compositional subject at
  ~40 % of frame height; there is nothing here to light. Defect 8.3.
- **The Warden.** The frame named for him does not contain him.
- **A replacement or a full hand-painted re-texture of the T-03 hero prop.** Its material
  language (sat 0.395, high-freq 16.13, photographic, blocky) cannot be reconciled with the
  flat painted stone (0.741, 4.79) by any lighting change, and its silhouette does not read
  at any zoom. Defects 7.6, 7.7.
- **A second and third stone/floor material.** Every wall in all three frames is one motif
  at one stone size. A stronghold interior needs at least a worn/damaged variant, a
  plaster or timber variant, and floor variation.
- **Real foliage.** The ivy is one leaf card at one scale in one olive tone (green = 0.6 %
  of T-02's chromatic pixels vs 24.0 % in palworld-01). It needs multiple greens, value
  range, trailers and leaf-scale variety. Defect 3.4.
- **Set dressing.** Braziers, modelled banner folds, weapon racks, chains, crates of varied
  size, sacks, spilled ore, tables with things on them. The survey contains four distinct
  prop types across three frames.
- **A character whose silhouette holds at 30 %.** Even correctly lit, a 78-px dark humanoid
  with no rim, no colour accent and no readable shape will not read at sheet size. Defect
  1.1.
