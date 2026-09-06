# Blind visual judgement — `shots/hall_judge/` (3 night interiors, 1280x720)

Judged from the images only, against `docs/reference/tetherbound-meadows-keyart.png`
and `docs/reference/palworld-0*.jpg`. No score. Every number below is Rec.709 luma
(0-255) or a pixel coordinate in the named 1280x720 frame, so all of it is
re-measurable.

Frames:
- **T-01** `T-01-approach-room.png`
- **T-02** `T-02-warden-arena.png`
- **T-03** `T-03-legendary-side-wall.png`

---

## 0. The thing to say first: there is nothing alive in these frames

The rubric says creatures and characters are the point and to say it plainly, so:

**All three frames contain zero creatures.** The only living thing in the survey is one
trainer in T-01, bounding box x 543-572, y 353-433 — **80 px tall, 11% of frame
height**. His torso reads mean Y = 50.4 against the wall directly behind him at Y = 58.2:
a **1.15 : 1 contrast ratio**. Only his helmet (Y = 109) separates at all. Downsampled to
384x216 (the 30% view) he is a 24 px smudge in a dark doorway and I could not locate him
without knowing where to look.

Compare the bar: `palworld-01` gives ~70% of frame height to a single creature with a
rim-lit silhouette; `palworld-04` stages four creatures across the frame; `palworld-05`
puts two in the near field. The key art's own NIGHT panel puts a trainer and a pal in the
foreground as the subject. A three-frame survey of a creature-training game that contains
no creature and one near-invisible human has no subject at all.

I judged the rest anyway, but nothing below outranks this.

---

## 1. Silhouette and readability at 30%

Viewed at 30% (sheet at 574x121, frames at 384x216):

- **All three frames collapse into one continuous brown smear.** The bottom ~40% of each
  frame carries no readable content. Measured on 16x16 tiles: T-02 has **22.8%** of tiles
  that are simultaneously dark (mean < 25) and featureless (sd < 8); T-03 **20.5%**;
  T-01 **11.1%**. The Palworld shots run **0.0-2.4%**. The key art's own NIGHT panel is
  12.5% — so the raw number is not damning for a night scene, but the key art spends its
  dark-and-empty budget on *sky*, doing silhouette work. These frames spend it on **the
  floor the player walks on and the wall beside them**.
- **The most legible object in the entire sheet is a cyan stripe.** T-01's teal strip is
  mean RGB 11/62/69 (R near zero) in a frame where 91% of saturated pixels sit in the
  0-30° orange band. In T-03 teal covers **3.52%** of the frame and crosses the entire
  foreground. At 30% it out-reads every prop, the doorway, and the trainer. Whatever this
  strip signifies, it is currently the strongest read in the game's look.
- **Nothing else is identifiable.** At 30% I cannot tell the T-01 workbench (x 215-345)
  from the T-01 ring (x 770-990) from the T-03 lectern and bucket (x 660-700, x 620-650) —
  they are all small warm-brown blobs of similar value against a warm-brown floor.
- **T-03's left 40% (x 0-520) is an unreadable grey-blue tangle.** At full size I still
  cannot say what it is; at 30% it is noise.
- **T-02's second-strongest read is an untextured slab.** The flat oxblood plane at
  x 0-307, y 305-550 and the lavender plane above it survive the downsample better than
  any authored object in the frame.

## 2. Colour and value structure

- **Hue monoculture.** Saturated pixels binned into 12 hues of 30°:
  T-01 = **91%** in bin 0 (0-30°, orange/red); T-02 = 63%; T-03 = 64%.
  `palworld-02` spreads 52/36/7; `palworld-03` 59/19/10; `palworld-04` 41/22/13.
  Warm/cool split in T-01: **77% of pixels and 93.2% of frame luma is warm; 0.7% / 0.6%
  is cool.**
- **The shadows have no colour.** T-01's shadow tier means RGB **10.6 / 1.0 / 1.1** —
  R/B = 9.6. Green and blue are effectively zero, so every dark area is a pure-red ramp
  that will band and posterize. The key art's NIGHT panel does the opposite: **77% of its
  saturated pixels sit in the 180-240° blue band** with a small warm campfire accent.
  These frames have inverted that relationship and then deleted the cool half entirely.
