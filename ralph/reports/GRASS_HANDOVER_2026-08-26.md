# GRASS — handover

`2026-08-26` · written for a successor with no memory of the session that
produced it · supersedes nothing; read it beside
`ralph/reports/WORLD_GRASS_2026-08-25.md` and
`ralph/reports/GRASS_FIELD_SPIKE_2026-08-25.md`, which carry the long-form
argument this file summarises.

---

## 1. The two branches, exactly

| branch | tip | state |
|---|---|---|
| `ralph/WORLD-GRASS` | `e213a7a4` | pushed. **Rebased onto `main` (`7c47b893`) by the coordinator, not by this lane.** Do not force-push over that rebase. Verified: the rebased tip differs from the pre-rebase local tip by `.github/workflows/ci.yml` only, so no lane work was lost. |
| `ralph/GRASS-FIELD` | `dd39381b` | pushed. Cut from `origin/main` at `636673ce`, sixteen commits. **Not yet consolidated into `main`.** |

`ralph/WORLD-GRASS` is the *scatter* lane: it tunes the existing stored-placement
ground cover — grass scale, a new `groundmat` mid-layer, flower drifts, verge
density — and corrects the record on `Terrain3DMeshAsset.density`.

`ralph/GRASS-FIELD` is the *generated* lane: a camera-relative shader carpet that
stores no placements at all. It is the branch with all of the recent work on it.

**A consolidation hazard.** `data/config/grass_field.json`'s
`suppress_scatter_layers` currently names `grass`, `drygrass` and `flowers`.
`ralph/WORLD-GRASS` adds a `groundmat` layer that the field also replaces.
**Whoever merges the two must add `"groundmat"` to that list**, or both systems
will dress the same ground. `tests/test_grass_field.gd` cannot catch this — the
name is real either way.

---

## 2. What the owner actually asked for

Read this section before deciding anything on this branch is drift.

The lane's written assignment was `docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md`,
priority order: grass reads as grass; grass survives into the middle distance;
mid-layer; flower drifts in clumps; mid-distance landmark. The owner's own words
were *"the grass feels most important to me."*

**Everything beyond prompt 72 on this branch was explicitly authorised by the
owner mid-session, in their own words.** It is not drift and must not be
reverted as such:

- *"can we generate stones and the dirt paths this way as well… move us more
  towards the palworld look"* → `shaders/stone_field.gdshader`, the gravel and
  path-grit tier.
- *"can you generate clouds this way too?"* → `shaders/sky_clouds.gdshader`.
- *"I thought you were going to make paths narrower?"* → `terrain_playground.json`
  `paths.width` 2.0 → 1.4 and `shoulder` 2.5 → 1.1, a 7.0m painted band down to
  3.6m. **This required a full terrain re-bake and a full scatter re-bake**, both
  of which are committed (`e29b2aed`, `3c35dc87`).
- *"we should add small bushes, flowers and forest litter then wind. then we
  should push to main. do each of those one at a time. at the end of it all do
  the visual review agent then push to main."* → `shaders/cover_tier.gdshader`
  and the three `cover_tiers` entries, plus the travelling gust on grass and
  flowers.

**One owner decision that outranks a critic.** The owner approved the grass look
at commit `7375246a` (11mm blades) with *"this look was pretty good to me"* and
*"I don't think you need to do much more with the grass"*. Two later rounds of
grass tuning were reverted on their instruction. Do not reopen blade width or
blade density on a critic's say-so; that is a settled owner call.

---

## 3. Settled findings — do not re-derive these

**A continuous carpet cannot be reached with stored placements.** Every
ground-cover instance is a stored transform. A tuft covers ~0.33 m², the
reference's carpet needs ~1.5 tufts/m², and the Meadows corridor is 16.8 km² —
about **25 million placements against a 900,000 chapter ceiling, roughly 40x out
however it is spent.** Three blind rounds ranked *"the player stands on a
painting of grass with props stabbed into it"* first every time, and no density
number ever moved it. This is why the shader path exists.

**`Terrain3DMeshAsset.density` is a paint-brush parameter, not a procedural
fill.** `WORLD_GRASS_2026-08-25.md` originally named it as the instrument that
could reach the carpet; that was wrong and the correction is committed on
`ralph/WORLD-GRASS`. Every `Terrain3DInstancer` entry point (`add_instances`,
`add_transforms`, `add_multimesh`, `append_location`, `append_region`) either
takes explicit transforms or generates them once and stores them in
`Terrain3DRegion.instances`. It costs exactly what we already pay. The addon
ships here as a GDExtension binary with no C++ sources vendored, so this was
established off ClassDB with `tools/_probe_terrain3d_api.gd` rather than from
source — that probe is the way to re-check any Terrain3D API claim offline.

**The path that works** is a camera-relative MultiMesh ring whose vertex shader
places each item on the terrain by sampling Terrain3D's own maps:
`Terrain3DData.get_height_maps_rid()` / `get_control_maps_rid()` /
`get_color_maps_rid()`, with `Terrain3DMaterial.get_shader_rid()` /
`shader_override` for reading the live material. Cost is a function of the ring,
not of the world.

