# Handover — T1-GROUND-3, 2026-08-30

Branch `ralph/T1-GROUND-3`, off `origin/main` at `28265a3a`. Pushed. This is
the third ground lane in a row; the two before it are
`handover-T1-GROUND-2026-08-30.md` and `handover-T1-GROUND-2-2026-08-30.md`,
and reading both is the fastest way to understand what is left.

**The brief I was given was one lane stale, and that matters for anyone
reading it.** It listed six items from T1-GROUND's undone list. Three of them
had already been done by T1-GROUND-2, which landed on `main` after
T1-GROUND's handover was written and which the brief does not mention:

| Brief item | Actual state on `main` at `28265a3a` |
| --- | --- |
| 4. Aerial perspective as a terrain-material distance gradient, explicitly not fog | **Already shipped** by T1-GROUND-2 — `shaders/terrain_ground.gdshader` plus five `aerial_fade_*` uniforms in `terrain_playground.json`. Verified present, not redone. |
| 5. Re-verify the pebble slope fix | **Already verified** by T1-GROUND-2 at band 1 (`path-pebbles-crop-AFTER.png`). Band 4 was never checked; I did that. |
| 3a. Wire stream reeds/bank_scrub | **Already shipped** by T1-GROUND-2 — `water.gd::_build_stream_reeds` and `water.json`'s `stream.reeds`/`stream.bank_scrub`. |

So the real remaining work was items 1, 2, 3b and 6, and that is what this
session spent itself on.

---

## Summary

| Item | Outcome |
| --- | --- |
| 1. A genuine second grass species | **Done.** `drygrass` un-suppressed and retuned into a real second species, plus a new per-layer band gradient so it thickens toward the stronghold. Re-baked. |
| 2. Dashed terrain seam lines | **Both standing hypotheses positively RULED OUT with measurements**; one real, measured, lattice-aligned artefact source found and fixed; the residual is characterised but not closed. Honest partial. |
| 3b. Stream visible from its own bank | **Done and measured** — from occluded by 0.363m to clear by 0.218m, against ground *plus grass*, at the capture tool's own stand. Terrain regen + `smoke_traversal.gd`. |
| 3c. River as engineered canal | **Partially done, capped by gameplay.** Rim and half-width varied within the limit the river's blocker role allows; the remaining canal read needs an owner decision. Stated plainly below. |
| 6. Mid-distance smear tier | Not attempted. T1-GROUND could not reproduce it as described and I had no budget left to re-litigate that. |

Three new headless probes are committed. They are the reusable part of this
session: each replaces a 12–30 minute boot-and-render round with seconds of
arithmetic, and two of them answered questions that had already cost two
lanes a render round each.

---

## 1. A genuine second grass species — DONE

Both previous lanes called this "the single biggest lever" and neither
attempted it, both correctly judging it too big to squeeze into a session
carrying other work.

**The constraint that decides the whole shape of the fix.** The near-field
carpet is `grass_field`'s tuft ring, and its tuft is *generated in code*
(`grass_field.gd::_tuft_mesh`, six tapered strips at different yaws). No
tint, density or height number on that mesh can be a second *plant* — it is
one silhouette by construction. So a second species has to come from a mesh;
`CLAUDE.md` forbids new Meadows art; therefore it has to come from the
installed nature pack. And the installed pack already had one, switched off:

`grass_field.json`'s `suppress_scatter_layers` carried `drygrass` —
Grass_Wispy_Short/Tall (a splayed fan) and Grass_Wheat (upright stalks with
seed heads) under a straw retint. It was suppressed on the same reasoning
`groundmat` was, and it was wrong for the same reason T1-GROUND found for
`groundmat`: the field's `cover_tiers` are bushes/flowers/litter, and none of
those is a grass. The field genuinely replaces `grass` (Grass_Common/
Grass_Wide, upright blades — the same silhouette as its own tuft), and it
genuinely replaces `flowers` (it has a flower tier). It never replaced the
wispy/wheat family at all.

