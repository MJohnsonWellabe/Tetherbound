# Blind visual judgement — Burrow Warrens, `shots/warrens_63/` — round 1

Judged from `_sheet.png` first, then the eight full-size frames, against
`docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`.
No score. Defects only, each named to a frame.

---

## First, the creature — because the rubric says say it first and say it plainly

**`06-den-and-guardian`: the guardian is two different creatures welded at the neck,
and it is dog-sized.**

- **Style seam.** The head is high-contrast black-and-white badger fur, painted with
  hard photographic splotches and a crisp glossy eye. The body behind it is a
  low-detail lumpy mass of green-grey scaled plates with almost no shading
  information. The two halves do not share a rendering language, a texel density, or
  a value range, and the join is visible as a hard line at the shoulder. Palworld's
  Mammorest (`palworld-01`) is one object: a single sculpt, one shading language,
  leaf-crown and hide and tusks all built to the same level of finish. This creature
  reads as a head asset dropped onto an unrelated body asset.
- **The face does not survive being small.** On `_sheet.png` at thumbnail scale the
  guardian is a white smear with a black hole in it. The splotching is high-frequency
  noise, not shape. Every Palworld creature in all five reference shots reads as a
  creature at thumbnail size — Grintale in `palworld-03` is a pink mass with a
  readable head, tail and stance from across the field.
- **Scale.** Use the doorway on the left wall of `06` as the ruler: a doorway a 1.80 m
  trainer walks through is ~2 m. The guardian measures under half that door in height
  and about three-quarters of it in length — call it 0.9 m at the shoulder, 1.5 m nose
  to rump. That is a large dog. It is the boss of the location. In `palworld-01` the
  field boss occupies roughly a third of frame area and towers over the 1.8 m player;
  in `palworld-03` the boss is wider than the player is tall. Nothing in `06` says
  "event". It is also, by eye, no larger than the mushroom cluster in `05` — the
  static set dressing in the next room is the same size as the thing you fight.
- **It is not standing on the floor.** The front paws terminate above the floor plane
  with visible daylight under them, and the soft contact shadow sits behind and below
  the body rather than under the paws. A green grass tuft passes straight through the
  chest and out the other side.
- **No staging.** The den is an empty tan box; the creature is lit by the same flat
  frontal fill as the crate. There is no arena, no floor marking, no light on it, no
  scale cue placed near it. `palworld-01` stages its boss with rim light, sparks,
  ground scatter and a health bar frame; even stripping the UI, the composition puts
  the creature at the focal centre with everything else falling away.

---

## 1. Silhouette and readability at small size

Squinting at `_sheet.png`, six of the eight frames have no identifiable subject.

- `04-hall-dressing` and `07-den-dressing` read as brown rectangles with two orange
  dots each. Neither says "burrow", "hall", or "den" — they say "brown".
- `02-knoll-from-outside` reads as grey lumps on a pale field. **The cave mouth — the
  reason this frame exists — is not findable at thumbnail size, and is barely findable
  at full size**: it is a dark notch between two rocks in the middle distance with no
  framing, no contrast step, and no dressing pointing at it. Compare `palworld-02`,
  where the cave entrance in the cliff is read instantly because the cliff face is a
  clean flat value and the opening is a hard black arch cut into it.
- `00-approach-60m` reads as a green field. The knoll it is supposedly approaching sits
  on the horizon at the same value as the tree band behind it and does not separate.
  The keyart's whole landmark language — the windmill hill, the peak, the standing
  stone, the stronghold — is built on a landmark being a distinct value and a distinct
  shape against sky. This knoll is neither.
- Only `03-mouth` (the arch) and `05-hall-from-the-doorway` (the mushroom cluster) have
  a legible subject at 30%.

Within-frame silhouette problems:

- `00`: at midground distance, tree, bush and flowering shrub are all the same
  rounded-blob outline in the same green. You cannot tell a tree from a bush without
  reading the trunk.
- `04`: the dark blue-black lump on the right wall has no readable outline at all. It
  is a blue blob. Whatever it is meant to be — ore, a nest, a boulder — does not read.
