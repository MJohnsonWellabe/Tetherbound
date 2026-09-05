# Blind visual verdict — dialogue portrait plates (contact sheet `plates_AB.png`)

Judged from pixels only. I was told nothing about what either row is, which is older,
or what either row is meant to prove. Reference material consulted:
`docs/reference/README.md`, `tetherbound-meadows-keyart.png`,
`owner-board-2026-08-15-creature-colors.png`,
`owner-board-2026-08-15-systems-and-castle.png`, `palworld-02-open-field-path.jpg`.

Coordinates below are **within a single 256×256 plate, origin top-left**. "Right"
means the viewer's right (the character's left).

Facts that hold for all fourteen plates: ground is flat `#F2F2F2` (242,242,242) with
no vignette; figure bounding box y10–255, x47–234; foreground coverage 44.5–45.3%.
The crop, the camera and the key light are the same in every cell of both rows.

---

## A. How many distinct people per row

### Row A — one person, seven times.

Not "similar" — the same. Hair crown samples read (64–65, 45, 33) in **all seven**
cells; whole-hair means run (49–54, 35–40, 27–32). Every pairwise difference inside
row A is confined to one-pixel outlines around the eyes, mouth, jawline and tunic
folds — the signature of a sub-pixel camera jitter between render passes, not of a
different asset. Head-silhouette XOR is ≤57 px within groups and ~130 px between
them, on a head of ~9,300 px.

The jitter falls into three alignment groups — {A1,A2,A3}, {A4}, {A5,A6,A7} — and
that is the *only* structure in the row. Nothing about hair colour, hair shape, face,
skin, eyes, brows, mouth or clothing differs between any two cells.

**Count: 1.** All seven cells are the same person. A player shown A1 through A7 in
sequence would see the identical portrait seven times.

### Row B — seven hair colours on one person.

Crown / whole-hair sampled colour:

| cell | crown RGB | hair-mass mean | reads as |
|---|---|---|---|
| B1 | 65, 45, 33 | 51, 37, 29 | dark brown — **identical to row A** |
| B2 | 105, 68, 44 | 84, 57, 41 | mid warm brown |
| B3 | 139, 85, 54 | 104, 67, 45 | chestnut / light auburn |
| B4 | 156, 149, 136 | 121, 114, 105 | warm ash grey |
| B5 | 138, 70, 44 | 108, 61, 42 | rust / copper |
| B6 | 162, 161, 171 | 123, 121, 126 | cool silver |
| B7 | 86, 104, 71 | 72, 83, 59 | muted green |

Everything that is not hair is byte-for-byte the same portrait. Diffing B1 against
B2–B7 lights up the hair mass and nothing else but antialias edges: skin, eyes,
eyebrows, mouth and clothing interiors come back black.

The hair **mesh** is also shared. Head-silhouette XOR between B cells peaks at 448 px
of ~9,300 (≤5%), and the pattern of that difference tracks the same three jitter
groups already present in row A — i.e. it is render alignment, not a different
haircut. Same parting, same fringe, same two side-locks, same tips.

**Count: 1 person in 7 tints**, not 7 people. What makes the cells "distinct" is a
hue/value shift on one hair texture. What makes them identical is everything else:
one head, one hair mesh, one skin, one expression, one hooded green tunic with the
same gold clasp, one pose, one crop.

---

## B. Column-by-column, A vs B

**Column 1 — nothing changed.** Crown (65,45,33) → (65,45,33); hair mean (51,37,29)
→ (49,35,27). Whole-plate mean absolute difference 3.6/255, and the diff mask is
pure edge outline. B1 is A1 re-rendered.

**Columns 2–7 — the hair albedo, and only the hair albedo.** Measured on flat
interiors, A → B:

| sample | A | B (range across cols) |
|---|---|---|
| background | 242,242,242 | 242,242,242 (exact, all 7) |
| nose bridge | 226,196,180 | 225–228, 195–198, 179–181 |
| left cheek | 204,173,152 | 204–206, 172–174, 151–153 |
| mouth line | 192,167,154 | 191–193, 166–168, 153–155 |
| chin | 163,142,131 | 161–172, 140–150, 130–138 |
| tunic, left shoulder | 93,86,48 | 91–93, 85–86, 48–49 |
| collar under right hair tip | 103,97,57 | 101–105, 96–99, 57–58 |
| darkest eyebrow pixels | 10,6,6 | 10–11, 6–10, 6–10 |

**Answer to "are eyes, eyebrows, skin, mouth and clothing identical between A and B
in every column?" — yes**, to within 1–3 levels, which is the same render-to-render
noise floor already measured in column 1 where nothing changed at all. There is no
recolour bleed into skin or cloth beyond a 1–2 px antialias fringe at the hairline.

Where each column's change lives: the hair mass, y≈10–160, x≈60–200. Nothing else
in the plate moved.

That the eyebrows are identical is not reassurance — see defect 3.

---

## C. Visible defects in row B, worst first

