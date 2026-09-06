# Blind visual judge — `shots/dress_final` (CLOUDREACH dress pass)

Six frames plus contact sheet, judged against `docs/reference/tetherbound-meadows-keyart.png`
(palette / mood / landmark language) and `docs/reference/palworld-0*.jpg` (the shipping-quality
real-time bar). No score. Defects only, each named to a frame.

Measurements below use the ruler in the picture: the trainer is 1.80 m.

---

## 0. Read at thumbnail scale first

At contact-sheet size, five of six frames resolve to the same silhouette: *a small brown figure
standing on a large empty green plane, with detail crowded into a band across the upper third.*
The lower 35–45% of 02, 08, 09, 11 and 12 is unbroken flat ground with nothing in it. That is the
first thing the sheet says, and it says it five times.

Individual thumbnail failures:

- **02** — the pale boulders and the black bushes both dissolve. The boulders read as light
  smudges on the lawn and the bushes as holes. You cannot tell a rock from a bush from a shrub;
  they are the same size and read only as "speckle."
- **06** — reads as a photograph with the bottom half printed wrong. A hard horizontal line runs
  the full width and everything below it is a dark, faceted, near-black mass. At thumbnail this
  is not a landscape, it is a rendering failure.
- **09** — reads as a pale disc on a brown field with a green wedge in front. The single figure
  standing across the ring is 28 px tall and invisible; there is nothing in the frame that says
  what the space is for.
- **11** — the tall central rock reads as a black rectangle punched out of the image, and the
  white creature — the only creature in the entire survey — vanishes against the pale sky and the
  pale rocks behind it. **The creature loses its silhouette at thumbnail size.** Every Palworld
  reference passes this test trivially: Grintale (palworld-03) is magenta against green, Mammorest
  (palworld-01) is green-and-tan against dark forest, and the mount in palworld-04 is saturated
  yellow. Silhouette-and-landmarks-from-distance is one of the five art-direction notes printed on
  the key art board, and 11 fails it on the creature.
- **12** is the only frame that survives thumbnail scale, because it is the only one with
  foreground clusters (flower clumps, bushes, a bench, crates) breaking the ground plane.

---

## 1. Silhouette and readability

- **11-aerie-ground-connection** — the white winged creature is essentially hueless
  (near-white body, pale blue-grey wings). It sits in front of a pale sky band and pale
  grey boulders. There is no value or hue separation on any side of it. Compare
  palworld-01/03/04, where every creature is a saturated hue that appears nowhere in
  the terrain behind it. Fix: give the creature a saturated secondary (the key art's palette
  strip offers gold, teal, violet, oxblood) or a darker underside, and stop putting pale rock
  directly behind it.
- **11** — **exactly one creature model appears across all six frames**, duplicated twice in
  the one frame it appears in. Five of six frames contain no creature and no NPC at all. This is
  a creature-collecting game shot without creatures in it. Palworld cannot produce a screenshot
  without a pal in it.
- **02, 08, 12** — the dark bushes measure RGB (0,11,0) in 02. That is literally black. They
  carry no highlight, no rim, no internal value break, so at any distance they read as holes in
  the grass rather than as vegetation.
- **09-final-arena-space** — the arena's stone perimeter wall and the cliff face behind it are
  within a few values of each other (both pale grey-green). The wall silhouette disappears into
  the cliff, so the arena has no readable enclosure.
- **11** — the two foreground tree trunks (left and right frame edges) are smooth untextured
  brown cylinders with no bark, no taper and no root flare, and no canopy in frame. They read as
  pipes, and they are the two largest objects in the composition.
- **All frames** — canopy and bush alpha edges are hard-cut with visible stair-stepping
  (clearest on the mid-ground trees in 11 and the bushes in 12). Silhouettes are jaggy at their
  most important edges.

## 2. Colour and value structure

Measured luminance percentiles (0–255):

| frame | p5 | p50 | p95 | p99 |
|---|---|---|---|---|
| 02 | 27 | 102 | **137** | 175 |
| 06 | 28 | 105 | 168 | 186 |
| 08 | 76 | 128 | 163 | 178 |
| 09 | 53 | 120 | 160 | 180 |
| 11 | 24 | 93 | 154 | 167 |
| 12 | 21 | 125 | 158 | 178 |
| palworld-01 | 29 | 126 | **218** | 237 |
| palworld-03 | 48 | 128 | **223** | 235 |
| palworld-04 | 14 | 102 | **234** | 242 |
| keyart | 13 | 65 | 194 | 232 |

