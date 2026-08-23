# D7 world surface — grass, ground, water, sky, weather

Lane `ralph/VIS-WORLD`. Owner's #1 visual priority. This file records what was
established, what was changed and why, and what is honestly out of reach of
tuning. Verdicts from the blind rounds are appended as they land.

## The owner's highest-value lead, resolved: the inference is wrong

The lead, from a round-1 blind critic:

> "water-02-river-eye shows a grass-blade ground texture reading well at close
> range... a different, better material that apparently exists in the build and
> is NOT used in the five walk bands. So the emptiness in bands 1-5 is a
> density/placement decision, not missing art."

**There is no second ground material.** `terrain_playground.json` carries
exactly four terrain textures — `grass` (Grass008), `rock` (Rock030), `soil`
(Ground003), `path` (Ground030) — and Terrain3D applies that one set globally
through `playground_world.gd::_build_texture_list` plus the baked control map.
No riverbank material exists, and nothing in `water.json` or `water.gd` paints
terrain. The river frame and the band frames stand on the same Grass008.

What the critic actually saw, checked against the frames:

1. **The band viewpoints stand on the PATH.** `ground-03-band3-crossing-day`'s
   near field is bare because it is correctly the `path` texture — a dirt and
   pebble photograph. The grass in that frame is the hillside to either side,
   seen at the ~17-degree grazing angle a 2.0m camera aimed at ground 6.7m
   ahead produces, where mip averaging flattens it to a wash.
2. **The river viewpoint stands on grass**, closer and more frontally lit, so
   the same texture resolves at full detail.

So the emptiness IS a placement decision — the lead's conclusion is right — but
not for the reason it gives, and "move the bands onto the better material"
is not an available action because there is no other material to move to.

**The observation that does survive, and matters more:** neither frame contains
a single piece of ground-cover GEOMETRY. Not one grass tuft, stone or twig in
either. The river frame reads well on texture alone; the band frame does not,
because a dirt path with nothing growing at its edge has nothing to read.

## What the near field is actually missing, and the arithmetic

Every structural layer already concentrates its corridor fill along the
authored routes. `VEG-SITING` gave `trail_bias` to trees, grove, saplings,
deadfall and bushes; `VISUAL-GROUNDCOVER` later gave it to path_stones. Each
time the recorded reason was the same measurement (`docs/reviews/band2/round-05`):
a uniform draw over a 2048m-wide corridor lands near none of the survey
viewpoints, all of which stand ON the trail, so a density multiplier has
nothing to multiply where the camera is.

**The three layers that carpet the near field — grass, drygrass, flowers —
were never given it.** The primary ground cover was still drawn uniformly
across 16.8 km2 while the player walks one line through it.

Band 3 before the change (the thinnest band, `density_scale` 0.05):

- ~68 kept grass clumps of radius 10m over 3.24 km2
- **~0.66% of the band's ground carried a grass clump at all**
- stray grass ran one tuft per ~5,800 m2 — one every ~76m

Corridor-wide the grass fill keeps ~574 clumps. Spread over 16.8 km2, the
chance one sat within 20m of a given trail point was **~4%**.

That is why the chapter-wide bump (143,630 -> 223,889 placements) measured only
~4% mean improvement and sent band 4 backwards: it multiplied a distribution
that mostly misses the frame.

### The change

`grass` and `drygrass` get `trail_bias` with `density_scale` UNCHANGED, so this
adds no instances — it only moves where existing clump centres land. At
`trail_bias` 0.65, ~373 of those 574 clumps sit within 34m of the route,
roughly one clump per 32m of a ~12km network.

0.65 and 0.55 rather than the 0.85 the tree layers use: a carpet concentrated
as hard as a copse layer stops being a meadow and becomes a green ribbon down a
bald plain, so a third of the fill stays where the unbiased draw puts it.

**`flowers` deliberately get no `trail_bias`.** OF12 removed this layer's path
anchoring outright after four rounds, and the owner's verdict was that
anchoring a garden-accent layer to a centreline is planting a border however
jittered. That still holds.