- `03`: the root/branch dressing hanging over the arch is a flat black scribble with no
  thickness or overlap; it reads as a decal, not geometry.

## 2. Colour and value structure

- **The exterior is value-crushed into one mid-tone.** `00`, `01` and `02` contain no
  black and no white below the sky. Foreground ground, midground ground and horizon
  ground are all within a narrow band of pale grey-green. The keyart's meadows have a
  full range in every panel: near-black tree shadow, saturated mid green, and blown
  sunlit grass. `palworld-02` and `palworld-04` do the same with a real-time budget —
  dark rock, bright path, deep tree shadow.
- **The ground albedo is grey, not green.** Across `00`, `01` and `02` the meadow floor
  is a desaturated blue-grey with dark blotchy mottling smeared over it. In `02` the
  right two-thirds of the frame is this grey with dark smears and nothing else. The
  art-direction note on the keyart board reads "vibrant, readable colours on a natural
  palette"; the swatch strip is saturated moss, olive, gold, cream. None of those
  colours appear in the ground.
- **The interior has the opposite failure — crushed both ends, nothing between.** In
  `04` the top of the corridor and the upper right are pure black with zero detail
  recovered, while the floor is a near-white tan. `07`'s upper left is solid black. The
  frames are a bright floor and a black void with almost no mid-values doing any work.
  Authored-dark is not the problem; authored-dark with no readable mid-range is.
- **Exterior and interior do not read as one place.** Exterior is cool grey-green with
  an orange-red tree-trunk accent. Interior is warm brown, tan and orange. Nothing
  carries across the threshold in `03` — you can see the interior through the arch and
  it is a different, cooler, bluer image than the arch surrounding it, which makes the
  mouth read as a hole into another scene rather than a passage into this one.
- **Red is leaking onto friendly elements.** `00` has saturated dark-crimson flowering
  bushes at left and right midground. `01` has a small red flag on the rock left of the
  mouth. `03` has a **red-and-white striped pole with a white ball on top**, standing
  in open ground to the left of the entrance — it reads as a barber pole, a survey
  stake or a debug marker, and it is the single most saturated red in the whole survey.
  If oxblood is Team Tether's colour, this location is spending it on scenery.

## 3. Intentionality — authored or generator output

The exterior scatter reads as generator output, clearly.

- `00`: the small leafy shrubs are placed at near-regular intervals across the entire
  midground at a single scale and a single tint. There are no clusters, no clearings,
  no thinning near the path, and no density gradient toward the landmark. The eye finds
  no route through the frame.
- `00`, `01`, `02`: the grass is individual isolated blades on bare ground rather than a
  continuous mat with tufts standing proud of it. You can see grey dirt between every
  blade. The keyart and `palworld-02`/`palworld-03` both show closed ground cover with
  tufts and flowers clustered on top of it — the ground is never visible as bare
  substrate in an open meadow.
- `01`: a lone crate sits in the middle of open ground between the camera and the
  mouth, with nothing near it and no reason to be there. It reads as a spawn point, not
  a placement.
- `02` is the clearest case: an enormous swathe of empty ground occupying the right
  two-thirds of the frame with perhaps six small plant clumps in it. In terms of "how
  much of the frame is empty", this is the furthest any frame in the survey sits from
  the reference bar.
- Interiors: `07` is one crate, one sack, one cone rock, a few pebbles and two leaf
  shapes spread across a room, with the bottom half of the frame given over to bare
  floor. `04` is one crate, one barrel and three rocks. A boss den and an entrance hall
  in a lived-in burrow should show what lives there. Also, **an iron-hooped cooper's
  barrel is human joinery sitting in an animal burrow** with no explanation, and it is
  the same orange-brown as the crate beside it, so the two props do not separate.

## 4. Lighting

