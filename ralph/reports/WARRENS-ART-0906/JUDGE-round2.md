# Blind visual judgement — Burrow Warrens (`shots/warrens_63/`)

Judged against `docs/reference/tetherbound-meadows-keyart.png` and
`docs/reference/palworld-0*.jpg`. No score. Frames named per defect.

---

## 0. What already works, so the gap is not mistaken for incapability

- **`03-mouth` is the best frame in the survey and it is genuinely good.** The
  arch of the earth lip, the tangle of exposed roots hanging into the opening,
  the framing boulders left and right, the black interior with one lit creature
  standing in it — that is authored composition with a foreground, a threshold
  and a reveal. It has depth, a subject, and a reason to walk forward.
- **The mushroom cluster in `05-hall-from-the-doorway`** is the only object in
  any interior frame with a designed silhouette: varied cap heights, varied stem
  lean, overlapping depths, a colour that separates from the room. It reads at
  thumbnail size. Nothing else indoors does.

Everything below is measured against the fact that this build can already do
those two things.

---

## 1. Silhouette and readability at small size

Viewed as a 256 px thumbnail row:

- **`00-approach-60m` has no landmark.** The burrow knoll at 60 m is a grey-green
  cone sitting at almost exactly the value and hue of the hills and tree canopy
  around and behind it. Nothing separates it. The most readable object in the
  entire thumbnail is the clump of **orange sedge in the near foreground**, and
  the second most readable is a **wooden crate 60 m away** — a loot prop
  out-silhouettes the location the shot is named after. Every Palworld reference
  puts a hard-value landmark on the skyline (`palworld-04` the plateau ruin and
  spire; `palworld-05` the snow peak and the standing pillars), and the keyart's
  top-left panel puts the settlement tower and the peak against sky. This frame
  has no such object.
- **`02-knoll-from-outside` has no subject at all at thumbnail size.** It is a
  grey rock pile on the left third and an empty pale field on the right
  two-thirds. The burrow mouth — the entire point of the location — is not
  visible from this angle. A survey shot that does not show its subject is a
  framing defect, not a lighting one.
- **`04-hall-dressing` and `07-den-dressing` both reduce to "a brown box with one
  small orange dot in it."** At thumbnail neither is distinguishable from the
  other, and neither says "entrance hall" or "boss den."
- Tree/rock/bush separation outdoors is weak: in `00` and `01` the trees are all
  the same rounded green blob on a stick, at three or four heights that cluster
  tightly, and the bushes are the same green at the same value. A tree, a bush
  and a mossy boulder in `02` all sit in the same narrow olive band.
- The guardian in `06-den-and-guardian` **does** silhouette — the white face mask
  against the dark room is the strongest read in the interior set. That part
  works.

## 2. Colour and value structure

Measured on the lower two-thirds of each exterior frame (sky excluded), against
the same measurement on the references:

| | median chroma | brightest 5% (value) |
|---|---|---|
| `00-approach-60m` | 0.28 | 0.67 |
| `01-knoll-from-outside` | 0.24 | 0.69 |
| `02-knoll-from-outside` | 0.18 | 0.62 |
| `palworld-02/03/05` | 0.42–0.49 | 0.90–0.94 |
| keyart (grove/meadow panels) | 0.39 | 0.92 |

- **The ground is never lit.** Nothing in the lower two-thirds of `00`, `01` or
  `02` gets brighter than about 67% grey, while both references reach 90%+ on
  sunlit grass. There is a hard blue sky with a clear sun direction overhead —
  the crate in `01` throws a sharp shadow — but no sunlight lands on the meadow.
  The result is a bright sky pasted over an overcast field. This is the single
  loudest colour defect in the survey and it is present in all three exterior
  frames.
- **The ground albedo is roughly half the chroma of the references.** The meadow
  in `01` and `02` is a pale grey-green closer to dead winter turf than to the
  saturated green of the keyart's grove panel or `palworld-03`'s field. The
  keyart's own palette strip runs deep forest green, olive, gold, cream — none of
  those colours appears in the terrain of any frame here.
- **Value range collapses in both directions.** The exteriors are one mid-tone:
  no deep shadow accent under the tree canopies, no highlight anywhere. `02` in
  particular is a single flat 0.18-chroma field from bottom edge to horizon.
