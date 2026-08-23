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

## A measurement trap that would have declared convergence falsely

`frame_stats.py`'s `nearL` is `luma[int(h * 0.85):, :].mean()` — the bottom
**15%** of the frame, and nothing else.

In this survey the camera stands ON the path, 2.0m up, aimed at a point 4.5m
ahead at ground level. So the bottom 15% of every ground frame is the worn dirt
directly under the player — ground the `path_factor` gate deliberately keeps
clear. **`nearL` is measuring the path.** It cannot move when groundcover
beside the path changes, and it did not: it is identical to three decimal
places across all three rounds on almost every frame (band1-day 0.280,
band3-day 0.262, band4-day 0.115) while the frames visibly changed and the
placement count went from 143,630 to 405,101.

This matters beyond bookkeeping. `ralph/conventions.md`'s stopping rule is two
consecutive rounds that name no new defect **and move no measured axis**, and
it names near-field luminance as one of those axes. On this survey's own
framing that axis is structurally incapable of moving, so a round that changed
the near field a great deal would still read as flat and the pass would stop
early on a false signal. Recorded so it does not.

`tools/_cover_stats.py` is the supplementary measure this lane used instead:
the share of pixels in rows 50-90% — the mid-to-near ground either side of the
path, where the cover actually sits — that fall in the green-yellow band above
a saturation floor. It is a proxy, not a segmentation, and only round-over-round
deltas on identical viewpoints mean anything.

| day frame | baseline | round 1 | round 2 |
|---|---|---|---|
| band1 opening | 7.022% | 7.022% | 7.003% |
| band2 stone-root | 3.113% | 3.112% | 3.280% |
| band3 crossing | 4.927% | 5.028% | 4.927% |
| band4 ironwood | 3.274% | 3.201% | 3.500% |
| band5 approach | 0.658% | 0.668% | **2.391%** |
| **mean** | 3.799% | 3.806% | **4.220%** |

Round 1: +0.2%, i.e. nothing. Round 2: +10.9% mean, with band 5 more than
tripling off the lowest base in the set. Band 1 is unchanged by construction
(inside the origin square). Band 3 did not move at all.

**+11% of visible cover for +86% of placements is a poor return, and it points
at the next lever rather than at more density.** Grass renders at `scale_min`
0.14 to `scale_max` 0.42 on meshes measuring 1.33-1.87m tall, so a tuft is
0.26-0.79m — ankle to knee against the 1.80m trainer. That is realistic, and it
is also why adding instances at distance buys so few pixels: past ~15m a 0.5m
tuft is a few pixels tall, and past `lod_range` 55m it is not drawn at all.

The build already demonstrates the alternative. `water.json`'s `river.reeds`
uses **the same two Grass_Wispy meshes** as the drygrass layer at `scale_min`
0.6 / `scale_max` 1.4 — 1.00-2.34m, knee to overhead — in tight 3.4m clumps.
That is the single biggest reason the river bank reads as a surface with
vegetation on it while the walk bands read as a texture. Same art, 4-5x the
scale.

So the round-3 lever is grass SIZE, not more grass. It costs no instances and
is checkable against the rubric's own scale criterion.

## Round 2 blind verdict

Fresh independent Fable critic, blind, told nothing about what changed. **A: no.
B: no.** Round 2 named several defects round 1 had not, so this is not
convergence by `ralph/conventions.md`'s rule.

Asked explicitly to COUNT distinct groundcover clumps in the lower half of each
day frame — because "sparse" and "empty" lead to different work — the answer
was:

| day frame | clumps in lower half |
|---|---|
| band1 opening | **0** ("pure dirt texture around the player") |
| band2 stone-root | 2 |
| band3 crossing | **0** on the hill around and ahead of the player |
| band4 ironwood | **1** |
| band5 approach | 12-15, "each isolated with a body-length of bare dirt between" |
| water-02-river-grazing | **0** — "not one blade of geometry" |

> *"The near field is empty, not sparse; the mid-field is sparse."*

And the decisive framing: *"Because the camera sits behind the player, the
lower half of every gameplay frame is this near field — so this one gap
dominates every second of play."*

### A regression this lane introduced, caught blind

> *"The neon-lime cutout tufts are 2-3 stops brighter and greener than the
> terrain they sit on, so they read as stickers, not growth."*

That is round 2's `variant_retint`, and the critic is literally right.
Measured: the four tints ran value 0.525-0.706 while
`terrain_playground.json`'s own R9.4 comment records the ground grass
**rendering** at value 0.199 — so the tufts were 2.6x to 3.5x the brightness
of the surface they grow out of. Fixed in round 3 by scaling them to ~0.29-0.39:
still lighter than the ground, because a blade catching light should be, but
no longer a different material pasted on top of it.