- **The exterior has no sun.** In `00`, `01` and `02` not one tree, rock or shrub casts
  a shadow on the ground. The dark blotches on the terrain correspond to nothing in the
  scene. Terrain has no form — the knoll in `02` is lit identically on both faces, so it
  reads as a flat grey cutout rather than a mound. Every keyart panel and every Palworld
  shot has an unambiguous sun direction with long shadows placing objects on the ground.
- The lighting is also **internally inconsistent across the survey**: `01`'s crate has a
  crisp cast shadow and `03` has a large soft shadow on the near ground, while the
  neighbouring exterior frames have none at all.
- **Interior light does not read as a torch.** The premise is a torch riding with the
  camera; a point source at the lens would rake the near wall with a hot near edge and
  a fast falloff, and would put a warm pool on the floor with dark beyond it. Instead:
  `05`'s near wall is evenly lit floor to ceiling with no falloff, `04`'s bright floor
  band extends to the far wall unattenuated, and nothing anywhere has a warm highlight
  rolling into a cool shadow. It reads as a flat frontal fill with the ambient turned
  down, which is why the interiors look dim rather than dark.
- Nothing in the burrow is a light source. No shafts from above, no glow on the
  mushrooms in `05`, no fire, no bioluminescence. `05`'s mushroom cluster is the single
  best-shaped thing in the interior and it is unlit.

## 5. Horizon and depth

- **No atmospheric perspective.** In `00`, `01` and `02` the distant terrain is the same
  saturation and value as the foreground. The keyart panels desaturate and blue-shift
  every receding plane; `palworld-04` puts visible haze on the plateau and the far
  spires. Here, distance is conveyed only by object size.
- `01` and `02`: the far ground meets the sky at a hard flat line with a solid green
  plateau band above it and nothing behind. The world visibly stops.
- `01`, bottom-right: **a hard-edged wedge of flat dark green terrain** intrudes into the
  corner, a different material and a much darker value than the pale grey-green ground
  it abuts, with a straight boundary. It reads as a chunk/material seam, not a hill.
- `03`: the bottom 40% of the frame is a single smooth chocolate-brown mass with no
  texture, no scatter and no detail — a large untextured foreground terrain patch that
  swallows almost half the composition and destroys the depth read into the mouth.
- Interiors have no depth cue at all beyond the doorway hole: no dust, no falloff
  gradient, no fog. `04`'s corridor is black rather than receding.

## 6. Interface

No HUD in these frames. Nothing to judge, and per the rubric UI is out of scope against
the Palworld shots anyway.

## 7. Artefacts

- `06`: guardian's front paws float above the floor; contact shadow offset behind the
  body; grass tuft intersects and passes through the chest.
- `03`: the striped white-and-red pole with a ball finial reads as a debug/placeholder
  marker left in the shot.
- `01`, bottom-right: hard terrain material seam (above).
- `03`: the moss on the boulders is a bright green band painted only on the upper faces
  with a hard straight edge where it stops — reads as a decal stripe, not growth. The
  same treatment appears on the rock at frame-right in `01`.
- `04`: a saturated yellow object is visible at the extreme left edge, apparently behind
  and clipping past the wall slab corner.
- `05`, `07`: the floor gravel texture is at the wrong world scale — the pebbles in it
  read at a size that makes the floor look like a photograph of a driveway shrunk onto
  a plane, which flattens the room and destroys the sense of how wide it is.
- `04`, `05`, `06`, `07`: the ceiling beams and wall slabs are flat planes meeting at
  clean right angles with no bevel, no sag and no dig marks. The rooms are boxes. Also
  `04` uses a brown dirt-and-gravel wall while `05`/`06`/`07` add a grey speckled
  granite for the same structural role — two unrelated rock materials in adjacent rooms
  with no transition, so the burrow has no material identity.
- `04`: the ceiling spider is a flat black cutout with no volume or shading.
- `00`: the tree canopies are flat leaf cards that show their edge-on silhouette in the
  upper left and upper right, where the canopy reads as a paper cluster rather than a
  mass.

## 8. Scale agreement

Ruler: the trainer is 1.80 m.

