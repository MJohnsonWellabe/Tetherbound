# Blind visual verdict — `plates_AB_round2.png`

Fourteen 256x256 dialogue portraits, row A (top) and row B (bottom), columns 1-7.
I was told nothing about either row. Everything below is measured off the pixels.

**Coordinate convention.** All coordinates are plate-local: origin at the top-left of
each 256x256 plate, x right, y down. (On the sheet itself the plates start at x=40,
y=20 for row A and y=296 for row B.)

**Method.** Hair was isolated by the pixels that change across the seven row-B plates
(std > 12 across B, < 6 across A), morphologically closed and hole-filled: 7,370 px,
covering crown, fringe, both side-locks in front of the ears and both jaw tips, and
excluding eyebrows, ear and garment. Colours are means over that mask or over named
sub-zones of it; Lab is D65 sRGB, ΔE is CIE76.

---

## A. Is each row-B head one hair colour, crown to tips?

**Yes.** Every head in row B holds a single hue from crown to tips, including the
side-lock in front of the ear and the tips at the jaw. What varies within a head is
chroma and lightness, which is what shading is supposed to do.

Zone means inside the hair mask (crown y20-58, fringe y58-95, sides y95-132, tips
y132-175, left = x<118, right = x>=138):

| cell | crown | fringe | sideL | sideR | tipL | tipR | hue span |
|---|---|---|---|---|---|---|---|
| B1 | (58,40,28) | (38,26,20) | (43,29,21) | (39,26,18) | (40,30,25) | (32,22,16) | 20-23° |
| B2 | (96,61,40) | (67,44,30) | (76,48,31) | (76,47,29) | (69,48,35) | (61,39,26) | 22-23° |
| B3 | (126,77,48) | (86,54,35) | (101,62,39) | (100,59,36) | (86,56,38) | (78,48,31) | 21-22° |
| B4 | (141,134,121) | (96,90,81) | (115,106,93) | (112,107,97) | (101,95,86) | (83,78,71) | 34-38° |
| B5 | (127,64,40) | (87,45,30) | (97,51,32) | (99,48,29) | (82,46,33) | (79,40,25) | 16° flat |
| B6 | (148,145,152) | (100,97,102) | (110,105,106) | (116,114,120) | (95,92,96) | (91,88,92) | C* ≤ 4.1 |
| B7 | (79,95,64) | (57,65,45) | (62,69,45) | (62,73,48) | (59,65,48) | (50,58,39) | 77-90° |

The Lab hue *angle* is stable to within about 5° in every head — B5 crown 46.8° vs
tipL 46.3°, B7 crown 127.6° vs tipL 123.1°. Chroma falls with light exactly as it
should: B5 C* 36.5 at the crown, 21.1 at the left jaw tip; B3 31.1 → 19.7; B7 19.8 →
11.4. Measured as maximum zone-to-zone chroma spread, row A sits at 6.8-7.6 and row B
at 3.2 (B6), 3.3 (B4), 6.5 (B1), 8.5 (B7), 9.3 (B2), 11.4 (B3), 15.4 (B5). Only B5 and
B3 exceed row A's own spread, and in both the excess is desaturation of shaded tips on
a highly saturated head, not a second colour.

An exhaustive chromaticity scan (every hair pixel more than 18 units from that head's
median chromaticity, clustered) found **exactly one out-of-colour patch**, and it is
the same patch in every head:

> **The widow's-peak apex, x 136-138, y 39-43.** A ~2x3 px warm rust cluster sitting
> inside the hair.
> - B6: patch **(97,59,41)** / **(99,76,68)**; surrounding hair **(118,113,115)** and
>   **(127,122,124)**. The patch is R−B = +56 where the hair is R−B = −6.
> - B7: patch **(100,63,46)** / **(76,58,37)**; surrounding hair **(65,73,47)** and
>   **(69,79,51)**.
> - B4: patch **(114,81,65)**; surrounding hair **(108,99,86)**.
>
> It is the antialiased tip of the forehead skin blending into the hair edge, not
> mis-tinted hair. It is present in row A too — same pixels, **(85-93,58-67,45-55)** in
> all seven A plates — where brown hair hides it. Recolouring the hair exposed it.

A second, smaller instance of the same thing: a 2-3 px warm seam down the inner edge
of the right side-lock, **x 167-169, y 98-140**. B6 reads **(92,82,80)** there against
hair **(121,117,121)**; B7 reads **(61,59,40)** against hair **(67,80,53)**. Again a
skin/hair blend boundary, again pre-existing.

