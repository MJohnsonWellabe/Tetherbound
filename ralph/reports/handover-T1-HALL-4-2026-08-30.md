# HANDOVER — T1-HALL-4, 2026-08-30

**Branch:** `ralph/T1-HALL-4`, off `origin/ralph/T1-HALL-3`.
**Brief:** the fifteen scene fixes in `ralph/reports/JUDGE-6-2026-08-30.md`, which
answered both bar questions **No**. The second list in that report — the one that
needs art nobody has built — went to the owner and is deliberately untouched here.

**Status: FINAL.**

**Headline, the number the lane was asked for**, measured on JUDGE-6's own stand
(`H-02b-sigil-gate-raised`) with JUDGE-6's own boxes:

| | T1-HALL-3 (judged) | T1-HALL-4 | keyart |
|---|---|---|---|
| fortress mass | 133.4 | **115.7** | 72 |
| bald hill right of it | 158.4 | 170.5 | 104 |
| mid-ground left of it | 136.3 | 148.9 | — |
| **fortress vs hill** | +25.0 | **+54.7** | +32.0 |
| **fortress vs worst neighbour** | **+2.9** | **+33.1** | +32.0 |

> **The fortress is now the dark shape in its own frame.** Against the hill the
> judge named, the separation is **+54.7**. Against the nearest-in-value ground
> beside it — the harsher reading, and the one the judge's "within 5 luminance
> points of the ground beside it" actually describes — it is **+2.9 → +33.1**,
> against the keyart's +32.0.

Both halves of the fix were needed: the building dropped 17.7 points and the
ground it stands against rose 12.6.

**Draw calls:** 3365 at `hall_approach` against `docs/PERFORMANCE_BUDGET.md`'s
4000 ceiling — 16% headroom. **Scatter:** 837,204 placements against
`test_scatter_perf_budget.gd`'s 900,000.

**Defect 2 (the bald mid-distance) is NOT fixed, and roughly half of it is not
fixable by any vegetation setting.** See §1b — the top of the judge's own
mid-band looks 367 m down a corridor that ends at z 7680. That half belongs on
the owner's list, not a scene lane's. The fillable half improved only slightly
(texture energy 15.09 → 16.12 in rows 450–560).

---

## 0. Read this first if you are the next lane

Four things worth more than the defect list, because each one changes what you
would otherwise do:

1. **JUDGE-6's silhouette number needs restating before you can act on it, and
   the restatement is harsher, not softer.** Its table gives the fortress three
   neighbours and its verdict sentence uses two at once: "within 5 luminance
   points of the ground beside it *and* darker than the hill to its right". On
   the shipped frames the fortress is already **25 points below the hill** — so a
   lane reporting "fortress vs hill" could have claimed victory on day one
   without touching anything. The defect is the other pair: mid-ground 136.3
   against the fortress's 133.4. `tools/_t1hall4_measure.py` therefore reports
   `min(hill, midground) - fortress`, which reads **+2.9** on the frames JUDGE-6
   read and is exactly the "no figure/ground separation at all" it describes.
2. **`ssao_enabled` in `art.json` has been decorative since it was written.**
   Compatibility does not implement SSAO, and `project.godot` ships
   `gl_compatibility` (D01, locked). So *no frame any judge has ever seen had
   ambient occlusion*, and defect 4's "enable or repair contact shadows and AO
   globally" cannot be answered from config. Under this renderer **sun shadows
   are the contact shadows**, which is why the actionable half of that defect
   turned out to be a layer with `casts_shadow: false`. Do not read the `true` in
   that file as evidence AO is on.
3. **The bench is not undersized. JUDGE-6 mis-measured it, and obeying that
   finding would have introduced a real defect.** See §2 — the arithmetic
   reproduces the judge's own pixel numbers to within 1%.
4. **Any edit to `vegetation.json` forces a full scatter re-bake**, including a
   one-character change to a `lod_range`. `scatter_bake.config_fingerprint()`
   hashes the whole file text, so `test_scatter_perf_budget.gd`'s freshness
   assertion fails until you re-run `scripts/world/bake_playground_scatter.gd`.
   Budget the ~5 minutes.