- **The Tether oxblood no longer means danger, because the world is the same colour.**
  In T-02 the oxblood banner plane measures RGB **55/13/15, Y = 22.2**. The floor of the
  same frame measures RGB **41/14/8, Y = 19.6**. Same hue family, 2.6 luma apart. The
  faction's identity colour and the ground are indistinguishable. In T-01 the floor is
  RGB 53/19/6 — again the banner colour.
- **Bimodal values, no midtones.** T-01 far wall in torchlight reaches Y = 157 and the
  same stone 4 m away in shadow reads Y = 10-16. Frame median is 38. There is a cliff, not
  a range.
- The three frames do read as one place, but only because they read as one *colour*.
  That is agreement by impoverishment, not by art direction.

## 3. Intentionality — this reads as generated, not authored

- **T-01 is mirror-symmetric to a few pixels.** Left half vs. horizontally flipped right
  half over the structural region (y 0-430) correlates at **r = 0.788**. The wall sconces
  are at exact mirror positions about x = 640: x = 333/946, 366/911, 405/873, 441/839
  (mirror error 1-3 px). Five back-wall sconces at a constant 34-38 px pitch. Nobody
  places lights that way on purpose; a kit generator does.
- **Every light is the same light.** Five sconce glows measured across the frame:
  peak luma **237, 240, 239, 240, 240** and half-widths **70, 65, 82, 68, 83 px** — at
  wildly different depths. They neither dim nor shrink with distance.
- **Scatter without clustering.** T-02's rubble (x 480-680, y 380-420) is a line of
  isolated single grey rocks along the wall base at roughly even intervals, with no debris
  field, no dust, no dirt decal and no piles. `palworld-05` clusters its props into a
  worked camp; `palworld-01`'s forest floor has flowers, grass tufts and undergrowth at
  three scales.
- **Prop vocabulary is generic dressing.** A five-arm silver candelabra + stone basin
  (T-01 x 1100-1200), an anvil, a stool, a lectern, a bucket, a wire crate. None of it
  says Team Tether, none of it says this room's function, and none of it is a landmark.
  The key art's stronghold panel earns its identity from carved arches, hung banners,
  scaffolding and a lit gate.

## 4. Lighting — the largest single fault

- **The light is inverted.** In T-01 the ceiling reads **median Y = 109 (centre) to 130
  (near camera)**; the floor directly beneath the wall sconces reads **Y = 39.8**, and the
  general floor **Y = 16-22**. The only visible light sources are candle sconces at
  ~1.6 m on the walls. The brightest large surface in the room is the one furthest from
  every light and facing away from all of them, and the surface every torch actually
  points at is the darkest thing in frame — a **5-8x** inversion. This one fact produces
  most of the murk in criterion 1.
- **Nothing casts a shadow. Nothing has contact AO.** Four measured contact points, floor
  luma directly beneath the object vs. floor immediately beside it:
  - T-01 workbench (base x 215-345): beneath **Y 48-58**, beside **Y 48-54** (left) /
    **Y 41-47** (right). No dip.
  - T-01 candelabra (base x 1125-1170): beneath **Y 66-76**, beside **Y 82-91** — a smooth
    monotone ramp away from the light, unbroken by the object standing on it.
  - T-03 bucket (base ~x 633, y 428): beneath **Y 69-72**, surround **Y 61-78**. No dip.
  - T-03 stool (legs x 535-560): beneath **Y 71-84**, surround **Y 71-84**. No dip.
  Every prop is pasted onto the floor. `palworld-01` and `-03` plant their boss with a
  ground shadow; the key art stronghold has cast shadow under every arch.
- **No bounce.** T-02's wall corner at x = 993→994 steps from Y = 119 to Y = 11 in one
  pixel (RGB 176/107/75 → 41/4/1). A 10:1 step at an inside corner of a torch-lit stone
  room means zero indirect light.
- **Hard vertical lighting seams on flat walls.** T-01 right wall, sampled y 295-340:
  Y = 90 at x = 1108, **Y = 152 at x = 1110** (a 62-luma step in 2 px), then a flat plateau
  at Y ≈ 157 to x = 1130, then Y = 107 at x = 1132. Light falloff is smooth; this is a
  20 px hard-edged band. Adjacent wall panels are receiving different light sets.