**Un-suppressing alone is not the fix, and that distinction is the work.**
Dropped in as-authored, `drygrass` is invisible: its `scale_min/max` of
0.20–0.44 was tuned to sit *below* the `grass` scatter layer that the field
has since replaced, which put the wispy meshes at 0.21–0.73m against a field
carpet of 0.40–0.62m. A plant you cannot see over the first one is a texture,
not a species. Three changes, all in `vegetation.json`:

- **Height** — 0.20–0.44 → 0.30–0.62. Measured against the meshes' own glTF
  accessors (Wispy_Short 1.07m, Wispy_Tall 1.67m, Wheat 1.78m at
  `model_scale` 0.72): the mean wispy tuft lands near 0.7m and the tallest
  near 1.04m against a 1.80m trainer. Knee-to-thigh tussocks breaking the
  carpet's top line. Still under the bushes tier's 0.85m, so the understorey
  ladder's order is unchanged.
- **Clustering** — a species reads as a species by standing in stands, so the
  same instance count is repacked into more, tighter clumps: 52×130 = 6760
  becomes 74×92 = 6808 (+0.7%, inside the noise) at a clump radius of 4.6m
  instead of 7.5m. That is EV3's own tighter-packing lever applied a second
  time. `strays` 140 → 90: a lone straw tuft in open green is the confetti
  read the blind pass named; a stand of them is a different grass.
- **Colour** — untouched. The straw retint was already a distinct family.

**Plus the half nobody could reach from config at all: regional
differentiation.** The blind pass's subject 8 says "bands 1, 3, 4 and 5 share
the same grass carpet… they differ by what is parked on them. Increasingly
demanding regions is not yet something the terrain itself says." That was not
a tuning failure — it was *unreachable*. `corridor_bands.density_scale` is one
scalar applied to all eleven layers at once, so a band could be sparser or
denser but never made of different plants.

New optional `layer.band_scale` in `scatter_rules.gd`, keyed by band id,
multiplied on top of the existing band table
(`_layer_band_scale_at`). `drygrass` carries the chapter's own story as a
gradient: 0.45 in the lower meadows the player leaves home into, 0.7 in the
grove, 0.9 at the wet river lock, 1.35 and 1.6 climbing toward the drain
stations and the stronghold. The same walk that gets harder gets visibly
drier underfoot, with no new asset and no band content touched.

It applies to the **verge** as well as corridor fill, and the verge is the
half that matters — corridor fill spreads over 16.8 km² the camera never sees,
while every verge draw lands within metres of an authored route. Normalised by
the layer's own largest weight rather than applied raw, or every weight ≥ 1.0
would clip to "keep everything" and collapse exactly the distinction the key
exists for. Not clamped to 1.0, unlike `density_scale` — the two tables answer
different questions. One is what the chapter can *afford* (budget, hence
clamped); the other is where a species *belongs* (look, no budget content).

### Two things I got wrong first, both caught by measurement

Recording these because both are invisible until measured, and both would
have shipped as "done" on the strength of a correct-looking diff.

**(a) The first cut moved nothing, and I only knew because I measured the
frames.** Un-suppressed and retuned as above, `drygrass` produced *no visible
change*: straw's share of lit ground pixels across the five band frames moved
+0.21, +11.41, −0.01, +0.12, +0.88 points, and the one large number is band
2's canopy shifting, not tussocks. `tools/_probe_layer_count.gd` (new) says
why in 20 seconds: **53,726 instances over a 16.8 km² corridor is 0.004 per
m²**, so a player-height frame holds single digits of them — against the grass
field's 300,000-tuft carpet inside the same 72 m ring. A species you meet
eight times in a frame is confetti, which is the defect this pass exists to
answer.

Retuned against that number rather than by eye: `corridor_fill.density_scale`
1.0 → 2.0, `trail_bias` 0.55 → 0.75 (the old value deliberately kept dry grass
*off* the trail so it would not stack under the green scatter carpet — a
carpet that is now suppressed, so there is nothing left to stack under), and
`verge.count` 4500 → 34000. That is **53,726 → 130,547** placements, and the
per-100 m density along the corridor now climbs 1326 / 1248 / 1369 / 2066 /
2222 across the five bands. Chapter total 750,071 → **826,892**, which is
73,108 under `test_scatter_perf_budget.gd`'s 900,000 ceiling.