- **`00`: the same tree species is both a giant and a sapling.** The left-hand
  orange-trunked tree has a trunk roughly 2 m across; the mid-distance trees of the
  identical canopy shape and identical trunk colour have trunks around 0.3 m and stand
  perhaps 4 m tall. Same asset, wildly different implied age, with no intermediate sizes
  and no visual acknowledgement that one is an old growth and the other a young tree.
- **`06`: boss creature vs. 2 m doorway** — under 1 m at the shoulder. Detailed above.
  This is the loudest scale error in the survey: the thing you fight is smaller than the
  set dressing in the room next door.
- **`05`: the mushrooms are 1.5–2 m tall** measured against the doorway behind them.
  Giant mushrooms are a legitimate choice, but they are currently the largest organic
  object in the entire burrow, larger than its guardian, which inverts the hierarchy the
  location is built to deliver.
- `01`: the mouth arch measures roughly six crate-widths across, so ~5–6 m — plausible.
  The dome above it, though, reads as only two or three times the arch height, which
  makes the whole knoll about 12 m tall while `00` frames it as a landmark visible from
  60 m. It is not big enough to be the destination `00` presents it as.
- `04`: barrel ~0.9 m, crate ~0.8 m against a passage ~3 m wide — internally consistent
  and the one place scale is fine.

---

# VERDICT

## 1. The three things that most separate these frames from the references, ranked

**1. The guardian is not a boss and is not one creature (`06-den-and-guardian`).**
`palworld-01` puts a single, bespoke, coherently-sculpted creature at the centre of the
frame, big enough that the 1.8 m player reaches its knee, lit and staged so the fight is
obviously an event. `06` puts a photographic badger head on an unrelated scaly body,
with a visible style seam at the neck, floating above the floor with a grass tuft
through its chest, at dog scale, in an empty flat-lit tan box with a crate beside it.
At thumbnail on the contact sheet it is a white smear. This is the frame the whole
location exists to deliver and it is the weakest frame in the survey.

**2. The exterior meadow is empty, flat-lit and grey where every reference is dense,
sunlit and saturated (`02-knoll-from-outside`, then `00-approach-60m`).** In `02`, two
thirds of the frame is bare grey-green ground with six plant clumps on it and no shadow
cast by anything. `palworld-02` and `palworld-03` show closed ground cover with clustered
tufts, a clear sun direction, long shadows placing every object, and haze separating the
distance; the keyart shows the same plus wildflower drifts and value contrast from
black shadow to blown highlight. Here the ground is bare substrate with isolated grass
spikes standing in it, the scatter is evenly spaced at one scale and one tint, there is
no sun, and foreground and horizon sit at the same value and saturation.

**3. The burrow interior reads as a rectangular basement, not a dug den
(`04-hall-dressing`, `07-den-dressing`).** Flat planes at clean right angles, ceiling
beams as unbevelled slabs, two unrelated wall rock materials between adjacent rooms, a
gravel floor texture at the wrong world scale, near-white floor against pure-black
corners with no mid-values, and three or four props scattered across a room that should
show what lives there. Half of `04` is given to a featureless wall slab; half of `07` is
given to bare floor. The references never surrender that much frame to nothing:
`palworld-05` fills its foreground with crates, planters, a workbench, chickens and
crops, and `palworld-04` fills its midground with ruin, trees and four creatures.

## 2. The two bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`? — NO.**

What carries: the broad ingredients are present and on-brief. Rolling meadow, oak-form
canopy trees, a rocky knoll landmark with a mossy arched mouth, wildflowers, blue sky
with cumulus. `03-mouth` has a genuinely good arch silhouette — the mossy lintel over a
dark opening with grass fringing the top is a real piece of landmark language and it is
the best-composed frame here.

What sinks it: the palette is not the board's palette. The board's swatch strip is
saturated moss, olive, gold and cream under warm sun; the meadow here is desaturated
blue-grey with dark smears and no sun at all, and the tree trunks are a saturated
terracotta orange that appears nowhere on the board. The board's mood — "cozy and
inviting" — is produced by warm directional light, closed ground cover and layered
depth, and all three are missing in `00`, `01` and `02`. The board's "silhouettes and
landmarks visible from distance" is directly contradicted by `00`, where the knoll
cannot be separated from the tree line, and by `02`, where the cave mouth cannot be
found. And nothing carries across the threshold: the cool grey exterior and the warm
brown interior in `03` read as two different games seen through one hole.