- **The same wall disagrees with itself.** T-03, sampled y 120-300 across the back wall:
  panel means Y = 67 (x 565-595) → 63 (615-690) → **12 (slot x 694-699)** → 43 (705-780)
  → **16 (800-880)** → 25 (905-960), with R/B ramping 1.16 → 1.95 across it. The
  discontinuity from Y 43 to Y 16 between adjacent panels has no geometry change behind it,
  and the stone courses do not line up across the seam.

## 5. Horizon and depth

Interiors, so no horizon to judge. Depth cueing is nonetheless broken:

- The non-attenuating sconce glows (§3) flatten the frame — a light 15 m away and a light
  3 m away are the same size and the same brightness on screen.
- There is no aerial perspective or fog gradient. T-03's far end (x 560-950, Y 16-67) and
  its near-camera wall occupy the same value range.
- **T-03 has black gaps between modular wall panels.** At x 694-699, y 120-300 the wall
  reads **Y = 12.6** flanked by Y = 63 and Y = 43 — a 5 px slot of void showing through a
  wall the player is standing inside. There is a second at x ≈ 882-900.

## 6. Interface

No HUD, no UI in any frame. Nothing to judge, and per the rubric UI is out of scope
against the Palworld shots anyway.

## 7. Artefacts

Ranked by how badly each reads as a bug:

1. **T-03, the left mass (x 0 → ~520, y 0 → 620).** Intersecting flat planes, hard
   triangular slivers cutting through each other, some faces blurred to mush and others
   crunchy with mip noise, and no readable silhouette at any zoom. Its palette is cool
   grey-green and matches nothing else in the three frames. It is cut by three frame
   edges. I cannot tell what object this is meant to be.
2. **T-02, three flat unlit quads** at x 0-45 (y 120-280), x 112-305 (y 132-312) and
   x 508-544 (y 190-350). Each is a hard-edged parallelogram with a smooth gradient
   (top RGB 105/83/125 lavender → bottom RGB 193/144/152 pink), Ymean **94-110**, and each
   *overlaps* the stone courses and wooden beams behind it rather than being framed by an
   opening. The actual night sky in the same frame measures RGB 0/12/26 to 31/26/34,
   **Y = 10-28**. The frame therefore shows two mutually contradictory skies, 4-10x apart
   in luma and opposite in hue.
3. **T-03, a floating white chevron** at x 0-45, y 55-110. RGB 237/239/239, uniform width,
   perfectly hard-edged, constant colour along its whole length regardless of what is
   behind it, attached to no object. Reads as a debug gizmo or a stray unlit-material mesh.
4. **T-02, the untextured oxblood plane** (x 0-307, y 305-550). Over a 240x130 px interior
   sample: **Ystd = 0.69, 11 unique colours, Y range 20.9-24.2**. It receives no per-pixel
   lighting at all. It has no cloth texture, no fold, no trim and no emblem, and it is the
   nearest object to camera, occluding the left 24% of the frame.
5. **T-03, stretched texture on the right-hand crate** (x 1160-1280, y 265-570). Mean
   gradient energy across the grain **15.63** vs. along it **3.31** — a **4.73x**
   anisotropy. The plank knots are smeared into 200 px vertical streaks.
6. **T-01/T-02, the blown-out machine screen** (T-01 x 0-55 y 300-420; T-02 x 862-935
   y 330-390): mean RGB **215/182/174 / 220/188/177, Y = 188-194**. A flat featureless
   pink-white gradient, brighter than any torch-lit stone in either frame, reading as a
   hole punched in the image. Magenta also appears nowhere in the key art's 11-swatch
   palette strip.
7. **T-02, two vegetation assets disagree about the night.** The canopy at x 300-480,
   y 90-240 reads mean RGB 9/17/28, **Ymean 15.7** — a flat black alpha-cut card with
   stair-stepped 1-2 px cutout edges and zero internal value variation. The ivy 50 px to
   its right (x 530-600) reads RGB 86/68/44, **Ymean 70.2**, and the ivy at x 680-830 reads
   **Ymean 73.9**. Same frame, same sky, **4.5x** apart.
8. **Aliasing on thin geometry.** T-02's wire crates (x ~555 and ~700, y 380-440) and the
   T-02 right-hand wooden frame (x 1150-1280) fringe with white speckle along every bar.