*Free headroom, noticed on the way past and not spent:* `grass` still carries
`verge.count: 30000` and renders **none** of it, because that layer is
suppressed. 30,000 baked placements the player never sees.

**(b) The band table is half of a product, and my first table read as a ramp
while landing as something else.** The bake applies `corridor_bands.
density_scale × band_scale`, and the affordability table is itself uneven
(0.18 / 0.13 / 0.12 / 0.13 / **0.07**) — band 5 is deliberately the thinnest
in the chapter because its drain stations strip vegetation at run time. So a
tidy 0.45 → 1.6 ramp landed as an effective 0.081 / 0.091 / 0.108 / 0.176 /
**0.112**: band 4 drier than band 5, which is not the story. Band 5's weight
is now 2.9 and the products climb the whole way — 0.081 / 0.091 / 0.108 /
0.176 / 0.203. The large number is compensating a floor set for a different
purpose, not asking for three times band 4's dry grass.

Tests: five new assertions in `tests/test_veg_corridor.gd`. One runs against
the *real* config so a typo'd or dropped band id — which falls back to 1.0 and
silently flattens the gradient — fails a test; another asserts the **product**
rises monotonically along z, which is the assertion that would have caught (b)
and which pinning `band_scale` alone would not.

---

## 2. Dashed seam lines — two hypotheses killed, one real source fixed, residual characterised

This is the item two lanes left open with "two hypotheses, neither tested,
next step is a debug-overlay render". I did not build that render. Every
question on the table was arithmetic over config and the analytic
heightfield, so `tools/_probe_ground_seams.gd` answers them headlessly in
about a minute instead of 10–30 minutes per round.

**H1, the `sin()` pseudo-hash — RULED OUT, measured.** `build_playground_
terrain.gd` dithers five threshold decisions with the classic GLSL sin-dot
hash, which is known to alias into periodic banding in float32. Over the exact
integer domain the bake feeds it (region-local pixel indices, 0..255):

```
distribution: mean 0.5003 (ideal 0.5000)  sd 0.2889 (ideal 0.2887)
worst autocorrelation over lags 1..39, both axes: r = -0.0129 at lag 37
```

White to the noise floor. An aliasing hash shows up as autocorrelation at some
lag — that is what a periodic ripple *is* — and there isn't any. This hash is
not drawing the dashes. (GDScript evaluates `sin` in float64, which is
probably why the well-known float32 failure does not appear here.)

**H4, control-map dropouts — RULED OUT, dumped and looked at.** The control
map is the only part of the terrain data written per world position rather
than imported as a whole Image, so it is the one place a per-texel indexing
slip could leave a lattice of unwritten texels. `tools/_probe_control_map_
dump.gd` (new; sibling to the existing `_probe_control_map.gd`, which
histograms the same data and cannot tell a boundary from a dropout) writes the
baked region out as false colour. It is clean: organic patches, a coherent
path, a coherent rise, no lattice, no rows. 1.29% of texels differ from all
four neighbours and they cluster on boundaries, which is the raggedness dither
doing its job.

**H2, far-cover sheet poke-through — CONFIRMED as a real artefact source, and
FIXED.** `grass_field.json`'s `far_cover` is one terrain-following sheet on a
fixed, world-axis-aligned 6m grid whose vertices the vertex shader lifts to
the sampled terrain height plus `lift` (0.35m). Between vertices the sheet is
a chord and the ground bulges over it. Measured at the five capture
viewpoints:

```
band1-opening        533 of  5034 cells breached (10.6%), worst excess 5.78m
band2-stone-root      51 of  5007 cells breached ( 1.0%)
band3-crossing        85 of  5021 cells breached ( 1.7%)
band4-ironwood        39 of  5014 cells breached ( 0.8%)
band5-approach       115 of  5026 cells breached ( 2.3%)
ALL SITES:           823 of 25102 cells breached ( 3.3%)
```

