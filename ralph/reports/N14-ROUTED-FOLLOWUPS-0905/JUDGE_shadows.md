# Blind visual judgement — `_sheet_shadows_ab.png`

Frames judged: `shots/n14/world_ship/` — three camera stands
(`bridge-approach-played`, `bridge-checkpoint-shoulder`, `village-square-signpost`),
each captured twice, 1280×800.
References used: `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg`.

All luminance figures below are Rec.709 luma on a 5-px median-filtered copy
(median filter removes grass-blade aliasing so the numbers describe the surface,
not the sampling). Region coordinates are image pixels, origin top-left.

---

## 1. What is wrong with these frames — ranked, worst first

### 1. There is not a single creature in any of the six frames.
Three camera stands covering a checkpoint, a bridge approach and the village
square, and the world contains two humans, a villager doll and props. All five
Palworld reference shots have creatures on screen — `palworld-02` has three
mid-frame plus one at the player's shoulder, `palworld-05` has one at arm's
length and three more in the base. The key art's DAY and NIGHT panels both put a
creature beside the trainer. As shot, this reads as an empty prop yard for a
game named after the bond with a creature. This is the loudest gap and it is not
a lighting problem.

### 2. Row 2 — the foreground trunk is wearing the faction's danger colour, and it is the largest colour mass in the frame.
The trunk occupies x 740–1060 (25% of frame width) at full frame height. Its lit
side measures median RGB **(124, 50, 22)** — hue ≈16°, saturation 0.82. The Team
Tether banner cloth **in the same frame** measures **(150, 64, 49)** — hue ≈9°,
saturation 0.67. The tree is a closer hue match to the faction banner than any
other trunk in the survey (village oak `(88, 58, 44)`, hue 19°, sat 0.50;
row-3 porch post `(84, 58, 29)`, sat 0.65) — and it is *more* saturated than the
banner it sits beside. The rubric's question "is the oxblood still reserved for
danger" answers itself here: no. Compounding it, the trunk carries no bark
texture at all — smooth vertical creases only — so at 30% zoom it reads as a red
curtain drawn across the right of the frame, not as wood.

### 3. Row 2 — the mid-ground and horizon are empty.
Between the checkpoint cluster (x 200–650) and the sky, roughly 400 000 px of
undifferentiated green carries nothing but a field of evenly-spaced dark speck
decals (clearly visible as a regular dot lattice at x 1050–1280, y 400–470). No
rock, no tree of any size, no path, no structure, no silhouette on the skyline.
The key art puts a tower, a windmill and a mountain in exactly this band;
`palworld-04` puts a plateau there. Nothing in this frame reads as somewhere to
walk to. Fixable by scene work.

### 4. Row 3 — the camera is parked inside architecture and a quarter of the frame is dead.
**25.2% of the frame is below luminance 50 and 10.6% is below luminance 30** — a
featureless near-black porch soffit down the left edge plus an untextured grey
stone mass filling the bottom-left quadrant. The subject (Mira's house and the
signpost) is squeezed into the middle third, and the signpost planks collide with
the building behind them: the "The Inn" plank crosses the window mullions at
x 655–745, y 375–400, and "The Pond" overlaps the stone course. Compare the
composition discipline in `palworld-05`, where the foreground is the player and
one creature and everything else is legible depth.

### 5. Flat untextured grey placeholder surfaces sit directly beside fully textured ones.
Row 1: the gate threshold slab, x 560–830 / y 545–580, is uniform grey
`(142, 141, 123)` with no texture, normal detail or edge wear, immediately
adjacent to a gatepost `(197, 189, 171)` carrying visible block courses and
grime. Row 3: the entire foreground wall/roof mass is that same untextured grey.
Both read as collision boxes that never received a material.

