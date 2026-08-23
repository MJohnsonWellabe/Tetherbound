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

## The black grass is not a backface bug, and the mechanism is confirmed

Reported to this lane as *"grass tufts render BLACK on back faces — a
two-sided material bug"*. It is a real defect and it is clearly visible in
`ground-03-band3-crossing-day` (the near-field tuft at bottom right: the lower
third of every blade is solid black, following the blade geometry rather than
any light direction). **But the diagnosis is wrong, and acting on it would have
fixed nothing.**

Culling is correct. Every grass, flower and bush source declares
`doubleSided: true` in its own glTF, and `vegetation.gd` copies
`standard.cull_mode` faithfully, so the back faces are drawn. It is not a
two-sided material bug and there is no culling flag to set.

What is actually happening, traced end to end and measured:

1. The pack's meshes carry a `COLOR_0` vertex attribute. Decoding
   `Grass_Common_Tall.gltf`'s accessor: mean vertex colour **0.001 at the
   lowest 15% of vertices and 0.962 at the highest**. It is a baked
   ambient-occlusion gradient, black at the blade base, white at the tip.
2. The pack's own glTF material declares only `baseColorTexture` and
   `metallicFactor`. It does **not** ask for that vertex colour as albedo.
3. `vegetation.gd::_tint_for` sets
   `vertex_color_use_as_albedo = standard.vertex_color_use_as_albedo or needs_instance_colour`.
4. `needs_instance_colour` is simply `colour_jitter > 0.0`, and grass carries
   `colour_jitter` 0.22, drygrass 0.20, rocks 0.16.

So asking for per-instance colour jitter force-enables the vertex-colour
channel, and `albedo_color` MULTIPLIES — which turns a 0.001 vertex colour at
the blade base into black. Every jittered layer pays this; grass is where it is
visible, because a blade is thin enough that the black half is most of it.

The two channels cannot simply be separated: Godot's MultiMesh per-instance
colour reaches albedo through the same `vertex_color_use_as_albedo` switch, so
turning it off to fix the black would silently disable the jitter — the exact
"set a value, nothing happens, nobody notices" failure class this repo has
already paid for twice.

The correct fix is therefore to neutralise the mesh's own `COLOR_0` (rebuild
the surface with a white ARRAY_COLOR) at the point `_retint` already rebuilds
surfaces, keeping per-instance jitter working and losing only the pack's baked
AO. Not applied yet; queued behind the current blind round so it lands as one
coherent change with the other near-field work.

## What round 1 actually moved, measured

`tools/frame_stats.py`, baseline against round 1:

| frame | chroma | near luminance | hue families |
|---|---|---|---|
| band2 cloudy | 41.7 -> **46.7** | 0.137 -> **0.151** | 3 -> **4** |
| band2 fog | 40.9 -> **44.9** | 0.199 -> **0.220** | 4 -> **5** |
| band2 rain | 42.9 -> **47.2** | 0.112 -> **0.125** | 3 -> **5** |
| band2 day | 49.48 -> 49.47 | 0.220 -> 0.220 | 3 -> 3 |
| band3 day | 62.18 -> 62.25 | 0.262 -> 0.262 | 3 -> 3 |
| band4 day | 48.97 -> 49.15 | 0.115 -> 0.115 | 3 -> 3 |
| band5 day | 54.08 -> 54.11 | 0.263 -> 0.263 | 2 -> 2 |

Read honestly: **the weather work moved, and the ground-cover siting did not** —
not on the numbers. The three weather frames are the shadow_opacity fix, and
they break the standing "eleven of twelve day frames carry exactly three hue
families" finding for the first time.

The day frames moved by hundredths. Cover did visibly relocate onto the route
(compare the band-3 day frame's near field between `shots/ground_baseline` and
`shots/ground_r1`: a tuft now reads clearly at bottom right where there was
bare path), but a handful of tufts per frame cannot shift a whole-frame
statistic. Siting was necessary and is not sufficient.

Band 1 is unchanged by construction and should not be read as a null result:
its viewpoint at (8, 90) sits inside the +-256m origin square, which
`_place_corridor_fill` skips outright.

## The path is 6m wide. The bald strip around it is 20m

Measured from the configs rather than judged by eye:

- `paths.width` 3.0 plus `paths.shoulder` 1.5 each side = **6.0m of painted
  dirt**, which is inside Palworld's own 3-4m footpath range at the low end and
  reasonable at the high.
- `grass.path_standoff.max` **7.0m**, drygrass 8.0, flowers 5.0. So vegetation
  is culled to a half-width of up to 10-11m, and the ground that reads as
  "path" is up to **20-22m across**.

So the critique that the path is *"10-20 m wide, ten trainer-heights... not a
footpath"* is exactly right, and the cause is not the path. **Up to 14m of it
is grass-free ground beside a correctly-sized path.** OF12 introduced the
0.3-7.0m noise range to stop a ruler-straight verge, and the noise is the right
idea; the ceiling is what makes the meadow stand back a full trainer-height and
a half from a footpath. This is the largest remaining near-field lever and it
costs no instances.

## Round 1 blind verdict

Independent Fable critic, blind, given only the sheet, the frames, the
references and the rubric, told nothing about what changed.

