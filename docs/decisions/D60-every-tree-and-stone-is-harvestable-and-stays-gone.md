# D60 — every tree and stone is harvestable, and a chopped one stays gone

## Context

Owner directive, 2026-08-17, verbatim: *"every tree and stone asset we place
should be harvestable. once it's chopped it should disappear and not
regrow. they should be very frequent. whatever density palworld has."*

Before this, `data/config/vegetation.json` gave `trees` a `harvest_fraction`
of 0.083 (1-in-12) and `rocks` 0.071 (1-in-14) — across the pre-corridor
world, roughly 19 choppable trees and 30 gatherable rocks in the whole
playground. That sparsity is what prompted the directive. Harvesting itself
was also never permanent: `vegetation_harvest_point.gd::_on_gathered()`
dimmed its glint and the resource prop, then restored both after
`harvest_respawn_seconds` (120s for both layers) — a chopped tree stood
there the whole time, unharvestable-looking but never actually gone.

`VEG-CORRIDOR` (same day, `D57`) had just widened the scatter from the old
±256m square to the full ~8192×2048m corridor, taking the whole world from
26,985 to 102,192 instances. That is the lever this item tunes further for
trees and rocks specifically, and the lever it verifies stays affordable
under.

## Decision

Three independent changes, landed together on `ralph/HARVEST-ALL`:

### 1. `harvest_fraction` to 1.0 for `trees` and `rocks`

Both layers' `harvest_fraction` moved to 1.0. `vegetation.gd::_mark_harvestable`'s
existing stride mechanism (`stride = round(1.0 / fraction)`) already handles
this correctly at stride 1 — every placement in the layer gets marked,
verified directly (`tests/test_harvest_permanence.gd::
test_marking_gives_every_tree_and_rock_a_harvest_point_at_full_density`).
The stride mechanism itself was kept rather than special-cased away, since a
future layer could still ship at a fraction below 1.0 (a rare-resource
species) and it is exactly the lever for that.