- **Red is not being reserved.** The brightest, most saturated red in the entire
  exterior set is the **base block of the lamp post in `03-mouth`** — a
  fire-engine red on a friendly navigation prop. The next most saturated warm
  accents are the orange crates and chests, which appear in five of eight frames.
  If oxblood is meant to signal Team Tether and danger, a red lamp base and a
  field of orange crates dilute it.
- **The frames disagree about the burrow's floor.** Through the doorway in
  `03-mouth` the interior floor reads dark blue-grey. In `04` and `05` the same
  floor is a bright warm cream sand. That is not a torch-brightness difference;
  it is a hue flip, and seeing the two shots side by side on the sheet is what
  exposes it.

## 3. Intentionality — authored or generator output

- **`01-knoll-from-outside` reads as scatter output.** The grass is a monoculture:
  one blade type, one height band, one tint, distributed at even spacing across
  the whole visible field with no clearings, no clumps, no paths, no bare patches
  and no tall/short contrast. Compare `palworld-02`, where the field is broken by
  a worn dirt path, taller grass at the verges and bare rock — the ground tells
  you where to walk. Nothing in `01` does.
- **`04-hall-dressing`: the props are laid out in a line at even spacing.** Crate,
  barrel, two rocks, one rock, one dark slab, marching left to right across the
  floor at roughly constant intervals and constant footprint. No stack, no
  cluster, no leaning object, no object touching another. It reads as items
  dropped on a grid, not as a place anyone lived in.
- **`07-den-dressing` is 70% empty floor.** One chest, one boulder, one sack,
  three pebbles, in the upper-middle band; the entire lower half of the frame is
  bare sand. `palworld-05` fills a comparable area with a chest, a workbench, a
  campfire, a palisade, crates, a creature and a player, and every one of them
  overlaps something else.
- **The rock language is inconsistent within one frame.** In `02-knoll-from-
  outside` the boulders are flat-shaded low-poly slabs with hard facets and
  visible triangle edges, while the knoll they sit on is a smooth high-resolution
  blob with a noise texture. Two incompatible rock treatments, adjacent, in the
  same shot.
- **The lamp post in `03-mouth` does not belong to this world.** It is a modern
  mushroom-shade park lamp on a smooth grey aluminium pole with an unshaded
  emissive yellow sphere and a painted red base, standing outside a prehistoric
  earth burrow in a wildflower meadow. Nothing in the keyart uses that vocabulary
  and nothing in Palworld does either. It reads as a municipal streetlight.

## 4. Lighting

- **The sun does no diffuse work outdoors.** See §2. Sharp cast shadows exist
  (`01` crate) but the lit side of the terrain is no brighter than the shadowed
  side by any meaningful amount.
- **Shadow treatment is inconsistent between frames of the same location.** The
  crate shadow in `01` is a soft grey ellipse; the shadow band under the rock
  cluster in `02` is a hard-edged, near-black wedge with a straight leading edge
  cutting across the grass. Same location, same time of day, two different
  shadow behaviours.
- **`03-mouth` has an unattributed black shadow blob** in the bottom-right corner
  of the mud apron with no visible caster.
- **`04-hall-dressing` has a hard straight-line light terminator** running
  diagonally across the big left-hand wall plane. It reads as the edge of a
  shadow map or a light cone, not as a soft falloff off a torch.
- **The torch falls off to nothing.** In `04` the entire right and back of the
  room is a flat near-black brown field with no detail recoverable. That is a
  legitimate authored-dark choice up to a point, but there is no bounce, no
  secondary bounce colour, and no rim on anything — objects at the edge of the
  cone simply vanish rather than dimming. The dark blue-black slab at the right
  of `04` collapses to pure black and reads as a hole in the wall rather than a
  boulder.
- **The props are flat-lit relative to the room.** The crate in `01` shows almost
  no brightness difference between its two visible faces even though its own
  shadow says the sun is behind-right. Same for the chests in `06` and `07`:
  front face and side face are the same value.

## 5. Horizon and depth

- **No atmospheric perspective outdoors.** In `00-approach-60m` the distant
  treeline on the right sits at essentially the same value and saturation as the
  trees 5 m from camera. In `02` the far hills are a flat green band that meets
  the sky at a hard cut. `palworld-04` and `palworld-05` both wash the far
  landmark toward the sky colour, which is what makes their distance read; the
  keyart does the same to its mountain. Nothing here does.