Nothing else. No lock, no fringe, no jaw tip in row B carries a different colour from
its own head.

---

## B. Strand detail and shading, or a flat mass?

**Not a flat mass — the shading and the strands are still there — but the light heads
do read flatter, and the number is about a third.**

Relative contrast inside the hair mask, luminance percentiles:

| | A (cols 2-7) | B2 | B3 | B4 | B5 | B6 | B7 |
|---|---|---|---|---|---|---|---|
| mean L | 36.9-37.5 | 59.9 | 75.1 | 117.3 | 66.5 | 126.5 | 78.0 |
| (P90−P10)/P50 | 1.149-1.178 | 0.734 | 0.734 | **0.747** | 0.730 | **0.745** | 0.739 |
| std/mean | 0.589-0.635 | 0.375 | 0.339 | **0.306** | 0.357 | **0.304** | 0.328 |
| Michelson (P90,P10) | 0.557 | 0.418 | 0.421 | 0.429 | 0.417 | 0.431 | 0.426 |

**Row B columns 2-7 carry 63-65% of row A's relative contrast** by (P90−P10)/P50, and
48-61% by std/mean. High-frequency strand energy tells the same story: absolute
high-pass RMS inside the hair is unchanged or higher (A 5.5-7.7, B 5.3-8.3), but as a
fraction of local brightness it falls from **0.15-0.21 in row A to 0.061-0.097 in B2-B7**
— B6 is the flattest at 0.061, B4 next at 0.068.

The reason is a black lift, not a loss of detail. Fitting each B head's luminance
against B1's: `L = 0.89·L + 27.7` (B2), `1.05·L + 37.9` (B3), `1.35·L + 71.9` (B4),
`0.91·L + 34.2` (B5), `1.40·L + 80.0` (B6), `1.01·L + 43.0` (B7). The darkest 5% of
hair pixels lift from L≈9 in B1 to L≈40 (B4) and L≈42 (B6). In *absolute* luminance
range the light heads gain: dark-5%-to-bright-95% span is 69 L in B1 against **121 L in
B4 and 131 L in B6**. So the light-to-dark ramp is intact and the strands are intact;
they simply sit on a raised floor, so per unit of brightness the modelling reads
softer.

**Verdict: B is flatter than A in relative terms by roughly one third, worst on B6 and
B4.** It is a tone-curve problem, not a lost-detail problem — pulling the shadow floor
back down on the light tints would recover most of it without touching the strand
texture.

One consequence worth naming: the dark speckle in the crown texture, invisible at row
A's level, becomes visible when the floor lifts. In the window x100-140, y18-42,
pixels more than 12 L below their local 5x5 mean number **8-12 in every A plate and in
B1, but 42 in B4 and 56 in B6**, with dips of 27-36 L. On the ash and silver heads it
reads as grit or dandruff scattered across the top-left crown.

---

## C. Are eyes, eyebrows, skin, mouth and clothing identical between A and B?

**Yes — to well under one 8-bit level. There is no colour bleed from hair onto skin or
clothing anywhere in the sheet.**

Means over fixed masks, A vs B, per column (largest deviation of the seven shown):

| region | px sampled | A | B | max |B−A| per channel |
|---|---|---|---|---|
| skin (face + neck, hair excluded) | 3,632 | (206.9,176.8,159.4) | (206.8,176.7,159.2) | 0.20 |
| green cloak | 6,225 | (85.0,80.7,48.3) | (85.2,80.8,48.3) | 0.18 |
| white shirt | 5,486 | (236.9,234.7,232.3) | (236.8,234.6,232.2) | 0.13 |
| eye/brow ink | 171 | (18.8,18.3,18.3) | (18.4,18.0,18.0) | 0.36 |

Fixed points confirm it: right eyebrow core (75 px at x126-152, y64-78, clear of the
hair) is **(22,16,16)** in A1-A3 and B1-B3 and **(39-45,31-37,29-35)** in A4-A7 and
B4-B7 — the same value in both rows, column for column. Nose (114,115), chin
(116,140), lower lip (118,134), neck (128,175), cloak shoulder (80,215) and hood
(150,190) all match to 0-2 units.

The only A-vs-B differences anywhere outside the hair are geometric, not chromatic:

- **A 0.5 px horizontal offset between the rows in columns 1 and 2 only.** Cross-
  correlating the garment region, c1 best-aligns at dx = −0.5 and c2 at dx = +0.5;
  columns 3-7 align at 0.0. This is what produces the ~2,800 edge pixels that differ
  between A1/B1 and A2/B2 along the embroidery and the eye outlines. No hue change.
