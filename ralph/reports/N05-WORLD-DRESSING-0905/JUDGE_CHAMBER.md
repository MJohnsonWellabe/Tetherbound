# Blind visual judgement — `_sheet_chamber.png` (narrow round, five points)

Judged from `ralph/reports/N05-WORLD-DRESSING-0905/_sheet_chamber.png` (1298x1582, cells
~640x360 = half scale) and the eight full-size frames in `shots/n05_before2/` (column A)
and `shots/n05_after2/` (column B). References: `docs/reference/tetherbound-meadows-keyart.png`
and `docs/reference/palworld-0*.jpg`.

I was told nothing about what differs. What the pixels say: **the two columns are the
same scene, same cameras, same geometry, with a lighting/dressing pass applied in B that
lands in rows 1–3 and does essentially nothing in row 4.** Frame-to-frame max-channel
difference >12 covers 17.3% / 20.9% / 18.2% of rows 1–3 and only 6.4% of row 4, and in
row 4 that 6.4% is almost entirely the light strips themselves.

Method note: luma is Rec.709 (`0.2126R+0.7152G+0.0722B`) on the raw PNGs, no gamma
adjustment. "Unreadable black" below means luma < 20 **and** 5x5 local max−min < 4 — dark
*and* featureless, which is stricter and more honest than a flat luma threshold. Crops are
named in original 1280x720 frame coordinates.

Row map used throughout: **Row 1** = `C-01-chamber-face.png`, **Row 2** =
`C-03-chamber-corner.png`, **Row 3** = `C-02-chamber-creature.png`, **Row 4** =
`W-01-warden-arena.png`.

---

## 1. Bars of light

**Row 1 — B is much better, and it is the only place in the sheet where the fix is
convincing.**

Column A carries two pale slabs running from the top frame edge diagonally down to a flat
square end at (366, 246) and (913, 246). Cross-sections at y=60/100/150 measure **38 / 35 /
30 px wide**, colour **RGB (175, 232, 231) = luma 220**, against a frame median of 28. They
have no housing, no bracket, no fixture: at y=60 the pixel immediately left of the strip is
(24, 30, 23) wall and the pixel immediately right is (33, 95, 90) wall. A 38px-wide
uniform-luma-220 line drawn over masonry, terminating in mid-air with a squared end, is a
debug draw. It reads as nothing else.