**Every reference carries real highlights into the 215–240 band. Not one shot does.** The top
quarter of the value range is unused in all six frames. 02 is the worst case: 95% of that image is
darker than 54% grey. This is not "a bit flat" — there is no sunlit surface anywhere in the
survey. The key art's meadows have blown-out grass under direct sun, sky glare, and white
cumulus; these frames have none of those, which is why they read as overcast even though the sky
is drawn clear and the shadows are hard.

- **The brightest pixels in these frames are all bugs.** The white finial on the dome in **06**
  is a flat, unshaded (231,231,231) — identical value at every sample point, no gradient, i.e.
  fullbright. The green cube in **02** is (213,231,196). The white slivers in **12** are
  (211,209,188) and (223,219,209). Those four placeholder objects are brighter than the sky, the
  roofs, the sand and the stone in their own frames. When the only thing hitting the highlight
  range is an unfinished asset, the lighting is not delivering a value structure.
- **09 — the Team Tether oxblood has leaked badly.** The deep blood red measured at (38,6,3)
  appears on *market stall awnings* at the left edge, the right edge, and twice in the middle of
  the arena, plus the rails above them — six or more times as ordinary furniture colour, each with
  the white Team Tether wheel emblem on it. The same banner-and-emblem appears on the friendly
  keep wall at the right edge of **12**. If oxblood + wheel means "danger, this is the enemy," it
  currently also means "shop" and "village." Reserve it or it stops meaning anything.
- **Frames disagree about the sky.** 02, 08, 09 and 12 share a deep clear blue with thin cirrus.
  **06** has a completely different sky — heavy wispy cirrus streaked across the whole upper half
  and a lighter, hazier blue. **11** has a pale washed cyan with a bright white horizon band. Seen
  on one sheet these do not read as one day in one place.
- **08** — the ground palette splits down the middle for no compositional reason: mown mid-green
  on the left, bright yellow-green tall grass on the right, meeting at a hard line beside the path.
- Foliage in all frames occupies one narrow band of yellow-green. The key art builds its meadows
  from at least four greens (deep oak shadow, sunlit blade, blue-green distance, olive scrub) and
  breaks them with wildflower violet and gold. Here there is one green plus a violet flower decal.

## 3. Intentionality — this reads as scatter output, not authoring

- **02-lower-cliffs-galefoot** — the foreground scatter is a repeated **bush-then-pale-boulder
  pair**, at near-identical size and near-identical spacing, five times across the frame. Once
  seen it cannot be unseen. There are no clusters, no clearings, no density gradient, no
  scatter-free approach to the path, nothing pushed up against a wall or a fence.
- **08** — the left slope carries five dark bush pucks at regular intervals, all the same
  diameter, in a line. The purple flowers on the right slope are all the same height, all the same
  model, all evenly spaced.
- **12** — best of the six, but still a bush / flower-clump / boulder / bush / flower-clump
  sequence running left-to-right at a constant y, all at one size. Real gardens and real
  hillsides clump.
- **09** — the arena's market stalls are the same stall asset repeated at four positions around
  the ring with the same awning, same banner, same crates. Two identical wooden lattice towers
  stand at two points on the perimeter. It reads as a ring of instances, not a built place.
- **02, 08, 12** — the cliffs are the same rock module stacked and repeated. In **12** the block
  at x≈600–720 and the block at x≈900–1090 are visibly the same mesh at the same rotation, side
  by side.
- **12** — three separate bare wooden poles (one running the full height of the frame) with
  nothing on them: no flag, no rope, no lantern, no banner. Three vertical accents that carry no
  information.
- **All settlement frames** — no smoke from any chimney, no laundry, no livestock, no tools left
  out mid-job, no wear paths worn into the grass by feet, no NPC anywhere except the single
  distant figure in 09. palworld-05 sells "lived in" with a chicken, a fruit basket, scattered
  crates, a workbench and pals mid-task in a single frame.

## 4. Lighting

