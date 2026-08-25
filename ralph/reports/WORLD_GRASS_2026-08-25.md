# WORLD-GRASS — the Meadows ground plane, measured

`branch: ralph/WORLD-GRASS` · `contract: docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md`
· `cut from origin/main at 636673ce` · `2026-08-25`

Owner-directed, blocker class QUALITY BLOCKER. The owner's words were *"the
grass feels most important to me."*

Everything below was measured on this branch with `tools/_probe_grass_census.gd`
and `tools/perf_profile.gd`, both of which run against the committed bake. No
number here is a frame rate and none of them come from an ROG Ally.

## The short version

The prompt's priority order was followed and items 1-4 shipped. What the prompt
says is *wrong* about the cause, and correcting it is most of why this lane
reached anything: the grass was never a few centimetres tall. It was isolated.

Three levers did the work, and two of them cost nothing in the placement budget.

| lever | before | after | placements |
|---|---|---|---|
| `grass.scale_min`/`scale_max` | 0.14 / 0.42 | 0.32 / 0.58 | none |
| `grass.model_scale` (new) | did not exist | 4 height classes, 0.35-1.28 m | none |
| `grass.lod_range` / fade | 55 / 12 | 120 / 55 | none |
| `grass.verge.count` | 14,000 | 30,000 | +16,000 |
| `grass.clumps` | 110 | 150 | layer x1.38 |
| `groundmat` layer (new) | did not exist | 145,577 | +145,577 |
| `flowers` drift shape | r9.0 / 78 / 620 strays | r6.0 / 120 / 320 | +18,481 |

Committed bake **466,922 -> 725,949** against `test_scatter_perf_budget.gd`'s
**900,000** ceiling: 19% headroom left, and the cap was not touched.

## What prompt 72 gets wrong, and why it matters

Prompt 72's table says `scale_min`/`scale_max` of 0.14/0.42 means "blades a few
centimetres tall", and names that as the root cause. The coordination record
re-verified the *numbers* against `636673ce` and found them unchanged, which is
true, and then inherited the *interpretation*, which is not.

Measured off the four source meshes' own glTF `POSITION` accessors:

| model | raw height | at 0.14 | at 0.42 |
|---|---|---|---|
| `Grass_Wide_Short` | 1.20 m | 0.17 m | 0.50 m |
| `Grass_Common_Short` | 1.31 m | 0.18 m | 0.55 m |
| `Grass_Wide_Tall` | 1.52 m | 0.21 m | 0.64 m |
| `Grass_Common_Tall` | 1.84 m | 0.26 m | 0.77 m |