- **`01-knoll-from-outside` has a visible terrain seam.** The bottom-right corner
  is a hard-edged dark-olive terrain wedge, a completely different tint from the
  pale grey-green meadow it abuts, carrying zero grass and zero scatter, with the
  boundary running as a clean curve across the frame. It reads as an unpainted
  chunk or a different material layer, not as a hill.
- **`05-hall-from-the-doorway` has a white speckle line** running along the joint
  where the ceiling slab meets the right-hand wall — a crack/z-fight along a
  geometry seam.

## 6. Interface

No UI is present in any of the eight frames. Nothing to assess. Noting it so it
is not mistaken for a pass.

## 7. Artefacts

Ranked by how much they read as a bug rather than a choice:

1. **The guardian floats.** In `06-den-and-guardian` both front paws end
   visibly above the floor plane — sand is visible under the claws — and the
   creature has **no contact shadow at all**. The large soft dark patch on the
   floor is offset well to the left and behind it and does not follow its
   outline. It reads as a model dropped into the room at the wrong Y with its
   shadow disabled. This is the boss of the location; it is the one object in the
   survey that most needs to have weight.
2. **Duplicate chests, in three frames.** `04-hall-dressing`, `06-den-and-
   guardian` and `07-den-dressing` each contain **two copies of the chest asset
   at nearly the same transform**, interpenetrating — the second copy's lid rim
   and back corner stick out behind and above the front one. It is visible at
   full size in all three. Systemic placement bug, not a one-off.
3. **Grass floating in the sky.** `03-mouth`, upper-left: two grass tufts hang in
   open air against the blue sky, detached from any surface, several metres above
   the nearest rock.
4. **Half-buried fin rocks.** `02-knoll-from-outside`: a flat dark rock slab is
   jammed edge-first into the left mound and juts out into the sky like a brim,
   with a hard black unlit underside. A second one does the same on the right
   mound. They read as boulders spawned at a random rotation inside the terrain.
5. **Geometry intersection on the guardian.** In `06` a bright green grass tuft
   passes straight through the creature's chest and out the front.
6. **Ceiling beams are painted, not built.** In `05` and `07` the "beams" are
   flat dark stripes on a flat ceiling plane with no thickness, no shadow and no
   sag. In `07` one of them terminates in mid-wall.
7. **Boxy burrow.** The interior is a set of hard 90° extruded prisms with
   perfectly flat walls, sharp vertical corners and a flat ceiling. Nothing about
   `04`, `05`, `06` or `07` says "dug." The doorways are plain rectangles cut in
   a wall with a flat frame band, no jamb, no lintel, no wear.
8. **Loose floor decals.** In `06` and `07` several dark rock/mud decals sit on
   the sand with hard edges and no relation to the surface shading; one in `06`
   floats above its own shading.
9. **The boulder in `07` is a truncated cone** — a smooth symmetric bucket shape
   with no facet, no silhouette break and no ground contact shading. It does not
   read as rock.

## 8. Scale agreement

**No trainer is in frame, and no object in these eight frames has an
independently known size.** I therefore cannot give absolute metres, and I will
not do it by assuming a doorway. I am also explicitly not measuring doorways
against 2 m, as instructed. What is checkable is relative scale between objects
sharing a ground line in the same frame.

- **Prop-to-prop scale is internally consistent and fine.** In `04` the barrel and
  the crate share a ground line and the barrel is very slightly the taller — the
  normal relationship. In `07` the boulder and the chest share a ground line and
  the boulder is about 2.2× the chest. Nothing disagrees.
- **The guardian is genuinely large, and that reads correctly.** In `06` the
  guardian's lowest paw and the chest's base sit at essentially the same screen
  height, so they are at comparable depth; the guardian measures about **4.5–5×
  the chest's height** at the shoulder. Whatever the chest is, the boss is
  several times it. It is not the frog-sized-boss failure. Good.
- **The one thing I cannot resolve and will not guess:** in `05` the guardian is
  seen through a far doorway from well behind the door plane, so its apparent
  fraction of that opening is not a valid measurement of anything. I am naming
  this only so nobody reads that frame as a scale finding in either direction.
- **The mushrooms may disagree with themselves.** The cluster in `05` is a hero
  object several times a chest in height; a single mushroom of apparently the
  same green species sits beside the dark slab in `04` at a small fraction of a
  chest. If those are the same asset, the size difference is large and visible.
  If they are different species, disregard.