- **06-summit-final-approach — THE major defect of this survey.** A hard horizontal seam runs
  the entire width of the frame at y≈575–582. I sampled the same grass material on both sides
  of it at x=200: **(140,147,73) above, (29,26,14) six pixels below** — a 5× luminance drop
  across a straight line, with the identical surface on both sides. Everything below the seam is
  a dark, faceted, hard-edged mass of near-black wedges and a dark blue-grey ramp. This is not a
  shadow (it does not follow any caster, it is a ruled straight line across the whole frame, and
  the faceting is polygonal). **Roughly 40% of frame 06 is unlit or wrongly-lit geometry.** No
  other criticism in this report matters until this is fixed.
- **Shadows are single-density hard black with no penumbra and no ambient bounce.** In **11** the
  shadowed grass drops to near-black while the lit grass beside it is bright — that binary is what
  produces the compressed, sunless value structure noted above. The key art and all five Palworld
  shots carry coloured, lifted shadow with visible bounce light.
- **02 and 12** — the pale boulders have essentially no contact shadow. They sit on top of the
  grass rather than in it, which is most of the reason they read as props.
- **11** — the creature's shadow is a soft blurred smear offset well to the left of its feet, so
  the creature does not read as standing on the ground.
- **02, 08, 09, 12** — terrain has no form. The slopes are one value from top to bottom with no
  shaded side and no ambient occlusion in the hollows, so hills read as painted rather than
  modelled. The left slope in **08** is a single flat green from crest to path.
- **12** — the house interior behind the lattice door measures (30,12,2): a black void with no
  ambient fill at all. The whole ground floor of the frame's hero building is a hole.
- **Time of day does not read.** Hard short shadows say noon; the total absence of highlight and
  the low overall key say overcast. The two disagree in every frame.

## 5. Horizon and depth

- **Zero aerial perspective anywhere.** Distant cliffs in **02** and **12** are the same
  saturation and the same value as objects ten metres away. The key art stacks four or five
  depth planes with progressive desaturation and blue shift in every panel; palworld-04 does the
  same with real fog on its plateau. Nothing here recedes.
- **08** — the world ends about forty metres out. Left of the tower the ground simply stops
  against a flat pale grey-blue skybox band with a visible hard edge, and there is no distant
  landform in any direction. Every key art panel puts a peak, a windmill, a tower or a layered
  ridge on the horizon; palworld-04 and -05 both put a distant landmark tower and a mountain range
  behind the play space. There is nothing to walk toward in 08.
- **02** — the terrain at the far left (x 0–140) is cut off at a straight lip against the sky. It
  reads as a flat card, not a plateau.
- **08** — a visible terrain chunk edge on the right (x≈1180–1280) with a pale void beyond it.
- **11** — the ground on the right simply fades to a white void at the horizon.
- **09** — the pale cliffs behind the arena are the same value as the walls in front of them, so
  the whole background collapses into one plane about 60 m deep. The arena has no sense of being
  set into anything.
- No fog is being used for depth in any frame. Adding it is the single cheapest fix available.

## 6. Interface

There is no HUD in any of the six frames — no health, no party, no reticle, no prompts. Nothing
to judge for hierarchy or safe area. Worth stating only because every Palworld reference carries a
full HUD, so a like-for-like side-by-side is not possible on this axis.

## 7. Artefacts

- **06** — the horizontal lighting seam and the unlit lower terrain (see §4). Also: a thin
  dark-red dashed hairline running diagonally across the lower terrain that reads as a stray line
  or a broken path decal, not a path.
- **06** — the white finial on top of the dome is fullbright flat (231,231,231) with no shading
  variation across it. It reads as a broken/unassigned material, and it is the brightest object
  in the survey.
- **06** — several bright salmon-pink rounded blobs (measured (238,168,118)) float in mid-air at
  chest height inside and around the gate, unsupported. Untextured props or creatures with no
  material.
- **11** — **a rock chunk floats detached in the sky** at the top of the frame (x≈345–420,
  y≈0–90) with small fragments hanging below it and nothing beneath it. Unambiguous floating
  geometry.
- **11** — the central spire's texture is smeared into horizontal bands with a large white
  scratchy circular swirl pasted across it and a soft dark ellipse "bruise" on its left face. This
  reads as broken UVs on a cylinder.