## 8. Scale agreement

Using the trainer as the ruler (T-01, 80 px = 1.80 m → 44.4 px/m at his depth, corrected
for ground-plane depth via the y-below-eyeline ratio):

- Doorway opening (x 583-703, y 283-413): ~130 px → **≈ 2.9 m**. Plausible for a hall.
- Left workbench (x 215-345, top y 413, base y 465): 52 px at ~62.6 px/m → **≈ 0.83 m**.
  Correct for a bench.
- Ceiling at the far wall: ~287 px → **≈ 6.5 m**. Plausible for a great hall.
- The ring/pen (T-01, x 770-990, base y 462): ~220 px at ~60.9 px/m → **≈ 3.6 m across**,
  with a ~1.1 m A-frame on it. It is two trainer-widths of enclosure — the only
  arena-shaped feature in the survey, and a trainer standing in it with arms out spans
  half of it.

**The props agree with each other about how big a metre is. But the ruler has nothing to
measure**: with zero creatures in the survey, the criterion this rubric was extended for
cannot be exercised at all. That is itself the finding.

---

# The verdict

## The three things that most separate these frames from the references

**1. The references have a subject; these have a room.**
`palworld-01` gives ~70% of frame height to one creature, lit and rim-separated, mid-action.
`palworld-04` stages four. The key art NIGHT panel foregrounds a trainer and a pal. **T-01,
T-02 and T-03 contain no creature at all**, and the single human (T-01, x 543-572,
y 353-433) is 11% of frame height at **1.15 : 1** contrast against the wall behind him and
disappears entirely at 30%. Nothing in these frames is the thing you are looking at.

**2. The references light objects; these light a room from nowhere and land the light on
nothing.**
In **T-01** the ceiling is median **Y = 109-130** while the floor under the torches is
**Y = 39.8** and the general floor **Y = 16-22** — the surface furthest from every visible
light is 5-8x brighter than the surface every torch points at. And no object in any of the
three frames has a cast shadow or contact AO: the floor beneath the T-01 workbench
(Y 48-58) is indistinguishable from the floor beside it (Y 41-54), and the same holds under
the T-01 candelabra, the T-03 bucket and the T-03 stool. Palworld plants its boss on the
ground with a shadow; the key art stronghold has cast shadow under every arch. Here
everything is pasted on.

**3. The references have a palette; these have one colour.**
**T-01** puts **91% of its saturated pixels in a single 30° hue bin** and **93.2% of its
frame luma** in the warm half, with 0.6% cool. Its shadow tier is RGB 10.6/1.0/1.1
(R/B = 9.6) — the darks have no chroma but red. The key art's own NIGHT panel is the
inverse: **77% blue (180-240°)** with a small warm fire accent. And because everything is
the same red-brown, **T-02's Team Tether oxblood banner (Y = 22.2, RGB 55/13/15) is
2.6 luma from the floor of the same frame (Y = 19.6, RGB 41/14/8)** — the faction's danger
colour has been absorbed by the ground.

## The two bar questions

### A. Do these read as belonging to the world of `tetherbound-meadows-keyart.png`?

**No.**

What sank it: the palette is inverted from the board's own night language (§2), and the
board's 11-swatch strip contains no saturated cyan, yet the most legible object in all
three frames is a saturated cyan floor stripe (T-01 RGB 11/62/69; 3.52% of T-03). The
board's Team Tether stronghold is a *landmark* — silhouetted gate, hung banners,
scaffolding, carved arches, lit interior; **T-01** and **T-03** are unornamented modular
stone corridors whose most memorable feature is a piece of broken geometry. The board says
"cozy and inviting, with hints of mystery"; these read as murky, and murk is not mystery —
20.5% (T-03) and 22.8% (T-02) of the frame is dark-and-featureless, and unlike the board's
night panel that budget is spent on floor and wall rather than on sky doing silhouette work.