- A **~3.5% exposure step by column**, present identically in *both* rows: the cloak
  means (85.0,80.7,48.3) in columns 1-3, (86.4,82.0,49.6) in column 4, (87.9,83.2,50.0)
  in columns 5-7. A capture-rig inconsistency, not a portrait one.

Two things that stay constant and therefore *become* mismatches once the hair changes,
covered under D: the eyebrows, and the shadowed ear.

---

## D. Visible defects in row B, worst first

1. **All seven are the same person.** Face, eyes, brows, freckles, mouth, ear,
   earring, neck, garment, pose and lighting are pixel-identical across the row
   (Δ ≤ 0.4/255 over 15,000+ sampled pixels). Only the hair colour differs, and the
   hair *shape* is identical too — one cut, seven tints. Whole plate. This is the
   single biggest thing separating these portraits from the owner's own dialogue
   reference on `owner-board-2026-08-15-systems-and-castle.png`, where Grandpa Elias
   has his own head shape, beard, garment and lighting.

2. **Eyebrows stay jet black on every head.** Right brow **(22,16,16)** in B1-B3,
   **(39-45,31-37,29-35)** in B4-B7 — identical to row A. B4 (hair L* 49), B6 (hair
   L* 53) and B7 (green) all wear black brows. Position x126-152, y64-78 and x86-104,
   y70-80. On B6 it is the loudest error in the row: a silver-haired villager with
   black eyebrows reads as a bad wig, not as a different person.

3. **Warm skin cluster inside the hair at the widow's-peak apex**, x136-138, y39-43:
   B6 **(97,59,41)** against **(118,113,115)**, B7 **(100,63,46)** against
   **(65,73,47)**, B4 **(114,81,65)** against **(108,99,86)**. Pre-existing (it is in
   row A too) but only visible once the hair stopped being brown.

4. **Crown speckle exposed by the lifted shadow floor.** x100-140, y18-42: 42 dark
   outlier pixels in B4 and 56 in B6, against 8-12 in every A plate and in B1; dips of
   27-36 L below local mean. Reads as grit on the ash and silver heads.

5. **The shadowed ear becomes a brown clump inside light hair.** The ear at x150-166,
   y126-146 is a constant **(100,87,82)** in all fourteen plates. Against B1's hair
   that is invisible; against B4 **(112,107,97)** and B6 **(116,114,120)** it is the
   warmest and one of the darkest things inside the hair silhouette, and at a glance it
   reads as a patch of brown hair behind the ear rather than as an ear.

6. **Silhouette contrast against the light plate ground collapses on the light heads.**
   Outer hair contour mean luminance: 82-84 in row A and B1 (Weber contrast 0.65-0.66
   against the L=242 ground), 99.4 (B2), 106.8 (B5), 112.5 (B3), 114.3 (B7),
   **150.6 (B4, 0.38)** and **157.0 (B6, 0.35)**. Whether this bites depends on the
   dialogue box these sit on, which I cannot see here — but B4 and B6 have roughly half
   the edge contrast of the rest of the row, and any light or pale dialogue panel will
   erase their crown line.

7. **Hard-edged grey wedge on the character's left cheek** (viewer's right), x136-160,
   y115-127. Skin drops from **(220,192,177)** to **(136,120,115)** across a jagged,
   single-pixel-stepped boundary — a ~35% luminance drop with no soft terminator. Reads
   as a bruise or a smear of dirt, not as a shadow. Present in every plate of *both*
   rows, so it is not a row-B regression, but it is the most conspicuous non-hair
   artefact on the sheet and it sits directly beside the mouth where a reader's eye
   goes.

8. **2-3 px warm seam down the inner edge of the right side-lock**, x167-169, y98-140:
   B6 **(92,82,80)** where the hair is **(121,117,121)**; B7 **(61,59,40)** where the
   hair is **(67,80,53)**. Sub-pixel at dialogue size; visible at full plate size.

9. **B7's olive green sits ΔE 9.3 from the villager cloak.** Hair mean **(70,82,56)**,
   Lab (33.4, −10.2, +13.8); cloak **(88,83,50)**, Lab (35.0, −3.6, +20.1) — ΔL only
   1.9. In these plates hair and cloak never touch (hair ends ~y152, the cloak starts
   ~y175, with background between), so it costs nothing here. In game, drawn over a
   dialogue box or against a body wearing that cloak, a head whose hair is within ΔE 10
   of the garment beneath it will lose its silhouette. Worth moving before it ships.