- **12** — two thin near-white slivers (211,209,188) and (223,219,209) lie flat in the grass on
  either side of the foreground boulder. They have no thickness, no contact shadow, no material
  identity, and one has a hard black dot on it. Two more appear in **02** near the left cottage.
- **02** — a mint-green translucent slab (213,231,196) sits on the path at frame centre. **11**
  has the same object as a glowing emerald cube with a blue-white halo. Both read as placeholder
  pickups, not world objects, and both are among the brightest pixels in their frame.
- **09** — the arena circle's edge is a texture-blend boundary with visible staircase aliasing
  along its upper-left arc; another stray pale-grey flat slab lies at x≈320, y≈345.
- **08** — the "boulders" on the right slope are **flat polygonal patches of rock texture painted
  onto the terrain surface**: straight-edged, zero thickness, zero silhouette against the hill,
  no shadow. Three of them. They are decals wearing a rock texture.
- **08** — the dirt path texture stretches and smears into streaks at the bottom of frame.
- **02** — the right-hand cliff column (x 1150–1280) is a smooth extrusion with vertically
  stretched texture.
- **08** — the tall grass on the right is sparse straight blade cards standing well apart with
  bare terrain visible between them; it reads as scattered straw rather than a grass field.

## 8. Scale agreement

**06-summit-final-approach is broken on scale.** Measuring against the 1.80 m trainer, whose
feet sit on the same ground line as the wall base:

- trainer: 180 px = 1.80 m
- the stronghold's **stone perimeter wall: ~140 px ≈ 1.40 m** — the wall's top edge crosses the
  trainer at chest height. You can see his shoulders and head over it. That is a wall you step
  over, not a fortification.
- the **gate lintel** he is standing under crosses at hip/waist height.
- the **dome, the landmark of the entire approach: ~312 px ≈ 3.1 m** to the top of the lattice.
  Even allowing generously for it standing slightly behind him, it is at most 4 m. The trainer
  reaches better than half its height.

For comparison the key art's Team Tether stronghold panel puts a gate arch at roughly three
human heights with a multi-storey keep and towers above it; palworld-04's landmark tower is
tens of metres and dominates the sky. A 3 m dome is a garden gazebo, and the frame is composed as
if it were a cathedral.

Other scale problems:

- **12** — the trees are half the height of a single-storey cottage. The tree at x≈530 is ~40 px
  tall where the cottage beside it at x≈580–660 is ~80 px. Trees that come up to a roof gutter
  read as shrubs. The key art's defining feature is oaks that dwarf the buildings; here the
  buildings dwarf the oaks.
- **02** — same problem: the trees on the cliff top are smaller than the cottages below them.
- **11** — the two edge tree trunks are ~120 px wide in the near field, implying a 3–4 m trunk,
  while the mid-ground trunks of what appears to be the same tree are ~20 px. The same species
  disagrees with itself by an order of magnitude.
- **09** — the market stall awnings at the left and right edges are nearer to camera than the
  trainer yet only about two trainer-heights tall overall, which makes them read as toy-scale
  furniture.
- **08** — the stone tower, the region's only landmark, measures roughly 4.5 trainer-heights
  ≈ 8 m. That is a two-storey building, not a watchtower you can see from across a region.
- **11** — the one creature reads at roughly trainer height with its ears erect and about
  chest-height at the body. Both copies of it in the frame are consistent with each other, so
  this is not an internal contradiction — but it is the only data point the survey offers, and
  it does not demonstrate a roster with size variety. Nothing in these six frames shows a large
  creature and a small creature in the same shot, so relative creature scale is untestable here.

---

# VERDICT

## 1. The three things that most separate these frames from the references

**1. Frame 06 is not a finished render.** A ruled horizontal seam splits it in half and the lower
40% is unlit geometry at one-fifth the brightness of the identical material above it. Every
Palworld reference and every key art panel is a continuous, coherently lit space. This is not an
art-direction gap, it is a broken frame, and it is on the contact sheet representing the game's
climactic approach. Nothing else on this list can be evaluated fairly until 06 renders.