**B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to
be the same kind of game? — NO.**

They would say it is trying to be the same *genre* — a creature is being fought in a
den, there is a meadow to walk across, there are crates to open. They would not say it
is the same kind of game, and the reason is `06` beside `palworld-01`: one is a
purpose-built creature staged as a spectacle, the other is a dog-sized composite asset
floating in an empty room. Add the density gap (`02` vs `palworld-03`) and the lighting
gap (no sun anywhere outside vs. a hard sun direction in all five references) and the
comparison does not survive.

### Which gaps are fixable in the scene, and which need art that is not in the build

**Fixable by changing the scene — this is the work:**

- Sun. Give the exterior a directional light with a real angle and cast shadows.
  `00`/`01`/`02` currently have none; this single change buys terrain form, object
  grounding and value range at once.
- Ground albedo and value range. The meadow floor is grey; the board says green-gold.
- Ground cover density and clustering. Close the ground with a mat, cluster the tufts
  and shrubs, vary their scale, cut clearings and a path. Kill the even spacing in `00`.
- Fill `02`. Two thirds of that frame is nothing.
- Landmark contrast. Push the knoll's value and mass so it separates from the tree band
  in `00`, and frame the mouth in `02` with dressing and a contrast step so it can be
  found.
- Atmospheric perspective / distance haze; and something behind the horizon line in
  `01`/`02`.
- The bottom 40% of `03` — the untextured brown foreground mass — and the hard terrain
  seam in the bottom-right of `01`.
- Remove the red-and-white striped pole in `03`. Pull the crimson bushes and the red
  flag back off friendly dressing if oxblood is reserved.
- Guardian grounding in `06`: paws on the floor, shadow under the contact, grass tuft
  moved out of the chest.
- Guardian **size** in `06`: relative scale is a transform, and it is the cheapest large
  improvement available in this whole survey.
- Boss staging in `06`: clear the crate and sack away, give the den a focal light on the
  creature, give the floor a reason to be an arena.
- Interior light: make the torch behave like a torch — hot near, fast falloff, warm-to-
  cool. Lift the interior mid-values so black areas hold detail.
- Interior geometry proportions and the right angles; pick ONE wall rock material for
  the burrow; fix the floor texture world scale in `05`/`07`.
- Interior dressing count in `04` and `07`, and drop or re-skin the iron-hooped human
  barrel.
- Exterior/interior palette continuity at the `03` threshold.

**Not fixable in the scene — this needs art that is not in the build:**

- **The guardian.** Growing it and grounding it will not fix the badger-head-on-scaly-
  body seam, the two texel densities, or the splotch pattern that turns to noise at
  thumbnail. This needs a single coherent sculpt and texture, or at minimum a unifying
  retexture across head and body. This is the highest-value art purchase the location
  has, and until it lands, bar question B stays no no matter what the scene does.
- **The tree set.** Two silhouettes in the entire exterior, flat leaf-card canopies that
  show their edge in `00`, and a trunk colour that is off the board. Needs more canopy
  shapes, real old-growth versus young-growth variants, and a trunk material aligned to
  the palette.
- **The ground-cover set.** A single-blade grass and one shrub shape cannot make a
  meadow read as closed ground however densely they are scattered. Needs a grass clump/
  mat asset and two or three more plant silhouettes.
- **The rock set.** Flat hard-edged facet slabs with a painted-on moss band, used for
  both the exterior knoll and the interior walls. Needs rock forms with real strata and
  a moss treatment that grows rather than stripes.
- **The interior kit.** Boxy planes and unbevelled beams cannot be dressed into a dug
  burrow. Needs a curved/organic tunnel kit, or the burrow reads as a cellar forever.
