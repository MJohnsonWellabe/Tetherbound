# HANDOVER — T1-HALL-4, 2026-08-30

**Branch:** `ralph/T1-HALL-4`, off `origin/ralph/T1-HALL-3`.
**Brief:** the fifteen scene fixes in `ralph/reports/JUDGE-6-2026-08-30.md`, which
answered both bar questions **No**. The second list in that report — the one that
needs art nobody has built — went to the owner and is deliberately untouched here.

**Headline, the number the lane was asked for:**

> *(filled in from the rendered frames — see §1)*

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

## 1. The headline defect: silhouette contrast

*(filled in from the rendered frames)*

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

### 2 — The bald mid-distance *(ranked 2nd)*

**The hard cull line was never a content gap.** The trees past 260 m existed and
were being distance-culled by `vegetation.gd`'s `lod_range`, which feeds
Terrain3D's own `instance_geometry_set_visibility_range`. `H-02b`'s subject sits
165 m from the stand and the horizon runs several hundred metres beyond, so the
cull was landing in the middle of the chapter's establishing shot. Six layers
raised — trees 260→620, grove 220→520, rocks 150→360, bushes 110→300,
saplings/deadfall →320 — with fade margins widened so the new edge is a fade and
not a second hard line. The five sub-metre ground layers are deliberately not
raised: a 0.4 m tuft at 300 m is smaller than a pixel and would spend render
budget for nothing.

**And the ground past it gets content.** Band 5's `density_scale` 0.07 → 0.22.
The two existing notes on that number are about the *drain* contrast, and raising
the healthy floor strengthens both sides of that comparison rather than weakening
it — but see §5, this spent most of the bake's remaining headroom.

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

- **Scatter placements: 826,892 → 874,616.** `test_scatter_perf_budget.gd` allows
  900,000, so band 5's density spent 47,724 of the 73,108 that were free and
  leaves **25,384**. That guard exists to catch an accidental density explosion,
  and at 97% of its ceiling it can no longer catch much. Keeping the density —
  the growth is authored and measured, which is the condition that comment sets —
  but **the next lane that wants density here needs a deliberate look at the
  ceiling, not another guess from this bake.**
- **Draw calls:** see below.