What carried what little there is: the chunky hand-painted stone material is genuinely on
style for "stylised realism between Valheim and Palworld", and the hung banners plus the
ivy overgrowth in **T-02**/**T-03** are the right vocabulary for an occupied ruin. Those
two things are the only parts of the set I would keep unchanged.

### B. Shown these beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

No creature, no character worth looking at, and no event (§0). Every Palworld frame is
built around a subject at 30-70% of frame height with silhouette separation from its
ground; these are built around empty floor. Beyond that, a shipping game does not ship the
artefacts in §7 — the unreadable intersecting mass in **T-03**, the three flat unlit sky
quads in **T-02** contradicting the actual sky by 4-10x luma, the floating white chevron at
T-03 (0-45, 55-110), and an untextured 11-colour oxblood plane occluding the left quarter
of **T-02**. Someone shown these side by side would not call them the same category of
product, let alone the same genre.

### Which gaps are fixable by changing the scene

- **Invert the light budget in T-01.** The ceiling should not be the brightest surface in a
  sconce-lit hall; the floor under each torch should be. Target: floor-under-torch above
  ceiling median, and lift the floor's 16-22 into a workable 40-70.
- **Turn on shadows and contact AO.** Four measured contact points have none; this is the
  single change that would most improve criterion 1.
- **Give the darks a cool chroma.** T-01's shadow tier at R/B = 9.6 should be closer to
  the key art's blue night. A cool ambient/fill also restores the value structure the
  frames currently lack.
- **Make lights attenuate.** Five glows at peak Y 237-240 and half-width 65-83 px at
  different depths is a depth-cue failure, not an asset problem.
- **Fix the sky.** Remove or correctly texture the three flat quads in T-02 (x 0-45,
  x 112-305, x 508-544) so the frame has one sky.
- **Delete the debug chevron** at T-03 (0-45, 55-110).
- **Break T-01's mirror symmetry** (r = 0.788; sconces at exact mirror positions
  333/946, 366/911, 405/873, 441/839). Vary the sconce pitch, offset one wall, put
  different function on each side.
- **Re-hue or subordinate the cyan strip** — it currently out-reads the player.
- **Fix the panel lighting seams**: T-01 right wall x 1108→1110 (Y 90→152 in 2 px), T-03
  back wall Y 43→16 between adjacent panels, and close the black slots at T-03 x 694-699
  and x 882-900.
- **Tone the blown props**: the machine screen at Y 188-194 and the pale rubble/workbench
  should not read brighter than torch-lit stone.
- **Reframe.** T-02's near slab occludes 24% of the frame width; T-03's mass occupies 40%.
  Move the camera or move the object.
- **Cluster the scatter.** T-02's evenly-spaced single rocks want to become piles, spills
  and worn paths.

### Which gaps need art that is not in the build

- **Creatures.** There is not one in the survey. Nothing about scene, lighting, scatter or
  composition converts these frames into the Palworld comparison; that gap is bespoke
  creature art and cannot be lit into existence.
- **A trainer that holds a silhouette.** Part of his invisibility is lighting, but a
  desaturated grey-brown figure with no strong shape language will still lose to a
  Palworld protagonist after any relight. He needs chroma, a readable silhouette and a
  shape a player recognises at 30%.
- **The T-03 left mass.** Intersecting coplanar slivers, no readable form, and a
  grey-green palette matching nothing else in the set. This needs rebuilding or replacing,
  not relighting.
- **The tether machine** (T-01 x 0-110; T-02 x 850-960). Pale blue-grey plastic lab
  equipment with a magenta screen, in a stone hall. Its material language is from a
  different game. Needs a re-skin at minimum.
- **Stronghold set dressing.** The key art's Team Tether hall is carved arches, banners,
  scaffolding, a gate, an emblem. What is in the build is unornamented modular stone
  panels plus generic tavern props (a silver candelabra, a stool, a bucket). That is
  missing art, not a missing light.
- **UV/texture fixes on the T-03 crate** (4.73x grain anisotropy) and alpha-coverage on
  the T-02 foliage cutouts (stair-stepped 1-2 px edges) — asset-side authoring, not scene
  tuning.

---

### Honest limits of this judgement
Software GL, no SSAO and no volumetric fog, so the *absence* of ambient occlusion may in
part be a capability of this capture rather than of the shipped scene; the *inverted*
light budget, the missing cast shadows, the two skies, the untextured planes, the mirror
symmetry, the non-attenuating glows and every artefact in §7 are not. Static frames say
nothing about popping, motion aliasing or traversal.