**The glint marker's cost was NOT decided here — it is flagged, not
resolved.** `vegetation_harvest_point.gd`'s glint (two additive billboard
quads plus a 5-particle `GPUParticles3D` system per harvest point, each
building its own `GradientTexture2D`) was built when harvest points numbered
in the dozens, to solve a real problem then: distinguishing a harvestable
prop from a decorative one before the interact prompt appeared. At today's
density (2,848 wood points + 4,327 stone points = 7,175 total, up from ~49)
that marker has essentially no work left to do — nearly every tree and rock
in the meadow carries one, so "which ones glint" stops being useful
information. Construction cost was measured directly and is NOT the
concern: 500 harvest points built in 211ms (0.422ms/point), extrapolating to
~3.0s of extra boot time at 7,175 points — real, but small next to the
scatter's own ~60s. The unmeasured cost is RUNTIME rendering — roughly
14,350 always-on additive billboards plus ~35,875 orbiting particle
billboards, ticking every frame, on the software renderer this harness
cannot honestly time (D06) and the Ally this actually has to run on. **This
is a visual-affecting change and needs the blind pass before anyone decides
to cut or keep it** (`conventions.md`'s own rule) — raised here rather than
decided unilaterally. If it does get cut, the resource prop itself (the
woodpile, the rock already being a rock) is what should carry the "this is
gatherable" read at this density, not a marker on top of it.

### 2. Chopped stays chopped — permanent removal, persisted

This is genuinely two problems.

**Render removal.** The scatter renders through `Terrain3DInstancer`
(`OW5A`/`STREAM-SCATTER` — the file header's own MultiMesh framing predates
that swap and was stale by the time this item started; there is no
MultiMeshInstance3D here to rewrite a buffer on). `Terrain3DInstancer`
exposes `remove_instances(global_position: Vector3, params: Dictionary)`, a
brush-radius tool built for the editor's own erase-instances operation
(`asset_id`, `modifier_shift`, `modifier_alt`, `size`, `strength`, `slope`,
`on_collision`, `raycast_height` — recovered from Terrain3D's own upstream
source, since this vendored build ships no docs for it) rather than a
designed "remove exactly one instance" API: `strength` is a distance-
weighted removal PROBABILITY, not a guarantee, verified directly —
`remove_instances` at `size=2.0`, `strength=100` on a 1m-spaced test grid
removed only the exact-centre instance and left both neighbours (1.0m away)
untouched, even at maximum strength. Two scratch probes (a 1.0m-spaced grid
and a 0.3m-spaced grid — tighter than any real clump this scatter draws)
both confirmed that `size=0.05`, `strength=100`, called at the EXACT stored
position of the placement being harvested (never a player-aimed point),
removes exactly and only that instance. `vegetation.gd::
_remove_render_instance` calls it exactly that way — never with a
player-supplied position — which is what makes the probabilistic brush
semantics safe to rely on here: the near-zero-distance case is the only
case ever exercised, and that case measured reliable across both spacings.

Collision is separate (Terrain3D's instancer does not collide;
`vegetation.gd`'s own `StaticBody3D`/`CollisionShape3D` bookkeeping does) —
a new `_harvest_collision_lookup` (keyed the same way as the render lookup)
finds and removes the one `CollisionShape3D` and its `placements`/`resident`
array entries, in place, so `update_collision_streaming()` never tries to
stream a chopped instance back in.

**Persistence.** `_harvested: Dictionary[layer_name -> PackedByteArray]`, one
BIT (not one byte) per placement in that layer's own deterministic draw
order — sized once from the layer's own placement COUNT the moment
`_mark_harvestable()` runs, and never resized after. This is the bound the
owner's brief asked for explicitly: the record's size is fixed by the seed
and config (the scatter is deterministic — `VEG-CORRIDOR` already proved
and probed this for the corridor fill), so it cannot grow without bound no
matter how much the player chops — only which bits are SET grows, capped at
the world's own total harvestable count. An id list (the naive
implementation) would instead grow linearly with every chop, at several
times the per-entry cost of one bit.

Saved as `harvested_vegetation: Dictionary[layer_name -> base64 bitset]` on
`GameState`, VERSION 10 of `scripts/save/save_game.gd`'s format
(`_migrate_v9`: a pre-VERSION-10 save has nothing chopped, migrates to
`{}`). `vegetation.gd` joins the `"harvest_state"` group (mirroring
`build_placer.gd`/`player_death.gd`'s own group-based sync/restore split):
`sync_state_to_game()` writes the bitsets right before every save,
`restore_from_game()` re-applies them on top of a fresh (nothing-chopped)
`build()` — called once at boot (`playground_world.gd::_dress_the_meadow`,
for a "Continue" scene load where `Game` already holds a loaded save) and
again by `GameState.load_game()`'s own group loop (a mid-session "Load").

`restore_from_game()` deliberately never un-chops: a bit already set
locally (this session's own chopping) that is absent from a LOADED save is
left exactly as it is. Loading an older save mid-session does not bring
back a tree chopped after that save was written — that is not a gap, it is
the directive taken literally: chopped stays chopped regardless of which
save gets loaded on top, not merely across a normal reboot. A bitset whose
byte length does not match the layer's current placement count (a config
edit changed the layer under the save) is discarded rather than
misapplied, the same "trust nothing that doesn't validate" rule
`map_state.gd`'s own grid descriptor check already uses for its fog bytes.

### 3. Density — trees and rocks specifically, not everything

`VEG-CORRIDOR`'s `corridor_bands` table (`density_scale`, shared across
every layer that opts into `corridor_fill`) and each layer's own
`corridor_fill.density_scale` (a per-layer multiplier, clamped 0..1) are
both already at their ceiling for `trees`/`rocks` (1.0) — raising either
would raise every ground-cover layer that shares the same band table
(grass, bushes, flowers, drygrass), which is explicitly NOT what was asked
for ("raise trees and rocks specifically, not everything").

`scatter_rules.gd::_place_corridor_fill` draws its candidate count
proportional to the LAYER'S OWN `clumps`/`per_clump`/`strays` fields (`
candidate_clumps = round(clumps / origin_area * corridor_area)`, similarly
for strays) — the corridor fill and the old square scale together off the
same base density. Raising `per_clump` and `strays` for `trees`/`rocks`
specifically (4x each: trees 16→64/22→88, rocks 9→36/130→520), while
leaving `clumps` (how many copse CENTRES exist, already tuned across five
visual passes) untouched, thickens the existing copses and the corridor's
own fill together, without touching any other layer's density or the
shared band table.

**Measured, not assumed** (`scatter_rules.all_placements()`, same
methodology `D57` used):

| | trees | rocks | world total | compute |
|---|---|---|---|---|
| before | 830 | 1,098 | 102,007 | 59.5s |
| after | 2,848 | 4,327 | 107,254 | 61.6s |
| factor | 3.4x | 3.9x | 1.05x | 1.03x |

Trees and rocks alone were a small fraction of the corridor's total
instance count (dominated by grass/flowers/drygrass), so a 3-4x increase in
the two harvestable layers moves the WORLD total by only ~5% and compute
by ~3%. There is no boot-budget concern here — this is well inside the
headroom `D57` already measured (real end-to-end boot 68.4s→117.4s against
`EXP1`'s 420s allowance), and this change adds a few percent of scatter
compute on top of that, not a multiple.

This did NOT preserve `VEG-CORRIDOR`'s "old square placements are
bit-identical" invariant for `trees`/`rocks` specifically —
`tools/_probe_veg_corridor_perf.gd` will show real diffs on those two
layers if run against this change, and that is expected: raising a layer's
own `clumps`/`per_clump`/`strays` changes its RNG draw sequence everywhere,
inside the old square included, and the directive is about density
everywhere those two layers grow, not just past 512m. The invariant that
probe protects (VEG-CORRIDOR's OWN corridor-fill mechanism never touching
the square) is unaffected; it is this item's separate density edit to the
base layer config that legitimately moves those positions, same as any
other density retune of `clumps`/`per_clump`/`strays` always has.

## What this does not do

- It does not decide the glint marker's fate at this density. Flagged above,
  needs a blind pass, not decided here.
- It does not attempt to solve resource exhaustion. See "Consequence" below —
  recorded for the owner, not solved.
- It does not touch `harvest_node.gd`'s ~10 authored tutorial spots, which
  keep their own separate respawn behaviour unchanged — this item is scoped
  to `vegetation.gd`'s own scattered-instance harvesting (R2.3), not the
  authored spots.
- It does not wire permanent harvesting to `SG46`/D41's drain-and-regrow
  system (Team Tether stations killing and later healing vegetation) at all
  — the two are orthogonal by construction (drained placements are thinned
  out of `by_layer` before `_mark_harvestable` ever sees them, so a drained-
  then-regrown tree was never in this item's own `_harvest_lookup` to begin
  with). A tree that is BOTH inside a station's drain radius AND gets
  harvested before the station ever activates is an edge case neither
  system currently reasons about together; not solved here.

## Consequence: wood and stone are now finite, stated plainly rather than solved

Permanent removal at real density is still permanent removal. A player who
clears a region's trees and rocks has, for that region, removed the
resource for the rest of the save — Palworld itself respawns its trees and
ore; this build, on the owner's explicit instruction, does not. At roughly
40 minutes of play end to end (the chapter's own target, `D42`), a player
who chops aggressively near the start may find a nearby stretch bare with no
convenient replacement close by, particularly once neighbouring bands are
authored more sparsely than Band 1/2 (`corridor_bands`' own `density_scale`
0.03 for bands 3-5 today). This is the owner's decision, made with the
tradeoff in view ("no regrowth" was said plainly, not implied) — recorded
here so it can be revisited with real numbers (average trees-per-minute
chopped, a real playtest's actual exhaustion radius) rather than a hunch, if
it turns out to bite.

## Verification

`tests/test_harvest_permanence.gd` (new): the bitset helpers (`_bitset_bytes`/
`_new_bitset`/`_bit_get`/`_bit_set`), `_mark_harvestable` stamping a stable
`harvest_layer`/`harvest_index` on every placement and marking 100% of
`trees`/`rocks` at the new fraction, `harvest_permanently()`'s bit-setting/
idempotency/lookup-forgetting, `sync_state_to_game()`/`restore_from_game()`'s
round trip including the "never un-chops" and "discards a mismatched-size
bitset" rules — all exercised at the data level (no live `Terrain3D` node,
so `_remove_render_instance`'s `_instancer == null` guard makes render
removal a safe no-op and the tests stay fast).

`tests/test_save_format.gd`: VERSION 10 round-trips `harvested_vegetation`
(`test_save_then_load_round_trips_permanently_harvested_vegetation`) and a
VERSION 9 fixture migrates to nothing-chopped
(`test_v9_save_migrates_with_nothing_harvested`); `test_every_readable_
save_version_actually_loads`'s existing version-sweep exercises the new
migration step automatically.

`tests/test_harvest.gd`, `tests/test_gather_point_props.gd`: unchanged
behaviour re-verified green (harvest points still stand a real woodpile,
the tool-gating/durability rules are untouched — only the post-gather
outcome changed, from dim-and-respawn to permanent removal).

Full suite: run before push, see `ralph/NOTES.md` for the count.