Column B replaces each with a **5–6 px** strip at **RGB (87, 196, 180) = luma 172**, sitting
along the lower edge of a dark wedge that occupies the same 26–29 px footprint the fat A bar
occupied (black run at y=60 spans x164–200; A's bar spanned x163–200). At 3x exposure that
wedge reads as an angled soffit or rail with a light strip mounted under it. **In B this
reads as intentional mounted lighting. In A it does not.** That is a genuine, large win.

Two things B did not fix here:
- The housing renders at **exactly RGB (0,0,0)** at every exposure I pushed it to (up to
  5x). It is not dark hardware, it is a hole. Against a wall at luma 35–50 it reads as a
  black slot cut through the masonry, so the strip reads as light leaking through a gap
  rather than as a fixture bolted to a wall.
- The strip still **ends in mid-air** with a square cut at (344, 218) — no end cap, no
  bracket, nothing it plugs into.
- Two further strips are untouched in B: a 50x7 px horizontal cyan stub at **x96–146,
  y599–605** on the left wall, and a 56x18 px fragment at **x0–56, y675–692** bleeding off
  the bottom-left corner. Both are still unmounted floating strips in both columns.

**Row 2 — B better on one of three strips; the other two are unchanged.**

Component inventory of cyan pixels (`B>110 and B>R+30`):

| strip | A | B |
|---|---|---|
| upper diagonal | 7301 px, x127–563, y56–176 | 1273 px, x195–563, y76–167 — thinned, black housing added |
| floor-level strip, right | 3991 px, x942–1279, y579–705 | 3650 px — **geometry unchanged** |
| bottom stub | 1199 px, x681–754, y669–719 | 1135 px — **geometry unchanged** |

Column profile at x=1150 through the floor-level strip: A rows 651–660 = (174,232,231)
with rows 636–648 = (4,8,0) and rows 663–675 = (7–10, 11–13, 0–4). B: rows 651–660 =
(84,194,178) with the identical black floor above and below. **No housing was added to this
one.** A 9–14 px luma-220 line lying on a floor at luma 4–9, running off the right frame
edge, is a debug draw in A and a recoloured debug draw in B. The 74 px stub at x681–754 ends
in mid-air at *both* ends, in both columns.

**Row 3 — no meaningful difference.** One strip only: a 35x8 px cyan stub at **x0–34,
y436–443**, poking in from off-frame with no visible mount, in both columns. Cyan pixel
coverage 0.05% (A) → 0.03% (B).

**Row 4 — no fix at all, in either column. This is the worst row on this point.**

The three strips are **pixel-identical in position and extent** between A and B:
- x640–1279, y562–583 (22 px thick) — runs off the right frame edge;
- x70–477, y488–719 (diagonal) — square end at (477, 489), mid-floor, on nothing;
- x640–1098, y457–463 (7 px thick) — square end at x=1098, mid-floor, on nothing.

Column at x=900: A rows 456=(0,0,0), 459–462=(175,232,231), 465=(2,2,0). B rows
456=(0,0,0), 459–462=(80,192,177), 465=(3,2,0). **The only change in row 4 is the bar
colour: RGB (171,231,230) luma 218 → (79,191,177) luma 166.** Coverage is 3.19% of the frame
in A and 3.16% in B. At 5x exposure there is no housing, no mount, no bracket adjacent to any
of the three. Against a frame median of 11–12 luma, that is a **15–18x** highlight ratio on
three lines that end in mid-air. **Both columns read as debug draws in row 4; B is a
recolour, not a fix.**

**Separately, and unchanged between columns: the creature cage.** In rows 2 and 3 the ring is
nine near-white vertical strips at **RGB (217,223,221) = luma 222** — the brightest object in
either frame, over a room whose median is 22. Their bounding boxes are identical in A and B
(x133–175, 180–191, 207–227, 258–315, 336–423, 437–455, 468–484, 504–515, 523–544). They have
no base ring, no cap, and their bottoms terminate at **y=516, 622, 625, 649, 678** while five
others run to y=719. A bar whose bottom stops at y=516 while its immediate neighbours stop at
618–678 is not perspective. These read as debug draws too, in both columns.

---

## 2. Contact shadows

**Neither column has a contact shadow anywhere, in any of the four rows. This is a tie, and
both fail.** Measured, not eyeballed:

- **Creature, row 2.** Floor strip averaged over y662–682, immediately below the hooves
  (hooves land ≈y655), cage-bar pixels excluded. *Under* the animal (x280–400): A = 19, 19,
  17, 20, 20, 14, 17. *Beside* it at the same depth (x460–540): A = 14, 17, 16, 18, 17. In B:
  under = 31, 31, 31, 28, 30, 32, 23; beside = 21, 24, 22, 25, 25. **In both columns the floor
  directly under the creature is equal to or brighter than the floor next to it.** There is
  not merely a weak shadow — there is negative shadow. The creature is pasted onto the floor,
  and B's fill made that slightly worse by lifting the ground it stands on.
- **Tether machine, row 2.** At 4x exposure (crop x400–1280, y560–720) the machine base meets
  the floor at a hard geometric edge with a *bright* rim highlight, and the floor cobbles run
  right up to the geometry with no occlusion darkening. Identical in A and B.
- **Tether machine, row 3.** Row means of the floor in front of the plinth, x300–980:
  y647=11.3, y659=14.3, y671=13.0, y683=14.4, y695=12.7, y707=12.7, y719=13.6 (A); 13.0, 16.7,
  15.2, 17.0, 14.8, 14.6, 15.9 (B). Flat. A structure that size would throw a readable shape;
  there is none in either column.
- **Warden figure, row 4** (x620–660, y370–435). At 4.5x exposure the boots meet the floor
  with zero darkening in both columns.

Conclusion: nothing in these eight frames casts a shadow onto anything. The machine does not
sit on the floor, the creature does not sit on the floor, and the Warden does not sit on the
floor. B changed nothing here.

---

## 3. Value structure

Unreadable black (luma<20 **and** 5x5 local range<4), and the plain-threshold numbers:

| row | frame | dead-black A | dead-black B | luma<20 A/B | luma<5 A/B | mean luma A/B |
|---|---|---|---|---|---|---|
| 1 | C-01 | **2.4%** | **2.4%** | 31% / 29% | 4.0% / 3.8% | 36.7 / 36.8 |
| 2 | C-03 | **6.3%** | **3.6%** | 45% / 39% | 5.2% / 2.7% | 33.4 / 34.7 |
| 3 | C-02 | **5.7%** | **4.1%** | 45% / 39% | 4.5% / 3.5% | 30.3 / 34.7 |
| 4 | W-01 | **24.1%** | **23.1%** | 61% / 63% | 29.0% / 25.4% | 25.0 / 23.3 |

**Is there a fill?** In rows 1–3, yes, and it is local rather than global. Row 2 crop deltas
(B − A): floor under creature (x270–420, y620–680) **+8.0**; floor before machine (x430–520,
y620–680) **+8.1**; creature torso (x280–420, y500–600) **+9.2**; left wall (x0–110,
y200–400) **+2.0**; back wall (x200–500, y150–380) **+0.0**; right wall (x1000–1270,
y200–400) **−0.2**. So the fill reaches **the near floor, the creature and the machine base,
and does not reach the walls or the ceiling at all.** Row 4 got no fill: the arena floor
(y440–720) mean went **down**, 22.6 → 19.0, and the floor centre (x400–900, y480–700) 18.5 →
15.7. **89% of the arena floor is below luma 15 in both columns.**

**Is there a second hue family?** Yes in rows 1–3, measured over pixels with luma>20 and
saturation>0.15, binned by hue:

| row | teal/cyan (150–200°) A→B | warm olive+yellow-green (45–105°) A→B |
|---|---|---|
| 1 | 32% → **17%** | 32% → **50%** |
| 2 | 26% → **13%** | 37% → **63%** |
| 3 | 47% → **25%** | 17% → **43%** |
| 4 | 12% → 13% | 55% → 55% |

Floor hue confirms it directly: row 2 near floor A = RGB(42,47,37), hue 87°, sat 0.12 → B =
RGB(57,54,38), hue 52°, sat 0.20. Row 1 floor A hue 162° (teal) → B hue 115–120° (green-warm).
**B establishes a real warm stone/olive family for the teal to read against, in rows 1–3.
Row 4 is unchanged and remains a single-hue teal-and-black frame.**

**Calibration against the references.** The key art's own **night** panel measures mean luma
30.3, luma<20 = 36%, luma<5 = 3.8%, p95 = 62. The chamber frames (mean 30–37, luma<5
2.4–5.2%) sit *inside* the project's own night budget in both columns — the chamber's darkness
is not the problem. **The Warden Arena at luma<5 = 25–29% is 6.6x the key art night panel's
pure-black budget, and that is the outlier.** The other half of the reference's discipline
that neither column meets: the key art night panel's p95 is 62, i.e. its brightest content is
restrained; these frames put 220-luma bars and a 222-luma cage against a median of 11–29. The
Palworld shots run mean luma 118–132 with 0.0–1.0% below luma 5 — daylight exteriors, so not a
like-for-like value comparison, and I am not scoring the rooms against them on brightness.

**Which surfaces carry the difference:** near floor, creature, machine base — yes. Walls,
ceiling, back wall — no, in any row. Row 4 — nothing.

---

## 4. Wall integrity

**Row 2 — B is clearly better, and this is the single most convincing fix in the sheet.**
Column A has a hard black vertical slot on the left wall at **x≈102–136, y≈100–430**: 34 px
wide, 330 px tall, **mean luma 9.1, 69% of its pixels below luma 5**. Column profile of
y200–430 in A reads `…x96:34 x102:12 x108:0 x114:0 x120:0 x126:0 x132:1 x138:20…`. At 3x
exposure it contains no stone at all. In B the same rectangle measures **mean 21.3, 8% below
luma 5**, and shows continuous masonry: `…x96:27 x102:20 x108:10 x114:12 x120:16 x126:18
x132:19 x138:17…`. Whole left wall (x0–300, y100–430) fraction below luma 5 falls **0.14 →
0.03**. The void is gone.

**Row 1 — small win for B.** Scanning y150–520 for columns more than 25% below luma 6: A has
two 3 px seams at **x653–655** (33%) and **x882–884** (26%); B has none. No full-height void in
either column. What both columns still show, at 3x exposure on the right wall (x930–1280,
y180–560), is masonry built from **overlapping flat slabs with hard vertical silhouette
edges**, where courses do not run through the overlap. The vertical course period measured by
autocorrelation steps from ~68 px on the near slab (x1180–1270) to ~13 px on the slab it
overlaps (x1000–1070); some of that ratio is legitimate perspective on a receding wall, so I
will not claim the full 5x as a scale error — but the courses visibly fail to meet across the
seam in both columns.

**Row 3 — not fixed; B is the same as A.** Columns more than 25% below luma 6 over y150–520:
A = x34–47 (14 px, 33%), x659–662, x790–798, x1186–1201 (16 px, 47%). B = x35–47 (32%),
x660–662, x793–796, x1186–1201 (44%). At 4x exposure the right-hand pair (x1186–1201) is
plainly a **black gap between two wall slabs** running the visible height of the corner, with
the slab on its left carrying stones roughly 1.4x the size of the slab on its right and a hard
overlap edge between them. Present in both columns, essentially unchanged.

**Row 4 — not fixed; slightly worse in B.** A 16x270 px vertical slot at **x336–352,
y160–430** measures **mean luma 4.3, 74% (A) / 70% (B) of pixels below luma 2, maximum 36 over
the entire slot**. A second at **x896–916**: mean 12.0 (A) / 10.6 (B), 38% / 13% below luma 2.
At 5x exposure both show zero texture — geometry that renders at absolute 0 at any exposure is
a void between wall pieces, not a shaded recess. Add black slabs and a floating beam at x0–40
and x950–1100, y170–200, black in both columns. The two dark wall slabs measured over
y150–430 got **darker** in B: x340–400 mean 11.0 → 8.8; x880–960 mean 13.0 → 7.2.

---

## 5. Creature legibility (rows 2 and 3)

**Row 2 — yes in both columns, B slightly better against the wall and slightly worse against
the floor.** At contact-sheet scale (half resolution) you can tell there is a quadruped there
in A and in B. What identifies it in both is the cream antler crown, which measures **Δ17–18
luma** against the wall behind it (head 41.2 vs wall 22.7 in A; 39.9 vs 22.8 in B). The body
is the weak part:

| separation | A | B |
|---|---|---|
| torso vs wall behind (x260–430, y300–420) | 27.2 vs 22.7 = **Δ4.5** | 32.9 vs 22.8 = **Δ10.1** |
| torso vs floor below (x280–420, y640–680) | 27.2 vs 18.8 = **Δ8.4** | 32.9 vs 29.3 = **Δ3.6** |

So B trades one for the other: it more than doubles the separation from the wall and roughly
halves the separation from the floor, because the same fill that lifted the creature lifted
the ground under it by nearly as much. Neither column reaches a comfortable read; a body that
must be found at a glance wants Δ20–25 on this scale, or a clean hue break, and it has neither
here. And in both columns the read is dominated by the **cage, not the creature**: nine
222-luma bars slice the animal into vertical fragments and are the brightest object in the
frame by a wide margin. The strongest single thing you could do for creature legibility in
row 2 is take the cage down from 222 luma, and neither column has done it.

**Row 3 — there is no creature in the frame, in either column.** `C-02-chamber-creature.png`
is named for the held creature and contains none. At 4x exposure the region between the far
cage bars (x470–810, y265–345) is machine geometry and cage-bar tips only; nothing in it reads
as an animal at any exposure I tried, in A or in B. The answer to "can you tell there is a
creature there at all" is **no, in both columns**, and no lighting change fixes it — the
camera is staged so the machine occludes the subject.

---

## The two bar questions, scoped to these five points only

> **A. Do these frames read as belonging to the world in
> `docs/reference/tetherbound-meadows-keyart.png`?**

**No — for both columns. B is materially closer.**

What carries B toward it: the warm olive/stone hue family it establishes in rows 1–3 (teal
share 26–47% → 13–25%) is exactly the board's "vibrant, readable colours on a natural
palette", and the row-2 wall repair removes the one place where a wall simply stopped existing.
What still sinks both:

1. **Nothing in the key art terminates a light in mid-air.** The stronghold panel's fixtures
   are braziers and windows attached to masonry. Row 4 has three glowing lines with square
   ends over a bare floor in *both* columns; row 2 has two; row 1 has two stubs. B fixed
   exactly two strips (the row-1 and row-2 ceiling diagonals) out of about ten.
2. **Everything in the key art is bedded into the ground.** Every structure and figure in the
   stronghold and night panels has an occlusion darkening where it meets stone or grass.
   Measured above: the floor under the creature in row 2 is *brighter* than the floor beside
   it, in both columns.
3. **The key art's masonry is continuous, with courses running through.** Rows 3 and 4 still
   show overlapping slabs and hard-black gaps between wall pieces at x1186–1201 (row 3) and
   x336–352 / x896–916 (row 4), unchanged in B.

> **B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone say these are
> trying to be the same kind of game?**

**No — for both columns, and on these five points the gap is not close.**

In `palworld-05-base-building.jpg` every placed object — the chests, the workbench, the
palbox, the barrel of produce — sits in a visible ground-contact darkening, and in
`palworld-01-boss-fight-forest.jpg` the boss's feet and the trainer both do. Across all five
Palworld shots, **no light source ends in mid-air and no wall has a hole in it.** These frames
have both, in both columns. The value comparison is not fair (their five shots are daylight
exteriors at mean luma 118–132), and I am not using it against these interiors — but the
structural failures above are exposure-independent and would be just as visible in a bright
frame.

### Fixable by changing the scene, versus needing art that is not in the build

**Fixable in scene, now:**
- Apply the row-1/row-2 ceiling-diagonal treatment (thin strip + housing) to the remaining
  strips: row 2's floor strip (x942–1279) and stub (x681–754), row 3's stub (x0–34), and all
  three row-4 strips. This is the same change, already proven to work, just not propagated.
- Give the housing a non-zero material. It currently renders (0,0,0) at 5x exposure, so it
  reads as a hole rather than as hardware.
- Terminate every strip on a bracket instead of a square cut in mid-air.
- Drop the cage bars from luma 222 and give them a base ring; give the five bars whose bottoms
  stop at y=516–678 a common floor line.
- Close the wall voids at row 3 x1186–1201 and x34–47, and row 4 x336–352 and x896–916 — the
  identical fix that already worked on row 2's left wall.
- Extend the rows-1–3 fill into row 4. The Warden Arena got none of it, and its floor got
  *darker*, 22.6 → 19.0, with 89% of the floor under luma 15.
- Add contact darkening under the machine, the creature, the cage and the Warden. A decal or
  a blob is a scene change, not new art.

**Not fixable by lighting or dressing:**
- Row 3's camera. The frame named for the held creature contains no creature in either
  column; the machine occludes it. That is a staging decision.
- The wall-slab overlaps in rows 1 and 3 where masonry courses do not meet across the seam.
  That is kit authoring, not lighting.

**Which column wins:** **B**, on points 1 (rows 1–2 only), 3 (rows 1–3 only) and 4 (row 2
only). **Tie** on point 2 — both fail completely. **Mixed** on point 5. **Row 4 is a
regression on point 3**: no fill, floor mean 22.6 → 19.0, wall slabs 11.0 → 8.8 and 13.0 →
7.2, and the light strips recoloured rather than mounted.

*Out of scope, noticed: the row-4 arena floor is a visible checkerboard of light and dark quads
in both columns.*