**2. There is no sunlight — the top quarter of the value range is empty in all six frames.**
Every reference reaches 215–240 in its 95th percentile; the best of these frames reaches 168 and
02 reaches 137. The references get their vibrancy from *range* — blown grass, sky glare, hot rims
on creatures — not from saturation. These frames are saturated but sunless, so 02, 09 and 12 all
read as one soft mid-tone under overcast despite drawing a clear blue sky and hard shadows. The
only pixels in the entire survey that reach the reference highlight band belong to four
placeholder objects (the fullbright finial in 06, the green cube in 02, the white slivers in 12).

**3. Frame 09 does not read as a place where anything happens, and frames 02/08/11/12 give
40% of their area to empty lawn.** In palworld-01 and -03 a fight fills the frame with a
creature, sparks, trampled flowers and a second creature at the edge; in palworld-05 a base is
dense with props, pals and tasks. 09 is a flat empty disc with one 28-pixel figure across it and
a ring of repeated market stalls. 02 and 08 put the trainer alone on an unbroken green plane
with a bush-boulder pattern repeating behind him. The references are never empty and never
regular; these are both.

## 2. The two bar questions

### A. Do these frames belong to the world in `tetherbound-meadows-keyart.png`?

**No.**

*What carried:* the building family is right. The half-timbered cottages with dark slate roofs in
02, 08 and 12, the stone tower in 08, the oxblood-and-white-wheel banners on the stronghold gate
in 06 — these are recognisably the key art's settlement and stronghold vocabulary. 12 in
particular, with its wisteria trellis, benches, crates and flower clumps, is genuinely on-board.

*What sank it:*
- **Trees.** The key art's Meadows is defined by oak groves — huge canopies that overshadow the
  buildings and put dappled light on the ground. In **12** and **02** the trees are half the
  height of a cottage. The single most identifiable feature of the art direction is absent.
- **Distance.** Every key art panel has a horizon event: a peak, a windmill, a tower, a ridge
  line. **08** has an empty grey band. **02** and **12** have cliffs at forty metres and then
  nothing. "Silhouettes and landmarks visible from distance" is printed on the board and is not
  happening.
- **Value and light.** The board's mood is warm sun on green, with deep cool shadow under the
  oaks. These frames have neither the highlight nor the coloured shadow.
- **Oxblood discipline.** The board reserves oxblood for the Team Tether stronghold panel. In
  **09** it is the colour of the market awnings.

*Fixable by changing the scene:* everything above except the tree canopies. Aerial-perspective
fog, a brighter/warmer key with a real specular response, distant landform silhouettes on the
horizon, clustered rather than evenly-spaced scatter, restricting oxblood to Team Tether props —
all scene, lighting and placement work.

*Not fixable without art:* the oak canopy. The tree in these frames is a small round-canopy asset
with a smooth untextured trunk; scaling it up will make **11**'s pipe-trunk problem worse, not
better. A large-canopy oak with real bark, root flare and a broken silhouette is art that is not
in the build. The near-white pale-boulder asset is also a different stone family from the cliff
modules and no amount of placement reconciles them — one of the two has to be re-authored or
re-tinted.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

*What carried:* the trainer character reads correctly — third-person, over-the-shoulder, backpack,
stylised proportions, a small figure in a large landscape. That framing is the same genre
language, and it is consistent across all six frames.

*What sank it:*
- **Five of six frames contain no creature at all.** The sixth contains one model, duplicated.
  You cannot show someone six screenshots of a creature-training game in which five have no
  creature and expect the comparison to survive. Every Palworld shot has multiple pals in frame,
  several species, several silhouettes, several hues.
- **The one creature has no colour and no silhouette.** In **11** it is white-on-white against
  pale sky and pale rock, and it disappears at thumbnail size. Palworld's creatures are bespoke,
  saturated and instantly legible at any scale — that is the product.
- **Ground density.** Compare the forest floor in palworld-01 or the meadow in palworld-03
  (continuous grass tufts, flowers, shrubs, undergrowth to the horizon) with the bare uniform
  plane filling the bottom of **02**, **09** and **11**. In **08** the tall grass is sparse straw
  cards with bare ground showing between them.
- **A fight does not look like an event.** **09** is the final arena and it has a flat empty
  circle, no elevation, no barrier, no crowd, no hazard, no VFX and one distant figure.