### 6. Prop shadow casting is inconsistent between props two metres apart.
Even in the better of the two columns, the largest foreground prop in row 1 —
the crate at x 150–320 / y 545–700 — casts nothing. Ground immediately down-sun
of it (x 325–365, y 660–700) measures **121.4**, while grass 120 px further away
measures **99.2**: the crate's contact zone is the *brightest* ground in its
neighbourhood. The sawhorse barricades a couple of metres away do cast a clear
shadow. Something has cast-shadow disabled per-mesh.

### 7. Scatter and dressing read as generator output, not authored.
Row 1 places two identical oxblood banners at near-identical screen height,
symmetrically flanking the frame (left x 295–425, right x 960–1050), and two
sawhorse barricades of the identical model and scale mirrored across the path.
Ground cover is a single grass-blade model at one scale, planted at near-even
spacing with bare terrain visible between blades, plus one repeated white
five-petal flower prop. `palworld-02`'s ground layer carries three or four
distinct species at different heights, clumped into patches with genuine
clearings between them.

### 8. Row 2 — hard terrain material seam and slope stretching.
An unblended arc where the near golden-brown terrain layer meets the mid green
layer runs across the frame at y ≈ 390 (clearest at x 1040–1280). The steep left
hillside (x 0–330, y 230–330) shows the splat texture smeared vertically down the
slope with a hard line where it meets grass. Both read as bugs, not choices.

### 9. Both humans stand in a stiff neutral idle and nothing in the frame is happening.
Row 1: the trainer faces a gate he does not touch, arms splayed away from the
torso; the Tether guard's hand rests on nothing. Row 3's villager (x 505–545,
y 372–430) is a markedly lower-fidelity asset than the trainer — a flat black
hair cap, no facial shading, painted-on vest — and stands in the same neutral
pose. `palworld-01` and `-03` both read instantly as *an event in progress*.

### 10. Distant vegetation degrades badly.
Row 2's bare tree at x 350–400 / y 185–280 aliases to a near-black scribble that
reads as a rendering glitch. The distant tree clusters at x 520–700 are the same
two green blobs repeated with visible flat card edges.

### 11. Terrain macro texture is low-frequency and blurry at contact scale.
Row 2's near field (x 0–400, y 700–800) is soft blotches at roughly 1–2 m scale
with no detail where the player's feet are. `palworld-02`'s path carries pebble
and dirt detail right at the character's feet.

### 12. Windows are flat single-value cream rectangles.
Row 3, x 645–745 and x 800–880: no glass, no frame depth, no interior value, no
reflection. At 30% zoom they read as stickers on the wall.

### 13. Minor scale note — the checkpoint gate is short.
Ruler: the trainer measures **198 px** (head top y 427, boot bottom y 625) = 1.80 m,
so ≈110 px/m at his depth. He stands one step from the gate; the gate leaf's top
rail is at y 387, only **40 px above his head**, putting the "fortified" bridge
gate at roughly **2.2 m** — low enough that a person clears it by eye and could
pull himself over. Gateposts read ≈2.7 m. Everything else agreed on scale: crate
≈1.3 m, barrel ≈0.9 m, foreground trunk ≈1.9 m diameter. I flag the gate as
possibly-intentional; the rest of the frame is scale-consistent.

---

## 2. A vs B

**There is a real, substantial and consistent difference, and it is not subtle
once you know where to look: column B renders near- and mid-field cast shadows
that column A does not render at all.** In all three rows.

### The difference is local occlusion, not exposure or grade

Whole-frame mean luminance is essentially identical, so nothing global moved:

| Row | mean luma A | mean luma B | B/A |
|---|---|---|---|
| bridge-approach-played | 111.71 | 111.42 | 0.997 |
| bridge-checkpoint-shoulder | 98.27 | 98.10 | 0.998 |
| village-square-signpost | 91.07 | 90.57 | 0.995 |

Per-frame 1st/50th/99th luminance percentiles and mean saturation match to within
0.2 units in every row. No tone curve, no exposure, no colour change.

### Where B is darker — measured region medians

Every "control" region below is ground of the same material a short distance
away from the shadow, chosen down-sun-adjacent so it should be identical if
nothing but shadowing changed.