Mean tuft height on `main` was **0.41 m** — shin height on the 1.80 m trainer
who is standing in every one of these frames as the ruler. The layer's own
`_comment_scale` says so plainly ("the source tufts are 1.3-1.9m... trimmed to
roughly knee height"), and `R9.4` cut the range to this value *deliberately*
after a blind critic measured the previous 0.34-1.0 range at ~1.2 m and called
it "pampas, not meadow grass".

What the frames actually show is isolated grass. `tools/_probe_grass_census.gd`
on `main`'s bake:

| eye | grass within 20 m | per m2 |
|---|---|---|
| band1 open meadow | 24 | **0.019** |
| band1 mounted | 29 | **0.023** |
| band4 high pasture | 135 | 0.107 |
| band3 crossing | 324 | 0.258 |
| band2 forest floor | 439 | 0.349 |

One tuft per 40-50 square metres at the game's opening, and at the mounted eye —
the exact framing the owner's own reference frame is of.

**So the coordinator's resolution was right for a reason it did not state.** It
said to lead with blade scale and LOD range rather than instance count. That is
correct, but not because the grass is short: it is correct because scale is the
only ground-coverage lever that costs zero placements. Scale is uniform
(`scatter_rules.gd::_consider` draws one `randf_range` and applies it to all
three axes), so a mean of 0.42 against 0.28 covers **2.25x** the ground with
exactly the same instance count. Nothing in the placement budget can buy that.

## The ceiling, stated once so the next lane does not re-derive it

`GROUND-LAYERS` concluded that ground appearance is a material problem and that
scatter was the wrong instrument. Its arithmetic was right and this lane's
frames agree with it. Written out:

- A tuft at this lane's mean scale has a footprint of roughly 0.65 m across,
  about 0.33 m2 of ground covered.
- Apparent coverage is therefore about `density x 0.33`. To read as the
  reference's continuous carpet — call it 50% apparent coverage — needs on the
  order of **1.5 instances per m2**.
- The corridor is 2048 x 8192 m = **16.8 km2**. A uniform carpet is 25 million
  placements. Even carpeting only a 60 m ribbon along the 12 km route network is
  ~1.08 million.
- The ceiling is 900,000 for the **whole chapter, all eleven layers**.

**A continuous grass carpet is roughly 40x outside the placement budget however
it is spent.** That is not a tuning failure and no density number reaches it.
Reaching the reference's ground would need a different instrument — Terrain3D's
own per-`Terrain3DMeshAsset` `density` field, which `vegetation.gd` registers
assets through but has never set, or a grass shader on the terrain material
itself. Both are `vegetation.gd`/terrain work and outside this lane's files.

What *is* reachable, and what this lane delivered, is ground that reads as
grassland with real growth on it at legible scale, in three tiers, out to the
treeline — rather than a painted surface with confetti on it.

## What changed, and why each

### 1. Blade scale, and a per-model multiplier that did not exist

`scale_min`/`scale_max` 0.14-0.42 -> **0.32-0.58** (0.26 after round 1; the
floor rose again in round 3). Mean tuft height 0.41 m -> **0.71 m**, knee to
mid-thigh on the 1.80 m trainer.

Round 3 raised the FLOOR rather than the ceiling, deliberately. A second blind
pass, shown the round-2 frames and told nothing, still returned *"the grass is
too short to be a meadow -- mid-shin to knee on the trainer"*. The layer's mean
was already 0.62 m, but what the eye reads is not the mean, it is the commonest
class, and three of the four species topped out below 0.7 m. Raising `scale_max`
again would have walked the tall class back toward the ~1.2 m `R9.4` rejected as
pampas; raising the floor lifts the classes that actually carpet.

`scatter_rules.gd` gained **`model_scale`**: an optional per-layer map from model
path to a multiplier, applied to the drawn scale. It exists because the layer's
shared range applies to every species equally, so a 1.20 m mesh and a 1.84 m mesh
could only ever differ by the 53% their raw meshes differ by — and a blind critic
looking at four species reported *one*: "a single blade-fan type, always roughly
knee height". `vegetation.json`'s own `_comment_species_of12_b` names the same
gap from the other side ("scatter_rules.gd has no per-model weight/scale field")
while adding a second species it could not differentiate.

Grass now places four real height classes: Wide_Short 0.35-0.64 m, Common_Short
0.40-0.72 m, Wide_Tall 0.56-1.02 m, Common_Tall 0.71-1.28 m.

**It is RNG-safe by construction**, which is why the model and yaw draws moved
above the multiplier rather than the multiplier being folded into the range:
both draws still happen, in the same order, drawing the same values from the same
stream, and the multiplier is applied to the result. A layer with no
`model_scale` key places byte-identically to before the change. That matters
more here than usual — a stream perturbation reshuffles every clump in the
corridor and invalidates every tuned anchor in the file.

Confirmed by the bake: grass placements are **344,867 before and after adding
`model_scale`**, with the scale span moving 0.26-0.58 -> 0.208-0.696.

### 2. LOD range — the bald ring

`grass.lod_range` 55 -> **120**, fade 12 -> **55**. `drygrass` 55 -> 110/30,
`flowers` 45 -> 90/24.

`vegetation.gd::_make_mesh_asset` wires this to `Terrain3DMeshAsset.lod0_range`,
which becomes a real `RenderingServer` visibility range — a hard cutoff, not an
LOD swap. At 55 m the ground stopped carrying growth about a third of the way to
the treeline in every band-2 and band-4 frame, and the 12 m fade band was too
narrow to disguise it.

The three ground layers moved **together** on purpose. Ending at 45/55/55 draws
three concentric bald rings at three radii; only the outermost was ever named as
a defect, but all three were there.

Round 3 widened the fade band 35 -> 55 without touching the range, because the
round-2 blind pass still named the cull *"a hard line, not a fade"*. The ramp
now starts at 65 m instead of 85 m, so instances thin over 55 metres instead of
35. It is the one adjustment in this lane that makes the GPU picture slightly
BETTER rather than worse: more of the drawn grass is inside the fade, and none
of it is further away.

Zero placements. This is the single cheapest lever in the lane and the first one
to give back — see the GPU section.

### 3. The verge, and the one density raise

`grass.verge.count` 14,000 -> **30,000**, back to `VIS-WORLD` round 3's number.
This **deliberately reverses `GROUND-LAYERS`**, and the reason is in its own
words: it cut the verge because no verge count could fill a bare near field
"because the lower third of the survey frame is the 6.0m painted path itself".
That is true of that framing. This lane shot a second, lower camera aimed 9 m
ahead of the player (`-near` frames) precisely so ground cover stops being judged
from a frame whose lower third is road.

The verge is the most instance-efficient lever the layer has: every draw lands
within 13.5 m of an authored route, against `corridor_fill`'s draws spread over
16.8 km2. `GROUND-LAYERS`' negative-space intent is kept where it belongs — open
ground away from the route is untouched by this key.

`grass.clumps` 110 -> **150** is the only layer-wide density raise, and it is
made at `clumps` rather than at `corridor_fill.density_scale` because
`_place_corridor_fill` **drops every candidate whose centre lands inside the
+-256 m origin square**, and the two worst-measured eyes are both inside it. No
corridor-only knob can reach the game's opening. `corridor_fill.density_scale`
is untouched at 1.4.

### 4. `groundmat` — the tier between the ground and the tufts

New layer: `Clover_1`, `Clover_2`, `Plant_1_Big`, separated by `model_scale` into
a low leafy mat (0.27-0.58 m) and a broadleaf above it (0.40-0.76 m). 145,577
placements, clumped hard, trail-sited, `lod_range` 70.

This answers the defect a blind critic ranked second: *"each grass tuft meets
the ground at a razor line with no skirt, no thinning, no smaller filler
geometry — props stabbed into dirt"*, and it answers prompt 72's item 3.

**No asset entered the repository.** `Clover_1`/`Clover_2` were already vendored
and already placed — in the `flowers` layer, at flower scale, which put a clover
clump at 3-11 cm, under the terrain's own texture frequency and therefore
invisible. `Plant_1_Big` was vendored and referenced by nothing at all.

Two constraints shaped it and both are recorded in the config:

- **A mesh may only belong to one layer.** `vegetation.gd::_layer_for` resolves a
  model to the *first* layer whose `models` list holds it and `_build_batch`
  groups by model, so a mesh in two layers silently renders both layers'
  placements with one layer's retint, LOD, shadow and collision. So Clover had to
  *leave* `flowers` to arrive here, and `Plant_7`/`Plant_7_Big` — the obvious
  0.25 m mat candidates — could not be used at all, because they belong to
  `bushes` and Band 2's authored understorey anchors depend on them there.
- **A new layer must be appended, never inserted.** `all_placements` seeds each
  layer as `base_seed + INDEX * 7919`. Written first between `flowers` and
  `rocks`, this layer moved `rocks` 5,697 -> 5,669 and `path_stones` 9,243 ->
  9,420 for no edit of their own — the same silent reshuffle `STRONGHOLD-R2`
  chased when the road cairn started placing 0 of 3 on some seeds. Appending it
  restored both exactly.

### 5. Flower drifts

`clump_radius` 9.0 -> 6.0, `per_clump` 78 -> 120, `strays` 620 -> 320. Density
inside a drift 0.31 -> 1.06 per m2. Prompt 72's item 4, and the same
clustering-over-count trade `R7.1-remainder` and `VIS-WORLD` both made for grass.

### 6. Not done: prompt 72's item 5, a mid-distance landmark

Left undone deliberately. It is terrain authoring (`terrain_playground.json`),
not scatter, and this lane's file ownership does not include it. Recorded as a
remainder in `ralph/BACKLOG.md`.

## Evidence

Frames: `tools/_probe_grass_pass.gd` (new), four route bands plus a mounted
frame, two cameras per site from one seating — an over-the-shoulder eye at 2.4 m
for the middle distance and a 1.2 m eye pitched into the ground 9 m ahead for the
near field, because the ground plane fails in two places and one framing hides
one of them. Three capture sets: `shots/grass_r0` (baseline), `r1`, `r2`.

Blind critics: two rounds, each a sub-agent told nothing about what changed,
running `.claude/skills/visual-judge` against `docs/reference/`.

`tools/frame_stats.py` moved by hundredths across all three rounds and is
recorded here as **not the right instrument** for this change, which is the same
result `VIS-WORLD` measured ("the day frames moved by hundredths"): a
whole-frame statistic cannot see a ground-cover change that occupies the lower
third of the image. The measured axis for this lane is
`tools/_probe_grass_census.gd`'s per-eye density and the bake's own scale span.

## A measurement error in this lane's own harness, and what it cost

Worth recording because it wasted a defect slot in two consecutive blind passes
and would have caused a wrong fix.

The `-near` camera added in round 0 stands the player ON the route and aims down
it at 1.2 m. At that height the bottom of the image is two or three metres
ahead — and a path 7 m wide (`terrain_playground.json` `paths`: width 2.0,
shoulder 2.5 a side, so `path_factor` reaches zero 3.5 m off the centreline)
subtends the entire frame width there. Both critics measured the lower frame's
colour and reported the meadow as rendering in the trail's palette: *"the ground
is sitting on the trail colour, not the grass colour, and about 0.25 too
bright"*, measured at hue 45-46, value 0.79.

That is what the lower frame IS. It says nothing about the meadow. Sampled
off-route in the same world:

| sample | median | hue | sat | value |
|---|---|---|---|---|
| our open meadow, `01-band1-open-meadow-off` lower frame | `#798732` | 68.3 | 0.62 | **0.529** |
| `moong-01` foreground grass | `#7c8737` | 68.4 | 0.59 | **0.529** |
| `moong-02` near/mid ground carpet | `#668533` | 83.3 | 0.61 | 0.522 |
| our worn path, `01-band1-open-meadow-near` lower frame | `#cfbd83` | 45.0 | 0.37 | 0.812 |

The meadow's own ground is within 0.1 of a hue degree and 0.000 of a value of
the reference's own foreground grass. **The grass palette was never the thing
those measurements found**, and retinting it — the obvious response to "the
tufts are much darker than the ground they sit on" — would have been a
regression driven by a mis-sampled crop.

Round 3 therefore added an `-off` frame at every site: the player stood 10 m to
the side of the route, clearing the path's 3.5 m half-width and the grass
layer's 0.3-3.0 m standoff several times over, so ground cover is judged on
ground the player crosses rather than on road. The width of the worn band in a
`-near` frame remains a real composition question — but it is a terrain and path
question, not a scatter one, and it is handed over rather than guessed at here.

## Performance

**CPU.** The OP23-01 win is not spent, and the reason is structural rather than
lucky: every layer this lane touched is `collides: false` and carries no
`harvest_item`, so none of them registers an interaction provider or a collision
shape.

| world total | before | after |
|---|---|---|
| scatter instances | 465,752 | 724,769 |
| **solid placements** (collision streaming's `n`) | **51,511** | **51,511** |
| **harvest points** (the arbiter's provider population) | **56,430** | **56,430** |
| scatter batches (one `add_transforms` per model) | 41 | 43 |
| boot to settled | 60.7 s | 64.2 s (+5.8%) |

**GPU: not measurable here, and stated as risk.** `PERF-ROG-GPU` records why —
the Compatibility renderer counts MultiMesh batches, not instances, and this box
rasterises in software. The ROG Ally is the target and this lane cannot see it.
The honest statement of the risk:

- Instances drawn per frame rise on two axes at once: **+56% total placements**,
  and grass's own visibility range going 55 -> 120 m, which is roughly
  **(120/55)^2 ~ 4.8x** the grass instances inside the draw radius. Grass is 48%
  of the bake.
- Batch count barely moved (41 -> 43), so this is an instance-count question and
  not a draw-call one.

**The two cheapest things to give back, in order, if the owner's next handheld
pass hitches**, both named in `vegetation.json` at the keys themselves:

1. `grass.lod_range` back toward 80-90. Costs **no re-bake** — it is a
   render-side number — and reclaims most of the GPU rise on its own.
2. The whole `groundmat` layer. It is the smallest geometry in the world and the
   least missed at distance, and dropping it returns 145,577 placements.

## Tests

`test_veg_corridor`, `test_scatter_rules`, `test_scatter_perf_budget`,
`test_band_vegetation`, `test_scatter_fingerprint_covers_bands`, plus the full
suite because `scripts/world/scatter_rules.gd` changed.
