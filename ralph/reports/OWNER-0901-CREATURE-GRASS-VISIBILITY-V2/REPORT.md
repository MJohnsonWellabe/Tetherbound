# OWNER-0901-CREATURE-GRASS-VISIBILITY-V2

Branch `ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2`. Owner, 2026-09-02,
after the first `OWNER-0901-CREATURE-GRASS-VISIBILITY` fix had landed and
grass had come back on: **"small creatures in grass still want fixed.
they're not super visible."**

## Conclusion first

**This branch closes the silhouette. It does not close the whole complaint.**

- Shipped: a wild creature is no longer spawned on top of a bush it cannot
  be seen through — the specific defect that made a creature genuinely
  *invisible*, not just hard to spot, and the one two independent judges
  named as the dominant cause.
- Still open, filed as a named follow-up with its own evidence attached
  rather than bundled here: once the silhouette is intact, the creature's
  own colour/value contrast against the field is still weak at a glance,
  especially in local shade — a 30%-scale thumbnail comparison of the
  fixed case is still a faint smudge, not a clean readable shape. That is a
  *different* defect (creature material value/saturation, possibly a rim or
  contact shadow) needing its own pass, not something this branch's levers
  reach.

Do not read "the branch landed" as "the owner's complaint is fully closed."
It is not. What follows is the evidence for both halves.

## Two different things are both called "bushes" — read this before touching grass or scatter again

This cost real time on this branch and will cost the next person the same
if it isn't flagged plainly:

- `data/config/grass_field.json`'s `cover_tiers` has an entry named
  `"bushes"` — small procedurally-generated shrubs, part of the real-time
  camera-relative grass field, GPU-hashed from world position every frame.
- `data/config/vegetation.json` **separately** has a top-level layer also
  named `"bushes"` — real GLB assets (`Bush_Common.gltf` and siblings),
  placed once and baked into `data/scatter/**` at world-build time.