---

## E. Which of the seven would still be confused at ~72 px?

Rendered down to 72x72 and measured over the downsampled hair mask (577 px), pairwise
mean ΔE76:

|  | B1 | B2 | B3 | B4 | B5 | B6 | B7 |
|---|---|---|---|---|---|---|---|
| **B1** dark brown | — | 15.4 | 24.7 | 34.5 | 27.1 | 39.0 | 24.9 |
| **B2** mid brown | 15.4 | — | **10.1** | 28.0 | 13.5 | 34.5 | 22.9 |
| **B3** copper/auburn | 24.7 | **10.1** | — | 27.2 | **7.7** | 34.6 | 27.3 |
| **B4** warm ash | 34.5 | 28.0 | 27.2 | — | 33.7 | **11.8** | 21.4 |
| **B5** rust red | 27.1 | 13.5 | **7.7** | 33.7 | — | 39.6 | 33.5 |
| **B6** cool silver | 39.0 | 34.5 | 34.6 | **11.8** | 39.6 | — | 28.5 |
| **B7** olive green | 24.9 | 22.9 | 27.3 | 21.4 | 33.5 | 28.5 | — |

Hair mean colours behind the table: B1 (49,34,25) L*15; B2 (84,54,36) L*26;
B3 (110,67,43) L*33; B4 (123,116,105) L*49; B5 (110,56,36) L*30; B6 (128,125,131)
L*53; B7 (70,82,56) L*33.

**Pairs that would still be confused across one conversation chain:**

1. **B3 and B5 — the worst by a clear margin.** ΔE 7.7, ΔL only 2.9. Two copper
   redheads at the same lightness; the whole difference is 6 units of a*. At 72 px on
   an identical face and an identical cloak, these are one character. Fix this pair
   first — push one to a genuine chestnut (drop L*, add b*) or the other to a strawberry
   blond (raise L* by 12+).
2. **B2 and B3.** ΔE 10.1, ΔL 7.1. Distinguishable side by side, not distinguishable
   from memory two dialogue boxes apart.
3. **B4 and B6.** ΔE 11.8, ΔL 3.6. Warm ash against cool silver — the entire signal is
   b* +7.1 vs −2.8, which is exactly the axis that survives worst through a
   downsample and worst again on a tinted dialogue panel. The lightness barely
   separates them (L* 49 vs 53). Give one of them ~15 points of L* separation.
4. **B2 and B5** (13.5) and **B1 and B2** (15.4) are borderline; both are readable at
   72 px, but only because the pairs above are worse.

Everything else in the row is ≥ 21 and safe.

**The real answer to the question, though, is that all twenty-one pairs are confusable,
because hair colour is the only variable in the row.** Same head, same eyes, same
eyebrows, same freckles, same ear, same earring, same mouth, same cloak, same pose,
same light. A player meeting these seven in one chain will not remember seven people;
they will remember one person and a colour. Silhouette is the criterion that decides
readability at dialogue size, and at 72 px these seven silhouettes are byte-identical.
Hair *shape* — length, parting, whether it is tied — buys more separation per unit of
work than any further colour tuning, and unlike colour it survives a dark panel, a
colour-blind player and a thumbnail.

For contrast: **row A gives zero differentiation.** Its seven plates are the same image
— crown mean (58,40,28) in all seven, zone values matching to ±1, differing only by
sub-pixel antialiasing. B1 is that same colour exactly (crown (58,40,28)), so row B
adds six new tints, not seven.

---

## Summary

Row B does the thing it evidently set out to do, and does it cleanly: the recolour is
hue-stable crown to tips in all seven heads, it leaves skin, eyes, mouth and clothing
untouched to under a level, and it bleeds onto nothing. The measured costs are a
one-third drop in relative hair contrast from a lifted shadow floor, three small
pre-existing skin/hair blend artefacts that brown hair used to hide, and a pair of
light heads with half the silhouette contrast of the rest.

The two changes that would earn the most, in order:

1. **Recolour the eyebrows with the hair** (defect 2). One value, biggest visible win,
   and it is the difference between "different villager" and "same villager in a wig".
2. **Separate B3 from B5 and B4 from B6** (question E), then vary the hair *shape* —
   because seven identical silhouettes is the ceiling this row is up against, and no
   amount of further colour work raises it.