Band 1 — 10.6%, an order of magnitude above the others — is the exact frame
the artefact was reported in. Holes in a wash on a fixed world lattice line up
into rows at a grazing angle, which is the artefact's description.

**This is not covered by the ruling-out already on record.**
`GRASS_HANDOVER_2026-08-26` hid "the field's own MultiMeshes" and saw the
lines survive, and both later lanes repeated that as the reason the grass
field is ruled out. The far cover is **not** a MultiMesh —
`_build_far_cover` adds a single `MeshInstance3D` — so that check could not
have hidden it.

The fix is `dilate_lift`, a new uniform in `far_cover.gdshader`: raise each
vertex above its own half-cell *neighbourhood* maximum rather than above its
own sample — a morphological dilation at exactly the radius the chord spans.
Both obvious knobs were swept first and both are bad trades:

```
fix sweep -- % of cells still breaching, all five sites
  cell   lift=0.35  0.60  0.90  1.20   tris vs 6.0m
   6.0m    3.28%   2.09%   1.84%   1.57%    1.00x
   4.0m    1.96%   1.64%   1.26%   0.95%    2.25x
   3.0m    1.71%   1.28%   0.95%   0.66%    4.00x

H3 (the fix): cell 6.0m, lift 0.35m, dilation over half a cell
  dilate_cap 0.00m -> 3.28%   (today)
  dilate_cap 1.50m -> 1.19%
```

A smaller cell buys it with triangles on the tier whose GPU cost no container
in this project can measure; a bigger lift buys it by floating the wash off
the ground *everywhere*, including the 52–84m hand-over where the sheet is
nearest the eye. The dilation costs eight texture fetches per **vertex**
(never per fragment) on a vertex already doing seven, no triangles, and
nothing on flat ground — where the neighbourhood max *is* the vertex's own
height, so the wash still sits at `lift` exactly where a parallax offset
would show. `dilate_lift` is the cap on what the dilation may add so a cliff
cannot carry a whole cell with it; `0.0` restores the previous behaviour
exactly.

**What I could NOT close, stated plainly.** I do not claim the far-cover
breach is the whole of the reported artefact, and there is direct evidence it
is not. Measuring the band-1 evidence frame:

- The dashes are **~1 pixel wide** dark hairlines (a single-pixel luminance
  drop of ~30 against ~138 neighbours), not the several-pixel patches a 6m
  cell breach would subtend at that range.
- They cross the **sand path** as well as the grass, and *both* grass-field
  sheets carry `"path"` in their `forbidden_ground`, so neither draws a
  fragment there.
- They appear well inside 40m, where the far-cover mesh has a hole cut in it
  (`inner = fade_in_start - cell*2`).
- They form at least two families at different screen angles — a grid seen in
  perspective — and they are crisp while the ground under them is mip-blurred.

A 1-pixel dark hairline on a camera-relative grid, present at all distances,
crossing every material, is most consistent with **Terrain3D's own geometry
clipmap seams** — cracks between LOD rings — which is an addon-level artefact
rather than anything reachable from this repo's config. I did not confirm
that, and I want to be explicit that it is a characterisation, not a
diagnosis. What is now settled is that it is *not* the sin-hash, *not* the
control map, and only partly the far cover.

**Next step for whoever takes this**, and it is much cheaper than the
debug-overlay render two lanes have now proposed: render one frame with
Terrain3D's `mesh_lods`/`mesh_size` changed. If the line spacing moves, it is
the clipmap and the fix is an addon setting or an upstream issue; if it does
not, the clipmap is out too and the remaining candidate is the terrain
material's own mip/filter behaviour at grazing angles.

---

## 3. The stream, and the river

### 3b. Stream visible from its own bank — DONE, and measured rather than rendered