- **The small creature at the burrow mouth in `03`** is far too distant and too
  low to the ground for a defensible ratio against the guardian. I am not
  claiming one.

## 9. Creature art — said first because the rubric says to say it first

The guardian in `06-den-and-guardian`, seen full-size, **is two different animals
welded together, in two different painting styles**, and the seam is visible at
the shoulder:

- The **head and chest** are a hand-painted badger: high-contrast black and white
  mask, soft brush strokes, warm brown around the eye and muzzle, a matte
  stylised finish. It is expressive and it is the best-looking thing in the
  survey.
- The **back, flank and haunch** are a glossy grey-and-black speckled hide with
  chunky green moss plates bolted along the spine, rendered with a hard specular
  sheen and a totally different, noisier texture frequency. It looks like a rock
  golem's back.
- Where they meet, behind the ear, the badger fur simply stops and the mossy
  plating starts. There is no transition, no shared palette, and no shared
  material response — the head is matte and the body is shiny in the same light.
- The forepaws are grey with white claws in a third register again — smooth,
  plasticky, near-untextured.

The same mashup grammar appears on the small creature visible through the
entrance in `03-mouth`: a tan hedgehog/boar head on a moss-crusted back. So it is
a consistent authored idea, not an accident — but it is not currently reading as
one animal.

Held against `palworld-01`, whose Mammorest is a single designed silhouette where
the leafy crest, the tusks, the belly and the limbs all share one material
language and one line weight, the guardian does not hold up. Against
`palworld-04`, where four different creatures on screen at once are visibly the
same studio's hand, `03`'s small creature and `06`'s guardian read as two assets
from different sources.

**And the fight does not look like an event.** `palworld-01` and `palworld-03`
both stage the boss with a shattered ground, impact sparks, a wind ring, dust,
and other creatures in frame; the encounter announces itself. `06` is a large
animal standing motionless in an empty brown room next to two chests, with no
VFX, no ground disturbance, no dust, no light change and no second actor. Even
allowing that this is a still, there is nothing in the room that says a fight
happens here.

---

# VERDICT

## 1. The three things that most separate these frames from the references

**1 — The ground never receives light, and it is the wrong colour.**
In `00-approach-60m`, `01-knoll-from-outside` and `02-knoll-from-outside` nothing
in the lower two-thirds of the frame exceeds ~0.67 value, and median ground chroma
is 0.18–0.28. `palworld-02`, `palworld-03` and `palworld-05` all reach 0.90+ with
median chroma 0.42–0.49, and the keyart's grove and meadow panels reach 0.92 at
0.39. What the references do that these do not: they put **hot, saturated
sunlight on the grass**, so the field has a lit side and a shaded side and the
eye has somewhere bright to land. Here there is a hard blue sky, a sun direction
proven by the crate's sharp shadow in `01` — and a meadow lit as though it were
overcast. Everything else about the exteriors, including the palette complaint,
follows from this one fact.

**2 — The guardian is a two-style chimera and it is floating.**
`06-den-and-guardian`: a hand-painted matte badger head joined at the shoulder to
a glossy moss-plated rock body, with a third material on the paws; both front
paws end above the floor with sand visible beneath them and no contact shadow of
any kind — the only dark patch on the floor is offset behind and to the left and
does not follow the animal's outline. A green grass blade passes through its
chest. `palworld-01`'s Mammorest is one animal in one material language, planted
on ground it has visibly disturbed. This is the creature the location exists for,
and it is the frame a viewer will judge the whole game on.

**3 — Nothing is composed, indoors or out.**
`02-knoll-from-outside` is the clearest case: a survey shot of the Burrow Warrens
in which the burrow mouth is not visible, leaving a low-poly rock pile and an
empty grey-green field. `04-hall-dressing` places a crate, a barrel and rocks in
an evenly spaced line across a floor and gives 40% of the frame to a blank wall
plane. `07-den-dressing` leaves the entire lower half of the frame as bare sand.
`00-approach-60m` approaches a landmark that does not separate from its
background at all, while an orange crate 60 m away out-reads it. Every reference
shot — `palworld-02`'s worn path through broken grass, `palworld-05`'s stacked
base clutter, the keyart's grove with dappled floor and layered trunks — puts
clustered, overlapping, unevenly scaled stuff in frame and clears space
deliberately. These frames clear space by default.