**1. The recolour destroyed the hair's strand detail.** In row A (and B1) the hair
carries continuous directional striations running crown → tip; it reads as hair. In
B2–B7 those striations are gone. What is left is a smooth, latex-like mass with a
sparse network of thin dark scratches over it — it reads as craquelure, or chipped
paint on a ceramic wig. Relative contrast inside the hair mass falls from 0.50 (every
A plate, and B1) to 0.38–0.43 (B3, B4, B6, B7). Worst in **B7** and **B4**, whose
left mass is effectively one flat value from crown to jaw. Location: crown band
y≈14–70, x≈74–184, and the whole left fall.

**2. Untinted brown patches stranded inside the recoloured hair — B4, B6, B7.** The
side-lock in front of the right ear still carries the original dark brown. At
(x178, y118) and (x178, y124): B4 = (39,27,19) and (41,26,19); B6 = (33,20,11) and
(35,21,12); B7 = (36,23,16) and (39,24,17) — against B1's (37,25,16) at the same
pixels. These are literally the unrecoloured source pixels. A second patch sits on
the tip at (x172–178, y148–154). Roughly 2% of each plate's hair pixels. Against ash,
silver and green this reads as a smear of mud or a dead insect at the jawline, and it
is still visible after downscaling to 72 px. This is the loudest single defect in the
row.

**3. Eyebrows were never recoloured.** Darkest brow pixels are (10,6,6) to (11,9,10)
in all fourteen plates. On **B4** (ash), **B6** (silver) and **B7** (green) that puts
near-black brows under pale or green hair. It is the clearest tell that these are
tinted rather than designed, and it is visible at dialogue size.

**4. Pale tints lose the hairline silhouette.** At the left temple the outer lock at
(x81, y108) goes from (65,43,33) in A6 to (174,142,121) in B6, against skin at
(204,171,149). The lock's inner edge nearly dissolves into the cheek. Same in B4.
B1/B2/B3/B5 keep a firm dark boundary there; B4 and B6 do not, so their faces lose
the framing shape that reads "hair" at small size.

**5. The tint is not applied at constant hue.** B4's crown is warm ash (156,149,136)
while its right-hand fall is a cooler grey-green; B6 shows a warm cast at the left
temple against a blue-grey crown. The mass does not read as one dyed head of hair.

**6. B7's green is inside the garment's own colour family.** Hair Lab (33.7, −9.3,
12.7); hood and tunic Lab (36–42, −3 to −4, 23–25). ΔE 12–16, same hue quadrant, near
the same lightness. The hair-to-shoulder boundary at the jaw goes soft — which is
also exactly where defect 2 sits, so that corner of B7 is the messiest 20×20 px on
the sheet.

**7. Not caused by row B, but it disfigures every plate in it.** A pure neutral grey
chevron sits on the right cheek, running from below the eye toward the jaw at roughly
x138–166, y100–118. Core value (86–96) with channel chroma of 1–3, on skin of
(204,170,148). On a warm face that reads as a bruise or a smear of ash, not as
shading. Present at identical values in all fourteen plates. Beside it, under the
right hair tip on the collar (x150–185, y150–185), a hard black wedge crushed to
luminance 0 sits immediately adjacent to 242 background showing through a gap between
hair and shoulder — a 0-to-242 jump with no falloff. Both are base-asset defects. No
hair colour hides either, and re-tinting did not touch them.

---

## D. Does row B hold together as one UI family?

**Yes.** Ground is exactly (242,242,242) in all seven with no vignette; the bust
framing is pixel-identical (bbox y10–255, x47–234; coverage 44.6–45.3%); same key
light, same camera, same crop, same rendering style. Nothing in row B breaks family
with the rest of row B, and B1 is indistinguishable in family from row A.

Two family notes one level up, which apply to **both** rows equally and are therefore
not a row-B regression:

- The near-white plate does not match the project's own dialogue-portrait reference.
  The Grandpa Elias panel on `owner-board-2026-08-15-systems-and-castle.png` is a
  painted bust on a dark blue-teal vignette with rim light. A `#F2F2F2` plate will
  punch a bright hole in a dark dialogue box and will fight the UI rather than sit
  inside it.
- The Palworld set contains no dialogue portrait — see `palworld-02`, which is HUD
  and world only — so it cannot arbitrate this question, and the rubric forbids
  judging UI against it anyway.

---

## E. Would a player tell these seven apart in one village conversation chain?

**No — not as seven people.** Three or four at best, and what they would learn is
"the villager with the green hair", not seven villagers.

The reason is structural, not chromatic: same face, same eyes, same eyebrows, same
grey cheek chevron, same cheek mole, same smile, same hood, same clasp, same pose,
same crop. Hair hue is the *only* identity signal in the row, and hue is the weakest
of the signals a player uses to remember a person.

Downscaled to 72 px — dialogue-box size — ΔE (CIE76) between the hair colours:

|   | B1 | B2 | B3 | B4 | B5 | B6 | B7 |
|---|---|---|---|---|---|---|---|
| **B1** | — | 13.4 | 21.6 | 32.7 | 23.7 | 36.7 | 23.4 |
| **B2** | | — | **8.3** | 25.0 | 11.4 | 31.0 | 20.5 |
| **B3** | | | — | 24.7 | **5.4** | 31.5 | 23.8 |
| **B4** | | | | — | 28.6 | **8.9** | 19.2 |
| **B5** | | | | | — | 34.8 | 29.1 |
| **B6** | | | | | | — | 25.6 |

Pairs that would still be confused:

- **B3 and B5 — certainly.** ΔE 5.4, and L* 32.1 vs 31.1. Identical lightness, both
  warm. At portrait size these are the same character.
- **B4 and B6 — very likely.** ΔE 8.9, L* 48.4 vs 51.1, both near-neutral. Both read
  as "the grey-haired one"; a player would need them side by side to notice one is
  warm and one is cool, and a conversation chain never shows them side by side.
- **B2 and B3 — likely.** ΔE 8.3. Mid brown against chestnut, one step apart.
- **B1 and B2 — borderline.** ΔE 13.4; separable only because B1 is much darker.

Unambiguously their own person: **B7** (green, ΔE ≥ 19 from everything) and **B1**
(darkest by a wide margin, L* 16). That is two reliable identities out of seven.

---

## The three things that most separate these plates from the reference

1. **The reference portrait is a *person*; these are a slider.** The Grandpa Elias
   panel on `owner-board-2026-08-15-systems-and-castle.png` differentiates by face,
   age, beard, expression, costume and its own lighting. Row B differentiates by hue
   on one head. Named frames: **B2, B3 and B5** are the same portrait three times with
   the dial nudged; **B4 and B6** are the same portrait twice.
2. **The reference renders hair; these render a cap.** The board's portrait has
   strand direction and specular in the hair. **B4, B6 and B7** have a flat mass with
   a crack network over it (crown band y14–70), and **B4/B6/B7** additionally carry
   the untinted brown patch at x176–186, y110–152 that the board's portrait obviously
   has no equivalent of.
3. **The reference sits on a dark contained ground; these sit on a light-box plate.**
   `#F2F2F2` in every cell of both rows, against the board's dark blue-teal vignette.
   This one is not row B's doing but it separates every plate on the sheet from the
   project's own dialogue reference.

## The two bar questions

**A. Do these read as belonging to the world in `tetherbound-meadows-keyart.png`?**

**Partly — yes on the character, no on the plate.** The costume is on-palette: the
olive tunic (93,86,48 / 107,101,58) and the gold clasp sit squarely inside the board's
natural-palette swatch row, and the skin is a warm, readable stylised tone consistent
with the board's day panels. What does not belong: the flat `#F2F2F2` ground, which
appears nowhere in the board's language; the neutral grey chevron on the cheek, a
pure achromatic value on a palette that has no achromatic greys in it; and **B7**,
whose hair green (Lab 33.7, −9.3, 12.7) lands inside the same foliage green the board
reserves for the world, so the character reads as camouflaged against her own tunic.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be the
same kind of game?**

**Not answerable from these plates, and I will not manufacture an answer.** The
Palworld set has no dialogue portrait — `palworld-02` is world and HUD — and the
rubric explicitly bars judging UI against it. The one thing I can say honestly is
that the character rendering itself is in a different register: large flat anime eyes
with hard black masses, an almost featureless mid-face, and very low internal detail
in skin and cloth. That is a stylistic choice, not a defect, but it is not the
register the Palworld shots are in, and it is identical in row A and row B, so
nothing on this sheet moves it either way.

## Fixable by changing what is in the build vs. needs art that isn't here

**Fixable now (data / material / pipeline):**

- Recolour mask coverage — the brown patches at x176–186, y110–152 and x172–178,
  y148–154 in B4, B6, B7 are unremapped source pixels, not a lighting effect.
- Recolour the eyebrows with the hair. They are (10,6,6) in all fourteen plates.
- Preserve the albedo's luminance detail when tinting, instead of replacing it — the
  drop from 0.50 to 0.38 relative contrast in the hair mass is what turns hair into
  a latex cap.
- Spread the seven hues so no pair sits under about ΔE 20 at 72 px, and separate them
  in **L\*** as well as hue. Right now L\* clusters at 16 / 27 / 31–32 / 34 / 48 / 51.
- Pull B7's green off the tunic green, or change one of the two.
- Change the plate ground to something that reads against the dialogue box, per the
  Grandpa Elias reference.
- Fix the grey cheek chevron and the crushed-black collar wedge on the source asset.
  They are the most disfiguring thing on the sheet and they are in every plate.

**Not fixable by tinting — needs art that is not in these plates:**

- Seven villagers cannot come out of one head, one hair mesh, one costume and one
  expression. Even with a perfect recolour, row B is one woman in seven wigs. Distinct
  NPCs need varied hair meshes, varied face shape and age, and costume colour
  variation. Nothing on this sheet supplies any of that, and no amount of hue
  separation will.