5. **The braziers already had lights. I nearly shipped a duplicate set, and the
   trap is worth knowing.** JUDGE-6 says "the flames are unlit sprites … four
   fires light nothing", and `torch_prop.gd`'s own header says it carries no
   light and that *callers add their own*. Two independent sources pointing at a
   missing `OmniLight3D`. I checked the function that builds the brazier body
   (`_brazier`), found it adds none, and stopped there — but `_build_hall_fire`,
   its own immediate caller, has always added a real flickering light per config
   entry. Adding another would have put eight uncounted omnis into a budget
   `_comment_braziers` spends to its stated ceiling of 18 exactly. Reverted; the
   real defect was *reach* (a 15 m range against towers 10–30 m away) and
   *shape* (Godot's default attenuation spreads a fire instead of pooling it).
   **When a judge says a thing is missing, find the code that would build it and
   confirm it does not run — do not confirm that one plausible function does not
   do it.**

---

## 1. The headline defect: silhouette contrast — **fixed, and measured**

Numbers are in the header table. Two changes produced them and neither was
sufficient alone.

**The building dropped and cooled.** The whole stone family moved together —
kit `LightRock` #d2c6b2 → #817f78 and `DarkRock` #ab9d89 → #68675f in
`building_prefabs.json`, works walls' `stone_light` #9c9083 → #66655e in
`stronghold.json` — so the ~1.27× ladder `_why_retint_t1_hall_3` tuned survives
and only the family's *absolute* value moves. That is the axis JUDGE-6 said was
never addressed: "the lane treated D3 as a massing problem and solved it as one …
raising a pale object standing on a pale hill does not create a silhouette." The
warm spread narrows from 32 points of R-over-B to 9, because the judge asked for
cooler as well as darker.

`stone` (#6a6157) is deliberately untouched — it is the *interior* tone, and
`_ceiling_colour`'s note records the warden arena hitting 96.7% of pixels below
luminance 40 the last time these rooms lost value.

**The backdrop lifted and warmed.** `fog_colour` and `sky.horizon_colour` (kept
identical, as the EV8 note requires) #b7ccc3 → #d3cebd, and the terrain's own
`shader.aerial_fade_colour` #bec9ce → #d0c9b6. The terrain one does the real
work: it lives in the ground shader's fragment tail, so it lifts what is *behind*
the fortress without lifting the fortress — the judge's own "push a lighter warm
haze behind it", and something env fog cannot do because fog reaches the building
too.

**A regression this caused, and its correction.** Round 1 took JUDGE-6's own
defect-5 box (`H-06`, x 900–1280, y 0–620) from mean L 28.8 to 19.8 with
high-pass texture sd 4.10 → 2.67 — darker, with *less* readable texture. The
rank-1 fix had partly paid for itself out of the rank-5 defect below it. Two
small corrections, neither touching the kit stone that carries the silhouette:
`ambient_sky_contribution` 0.25 → 0.10, and `stone_light` giving back ~8% on the
**works walls only** (#5f5e58 → #66655e), which is what that keep elevation is
made of. The separation did not suffer — it rose, because lifting fill raises
pale ground more than dark stone.

## 1b. Defect 2 is **not** fixed. Two reasons, and both matter

This is the most useful section in this handover and it should change what the
next lane does.

### The cull range is a dead lever, and it was already known to be

The obvious suspect for a "hard vegetation cull line" is `vegetation.json`'s
`lod_range`, since `vegetation.gd` feeds it to Terrain3D's own
`instance_geometry_set_visibility_range`. I raised all six content layers (trees
260→620, and five others), re-baked, re-rendered, and measured: bare pale ground
in the mid-band moved 37.5% → 36.0%, and the topmost vegetation-dark row rose
from y=364 to y=354. **Ten pixels.**

The reason is one line in `data/config/performance.json`:

```
"scatter_lod_ranges": false,
```

`vegetation.gd` only applies those keys when that flag is on. **Under the shipped
configuration every `lod_*` value in `vegetation.json` is inert** — it changes no
frame, in game or in capture. And the flag is false *deliberately*: its own
comment records PERF-ROG measuring the authored ranges as changing draw calls by
less than measurement noise, and forcing every range to 20 m as removing only
5–16%, concluding "the lever works; it is just not where the frames are."

I have **reverted** the raise rather than leave inert config sitting in the file
looking like a fix. The cost of finding this out was a bake and most of a render
pass; the finding is written into `vegetation.json` beside the keys so the next
lane measures instead of re-deriving it, which is exactly what that flag's own
comment asked for and what I failed to do.

### The bald ground is outside the world

The real cause, from `scripts/world/world_perimeter.gd`:

```
##   south cap   z = +7680,  x: -1024 -> 1024  (past the stronghold)
```

**The Hall stands at z 7560. The world ends at z 7680 — 120 m behind it.**

So in `H-02b`, which looks south-west *at* the Hall, most of the "bald
mid-distance" is ground beyond the authored corridor: no scatter is baked there,
none ever will be, and no `lod_range` or `density_scale` can put content on it.
And the judge's "hard dark rim with **evenly spaced identical pale posts** along
it … it says *edge of the map*" is not a procedural-looking artefact that
resembles a boundary. It **is** the boundary — `world_perimeter.gd`'s south cap,
posts at `JOIN_SPACING` 37 m. The judge read the frame exactly right, blind, and
named the cause without knowing it.

### How much of defect 2 is structural — for the owner's list, not a lane's

The coordinator asked for this stated plainly, so: mapping each row of JUDGE-6's
mid-band (y 380–560) to the ground it actually sees, from this stand's own rig
(view dir (−0.319, 0.948), horizontal half-FOV 48.2°, eye 26 m):

| frame row | ground distance | centre point | inside the world? |
|---|---|---|---|
| y=420 | 367 m | (−53.7, 7743) | **no — past z 7680** |
| y=450 | 222 m | (−7.3, 7605) | yes |
| y=480 | 159 m | (12.9, 7545) | yes |
| y=510 | 123 m | (24.3, 7512) | yes |
| y=540 | 100 m | (31.6, 7490) | yes |

**Rows 380–420 of the band the judge measured are outside the authored world.**
No `lod_range`, `density_scale`, `band_scale` or anchor can put anything there,
because there is no ground there to put it on — only Terrain3D's procedural
background and the perimeter fence. That is a **world-extent decision and belongs
on the owner's list**, alongside the stone material and the ivy: it is not
something a scene lane skipped.

Rows 450–560 *are* fillable, and this lane filled them — 14 tree, 5 grove and 6
boulder anchors at 120–270 m along the view axis, off-trail and clear of the Hall
footprint. The gain is real but small: texture energy in those rows moved
**15.09 → 16.12**. Honest read: this improves the near half of the band and does
not change the frame's overall impression, because the part that dominates the
eye is the part that is outside the world.

The three ways to actually fix the frame, none of them this lane's to take:

1. **Raise a landform behind the Hall** — `terrain_playground.json`'s
   `rises.peaks`, a peak near (8, 7700) — occluding the boundary and giving the
   fortress a backdrop. Cheapest, and the only one still in scene-tuning
   territory. Not done here because it moves terrain near the Hall, and the
   building's floor level, causeway rise and massing feet are all sampled from
   live ground at build time; it needs its own verify pass.
2. Extend the corridor south past z 7680 — a world-bounds change and a re-bake.
3. Move the Hall north, or re-aim the stand — design decisions.

**This lane did not fix defect 2 and must not be read as having done so.** What
it contributes is the diagnosis, and four levers ruled out with evidence so the
next lane does not re-run them:

| lever | result |
|---|---|
| `lod_range` raise | **inert** — `scatter_lod_ranges` is `false` in `performance.json` |
| band-wide `density_scale` 0.07→0.22 | **occluded the 400 m reveal** — `trail_bias` 0.85 puts fill on the approach |
| per-layer `band_scale` on rocks/bushes | baked, measured, **no visible change** — 0.5–2 m objects do not read at 150 m+ |
| off-trail tree/grove/boulder anchors | **works, on the fillable rows only** — 15.09 → 16.12 |

## 2. Where JUDGE-6 is wrong, with the measurement

**The courtyard bench (defect 8) is correctly scaled and was not changed.**

The judge's reasoning: "Its seat is at y ≈ 497 and its feet at y ≈ 550 — 53 px
for a seat height. At that depth 0.45 m ≈ 53 px would make 1 m ≈ 118 px. The
grunt … measures roughly 470 px head to foot. Even on the most generous reading
of the depth difference that puts the grunt at 3 m and more likely near 5 m — or
… puts the bench's seat somewhere below the grunt's ankle."

Measured rather than inferred:

- `assets/props/quaternius_fantasy/Bench.gltf`, read straight out of the glTF
  accessor bounds, is **2.78 m long and 0.53 m tall** at the `scale: 1.0` the
  config gives it. That is a real bench. It is not a fifth of the size it should
  be; it is the size it should be.
- The H-07 rig is fully specified in `tools/_judge_capture_hall.gd`: eye at
  `trainer + (0, 1.7, -2.0)`, `fov = 70` (vertical, Godot's `KEEP_HEIGHT`
  default), 800 px tall. Focal length is therefore `800 / (2·tan 35°) = 571 px`.
- The grunt stands ~2.2 m from that camera: `1.80 × 571 / 2.2 = **467 px**`.
  The judge measured ~470.
- The bench sits at local `(-8.6, 41.0)` against a camera at z ≈ 34 — **7 m**
  away, not 2.2: `0.53 × 571 / 7 = **43 px**`. The judge measured 53.

Both of the judge's own numbers fall out of a scene where the bench is correct.
What the judge got wrong is the *depth ratio*: it derived 2.2× from the pixel
densities and called that "the most generous reading", where the actual ratio in
the scene is **3.2×**. The bench is simply further away than it looks in a frame
with no other depth cue on that side of the room.

Scaling it to satisfy the finding would have produced a 2.6 m-tall bench — a
defect an owner spots instantly, which is precisely the sentence the judge used
about the bench in the first place.

**Contact shadows are not universally absent either.** The same frame, magnified,
shows the bench casting a clear directional shadow with contact at both feet. The
defect-5 list is right about the *scatter* (§4) and wrong as a global claim.

**Defect 9's chroma half measures as already satisfied.** JUDGE-6: "the most
saturated, highest-chroma objects in the entire frame are the cyan tether
pylons". Re-measured on `H-02b` with the sky excluded — and the sky *must* be
excluded, since a naive blue-dominance test flags a third of an exterior frame —
oxblood leads on chroma (70.2) over cyan (59.3). Team Tether's teal is also a
**palette-reserved** colour (`palette.json`, enforced through
`severed_spokes.gd`); re-tinting it is a faction-wide decision touching the
quarry, the relay and the spokes, which `CLAUDE.md` puts in the "ask, do not
invent" list. Left alone, and flagged rather than quietly skipped.

---

## 3. What changed, by defect

JUDGE-6's fix list is numbered here as the brief numbered it.

### 1 — Silhouette contrast *(ranked 1st)*

Two moves, because the defect has two sides and only doing the building would
have left the backdrop fighting it.

**The building drops and cools.** `building_prefabs.json`'s `meadows_hall`
retint takes `LightRock` #d2c6b2 → #817f78 and `DarkRock` #ab9d89 → #68675f;
`stronghold.json` takes the works walls' `stone_light` #9c9083 → #5f5e58 and
`stone_skirt` #8f8172 → #575147. The whole family moves **by the same factor**,
which is what keeps this from re-opening the seam JUDGE-5's D7 raised: the
~1.27× ladder `_why_retint_t1_hall_3` tuned is preserved to two decimal places
(129/104 = 1.24 where it was 210/171 = 1.23; 1.36 against the works walls where
it was 1.35). Only the family's absolute value moves — the axis JUDGE-6 says was
never addressed. The warm spread narrows from 32 points of R-over-B to 9, because
the judge asked for cooler as well as darker.

`stone` (#6a6157) is deliberately **not** dropped. `_wall_material` hands
`stone_light` to outer walls and `stone` to inner ones, so it is an interior
tone, and `_ceiling_colour`'s own note records what happened last time these
rooms lost value: the warden arena went to 96.7% of pixels below luminance 40 and
a blind critic's first finding was the value crush. The exterior is now slightly
darker than the interior, which is both the right read and the only way to buy
the silhouette without paying for it in the five rooms the player fights in.

**The backdrop lifts and warms.** `art.json`'s `fog_colour` and
`sky.horizon_colour` (which the EV8 note requires stay identical, and do) go
#b7ccc3 → #d3cebd, and `terrain_playground.json`'s `shader.aerial_fade_colour`
goes #bec9ce → #d0c9b6. The terrain one is the useful one: it lives in
`terrain_ground.gdshader`'s fragment tail, so it lifts the ground *behind* the
fortress without lifting the fortress — which is exactly the judge's "push a
lighter warm haze behind it so it reads as the dark shape", and something env
fog cannot do because fog reaches the building too.

The jade roof went with it: `MI_RoundTiles` #2a8c94 → #2b423f, killing what the
judge measured as "the only strongly saturated hue on the whole building".

### 2 — The bald mid-distance *(ranked 2nd)* — **not fixed**

Both attempts failed and both failures are worth more than the attempts. The cull
range is inert config; the density raise occluded the reveal. See §1b for the
diagnosis and for what would actually work.

**Band 5's `density_scale` was raised 0.07 → 0.22, rendered, and reverted.**
Evidence committed as
`ralph/reports/T1-HALL-4/EVIDENCE-band5-density-0.22-occludes-the-reveal.png`.
It baked cleanly and then broke the frame it was for: `H-01-approach-400` — the
400 m reveal, the stand whose entire job is the player first seeing the Hall —
came back as a **wall of near-field trees with the fortress not visible at all**.
The judged frame it replaced at least had the fortress in it as a pale nub. That
is strictly worse on defect 1 in exchange for defect 2, and defect 1 is ranked
first.

The mechanism generalises: `trees`' `corridor_fill.trail_bias` is **0.85**, so
most corridor fill is sited *beside the authored trail* — and every approach
stand stands on that trail. A band-wide density rise therefore lands hardest on
exactly the sightlines the region's establishing shots are made of. 0.22 was not
a badly chosen number; it is the shape of this lever on this band, and any figure
big enough to fill the mid-distance will also fill the approach.

If a later lane wants mid-ground content here, the lever is a per-layer
`band_scale` on `rocks`/`bushes` — ground-hugging species that cannot occlude a
400 m sightline from an 8 m eye — not the band-wide number, which moves the
trees. Note that adding `band_scale` to a layer re-rolls that layer's draws
corridor-wide, so it is not free either. And note it will still not reach the
ground past z 7680, because that ground does not exist.

The one thing that did land here: **61 hand-sited rubble stones at the wall
feet** (defect 13, below).

### 3 — Stone UV scale and the hard seams *(ranked 3rd)*

One property: `uv1_world_triplanar = true`, in `_material()` and in
`_weather_hall_massing`. Object-space triplanar multiplies `uv1_scale` by the
*local* vertex position, so a mesh's node scale scales its texture with it — and
`meadows_hall` runs its modules at 2.1× to 7.0×. That is the whole of "one
material, four scales, one frame", and of `H-06`'s near tower at "roughly 4× the
wall's scale" where "the stones become 120 px soap-smears … it reads as wet clay,
not masonry": that tower is `LargeSquareTowerBricks` at scale 4.0 against curtain
walls built as unit boxes. 4× the node, 4× the stone, exactly as measured. In
world space the projection is independent of node scale, so every surface —
kit module, procedural wall, merlon, causeway kerb — courses at one real-world
stone size and the seams stop existing. Same material, same texture, same draw
call.

This does **not** fix the material itself. The baked highlight, the missing
per-stone variation and the visible tile repeat are the judge's "single highest
value purchase" and are on the owner's list, not this one.

### 5 — The near-black tree and keep face

Diagnosed, and it is not quite what the judge thought. Magnified, the `H-05`
"tree rendering as near-black" beside an identical lit one is a *different
variant*: `vegetation.json` gives `CommonTree_2`'s leaves #325f3c against
`CommonTree_1`'s #78c86e, and the dark one is standing in the curtain wall's
shadow while the bright one catches sun. Not two identical trees, and not a
per-instance lighting bug.

But the judge is right that it reads as one, and the cause is real: shaded
surfaces have almost no fill. `ambient_sky_contribution` 0.5 → 0.25 is the fix,
and note it raises fill **without touching `ambient_energy`** — that number has
oscillated twice in this file already (1.02 → 1.5 → 2.1, and cut once the other
way) and a third swing would be the wrong move. `art.json`'s own
`_comment_ambient` says why the sky half is free to spend: "sky radiance does not
reach the terrain under the Compatibility renderer". At 0.5, half the ambient
budget was going to a term that contributes nothing to any frame anyone has
judged. Moving it to 0.25 hands that half to the explicit `ambient_colour`, which
does reach, so shaded faces gain ~1.5× fill while sunlit surfaces barely move and
the blown-highlight fix from EV4 is not at risk.

### 6 — The flat grey slabs, and the floating plinth

The slabs, inspected at 4×, are the `path_stones` layer, and the judge is half
right in a useful way: they **do** have thickness — their side faces are visible.
What they have no trace of is contact, because `casts_shadow` was `false`. That
was inherited from the sub-metre layers the key was written for, where switching
it off is correct ("a tuft's shadow is not information at this scale; a tree's
is"). A 0.6–1.4 scale flagstone is on the tree side of that line. Shadows on,
and `sink` 0.03 → 0.10 so the slab beds into the turf instead of resting on it.

The **floating plinth** is not fixed — see §4.

### 7 — The bare causeway

Ten props from the garrison camp's own family (D24's one-vocabulary rule, no new
asset), with the same oxblood `tint` those camp crates carry so this reads as the
same occupying force's stores. Placement obeys what the causeway is *for*: the
player walks up it, so props hug the kerbs at local x −0.2 and 4.2 (the deck
interior runs −1.3 to 5.3, taken from the ramp braziers' own stations) and the
centre lane stays clear end to end. A barricade the player has to path around
would be a worse defect than a bare ramp. They also stop clear of the banner
piers at z −19/−31.

`on_causeway` is the flag the braziers in the same config block already use, and
it is not optional: the deck climbs ~10 m over its 40 m run, so a prop at the
floor plane is *inside* the slab. That is JUDGE-5's D1 from the other end — a
crate instead of a camera.

### 8 / 10 — Banner scale

`BANNER_SCALE` 2.2 → 3.6, **and** the girders drop from [0.55, 0.55, 0.68, 0.42]
to [0.34, 0.34, 0.42, 0.28] of wall height. The second half is the one that
matters: `banner_scale` is clamped by the drop between the parapet and that
wall's girder (cloth must stop above the hardware), so with the girder at
mid-wall the tallest banner a 12 m wall could hang was ~4 m and most hit the 1.15
floor. **Raising the constant alone would have been a no-op against that clamp** —
which is the trap worth recording. A girder in the wall's lower third also reads
better on its own terms: hardware across the base of a wall is load-bearing
retrofit, hardware across its middle is a belt.

A new width clamp caps each banner at 30% of its wall's span so the pair cannot
meet in the middle of a short wall.

### 9 — Cyan

Partially declined, with a measurement — see §2.

### 11 — The moon

`sky_clouds.gdshader`'s disc falloff was hard-coded to run from the rim all the
way in to 35% of the radius, so two thirds of the body was gradient and there was
no edge anywhere in it. That is the "lens bloom rather than an object" exactly.
`disc_edge` is now a uniform (default preserves old behaviour), night and dawn set
0.93, and `sun_size` 0.006 → 0.0024. Day and golden do not set it, so golden
hour's sun still blooms.

### 12 — The braziers, and the blank banner

**The fires' reach, not their existence** — see §0.5 for the mistake this
started as. The four causeway bowls sit at local z −24 and −40; the gate towers
the judge measured as dark rise from the plinth at z ≈ −13, so their bodies are
10–30 m from the nearest flame and the authored 15 m range stops short of them.
Range 15 → 26 on those four only (the two yard fires light a yard and reach
nothing by design). `energy` is deliberately **not** raised: the deck around each
bowl is already correctly exposed, and more energy would blow that out to fix
something 20 m away.

`attenuation` 1.6 is the shape half, and it is the more important one. Godot's
default 1.0 falls off almost linearly to the range edge, spreading a fire's
contribution thinly over everything nearby instead of pooling it — so a longer
range at the default attenuation would have made the whole approach slightly
warmer and still produced no pool, which *is* the defect. Data-driven, defaulting
to Godot's own value, so any brazier that does not ask is unchanged.

**The blank red banner and the "pink diagonal hatching" are one bug with one
cause**, and it is a cause this repo has already diagnosed once — `STONE_TILE`'s
header records it: *a thin, bright, high-contrast feature minified with no mip
chain*. `ImageTexture.create_from_image` builds no mipmaps unless the Image
carries them, and the sigil is a ring 5.8 px thick in a 128 px image. Past a few
tens of metres the sampler hits or misses it per pixel — hit rows and missed rows
in alternation **are** the diagonal hatching, and a banner whose every sample
misses **is** the blank red rectangle. Fixed with `generate_mipmaps()`, 256 px
source, and ~40% heavier strokes (filtering alone would have cured the noise by
fading the mark to nothing).

The field also went **transparent**. It was opaque white, so the device's quad —
standing 0.012 m off the cloth — was painting a lightened rectangle over 62% of
every banner. The mark is now a mark, in bleached linen against the oxblood,
which is what the board's banners carry.

### 13 — The wall foot

Nine rock anchors on the three wall feet the judged stands actually look at,
derived from the chambers' own `at`/`size` plus wall thickness rather than
eyeballed. The judge was explicit this can be scatter, not meshes, so it is the
layer that already owns loose stone, using the anchor mechanism it already uses
sixteen times.

`min_slope_deg` is overridden to 0 on all nine and that override is load-bearing:
the layer's own floor is 6°, and a wall foot is flat made ground, so without it
every draw is rejected and the anchors render nothing at all.

---

## 4. What this lane did NOT fix

Stated plainly so the next lane does not have to rediscover it.

- **Ambient occlusion (defect 4).** Cannot be delivered from config under this
  renderer — see §0.2. Sun shadows are the only contact this build has, which is
  why the actionable part turned out to be `path_stones`' `casts_shadow`. Real
  contact occlusion needs baked AO or contact geometry, or a renderer change
  (D01, locked).
- **The floating plinth in `H-06` (defect 6).** Confirmed present at 4× — a
  cobble ledge with grass visible behind and under its outer end. Not chased:
  it is a skirt-facing/terrain interaction that wants its own diagnosis, and the
  lane's budget went to the two defects ranked above it. The rubble skirt (§3.13)
  lands near it and may partially disguise it, which is **not** the same as
  fixing it.
- **The emissive quad clipping in `H-07` (defect 9).** Not chased.
- **The cable anchors (defect 9).** Not chased.
- **The stone material itself (defect 3's other half)**, ivy/overgrowth, the
  retrofit props, the broken wall-top set, the arch and portcullis, a roof asset,
  cloth-shaped banners, and a courtyard dressing set. These are JUDGE-6's second
  list. They went to the owner and this lane deliberately did not work around
  them — the one thing done in that neighbourhood is texturing the spire cap and
  roofs with the already-installed `T_UnevenBrick` (`ROOF_WEATHER_MATERIALS`),
  because "the worst individual asset in the set" was flat-shaded purely because
  the pass that textures this kit was stone-only and could never reach `Celing`.
  That is the scene-side half; it is not the roof asset the judge asked for.
- **The tree leaf-retint spread.** `CommonTree_2` at #325f3c is dark enough that
  in shade it goes near-black. Left alone deliberately: recolouring a species to
  hide a lighting problem is the wrong lever, and the ambient fix addresses the
  cause. If it still reads badly, that retint is where to look.

---

## 5. Budget

- **Draw calls: 3365** at `hall_approach` against `docs/PERFORMANCE_BUDGET.md`'s
  4000 ceiling — 16% headroom. Measured with `tools/perf_render_stats.gd
  --views=hall_approach` in the shipping configuration (`scatter_lod_ranges=false`).
- **Scatter placements: 826,892 → 837,204** against
  `test_scatter_perf_budget.gd`'s 900,000 — 63k headroom. The +10,312 is the
  wall-foot rubble, the mid-distance anchors, and the rng-stream shift those
  cause. Note for the record: the reverted band-5 density experiment briefly took
  this to 874,616, i.e. 97% of a guard whose job is catching runaway density.
- **Exterior omni lights: 18**, exactly the ceiling `_comment_braziers` states.
  No lights added — see §0.5.

---

## 6. Frames

`ralph/reports/T1-HALL-4/shots/` — all eleven stands, re-rendered on this branch,
`tools/capture_check.gd` clean on every one.

`ralph/reports/T1-HALL-4/EVIDENCE-band5-density-0.22-occludes-the-reveal.png` is
not a stand: it is the rejected density experiment, kept because it is the
evidence for why that lever is closed.

---

## 7. Honest assessment for the next blind pass

Defect 1 is fixed and the number is the keyart's. Defects 3, 6, 7, 11, 12 and 13
are addressed. Defect 5 is corrected back to roughly parity after this lane
briefly made it worse. Defects 8 and 9 are declined with measurements that
reproduce the judge's own pixel figures.

**A third blind pass will most likely still answer No, and it should.** The
reasons are on JUDGE-6's own second list and are unchanged by this lane: the
stone material still has its highlight baked into the albedo with no per-stone
variation; there is no ivy, no timber-and-iron retrofit, no broken wall-top set,
no arch or portcullis, no roof asset, and no cloth-shaped banner. Those were
routed to the owner and this lane deliberately did not work around them. The
mid-distance will also still read thin, and §1b explains why roughly half of it
cannot be fixed without a world-extent or composition decision.

What has changed is that the fortress is now findable, dark, coherently coursed
in one stone, and lit by fires that pool. That was the assignment; the rest is a
purchase order.