## 2. The two bar questions

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?

**No.**

What sank it: the keyart's meadow is a deep, saturated green under warm dappled
sun, with layered oak trunks, wildflower drifts, and a strong readable landmark
on every panel. The exteriors here are a pale, low-chroma grey-green field under
light that produces no highlight (`00`, `01`, `02`), with uniform single-species
grass at even spacing, a landmark that does not separate in value from its
surroundings (`00`), and a modern red-based park lamp post (`03`) that has no
counterpart anywhere on the board. The keyart's own palette strip — forest green,
olive, gold, cream, slate, oxblood — is not what is on screen.

What carried, partially: the sky is close to the board's sky, the tree shapes are
in the right family, and `03-mouth` — the arch, the root tangle, the flanking
boulders, the dark reveal — is the one frame that would sit on that board without
argument.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

The genre signals are present — a big creature in a den, a meadow, chests, a
burrow to enter — so the *intent* is legible. But shown side by side, the
specific things a viewer would name are: the Palworld shots have sunlit,
saturated ground with a full value range and these do not (`00`/`01`/`02`); the
Palworld creatures are one studio's consistent, expressive design and this one is
two assets in two styles fused at the shoulder (`06`); Palworld's boss frames are
events with impact VFX, disturbed ground and multiple actors, and `06` is an
animal standing still in an empty room beside two overlapping chests; and
Palworld's world is dense with overlapping, lived-in clutter where `04` and `07`
are near-empty brown rooms with props on a grid.

### Which gaps are fixable by changing the scene, and which need art that is not in the build

**Fixable by scene work — this is the work list:**

- Exterior lighting/exposure so the ground plane actually receives the sun; the
  highlight end of the value range is missing, not compressed (`00`, `01`, `02`).
- Terrain albedo saturation and hue variation on the meadow (`01`, `02`).
- Scatter authorship: clumping, height variation, species mix, clearings and worn
  paths instead of even single-species distribution (`00`, `01`, `02`).
- Atmospheric perspective / distance fade so far treelines and hills separate
  from near ones (`00`, `02`).
- The terrain seam and unscattered olive wedge in the bottom-right of `01`.
- Reframe `02` so it shows the burrow mouth, or drop the angle.
- Give the knoll a value or silhouette break so it reads as a landmark at 60 m
  (`00`) — a skyline snag, a lit face, a marker.
- Fix the floating grass tufts (`03`), the half-buried fin rocks (`02`), the
  loose floor decals (`06`, `07`).
- Fix the duplicate chest placements in `04`, `06` and `07`.
- Plant the guardian on the floor and give it a real contact shadow; move the
  grass tuft out of its chest (`06`).
- Cluster, stack, lean and overlap the interior dressing; fill the dead lower
  half of `07` and the blank wall half of `04`.
- Break the 90° prism walls and flat ceilings; give the doorways a jamb and wear;
  give the ceiling beams thickness instead of painting them (`04`–`07`).
- Reconcile the interior floor colour between `03` and `04`/`05`.
- Soften the hard shadow-map terminator on the left wall of `04`; reconcile the
  hard-black shadow band in `02` with the soft crate shadow in `01`.
- Stage the boss room: ground disturbance, dust, a light source with intent, so
  `06` reads as somewhere a fight happens.

**Not fixable by scene work — needs art that is not in the build:**

- **The guardian.** The head and body are different assets in different painting
  styles with different material responses. No lighting, placement or dressing
  change reconciles a matte hand-painted badger head with a glossy moss-plated
  rock body. It needs one artist's pass over the whole creature, or a different
  creature. Same for the small creature at the mouth in `03`, which uses the same
  head-on-moss-body grammar.
- **The prop family.** The crate, barrel and chest carry photographic-looking
  wood and metal textures while the world around them is flat-shaded stylised
  geometry. That is a texture-authoring mismatch, not a lighting one; they need
  re-texturing into the world's language or replacing.
- **The lamp post in `03`.** A modern park lamp with a red base does not belong
  in this world at any brightness. It needs to be a different object — a lantern,
  a torch, a marked cairn.
- **The rock family in `02`.** Flat-shaded faceted low-poly slabs sitting on a
  smooth high-resolution noise-textured knoll are two incompatible rock
  languages. One of them has to be remade so the location has a single rock
  vocabulary.