The verge — the one mechanism that puts cover at the worn edge — ran at 2400
grass instances by arc length over ~12km of route: one per 5m across an 18m
band on both sides, a spacing no viewer reads as a verge. Raised to
6000/1800/900. flowers are raised here rather than by `trail_bias` because an
arc-strung, standoff-thinned fringe is not the clump disc snapped to a
centreline that OF12 rejected.

`path_standoff` already varies 0.3-7m with position noise per side. It has had
almost no cover to ravel until now, which is why the path reads as stamped on
rather than worn through.

### The measurement that makes this falsifiable

The re-bake computes **217,599 placements against the previous 223,889 — 2.8%
FEWER**. Relocating clump centres onto the route costs some placements to the
path-standoff gate that open ground never triggered. So if the near field
improves, it improved with fewer props on the map, which is the cleanest
available evidence that siting rather than quantity was the defect.

## Clouds: no cloud layer exists, and that is not an oversight

Established by reading, not by looking at frames. The sky is a
`ProceduralSkyMaterial` — a vertical gradient and a soft sun blob.
`art.json`'s own comment states the limit plainly: *"No amount of tuning puts a
cloud in it."*

A `PanoramaSkyMaterial` path exists and once used `day.hdr`/`golden.hdr`, which
DID carry cloud form. **EV8 pulled it deliberately**: a static equirect photo
has its own baked-in sun position that cannot track `sun.pitch_deg`/`yaw_deg`,
so one viewpoint's sky read as dusk while its own ground lit as bright midday.
Golden hour additionally blew out two-thirds of the frame at every energy
tried.

The `cloudy` preset is explicitly *"a stylised flat-overcast look, not literal
cloud shapes"*.

**This is needs-implementation, not needs-tuning, and not something to fake.**
The two honest routes are a procedural sky shader deriving cloud form from the
real sun direction (no baked-sun seam, but a new shader this lane does not
own), or multiple panoramas matched to sun position by heading — which
`art.json` already names as the condition under which a panorama becomes
legitimate again.

## Weather changes particles and not light — the cause is a dead property

Three critics reported sun shadows staying razor-sharp under cloudy, fog and
rain. The presets were not silent about this: **all three already ask for soft
shadows** — `cloudy` and `rain` set `angular_distance` 3.0, `fog` 2.5.

None of it did anything. `light_angular_distance` is one of the two properties
`world_look.gd::_apply_sun`'s own comment records as a **no-op under the
Compatibility renderer**, which is the renderer the game ships (RB4/D01). The
presets carried the right intent through a property that cannot express it, so
every round that read the config saw a soft-shadow number sitting there and
moved on.

`shadow_opacity` scales the shadow term itself and does reach this renderer.
Added to `_apply_sun` and to the weather override path, and set per preset
(cloudy 0.45, fog 0.28, rain 0.40). `angular_distance` is kept rather than
deleted: it is correct intent a future renderer would honour.

It is deliberately **not** `shadow_enabled: false` — R5.2 tried that and
Terrain3D rendered the whole ground as fully occluded. The shadow map has to
keep existing; this only makes it faint.

## Water: one palette already, diverging on depth and alpha

"Three water bodies, three unrelated colours" is a real perceived defect, but
the config is already unified: pond, river and stream all use
`surface.deep_colour` #17494a and `surface.shallow_colour` #6fa384. The only
per-body overrides are `alpha_shallow` — pond 0.48, river 0.70, stream 0.78.

The divergence is emergent: depth decides how much of the frame resolves toward
`deep_colour`, alpha decides how much of the bed shows through, and a grazing
angle adds a fresnel reflection of a pale sky. So the fix is not "give them one
colour" — they have one. It is `depth_falloff` and the alpha split.

Not yet acted on; recorded so a round does not re-derive it.

## Night

Measured across all five night frames, before any change: **sky 0.0% and
horizon 0.00 in every one** — the sky is indistinguishable from the ground, so
there is no horizon at all. Near-field luminance 0.025-0.140 against 0.115-0.280
in daylight.

The night preset runs `exposure` 2.0 against day's 0.6, with
`ambient_energy` 2.3. A uniform ambient lift multiplies albedo, so it raises the
trainer's bright albedo far more than a terrain whose grass albedo R9.4
deliberately darkened to value 0.199. That is a direct arithmetic account of
"the character is pasted onto black paper", and it is checkable rather than a
guess. Not acted on this round.