**Row 1 — `bridge-approach-played`**

| Region | x | y | A | B | B/A |
|---|---|---|---|---|---|
| gatepost face behind trainer (trainer's own body shadow) | 482–527 | 522–562 | 40.8 | **20.8** | **0.51** |
| barricade cast shadow on grass | 506–622 | 684–722 | 43.3 | **26.5** | **0.61** |
| barricade leg shadow | 678–701 | 628–691 | 61.4 | **37.9** | **0.62** |
| ground down-sun of left barricade | 303–369 | 606–629 | 107.5 | **67.6** | **0.63** |
| ground below right barricade | 899–968 | 645–660 | 51.4 | **33.6** | **0.65** |
| *control:* dirt path centre | 700–800 | 700–760 | 106.7 | 107.5 | 1.007 |
| *control:* distant meadow | 560–760 | 330–370 | 97.3 | 97.1 | 0.997 |
| *control:* crate-adjacent ground | 320–395 | 640–700 | 118.5 | 118.7 | 1.001 |

**Row 2 — `bridge-checkpoint-shoulder`**

| Region | x | y | A | B | B/A |
|---|---|---|---|---|---|
| grass, near-field bottom-left | 26–110 | 756–793 | 86.9 | **51.0** | **0.59** |
| grass, near-field | 131–182 | 763–789 | 65.9 | **46.1** | **0.70** |
| grass, right of trunk | 1121–1177 | 676–692 | 45.9 | **29.2** | **0.64** |
| *control:* lit grass, same material | 200–300 | 750–790 | 97.9 | 97.5 | 0.996 |
| *control:* far meadow | 950–1100 | 600–640 | 54.4 | 54.2 | 0.997 |

**Row 3 — `village-square-signpost`**

| Region | x | y | A | B | B/A |
|---|---|---|---|---|---|
| house wall left of window (signpost's cast shadow) | 648–717 | 371–405 | 98.5 | **49.9** | **0.51** |
| grass under the tree line | 876–974 | 597–648 | 62.7 | **38.1** | **0.61** |
| grass left of the path | 145–303 | 586–611 | 38.9 | **22.4** | **0.58** |
| *control:* foreground stone path | 200–330 | 700–760 | 21.4 | 21.4 | 1.000 |

The pattern is unambiguous: **shadowed regions drop to 0.51–0.65 of their A
value; unshadowed regions of the same material a few tens of pixels away move by
under 1%.** That is occlusion appearing, not a filter.

### The effect is near-field only, and falls off with distance

Fraction of pixels where B is more than 15% darker than A, by screen row band
(screen y is a proxy for depth in all three shots):

| band (y) | row 1 | row 2 | row 3 |
|---|---|---|---|
| 280–320 (horizon) | 1.8% | **0.8%** | 1.9% |
| 320–360 | 2.7% | **0.2%** | 3.0% |
| 480–520 | 4.3% | 2.3% | 3.1% |
| 640–680 | **7.6%** | 3.1% | 1.2% |
| 760–800 (nearest) | 1.9% | **6.8%** | 2.9% |

Neither column has shadows at the horizon. B adds them from roughly the
mid-ground inward.

### What B specifically gains, frame by frame

- **Row 1.** The two sawhorse barricades lay long shadows across the dirt path
  and the grass (visible as a distinct diagonal band from the left barricade's
  legs, x 450–760 / y 610–740). The trainer casts onto the pale gatepost behind
  his shoulder and onto the ground at his boots. The wicker crate at x 940–1010
  gains a cast shadow on the grass beside the barrel.
- **Row 2.** Each individual grass blade casts a shadow streak on the soil —
  clearest at x 1080–1260 / y 630–760 and x 0–200 / y 740–800. In A the same
  ground is smooth and the blades stand on nothing. The trainer's boots gain a
  contact shadow.
- **Row 3.** The signpost casts onto the house wall and across its own planks
  ("The Inn" and "The Pond" both pick up a shadow across the left of the board);
  the tree line lays a shadow band across the grass strip; the porch structure
  casts across the foreground stone.

### Where B is *brighter* — and why that is not a regression

There are also B-brighter pixels (5 600 / 2 600 / 7 405 px above 18% below the
sky line, per row). Inspected, they are three things, none of them a lost
shadow feature:
1. **Cloud drift and grass sway.** The two columns are separate real-time
   captures, not one render post-processed — the clouds are in different places
   (largest B-darker blobs in every row are in the sky band y < 140), and
   individual grass blades have moved a few pixels between shots. This is the
   noise floor of the comparison, and it is why I discarded everything above
   y = 280 and used median-filtered region medians rather than per-pixel diffs.
2. **Shadows that moved rather than vanished.** Row 3's pair
   x 648–717/y 371–405 (0.51× darker) and x 645–750/y 472–505 (1.49× brighter)
   are the same signpost shadow resolving in a slightly different place — a
   sharper shadow, not a missing one.
3. **Row 1's banner pole** (x 299–340 / y 433–485, 1.43×) — the pole is shaded
   in A and lit in B. This is the only place where A holds occlusion B does not,
   it is one small object, and the banner cloth beside it has visibly moved
   between captures.

I found **no** case where B loses a shadow the frame needed.

### Which column I would ship

**B, without hesitation.** It is the only one of the two in which objects and
the ground exchange any information at all. The cost is confined to the shadow's
reach: the horizon band is identical in both (row 2, y 320–360: 0.2% of pixels
differ by >15%), so B is not giving up any visible distant shadowing to buy the
near-field ones — there was none in A to give up.

**One honest caveat.** At 30% zoom — the size the rubric asks about first — the
A/B difference is close to invisible in rows 2 and 3 and only just perceptible
in row 1 as slightly more ground contrast. The change is real and it matters at
play distance, but it does not alter what the frames read as from across a room,
and nothing on the ranked defect list above is fixed by it.

---

## 3. Objects standing on ground, or flat elements pasted on a backdrop?

**Column A — pasted.** Nothing in A touches the ground. The row-1 barricades,
the row-1 crate, the row-2 grass field and the row-3 signpost all meet the
terrain on a hard bright edge with zero darkening. The measurement that settles
it: in row 1 the ground immediately down-sun of the crate reads **118.5**, while
grass 120 px further from the crate reads **99.2** — the contact point is
*brighter* than its surroundings, the exact inverse of what a grounded object
does. The only value variation on A's ground is the terrain's own blurry macro
texture, which corresponds to nothing standing above it. Row 2 is the clearest
case: a whole meadow of grass blades standing on a smooth, uninterrupted
surface. A is a diorama of cut-outs on a painted floor.

**Column B — mostly standing, with named floaters.** The barricades, both
humans, the signpost, the tree line and every individual grass blade lay a
directional shadow down-sun and the ground takes their shape (0.51–0.65× the lit
value, tabulated above). That is enough to read as sunlight falling on solid
objects sitting in a field.

It is not complete:
- The row-1 foreground crate (x 150–320) still casts nothing — measured 1.001×,
  identical to A. It floats in both columns.
- There is no ambient occlusion anywhere. Every contact line — grass blade into
  soil, barricade leg into grass, crate corner into ground — is a hard edge with
  no soft darkening. B supplies the long directional shadow but not the tight
  contact darkening that actually welds an object to a surface, so props still
  sit slightly *on top of* the ground rather than *in* it.
- Row 3's mid-field props (the white crates at x 590–640, the villager) have no
  ground shadow, so the far half of that frame still reads pasted even in B.

Verdict: **A reads as flat elements on a backdrop. B reads as objects standing
on ground, imperfectly — grounded silhouettes with an unfinished contact.**

---

## Verdict

### The three things that most separate these frames from the references

1. **The references are inhabited; these frames are not.** Every Palworld shot
   and both key-art trainer panels put a creature in frame doing something.
   Across six frames here — `bridge-approach-played`, `bridge-checkpoint-shoulder`
   and `village-square-signpost`, both columns — there are zero creatures and no
   action. Nothing indicates this is a creature game.
2. **The references fill the middle distance with landmarks; row 2's middle
   distance is bare.** `palworld-04` builds the frame around a plateau; the key
   art's main panel puts a tower and a windmill on the far hill. In
   `bridge-checkpoint-shoulder`, the entire band between the checkpoint and the
   sky (x 650–1280, y 300–470) carries nothing but a regular lattice of dark
   speck decals — no rock, no tree, no structure, no skyline silhouette.
3. **The references keep the danger colour scarce; row 2 spends it on a tree.**
   The key art's palette strip puts the two deep reds last and the key art uses
   them only on the stronghold's banners. Here the single largest colour mass in
   `bridge-checkpoint-shoulder` is a foreground trunk at `(124, 50, 22)`,
   hue 16°, sat 0.82 — redder and more saturated than the actual Team Tether
   banner `(150, 64, 49)` standing eight metres behind it in the same frame.

### The two bar questions

> **A. Do these frames read as belonging to the world in
> `tetherbound-meadows-keyart.png`?**

**Yes — narrowly, and on the strength of one frame.** `bridge-approach-played`
carries the board's language convincingly: rolling grassland, oak-grove edge,
a timber-and-stone checkpoint, wildflowers, oxblood faction banners, a warm
midday key with a blue-white sky. Palette agrees — mid luma 121, saturation 0.57,
greens and golds off a natural range. `bridge-checkpoint-shoulder` is dragged
down by the red trunk and the empty middle distance;
`village-square-signpost` is dragged down by the camera being inside a porch.
The world is the right world; two of three cameras are not showing it.

> **B. Shown these beside `palworld-0*.jpg`, would someone say these are trying
> to be the same kind of game?**

**No.** The genre signal in every Palworld frame is a creature in the shot, and
there is not one here. Beyond that, the ground-cover density, the mid-distance
landmark content and the "something is happening" quality all fall well short.
Row 1 is close on architecture, dressing and palette — but a viewer shown row 1
would call it a stylised survival-crafting game, not a creature game, because
nothing tells them otherwise.

### Fixable by changing the scene vs needs art that is not in the build

**Fixable by scene work (density, palette, lighting, composition, scatter):**
- Put creatures in the survey shots (defect 1) — if creature meshes exist in the
  build at all, this is a scene-population fix and it is the single highest-value
  change on this list.
- Retint or replace the row-2 foreground trunk material away from the faction
  hue (defect 2); reserve hues within ~15° of `(150, 64, 49)` for Tether.
- Populate row 2's middle distance with rocks, tree clusters, a path and one
  skyline landmark (defect 3).
- Re-frame the row-3 camera out of the porch; it is throwing away 25% of the
  frame (defect 4).
- Re-enable cast shadows on the props that have it off — the row-1 crate first
  (defect 6).
- Break the mirrored banner/barricade placement and clump the ground scatter
  into patches with clearings; vary grass scale (defect 7).
- Blend the row-2 terrain layer seam at y ≈ 390 and fix the slope-stretched
  splat (defect 8).
- Ship **column B**; then add contact/ambient occlusion so objects stop sitting
  on top of the ground (section 3).

**Needs art or assets that are not in these frames:**
- Materials for the flat grey placeholder surfaces — the row-1 gate threshold
  slab and the row-3 foreground stone mass (defect 5).
- A bark material for the large trunk (defect 2, second half).
- Higher-density / multi-species ground cover; the current single grass blade
  cannot reach `palworld-02`'s turf however it is scattered (defect 7).
- Idle and interaction animations, and a villager character at the trainer's
  fidelity — the row-3 villager is visibly a cheaper asset than the trainer
  standing two frames away (defect 9).
- A distant-tree LOD that does not alias to a black scribble, and window glass
  with depth (defects 10, 12).
- Higher-frequency terrain detail material at contact scale (defect 11).