Worth recording as a process point: the colour_jitter removal was correct and
necessary, but choosing replacement tints by eye against a swatch rather than
against the ground's own *rendered* value reintroduced a visible defect in the
same change that fixed one. The ground's rendered value was already written
down in the file being edited.

### A hypothesis this round killed

Before the verdict, this lane's own measurement pointed at grass SIZE as the
next lever: `river.reeds` uses the same meshes at scale 0.6-1.4 against the
walk bands' 0.13-0.42, and pixel coverage per instance falls off hard with
distance. The critic answers it directly and negatively: *"Grass tufts are
knee-to-waist height — at the tall end for meadow grass but defensible as
stylisation."*

So grass is already at the tall end and raising it would have bought a new
scale defect. **Not done.** Recorded because the reasoning was sound and the
conclusion was still wrong — which is exactly what the blind pass is for.

### Round 3 changes

- **Tuft tints scaled down** to sit near the ground's rendered value (above).
- **Strays cut, per_clump raised** — grass 900 -> 300 strays and 130 -> 190 per
  clump, drygrass 380 -> 140 and 90 -> 130. Strays are the layer's uniform
  singles and they are precisely what the critic keeps describing ("every grass
  tuft stands alone at roughly even intervals", "scatter is one-by-one, not in
  drifts"). Same trade R7.1-remainder already made once for the origin square.
- **Verge raised and narrowed** — grass 6000 -> 30000 with `band` 18 -> 12,
  drygrass 1800 -> 9000, flowers 900 -> 4000. 6000 by arc length over ~12km is
  one instance per 2m across a 36 m2 strip, which is a rumour of a verge. The
  narrowing is deliberate: the same instances concentrated at the worn edge read
  as growth crowding it, spread over 18m they read as more sprinkle further out.
  `path_standoff` still culls per side with noise, which is what keeps a dense
  narrow fringe from becoming the planted border OF12 removed.
- Round 3 also carries the night and golden-hour lighting changes, which were
  committed after round 2's world had already booted and so appear in frames
  for the first time here.

**Placement trajectory, stated plainly because it is now the thing to watch:**
143,630 -> 223,889 -> 405,101 -> **532,886**. That is 3.7x the count this
chapter started the sweep with, and the last two rounds are this lane's. Draw
cost is bounded per frame by `lod_range` 55m and regional batch culling rather
than by the total, and the bake is loaded from disk rather than recomputed
(boot `placements` went 2.0s -> 4.6s across the 217k -> 405k step), but 533k
instances has not been measured on the Ally and should be before this goes
further. If a performance lane needs the number back, the honest order to give
it up in is: verge count first (it is the most recent and the most
concentrated), then `corridor_fill.density_scale`, and NOT the siting or the
clustering, which cost nothing and are what make the rest read.

## Why four rounds of density have not filled "the empty near field"

The single most useful thing found in this pass, and it is geometry, not art.

The ground camera sits 2.0m up, 2.2m behind the player, aimed at a point 4.5m
ahead at ground level, FOV 70. So the horizontal span of the frame at a given
distance ahead is `2 * d * tan(35deg)`:

| distance ahead | frame spans | painted path (6.0m) as % of frame width |
|---|---|---|
| 3m | 4.2m | **143%** |
| 5m | 7.0m | **86%** |
| 8m | 11.2m | 54% |
| 12m | 16.8m | 36% |
| 20m | 28.0m | 21% |

**The bottom third of every ground frame is the path, by construction.** At 3m
ahead the path is wider than the frame. No quantity of groundcover placed
*beside* the path can ever appear there, which is why a blind critic counting
clumps in the lower half returns 0 and 1 while the placement count goes
143,630 -> 532,886 and the mid-field visibly fills in.

This reframes the standing #1 finding. "The near field is empty" is true, and
three of the four things that would fix it are not density:

1. **The painted path is 6.0m wide** — `paths.width` 3.0 plus `paths.shoulder`
   1.5 on each side. The width is right; the shoulder doubles it. Against
   Palworld's 3-4m footpath and the 1.80m trainer, 6.0m is already over the
   bar before any vegetation standoff is added. Narrowing `shoulder` is the
   most direct fix and it is in this lane's file — but it is consumed by the
   TERRAIN bake (`build_playground_terrain.gd` writes `data/terrain/`, which
   this lane does not own and other lanes read), so it is a cross-lane change,
   not a scatter change. Flagged, not made.
2. **Cover has to encroach ONTO the worn dirt**, not merely up to it. That is
   the owner's own framing — "Palworld wears its paths THROUGH cover" — and it
   is reachable from this lane: `path_standoff.min`/`max` and
   `path_edge_jitter` together decide how often a tuft survives inside the worn
   zone. Round 2 took the standoff ceiling 7.0 -> 3.0; the remaining move is
   letting the floor reach 0 and raising the jitter so tufts genuinely stand in
   the dirt line rather than stopping politely at its edge.
3. **The capture framing itself is worth questioning.** This tool aims at a
   point 4.5m ahead precisely because that is "the half of frame a walking
   player actually looks at" — which is right, and is why the survey is
   valuable. But a survey whose lower third is definitionally path will keep
   returning "the near field is empty" no matter what grows in the meadow, and
   three critics have now spent their top finding on it. A second ground
   viewpoint per band, standing a few metres OFF the trail, would let the same
   rubric distinguish "the meadow is bald" from "the path is wide". Not changed
   mid-pass — changing the camera between rounds would invalidate every
   before/after in this report — but it is the first thing the next pass should
   do.

## A second measurement caveat, against this lane's own tool

`tools/_cover_stats.py` keys on saturated green above a value floor. Round 3
deliberately DARKENED the tuft tints to fix the sticker defect, so the same
tufts now score lower on that metric while looking better. Band 1 reads
7.003% -> 6.886% across a change that visibly added cover.

That is the same class of flaw this report criticises in `nearL`, in this
lane's own instrument, and it is recorded rather than tuned away: adjusting the
threshold until the number flatters the change would be exactly the wrong move.
The robust measure for the near field is the blind critic's literal clump
count, which does not care what colour the tufts are, and that is what the
round-3 critique is being asked for again.

## Round 3, measured

`frame_stats.py`, round 2 against round 3: **11 of 24 frames moved.** The
lighting work is where it landed, and it is not marginal.

| frame | chroma r2 -> r3 | saturation r2 -> r3 |
|---|---|---|
| band1 night | 18.47 -> **32.39** | 0.49 -> 0.65 |
| band2 night | 8.48 -> **11.54** | 0.37 -> 0.39 |
| band3 night | 15.47 -> **34.44** | 0.41 -> 0.44 |
| band4 night | 12.09 -> **44.63** | 0.25 -> 0.41 |
| band5 night | 13.90 -> 13.53 | 0.46 -> 0.53 |
| band1 golden | 95.38 -> 93.93 | 0.52 -> **0.67** |
| band2 golden | 80.01 -> 80.29 | 0.66 -> **0.71** |
| band3 golden | 93.56 -> 92.06 | 0.49 -> **0.62** |
| band5 golden | 93.39 -> 94.08 | 0.60 -> **0.75** |

Every night frame's dominant hue family also flipped from chartreuse/orange to
blue. Band 1 night reads blue 90% of chromatic pixels, against a previous
chartreuse 73% — the numeric form of "night is now a blue night rather than a
black void with unlit green tufts glowing in it".

Day frames are essentially unchanged, as in every round.

### The cover metric fell, and it was this lane's own instrument lying

`tools/_cover_stats.py` reported the opposite of progress: mean 4.220% ->
3.749%, with band 5 collapsing 2.391% -> 0.691%, back to its baseline.

That is the confound this report predicted one section earlier. The metric
requires `value > 0.22`, and round 3 deliberately DARKENED the tuft tints from
value 0.53-0.71 to 0.29-0.39 to fix the sticker defect. Re-running the
identical measure with the value floor at 0.10 — testing the confound, not
replacing the metric — separates the two cleanly:

| day frame | r2 | r3 |
|---|---|---|
| band1 | 19.931% | 19.852% |
| band2 | 38.895% | 39.003% |
| band3 | 23.264% | 21.645% |
| band4 | 43.748% | 43.632% |
| band5 | 22.324% | **22.979%** |

Flat or up on four of five, band 5 included. **The cover did not go away; it
got darker.** Only band 3 is genuinely down, by ~7%, which is the most likely
real cost of cutting strays 900 -> 300 at the band with the thinnest density
scale.

Both numbers are recorded, and the strict-floor figure is NOT being quietly
replaced by the flattering one. The point of keeping both is that neither is
trustworthy alone across a change that moved colour: the robust near-field
measure remains the blind critic's literal clump count.

## ROOT CAUSE: the day-lit character is an emissive material, not a lighting bug

**This is the most valuable finding in the pass and it is not in this lane's
files.** Four independent blind critics across three sweeps have reported the
same thing in almost the same words — *"the trainer renders at near-daylight
brightness against pitch black"*, *"pasted onto black paper"*, *"lit by a
different rig than the world"*, *"reads as composited in"* — and every attempt
to fix it has been a lighting change, because everyone reasonably assumed it
was a lighting problem. It is not.

**Every one of the six production humanoid rigs has `emissiveFactor = [1,1,1]`
with an emissive texture that is its own diffuse map.**

Probed on the imported material:

```
'Material_1' shading=1(per_pixel) emission_on=true emission=(1,1,1,1) energy=1.00
```

And in the source `.glb`, for all six:

| rig | emissiveFactor |
|---|---|
| trainer_lod0.glb | [1, 1, 1] |
| grandpa_lod0.glb | [1, 1, 1] |
| grunt_lod0.glb | [1, 1, 1] |
| warden_lod0.glb | [1, 1, 1] |
| villager_male_lod0.glb | [1, 1, 1] x2 |
| villager_female_lod0.glb | [1, 1, 1] x2 |

The trainer's `emissiveTexture` is index 0 and its `baseColorTexture` is index
1 — *different texture entries pointing at the same image*. Decoded and
measured, both resolve to `texture_0`, 2048x2048, mean 0.2891, max 0.796, 99.5%
of texels above 0.05. It is the full diffuse map, not a small glow mask.

**Emission is not affected by scene lighting.** It is added after the lighting
term, so no ambient value, no exposure, no time-of-day preset and no
adjustment_saturation can dim it. That is the whole explanation for a defect
three sweeps have circled:

- It is why the character stays bright while the world goes dark, at night and
  at golden hour.
- It is why this lane's night rework — which measurably moved every night
  frame's chroma (band 4: 12.09 -> 44.63) and flipped the palette to blue —
  made the WORLD read as night while a fresh critic still said the character
  looked day-lit. Both observations are correct and they are not in conflict.
- It is almost certainly why the grunt's armband reads as *"a flat pure-red
  untextured quad that ignores lighting"* in day and *"salmon-pink"* at golden:
  an emissive surface does not shade, it only shifts with the tonemap.

Almost certainly an export/import artefact — many exporters write
`emissiveFactor` [1,1,1] alongside an emissive texture slot, and the whole cast
shares it, which is the signature of a pipeline setting rather than an art
decision.

**The fix is one of two things, neither in this lane:** strip `emissiveFactor`
from the six character `.glb` files, or set `emission_enabled = false` when
character materials are built in code. `tools/_char_probe.gd` is left in the
repo as the check — it prints shading mode, emission and albedo per surface for
any rig, so the fix can be verified rather than assumed.

Flagged for the coordinator as the root cause of the standing NIGHT-LIGHT
backlog item. **Nothing this lane can do to `art.json` will fix it**, and any
future round that tries to solve it with ambient or exposure is chasing a
lighting explanation for a material property.

## `shadow_opacity` is honoured under Compatibility — verified, with a caveat

Round 3's critic still reported *"the same crisp sun shadows"* under cloudy,
fog and rain, which is a direct challenge to this lane's weather fix. Tested
rather than argued, with `tools/_so_probe.gd`: a bare scene — one plane, one
box, one DirectionalLight, no project content — rendered twice under
`--rendering-driver opengl3`, differing only in `shadow_opacity` 1.0 vs 0.0.

Result: **max per-pixel difference 163, 3,399 pixels changed.** The property
reaches this renderer. The fix is real and the commit that claimed it was
correct.

**But the critic is also right, and the distinction matters.** `shadow_opacity`
changes how DARK a shadow is; it does nothing to how SHARP its edge is. Edge
softening on this tier needs `shadow_blur` or `light_angular_distance`, and
both are the documented no-ops. So an overcast frame currently has a *fainter*
razor-edged shadow, which is a quieter version of the same contradiction rather
than a resolution of it.

Since crispness cannot be bought at this tier, the honest remaining lever is to
take the darkness far enough down that the edge stops carrying information.
Round 4 takes cloudy/fog/rain to 0.08/0.05/0.07 from 0.25/0.15/0.22. This is
still not `shadow_enabled: false`, which R5.2 proved blanks Terrain3D.

## Vegetation is NOT emissive — checked, so the glow is this lane's to fix

The round-3 critic read the agave in `water-03-stream-grazing` as *"lit like an
item pickup"* and the white flower sprites in the pond frames as *"full-bright,
floating confetti"*. Given what the character rigs turned out to be, that
warranted the same check: **all 46 `.gltf` files in
`assets/environment/stylized_nature/` carry zero emission.**

So the glow is albedo, not emission, and it is this lane's. `flowers` is the
one ground-cover layer still carrying no `retint` at all, which means
`albedo_color` stays pure white and the layer renders its source textures
unmodified at full brightness while grass and drygrass are now tinted down
toward the terrain. Fixed in round 4.