**A (keyart): no. B (Palworld): no.**

Ranked gaps, in the critic's own order:

1. **"The ground plane is a bare texture; the references' ground is a
   volume."** *"In `ground-04-band4-ironwood-day` and `water-02-river-grazing`
   the ground is a single flat olive texture with a countable number of sprout
   sprites — at grazing angle it dissolves into smear. This one gap accounts
   for more of the visual distance than everything else combined."*
   **Fourth independent critic to rank this first.**
2. **"Nothing lives here."** No creatures in any of the 24 frames, and no
   clutter of use — *"a house on a bald hill, no route to its door, no animal,
   no bird, no drying rack."*
3. **"The sky and the light do not perform."** Zero clouds in 24 frames, a
   golden hour that turns grey, a night that turns off.

Also named, in this lane: five bands share one olive-brown ground at ~35%
value; the three water bodies read turquoise / navy-steel / milky pale-blue;
rain leaves the world dry with no wetness or specular change; steep faces carry
stretched heightmap texturing with no cliff material; groundcover is *"evenly
sprinkled... reads generator, not gardener"*.

**The weather fix moved but did not land.** The critic still reads cloudy, fog
and rain as keeping *"the same hard canopy shadow masses"*. `shadow_opacity`
0.45/0.28/0.40 was too timid — a 0.45 shadow is still a shadow. Pushed to
0.25/0.15/0.22 in round 2.

### One correction to the critique, because it changes what is blocked

The critic lists under *needs art that is not in the build*: *"A grass/flower
groundcover asset set — blades, flower clumps, scrub — nothing in any frame
suggests one exists."*

**That is wrong, and it is the most important thing to get right here.** The
set exists and is already wired: four grass models, two dry-grass models, six
flower and clover models, five bushes and five deadfall pieces, all in
`assets/environment/stylized_nature/` and all referenced by `vegetation.json`.
The critic could not see them because there were five to ten instances in
frame, and because the bottom third of every grass blade was rendering black.

So this gap is **scene-fixable, not blocked** — which is the opposite of the
conclusion the critique would otherwise support. Recorded because a
`BLOCKED.md` entry raised on that sentence would have been wrong and expensive.

## Round 2 changes

All aimed at the critic's own number one, plus the confirmed black-blade bug.

- **`colour_jitter` removed from grass and drygrass**, replaced by
  `variant_retint` (four greens, two straws). This is the black-blade fix —
  see the root cause above. Verified by probe that the imported material's own
  `vertex_color_use_as_albedo` is false, so removing the jitter lets it stay
  false; and that `cull_mode` is 2 (CULL_DISABLED), so culling was never the
  problem.
- **`corridor_fill.density_scale` 1.0 -> 3.0 (grass) and 2.5 (drygrass).** This
  is a per-layer multiplier applied to layers that are now trail-sited, which
  is a different trade from the chapter-wide band-table bump that returned ~4%:
  it multiplies where the candidates actually land. Round 1's honest result —
  weather moved, day frames moved by hundredths — is what justifies it.
- **`path_standoff.max` 7.0 -> 3.0 (grass), 8.0 -> 3.5 (drygrass), 5.0 -> 2.5
  (flowers).** Reclaims up to 14m of bald ground per trail metre. OF12's noise
  range is kept; only the ceiling comes down.
- **`clump_radius` 10.0 -> 6.5 (grass), 12.0 -> 7.5 (drygrass).** Zero added
  instances; ~2.4x local density; aimed at "evenly sprinkled... reads
  generator, not gardener".
- **`shadow_opacity` 0.45/0.28/0.40 -> 0.25/0.15/0.22.**

Bake: **217,599 -> 405,101 placements.** This is the round that spends
instances, and it does so deliberately and only on the two carpet layers, after
a round that proved siting alone was not enough. Offline bake cost 90s -> 169s;
run time loads the bake rather than recomputing it, so this is disk, not boot
CPU. Worth a look on the Ally before it goes further: grass `lod_range` is 55m,
so draw cost is bounded by what is near the camera, but 405k instances is the
largest this scatter has been.

## The empty world is not a camera problem — for another lane

The round-1 critic ranked *"nothing lives here"* second overall and said
plainly that the frames could not distinguish two causes: *"if the world is
empty because there is nothing to spawn rather than nowhere to point the
camera... the survey should [tell me]."*

Answered, by reading rather than by shooting again: **there is no ambient
overworld wildlife in the corridor.** `EncounterDirector` is present in
`scenes/world/meadows_playground.tscn`, but the only caller of its
`spawn_wild()` anywhere in `scripts/` is `burrow_warrens.gd` — the dungeon.
Nothing populates the open field, so a capture that stands the player on the
trail at five viewpoints has nothing to photograph however long it waits, and
the ground capture does carry the player to every seat precisely so that
player-driven spawning would work if it existed.

So this is not a defect in this lane's harness and it is not tunable from any
file this lane owns. It is a content/systems gap: against `palworld-01`,
`-02` and `-03`, which all carry creatures in the midground, and against the
project's own key art, which puts a creature beside the trainer. Recorded here
for the coordinator rather than acted on.