T1-GROUND root-caused this correctly (the hillside's own grade swallows a 0.7m
carve) and T1-GROUND-2 wired the missing reeds and re-rendered honestly to
find it still invisible — exactly as T1-GROUND predicted, because dressing was
never the binding half. Two render rounds to learn something that is pure
geometry.

`tools/_probe_stream_sightline.gd` (new) rebuilds the capture tool's own
camera stand — the middle authored point, the perpendicular to local flow, the
bank at `width/2 + shoulder + 6.0`, the camera `WATER_BACK` behind it — and
traces the eye-to-water sightline against the analytic heightfield. No bake,
no renderer, seconds per configuration.

**The measurement that made this tractable: the occluder is ground *plus
grass*.** `grass_field`'s blades stand 0.40–0.62m and the field only clears the
water by `stream_factor`'s own half-width, so a sightline clearing the *dirt*
by 20cm at 5m off is looking straight into half a metre of grass. A
ground-only check calls that a pass; the frame does not. On the shipped
cross-section the water sat **0.363m below** that occluder — the reported
defect, as a number, from config alone.

**Width is the lever, and the sweep says so rather than intuition:**

```
  depth  carve  water shoulder  over-gnd over-grass  (at offset)
   0.70    5.0    2.4      1.2     0.147   -0.363   2.43m off   <- shipped
   1.10   12.0    3.4      1.2     0.264   -0.246   5.00m off
   1.40   16.0    3.4      1.2     0.463   -0.047   5.68m off
   1.40   20.0    3.4      1.2     0.620   +0.218   5.13m off   <- landed
   1.70   20.0    6.5      1.2     0.459   -0.051   6.48m off
   1.40   20.0    5.0      2.6     0.423   -0.087   6.44m off
```

Deepening alone makes it worse (1.7m is worse than 1.4m at the same width) —
it hides the water further under a rim that already occludes it. Widening
moves the rim back and flattens the ground the sightline grazes. `carve_width`
is the full width, so 5.0 → 20.0 takes the channel from a 2.5m-half slot to a
10.0m-half vale. Landed at `carve_depth` 1.4, `carve_width` 20.0, water width
3.4, `surface_depth` 0.62 — the only configuration in the sweep that clears
ground-plus-grass at all, a 0.58m swing.

`shoulder` is deliberately *not* part of the fix even though it is what moves
the grass line: the capture tool stands at `width/2 + shoulder + 6.0`, so
widening the shoulder pushes the camera further down the same hillside that
caused this, and the sweep shows it going backwards every time.

Traversal-safe by construction: 1.4m over a 10.0m half-width is an 8-degree
mean bank, ~12 degrees at the smoothstep's steepest, nowhere near the
45-degree floor limit. Widening a carve can only make ground more walkable.
`smoke_traversal.gd` was still run as the gate.

### 3c. The river as an engineered canal — PARTIALLY done, and capped by gameplay

T1-GROUND measured this correctly: 59–77° banks at every one of 19 authored
points, `half_width` flat at 12–13 on every open reach. It declined to touch
it. The brief asked me to "add river.course rim variation".

**I did, but much less than the complaint asks for, and the reason needs to be
on the record rather than rediscovered.** The river's bank angle is
load-bearing gameplay, not decoration. `terrain_playground.json`'s own river
comment states the contract: it "severs EVERY bearing it crosses", both ends
run past the world perimeter ring, and "the only ground link between the near
Meadows and the far bank is the Old Mill Crossing". It severs a bearing *by
being too steep to walk* — exactly what `_spoke_carve`'s own comment spells
out, that the wall angle "has to stay well past the player's own 45-degree
`floor_max_angle`, or the road is not severed at all, it just dips".

Gentling these banks toward a natural 30–40° would open a ford wherever it was
applied and delete Band 3's gate. That is a major gameplay decision and
`CLAUDE.md` reserves those for the owner. **I did not make it.**