They share a name and nothing else. `grass_field.gd`'s existing
`CLEAR_GROUP`/`built[]` clearing mechanism (the one buildings use so grass
doesn't grow through a floor) reaches the first and has **no path at all**
into the second — confirmed on this branch with a real before/after render
that came back pixel-identical in the bush region. The coordinator's own
worst-case creature-visibility example (a creature standing inside a real
bush) turned out to be the *second*, statically-baked kind. A lane that
reaches for `grass_field.gd`'s clearing mechanism to solve a "creature is
inside a bush" complaint will hit the same wall this branch did.

## Why the first fix (`field_emission` alone) didn't hold

`OWNER-0901-CREATURE-GRASS-VISIBILITY` (`bbfaaa2d` etc.) tuned
`bramblebun`/`terrapup`/`mudsnout`'s `field_emission` against a
creature/grass luma-ratio target, measured with `grass_field.enabled`
**false** the whole session (confirmed: the probe's own "grass field
re-bound" log line, which only prints when the field is actually bound, is
absent from that fix's saved evidence, and its "before" luma numbers match
a field-off baseline far more closely than anything measured with the field
on). The fix was tuned and judged against baked scatter standing in for
"grass," not the real-time carpet the owner actually plays against — which
is why hitting its own numeric target still read as unfixed in the build he
had.

## Root cause, in the order it was actually found

1. **Re-measured with the field really on** (`ralph/reports/hud-catch/repro_grasson/`):
   `field_emission` alone is a real, if modest, improvement — not nothing.
2. **Pixel-matched before/after comparison** showed most of the strongest
   green in these frames sits at screen positions that are pixel-identical
   whether the creature's own material changed or not — i.e. it belongs to
   real foreground grass/plant geometry standing between camera and
   creature, not to the creature's own surface. No per-species albedo lever
   can move those pixels.
3. **Added `field_degreen`** (below) for the fraction of the problem that
   *is* the creature's own material — real, measured improvement, confirmed
   by an independent blind visual-judge pass, but explicitly called
   "modest, not dramatic," closer to a value-contrast read than a real
   hue-contrast pop.
4. **A coordinator-run density ladder + two independent judges** then found
   the dominant cause directly: the creature was standing *inside* a real
   bush, silhouette completely broken by leaf geometry in front of it — no
   material tint reaches that, and grass density was not the lever either
   (tested A-75k/B-150k side by side; the difference is near-field-only and
   the meadow's own bigger defect, per the note at the end of this report,
   is the blade shape, not the count).
5. **Reached for `grass_field.gd`'s existing clearing mechanism** — proved
   it cannot reach a statically-baked bush at all (the two-things-named-
   "bushes" collision above), and separately carried a real, unmeasured
   performance risk (`grass_field.gdshader`'s per-vertex loop is only cheap
   because `built_count` is zero almost everywhere; joining all 200+ wild
   individuals to the group would have made it non-zero across most of any
   populated band). **Reverted, not shipped.**
6. **Fixed it as spawn siting instead**: don't put the creature there in the
   first place. Real fix, verified against the exact reproduced case.

## What ships

### `field_degreen` — the colour half

`scripts/creatures/creature_body.gd::_brighten_node()` gets a second,
independently opt-in per-species lever alongside the existing
`field_emission`: it suppresses the green channel's share of the same
brightness multiply, so a green-hued patch on a creature's *own* surface
shifts toward its coat's own warm tone instead of just getting brighter
without changing hue. Bramblebun ships `field_degreen: 0.75` (swept
0.0/0.5/0.65/0.8/1.0 against real grass-on renders — response is sharply
non-linear, 0.0/0.5 read almost identically and 0.65+ all land at
essentially the same strong warm/pink separation). Mudsnout, terrapup,
pipwing, sparkit are solid-coloured or blue/tan in their own reference art
(checked directly) and get no change — a no-op at 0.0.

Kept per direct instruction: harmless, the right axis for the contrast half
of the complaint, and it stays useful once the silhouette problem below is
fixed. **Not presented as sufficient on its own** — the blind visual-judge
pass that reviewed it called the result "modest," and a later sunlit
re-test (below) showed it can read as barely-separated to invisible
depending on lighting.

### Spawn siting — the silhouette half (the actual fix)

`scripts/world/vegetation.gd` gains a read-only query,
`has_solid_scatter_near(centre, extra)`, checking two sources:

- `_collision_batches` — trees/rocks/saplings/grove, which carry
  `collides: true` in `vegetation.json` and already have an authored
  `radius`.
- `_bush_positions` — a new, narrow position list filled alongside the
  existing `_instance_positions` for the `bushes` layer specifically,
  because **that layer carries `collides: false`** (a real, walk-through
  layer — the player is never blocked by it) and so was never in
  `_collision_batches` at all despite being the visually densest occluder
  in the set. `BUSH_VISUAL_RADIUS` (1.2m) stands in for the missing
  authored collision radius, derived from the layer's own measured raw
  glTF bounding box and widened past a bare edge-to-edge distance because
  `bushes` places in clumps (`clumps`/`per_clump`/`clump_radius`), not
  singly — a candidate just clear of the *nearest* bush is routinely still
  inside its neighbour's canopy, measured directly against a real dense
  pair 0.2m apart on this branch's own test site.

`scripts/combat/encounter_director.gd::_pick_clear_spot()` draws a
candidate spawn point the same way `_spawn_creatures()` always has (uniform
over the cluster disc's area, from the cluster's own seeded `rng`) and
retries — same `rng`, so the meadow stays seeded/deterministic — up to
`CLEAR_ATTEMPTS` (6) times if the candidate is inside solid scatter,
falling back to spawning anyway rather than never spawning: **a creature
that fails to appear is a worse defect than one that spawns partly
occluded**, so a cluster whose whole disc is unusually dense still gets its
creature on its last-tried candidate.

**Cost:** one query per creature at world-boot spawn time only (not
per-frame), no shader touched, no re-bake.

## Verification

**Detection bug caught and fixed before shipping.** The first version of
`has_solid_scatter_near()` only checked `_collision_batches` — a real bug,
not a naming slip: it silently returned "clear" for a point known to be
inside a bush, because `bushes` has no collision entry at all. Caught by
re-running the real algorithm against the exact reproduced case and getting
a suspicious result (`"picked spot after 1 attempt(s)...clear=true"` at a
point already proven 100% occluded) rather than trusting a plausible-looking
log line.

**Real geometry, not a guess, decided the radius and the test's own cluster
size.** `tools/_diag_bush_positions.gd` (fast, `--headless`, no render)
found this test site actually sits between a tight *pair* of bushes 1.4m
apart, and separately that this branch's own probe had been testing against
a 2.0m cluster-radius stand-in while real `band1_lower_meadows/spawns.json`
clusters range 0.0-22.0m, averaging ~13.7m — the tight stand-in made a
correctly-working retry look like it wasn't finding real clearance. Re-run
at a cluster radius (8m) nearer the real average: the algorithm finds a
spot with genuinely more clearance from the same dense pair.

**Before/after against the exact reproduced worst case**
(`ralph/reports/hud-catch/grass_spawn_siting/`):

- `bramblebun-before-unsited.png` — the known-occupied point: creature
  **0% visible**, fully inside opaque bush canopy.
- `bramblebun-after-sited-aimed-at-spot.png` — the real retry algorithm's
  picked spot (5.3m away, clear per `has_solid_scatter_near()`), camera
  re-aimed directly at the new position: the creature's silhouette is now
  **intact and discernible** — ears, rounded body outline all readable.
  Real, provable improvement from 0%.
- `thumb-30pct-before.png` / `thumb-30pct-after.png` — the honest
  thumbnail-scale check, exactly as asked. Before: a total absence, nothing
  to see. **After: present, not absent, but still a faint smudge rather
  than a clean shape at this scale.** The picked spot happens to sit in
  tree/fern shadow, and `field_degreen` was tuned and verified against full
  sun — it reads as a dark, low-value blob in shade rather than the bright
  pink it produces in direct light. **This is the open half of the
  complaint**: the silhouette is no longer broken, but creature-vs-ground
  contrast, particularly in partial shade, still needs its own pass. Filed
  as a follow-up with this evidence attached rather than pursued further on
  this branch, per direct instruction.

**Tests, on the final merged tree:** `tests/smoke_art.gd` (`art: OK`),
`tests/run_tests.gd --only=creature,test_evolution_links.gd,test_creature,
test_grass_field.gd,test_wild_alphas.gd` (77 tests, 88,030 assertions, 0
failed).

## The `grass_field.gd` clearing lever was tried and reverted — read this before re-adding it

A local-suppression lever (joining every creature body to `grass_field.gd`'s
existing `grass_clear`/`built[]` group) was implemented, then fully removed
from this branch. Two independent reasons, both real:

1. **It cannot reach the bush that actually caused the complaint** — see
   "Two different things are both called bushes" above. Proved with a real
   render, not inferred: with-vs-without frames at the exact occluded site
   came back pixel-identical in the bush region.
2. **Unmeasured but real performance risk.** `grass_field.gdshader`'s
   per-vertex loop is only cheap because `built_count` is zero almost
   everywhere in the corridor — its own comment says so. The Meadows
   carries 200+ wild individuals; joining all of them unconditionally would
   have made `built_count` non-zero (and `built_bounds` wide) across most
   of any populated band, on the exact draw the ~10 FPS handheld
   game-breaker traced to. A proximity-gated version (piggybacking
   `encounter_director.gd`'s existing per-cluster streaming activation) was
   built to address this, but became moot once (1) proved the whole
   mechanism doesn't solve the reproduced case anyway.

Nothing of this remains in the diff. `field_degreen` is the only creature-
material lever this branch ships.

## Not touched

`data/config/grass_field.json` and `vegetation.json` — no density, radius,
or suppress-layer values changed anywhere in this branch, including during
a grass-density-ladder side quest (see below) that was killed before
producing a recommendation, per direct instruction to leave the density
decision to the owner.

## Side quest: the density ladder (decided, not this branch's call)

A separate, time-sensitive owner request arrived mid-branch: render a
four-step grass density ladder (75k/150k/225k/300k tufts) so the owner
could pick a density with real frames in front of him, since
`OWNER-0902-GRASS-ON` had shipped a ~5x-cheaper field as a side effect of a
performance fix, not a separately-chosen look.
`tools/_capture_grass_density_ladder.gd` (one world boot, rebuilding only
the `GrassField` node between steps) completed and pushed steps A (75k) and
B (150k) before the density question was decided from those two steps
alone: **keep the shipped 75k config.** Two independent judges found the
density difference was near-field-only and not the actual lever for either
"does it look like the key art" or creature visibility — the bush-occlusion
finding above is what that judgment surfaced. C and D were never rendered;
the tool is left in the branch for a future density pass.

**For the record** (the meadow's own defect, not this branch's task, carried
here per instruction so it's on record): the two judges' single
highest-impact recommendation for the ground itself was that the
single-blade tuft reads as "hair on a lawn" against the key art's own
overlapping-blade reference (`docs/reference/moong-01-mounted-in-tall-grass.jpg`)
at any density tested — a clump card (3-5 blades per instance, wider base,
dark-to-light root-to-tip gradient, height variation) at the *current*
instance count was judged the fix, not more tufts. `grass_field.gd` is
VP-owned since PR #20; not this branch's task.

## Files

- `scripts/world/vegetation.gd` — `has_solid_scatter_near()`,
  `_bush_positions`/`BUSH_VISUAL_RADIUS`, `_layer_name_for()`. The actual
  fix.
- `scripts/combat/encounter_director.gd` — `_pick_clear_spot()`, wired into
  `_spawn_creatures()`'s existing per-creature spot draw.
- `scripts/creatures/creature_body.gd` — `field_degreen` lever only; the
  reverted `grass_clear` group-join is fully removed.
- `data/creatures/species.json` — bramblebun's `field_degreen: 0.75` +
  documented reasoning.
- `tools/_probe_grass_separation.gd` — `--extra-degreen=` sweep support.
- `tools/_probe_grass_sunlit.gd` — re-tunes/re-tests at a genuinely sunlit
  site after the first reproduction turned out to be shaded.
- `tools/_probe_spawn_siting.gd`, `tools/_diag_bush_positions.gd` — the
  spawn-siting fix's own verification (before/after, thumbnail, real-vs-
  test-cluster-radius geometry check).
- `tools/_capture_grass_density_ladder.gd` — density-ladder tool; density
  never changed.
- `tools/_dump_bramblebun_materials.gd` — throwaway, confirms the mesh's
  single-material/single-texture structure.
- `ralph/reports/hud-catch/**` — every render referenced above
  (`repro_grasson/`, `repro_grasson_vp/`, `grass_sunlit/`,
  `grass_bush_clear/`, `grass_spawn_siting/`, `grass_density_ladder/`).