**Three traps that each cost a render cycle. All three are commented in the
source; do not undo the comments.**

1. `get_index_coord()` is **copied verbatim** from Terrain3D's generated shader
   (pulled off the live material by `tools/_probe_terrain3d_shader.gd`). A region
   lookup that is subtly wrong **does not error** — it puts the cover a few
   metres underground and reads as "the shader doesn't work". Do not "clean it
   up"; the `search` loop handles region seams.
2. Terrain3D's colour map is a **near-white multiplier** (`#f7f8f2`, `#fbfbf6`),
   not a colour. Mixing *toward* it washes every base out to white. Multiply by
   it, which is what the terrain's own shader does.
3. **Godot rejects `return` inside `vertex()`** and fails silently — no compile,
   a default material substituted, and the raw mesh rendered at every instance as
   white shards filling the sky. It looks exactly like a broken height lookup.
   All three tier shaders cull with if/else for this reason.

---

## 4. `GRASS-FIELD` ships OFF, and that is not a lane's decision to change

`data/config/grass_field.json`'s `enabled` is `false`. `vegetation.gd` drops the
suppressed layers only when it is true, so the scatter path behind it is
completely intact and the A/B is one boolean.

`tests/test_grass_field.gd` fails if anyone flips it, and the failure message says
why: **no container in this project can measure GPU cost.** `PERF-ROG-GPU` records
that the Compatibility renderer counts MultiMesh batches rather than instances and
that this box rasterises in software. "It looked fine here" is not evidence about
the only hardware that matters. **Turning it on is an owner decision made against
an ROG Ally.**

The same test file also pins the rule that matters more: **nothing that collides
or is harvestable may ever be suppressed.** It reads `collides` / `harvest_item`
straight off `vegetation.json`, so a layer that gains collision later is covered
without anyone remembering. The field is the right instrument for what the player
walks *through* and the wrong one for what they walk *into* — trees, rocks and the
harvestable `bushes` layer stay scattered and are the landmarks the eye navigates
by.

`shaders/cover_tier.gdshader`'s header carries the general rule: a tier may be
generated only if it (a) does not collide, (b) carries no persistent state, (c) is
small enough that appearing at the ring's edge is invisible, and (d) exists in
numbers too large to store. Grass, gravel, litter, flowers and *decorative* bushes
pass. Trees and boulders fail (a)(b)(c). Harvestable bushes fail (b) — harvesting
needs an identity that survives, and a thing that does not exist until the camera
nears it has none.

---

## 5. The blind-pass record

**`ralph/WORLD-GRASS`: three rounds, converged WITHOUT passing.** Recorded as
`WORLD-GRASS-remainder` in `ralph/BACKLOG.md`, not marked done. The outstanding
defect is the scattered grass mesh being a *"flat two-tone polygon with no
base-to-tip gradient, no translucency, no ground blend"*. Note that **the
`GRASS-FIELD` shader answers both halves of that** — `UV.y` carries height along
the blade so the gradient is a `mix()`, and the base is multiplied by the terrain
colour map so growth comes out of the ground. If the field ships, that remainder
closes; if it does not, it needs art.

**`ralph/GRASS-FIELD`: one round on `shots/field_r4`** (recorded in
`GRASS_FIELD_SPIKE_2026-08-25.md`) and **one round on `shots/cover_final`**, the
twelve-frame set with every tier on. The second round's four in-lane findings were
all acted on in `dd39381b`; its out-of-lane findings are section 7 below.

**A protocol note worth keeping.** An early capture's low camera stood *on* the
travel route, so two critics measured road colour and reported that the meadow
rendered as trail. `tools/_probe_grass_field.gd` and `tools/_probe_grass_pass.gd`
now both shoot a third `-off` camera ten metres off-route. A camera standing on
the path photographs the path.

---

## 6. Measurement caveats — preserve these

- **No frame rate is claimed and none can be.** See section 4.
- **Band 4 measured 4.72 ms and 9.36 ms on the *same* config**, two runs of
  `perf_profile.gd`. Any per-site CPU claim from this container is noise. What is
  exact and unchanged: `scatter_solid` 51,511 and `harvest_points` 56,430 — every
  layer this lane touched is `collides: false` with no `harvest_item`, so the
  OP23-01 CPU win is not spent.
- The captures are **software-rendered under the Compatibility renderer**.
  Composition, density and silhouette are trustworthy. Frame times are not.
- Two briefing numbers were stale and are corrected: the placement cap is
  **900,000**, not 260,000, and the pre-existing bake was **466,922**, not
  144,456.
- **Inserting a layer into `vegetation.json` re-seeds every layer after it**
  (`base_seed + INDEX * 7919`). `groundmat` is appended *last* on
  `ralph/WORLD-GRASS` for exactly this reason. Append; do not insert.

---

## 7. A CI cost this lane caused, and hands on