Within that constraint: every rim moved, none to a bank shallower than 60°
(a 15° margin over the walk limit, which the ±2.2m `detail` noise riding on
top needs), and `half_width` now varies 10.0–15.5 where it was 10.0–13.0.
Open-reach bank angles run 60.1–72.1° against 59.0–69.0°, in irregular runs
rather than the smooth symmetric taper that was there. Indices 6–10 are
untouched: that is the Old Mill Crossing narrows, where the pinch is authored
content.

**Honest limit.** This does not fully answer the canal read and should not be
recorded as if it did. Two of the judge's three named causes are not the
angle: the bank *texture* scale (T1-GROUND already took `rock.uv_scale`
0.1538 → 0.22) and "a hard turf line where the meadow resumes", which is the
rim's top edge terminating on a clean smoothstep running parallel to the
water. The remaining lever for that line is per-metre noise on the rim inside
`_river_carve` so the edge wanders — code rather than data, and not attempted
here. **If a later pass still reads this as a levee, that noise is the next
instrument, not a shallower bank.**

---

## Two things about this repo's bake and capture that cost me time

Neither is a defect I introduced and neither is in any handover I read, but
both will mislead the next lane exactly the way they misled me.

### A terrain edit reshuffles the WHOLE chapter's scatter, in every layer

I expected the scatter diff to be local, because `all_placements` gives every
layer its own RNG (`base_seed + index * 7919`) and my only layer-level change
was to `drygrass`. It is not local: **all 256 region files changed, and the
`trees` layer's band-4 density rose 32%** (8,971 → 11,843 instances, 400 →
529 per 100 m) without a single tree-related edit.

The mechanism, confirmed by reading rather than guessed:
`scatter_rules.gd::_consider` returns early on the height, slope and bounds
rejections **before** consuming any rng, and only draws from it further down
once a candidate survives. So a candidate that flips from accepted to rejected
consumes a different number of rng values, and every later draw in that
layer's stream shifts. The stream and river carves flip a handful of
early decisions in band 1 and band 3 — and everything after that, in every
layer, lands somewhere else.

This is inherent to the design and is fine for a seeded re-bake (the
composition is statistically identical and every test passes), but it means:

- **"Only my layer moved" is never a safe assumption after a terrain edit.**
- A lane comparing before/after frames after a terrain regen is looking at a
  reshuffled world, not at its own change. Band 4's extra trees are an
  accident of this, not a decision — arguably a welcome one, since GATE-D4 and
  the blind pass both name thin ironwood canopy, but nobody chose it.

### `_capture_ground_and_sky.gd` is not deterministic run to run

Two captures of the **same commit, same viewpoint, same pinned day state**
differ by 403,564 pixels of 1,024,000 (band 4). The near ground is stable; the
sky's clouds and the distant tier are not. So a small distant difference
between two frames is not evidence of anything, and this is worth knowing
before anyone concludes — as I nearly did — that a change moved the trees.
The way to tell is what I ended up doing: re-render the *baseline* twice and
compare that against the change.

## Disagreements and corrections

- **The brief's items 4, 5 and 3a were already done** by a lane it does not
  mention (see the table at the top). I verified each against current `main`
  rather than redoing it, per `CLAUDE.md`'s "evidence-backed already fixed is
  valid". If the coordinator's routing docs still list them as open, they are
  wrong.
- **"Add river.course rim variation" as written is not safely implementable.**
  The rim is what makes the river a blocker. I did the part that is safe and
  said what the rest would cost; treating the remainder as a tuning task will
  silently delete Band 3's gate.
- **The far-cover sheet was never actually ruled out** by the 2026-08-26
  MultiMesh check that three documents cite as having ruled out the grass
  field. It is not a MultiMesh.
- **I overwrote `tools/_probe_control_map.gd` early in the session** and
  restored it from `HEAD`; my version ships alongside it as
  `_probe_control_map_dump.gd`. No content was lost, but it is worth naming
  because `tools/` has 345 scripts and a plausible-sounding name is easy to
  collide with.

---

## Tests

All run on this branch, after the terrain regen and the final scatter re-bake.