*Fixable by changing the scene:* creature presence and placement (put the roster in the shots),
foliage and ground-cover density, the arena's dressing — a rim, a lip, spectators, banners,
scuffed sand, hazards — and the lighting/value work from question A. All of it is placement,
scatter, terrain sculpt and lighting.

*Not fixable without art:* the creature roster. One hueless white model cannot carry a comparison
against Palworld's bestiary no matter how it is lit or placed. The gap here is species count,
silhouette variety and colour identity, and that is art that has to be made or bought — recolours
and scale variation on a single asset will not close it. The pale-putty boulder asset and the
untextured tree trunks in **11** are also below the bar as models, not as placements.

---

# The four direct questions

**A. 09-final-arena-space — does it read as somewhere a fight happens, and is the floor one flat
empty plane?**

No, and yes. The floor is a perfectly flat, perfectly circular patch of pale sand-tan applied as
a texture blend onto a level plane — no lip, no step, no excavation, no rim, no barrier, no
seating, no scuffing, no cracks, no hazards, no props, nothing. Its edge is a blend boundary with
visible staircase aliasing, not geometry. Nothing in the frame says fight: no crowd, no opponent
staging, no Team Tether presence beyond banners that also appear on the market stalls, and a
single 28-pixel figure standing on the far side. It reads as a village square that has been
swept, not as an arena.

**B. 06-summit-final-approach — is the dome a finished object with a purpose, and is anything
inside it?**

It reads as an unfinished frame. It is an open lattice of wooden ribs over a low stone wall;
sampling through it at two points returns sky colour (134,155,156), so you are looking straight
through to the sky, not at glazing. Nothing is inside it — the interior is empty, and the only
things visible in that space are a few unsupported salmon-pink blobs floating at chest height.
It is topped by a flat fullbright white (231,231,231) finial that reads as a broken material
rather than a designed crown. It is also only about 3.1 m tall measured against the trainer, so
even as a finished object it would be a gazebo rather than a summit landmark.

**C. 02, 08, 12 — do the cottages read as a windswept clifftop settlement?**

No — they are generic alpine/European village houses that could be anywhere. Identical
half-timbered walls and dark blue slate roofs in all three frames, standing perfectly upright,
with no lean, no bracing, no guy ropes, no stones weighting the roofs, no weathering on the
windward faces, no shutters, no wind-shaped or wind-flagged vegetation, and no directional bend
anywhere in the grass or trees. Nothing in the architecture, the dressing or the plant life knows
there is wind or a cliff. The only thing making them "clifftop" is that rock modules have been
placed behind them.

**D. Near-black matte blobs, pale translucent cubes, rocks that don't match their surroundings?**

Yes to all three, and it is systemic.

- *Near-black matte blobs:* the bushes in **02** measure (0,11,0) — pure black, no highlight, no
  rim; the same asset repeats in 08 and 12. The central spire in **11** is (18–34) near-black
  matte with smeared banding and no light side at all. The dark navy boiler at the right of **09**
  reads as a hole in the frame. The house interior in **12** is (30,12,2), an unlit void.
- *Pale translucent cubes:* the mint-green slab on the path in **02** (213,231,196) and the
  glowing emerald cube in **11** are the same placeholder object, and both are among the brightest
  pixels in their frames. Two thin near-white slivers lie in the grass in **12** (211,209,188 and
  223,219,209) with no thickness and no contact shadow, and two more appear in **02**. The white
  finial in **06** is flat fullbright.
- *Rocks that don't match their surroundings:* worst offender in the survey. In **02**, the cliff
  face measures (20,30,31) while the boulders sitting directly in front of it measure
  (169,181,171) — a 6× luminance gap between two stones in the same frame under the same sun.
  Those pale boulders are smooth, near-white, single-value, mossless and shadowless, and the same
  asset appears in 08 and 12 (168,180,170) against much darker green-grey cliffs. **11** has three
  incompatible rock languages in one shot: a near-black smeared spire, pale white putty lumps, and
  a mid-grey chip. And in **08**, three of the "boulders" on the right slope are not boulders at
  all — they are flat, straight-edged polygonal patches of rock texture painted onto the terrain,
  with zero thickness and zero silhouette.