The denser bake took placements **466,922 → 725,949**, which pushed
`tests/test_veg_corridor.gd` to **10m11s**, over the 12-minute shard ceiling on
`verify-unit-tests`. The coordinator has split that file into its own 25-minute
job on `ralph/UNITTEST-VEG-CORRIDOR-SPLIT`.

**A successor must know that this file's runtime tracks vegetation density.** Any
further density increase needs re-timing before it lands. The narrowed paths later
took the bake to 479,881 on `ralph/GRASS-FIELD` (paths exclude less), which is a
further increase over that baseline.

Related: `data/scatter/manifest.json` carries a **fingerprint over
`vegetation.json` + `terrain_playground.json` + the band vegetation files**. Any
edit to those invalidates the bake and fails `test_scatter_perf_budget`'s
freshness assertion. Edit them and re-bake in the same commit, or the tree between
the two commits is red.

---

## 8. What I was mid-way through

A four-band capture into `shots/cover_final2` was in flight at stand-down, shooting
the state at `dd39381b`. It is a verification capture only; nothing depends on it.

**The owner saw the first band-1 frame from that state and gave live feedback:**

> *"the sky looks better. the bushes still suck and the transition from real grass
> to paint is still very noticable"*

That is the top of the next-steps list, and both halves have a diagnosis rather
than a guess behind them.

---

## 9. What I would do next, in priority order

**1. The bushes — give the leaf a leaf-shaped silhouette.**
This has now failed four rounds and every one of them was the wrong instrument:
five big crossed panels, then twenty quads, then forty-four small leaves, then
softened normals and a lifted base tint. Each helped and none fixed it, because
the defect is not size, count, tint or lighting. **Each leaf is an opaque quad
with a hard rectangular silhouette, and no amount of lighting makes a rectangle
read as a leaf.** A blind critic's words on the current mesh: *"a heap of large
untextured flat quads in three flat greens, hard-edged, many detached and floating
with no stem."*

The fix is an **alpha cut in `cover_tier.gdshader`'s fragment stage**, shaping the
mask procedurally from `UV` so each quad becomes a ragged leaf outline. The shader
already runs `depth_prepass_alpha` with an `ALPHA_SCISSOR_THRESHOLD`, so the
machinery is present and `ALPHA` is currently hardcoded to 1.0. This costs **no
asset**, which matters: `CLAUDE.md` forbids new Meadows art and the previous
critic round filed "needs a bush asset that is not loose quads" as an art gap. It
is not an art gap; it is four lines of fragment maths.

**2. The grass-to-paint transition — fade height, not just density.**
Pushing `field_radius` 56 → 72 with a 30m fade moved the seam without removing it.
Two separate things make it visible and both need doing:
- `v_fade` gates a fragment `discard` and `keep` gates a vertex cull, so blades
  *thin* toward the edge at **full height** and the carpet stops rather than
  sinking. Multiply the blade height `h` by `v_fade` (or by a power of it) so the
  carpet grows down into the terrain instead of ending.
- The terrain past the ring is a painted colour that does not match the tier's own
  green, so the boundary is a *material* edge as well as a detail edge. Tint
  `terrain_playground.json`'s grass colour map toward `grass_field.json`'s
  `tint_tip`. The colour map is a multiplier (section 3), so this is a small
  multiply, not a repaint.

**3. Re-measure the value range rather than re-arguing it.**
`art.json`'s `ambient_energy` went 1.5 → 2.1 this session because a critic
measured the darkest 1% of six frames clipping to literal 0.0 against a Palworld
floor near 30/255. **An earlier round CUT this number** because a different critic
had measured the darkest 5% at 126, far too bright. The file has oscillated here
before and the two complaints are about opposite ends of the range. Use
`tools/frame_stats.py` and settle it with a measurement.

**4. Consolidate.** Add `"groundmat"` to `suppress_scatter_layers` (section 1),
get `ralph/GRASS-FIELD` green, and dispatch `ralph-sweep.yml`. **Never push to
`main` directly.**

**5. Out of this lane, but recorded because a blind pass found them and they are
real** — a successor should file these rather than fix them here:
- the trainer is **duplicated and airborne** in both band-4 frames, one copy ~2m
  above the other with the upper figure's shins intersecting the lower's head;
- the band-3 house **floats**, with sky visible under half its plinth, and is
  **4–5x oversized** against the trees on its own knoll;
- every trunk in bands 2–4 is one flat salmon-terracotta cylinder, which is the
  single thing making the forest read as a different project from the art board;
- the oxblood reserved for Team Tether has **leaked onto a boulder** in band 1;
- **bands 2 and 4 are indistinguishable** — "high pasture" is a forest;
- water is a flat plane with no specular, wave normal or shoreline;
- a straight dotted **terrain chunk seam** is visible in four frames;
- **no creature appears in any of the twelve frames** of a creature-training game.
  The critic ranked this its number-one gap from the bar and could not tell
  whether creature art exists and was not placed, or does not exist. Establishing
  which is worth doing before the next visual round.
