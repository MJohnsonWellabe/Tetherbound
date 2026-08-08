# MA-05 — no on both bars. The ground is fixed; the world is empty.

Blind visual review, round 5, judged against `docs/reference/tetherbound-meadows-keyart.png`
and `docs/reference/palworld-0*.jpg`. The critic saw five survey frames and the
two references and was told nothing about what changed.

First round since D18 — the meadow is now rendering grass rather than rock. That
fixed the ground *material* and revealed what was underneath it: the ground is
**empty**.

## The verdict

> **A. Do these frames read as belonging to the world in the key art?** **No.**
>
> **B. Shown beside the Palworld screenshots, would someone say these are trying
> to be the same kind of game?** **No.**
>
> They would say this is a landscape mock-up and that is a game.

`05-spawn-low-sun` alone very nearly carried question A — the dusk value split
and the settlement in silhouette are recognisably the key art's sunset panel.
Four of five did not.

## The three ranked gaps

**1. The frame is empty where the references are full, and the emptiness is the
ground plane — most of the picture.** The bottom half of `01-spawn-outward`
holds about three dozen flower sprites across 800×450px and nothing else: no
grass geometry, no rock, no log, no bush, no track, no creature. `palworld-02`
fills the same area with instanced knee-high grass, a rutted road, rock walls, a
cave mouth, layered trees and four creatures — and it is ordinary traversal, not
a set piece. Measured: ground-half value standard deviation **0.09–0.11 here
against ≈0.20 across the five references.**

**2. The player character is a stand-in and reads as one in every frame he
appears in.** See below — this is the single largest gap and no lighting pass
touches it.

**3. `03-rise-overlook` proves the world has no distance.** 5th-percentile
luminance **0.47** — literally no dark tone in the image, against p5 ≤ 0.20 in
every reference. A hard chromatic seam runs the full 1600px width at y≈235 where
fog colour meets sky colour. The horizon is a ruled flat line with no landmark
mass beyond it.

## The character — quoted, because it confirms the owner independently

> The pose is broken. Left arm is straight out horizontal, right arm is folded
> 90° behind the back with the hand resting on the belt buckle. This is not a
> readable idle in any of the three frames he appears in — it is an un-blended
> rest pose.

The owner reported "arms in a weird position lagging behind his body" from
gameplay at the same time, without seeing this review. Two independent
observations of one defect. A rig investigation was already running when this
landed.

Also: unlit near-#FFFFFF skin with no shading gradient, hands with no finger
separation ("white mittens"), hair as a smooth grey-white cap with no silhouette
break, and pale desaturated blue on mid-green — the lowest-contrast pairing
available, which makes him a 15-pixel unidentifiable lozenge in
`04-three-quarter` and invisible behind water in `02-valley-floor`.

## Scale errors a still frame caught

Measured against the 1.80m trainer:

- **The cottage ridge is ~2.5–3.0m.** The eave lands at the player's chest. He
  could not stand upright inside his own house. Corroborated by the geometry:
  the wall band under the eaves is a third of the roof's pitch height, and there
  is no door — a door would have exposed it immediately.
- **The stronghold is smaller than a barn** — two stone wall segments, ~4–5m,
  where the key art's panel is a monumental multi-storey gatehouse. The biome's
  hero landmark currently reads as rubble.
- **Windmill sails are mounted on top of the castellated ruin wall**, with a
  fifth poking through the wall face. A category error: a prop placed where a
  prop fit.

## Artefacts

- Terrain shows through roof tile seams across whole roofs (`04`, `01`).
- The water plane draws **over** the character (`02`) — sort order or the mesh
  overruns its basin.
- A stream ribbon lies **on top of** the hillside with a razor edge, no channel
  cut, no banks (`02`). The bed-cutting M7 added is not reaching the render.
- The pond has no shoreline: hard polygonal chord edges, uniform opaque pastel
  cyan, no depth darkening.
- Unblended tan/green terrain splat boundary (`02`).
- Flower billboards lie flat, reading as smears on the ground.

## Intentionality — it reads as generator output

~25 near-identical boulders evenly distributed across a slope "like sprinkles",
including on faces where nothing would rest. Ridge trees at uniform height,
lean, canopy size and spacing, and shaped as pole-and-tuft — palms, not the oak
woodland §25 specifies. The grove has no understory, no shadow pooling, and
bright unshaded grass visible straight through it: *"A grove is a place; this is
a tree density value."* The settlement is three prefabs on open grass with no
fence, path, well, cart or smoke.

The crimson foliage is called out hard: the loudest colour event in the world,
marking nothing — *"it is where a scatter rule changed"* — and absent from the
key art's palette strip entirely.

## The split

**Scene work (this is the list):** grass geometry across the playable surface
(highest leverage — fixes emptiness, value variation and small-size readability
at once); kill or desaturate the crimson foliage; re-author the fog to match the
sky's horizon value and pull density back; raise the shadow distance so the
player casts one; fix water sort order, shoreline and the floating stream; close
the roof tile gaps; cluster boulders into outcrops with size variation; compose
the settlement as a place; rescale cottages to ~4.5m ridge; remove the windmill
sails; put landmark mass beyond the fog line; blend the splat boundary; ship
golden hour as the default look.

**Art that must be bought or made:** a bespoke player character (silhouette
first — hair with shape, a strap or pack breaking the torso, values that read
against green, shaded skin, fingers) plus an authored idle; **at least one
creature in frame** — there is not a single creature in five frames of a
creature-training game, so the creature bar is entirely untested; a stronghold
with real mass; a settlement prop kit (well, fences, carts, banners, barrels);
a tree set with an actual canopy and an understory tier; and **style unification
across the prop packs** — `04-three-quarter` puts four incompatible visual
languages in one frame (photo-detailed terracotta, flat-shaded low-poly trees,
untextured near-white ruin, painterly terrain).

## Note on the survey itself

Five frames of a creature-training game contained no creatures. The wild pals
exist in the world; the camera positions do not look at them. The survey cannot
test half the bar it is being asked about, and that is a harness defect, not an
art one.