| Suite | Result |
| --- | --- |
| `test_scatter_perf_budget.gd` | 3 tests, 6 assertions, 0 failed — bake fresh, load budget, batch count |
| `test_scatter_rules.gd` | 27 tests, 957,763 assertions, 0 failed |
| `test_veg_corridor.gd` | 9 tests, 1,386,524 assertions, 0 failed (incl. the new `band_scale` trio) |
| `test_grass_field.gd` | 10 tests, 63 assertions, 0 failed (incl. flag/suppression agreement, far-sheet grid) |
| `smoke_pond_water.gd` | pass — pond 152 reeds unchanged, stream 77 reeds / 12 scrub, river 130 / 60 |
| `smoke_traversal.gd` | **pass** — and it asserts in its own words that "the river cannot be walked across between its crossings", which is the gate the rim variation had to survive |

`test_veg_corridor.gd` and `test_grass_field.gd` were re-run after the density
retune; the perf-budget and scatter-rules shards were run against the
intermediate bake and the placement total only moved within the same ceiling
(826,892 against a 900,000 limit), so nothing they assert changed class.
**Whoever consolidates should let CI re-run all of them rather than trusting
that sentence.**

Not run: the full `tests/run_tests.gd` (~30 min). Nothing here touches combat,
creatures, UI, story or save format.

## Bakes committed with their config

Both bakes are in the same commit as the config that produced them, per the
tracked-mirror rule:

- `data/terrain/playground/` — **7 of 64** region files changed (one stream
  region, six river regions), from `build_playground_terrain.gd`, 22 min.
- `data/scatter/playground/` — all 256 region files plus the manifest, from
  `bake_playground_scatter.gd`, 5 min. 766,371 → **826,892** placements
  (see the reshuffle note above for why all 256 moved).

## Reproducing anything here

```
# Setup on a fresh container
bash tools/art_pipeline/setup.sh godot        # -> /root/.cache/tetherbound-art/godot
godot --headless --path . --import            # twice; second is clean

# The three new diagnostics -- seconds each, no renderer, no bake
godot --headless --path . --script tools/_probe_ground_seams.gd
godot --headless --path . --script tools/_probe_stream_sightline.gd
godot --headless --path . --script tools/_probe_stream_sightline.gd -- --sweep
godot --headless --path . --script tools/_probe_layer_count.gd -- --layer=drygrass
godot --headless --path . --script tools/_probe_control_map_dump.gd -- --region=0:0

# The bakes, in this order (scatter reads the heightfield, so terrain first)
godot --headless --path . --script scripts/world/build_playground_terrain.gd   # ~22 min
godot --headless --path . --script scripts/world/bake_playground_scatter.gd    # ~5 min

# Evidence frames (NEVER --headless with a rendering driver -- see conventions)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --states=day
```

Measured on this container, against the numbers earlier handovers quote: a
five-band `--states=day` capture is **12 minutes**, not the 25+ T1-GROUND
budgeted for two bands. One terrain region bakes in 22 s.

## What I would do next, in priority order

1. **Judge the second species.** It is placed, measured and tested, but the
   only thing that decides whether 130,547 tussocks read as a second grass or
   as clutter is a blind pass over the AFTER frames in
   `ralph/reports/T1-GROUND-3/shots/`. If it reads as clutter, the first knob
   is `drygrass.verge.count`, then `corridor_fill.density_scale` — not the
   clump numbers, which are chapter-wide.
2. **Finish the dashed seam lines** with the clipmap test named in item 2 —
   one render with Terrain3D's `mesh_lods`/`mesh_size` changed. Much cheaper
   than the debug overlay two lanes have proposed, and it is the last
   candidate standing.
3. **The river's hard turf line** — per-metre noise on the rim inside
   `_river_carve`. This is the remaining half of the canal read and the one
   that does *not* require touching the bank angle. Needs a terrain regen.
4. **The 30,000 wasted `grass` verge placements**, which are baked and never
   rendered while the layer is suppressed. Free headroom under the ceiling for
   whoever needs it next.
5. **Mid-distance smear tier** (brief item 6), still un-reproduced by two
   lanes now.
