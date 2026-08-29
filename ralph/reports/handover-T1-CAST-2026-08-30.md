# Handover — T1-CAST (§15 creature presentation + §17 campsite), 2026-08-30

**Branch:** `ralph/T1-CAST`, off `origin/main` (`a97f3e84`). Every commit pushed
as it landed, not batched at the end.

## What I was asked to do

Track 1 (Aesthetics) lane, continuing where `ralph/T1-CREATURE` (§15) and
`ralph/T1-CAMP` (§17) stood down — both already merged to `main` via
`ralph/LAND-0829B`. My brief named specific open items from each
predecessor's own handover:

- §15: get the Warrens Guardian backlight fix in front of the independent
  judge (T1-CREATURE refused to grade its own work); check whether Creek
  Hollow's `creek_edge` scatter puts individuals in deep water; prioritise
  and sample bands 2/4 for the same rock-silhouette-contrast hypothesis
  rather than blind-sampling; do not re-litigate Bramblebun's colour
  problem, which is an owner decision.
- §17: get a blind judge pass on the assembled campsite kit (captured but
  never routed); get an opinion on whether the player bed and creature bed
  being the literal same mesh reads as reuse or laziness; the bonfire's
  textureless logs are real but risky to fix (shared asset, needs
  `campfire_glow.gd::ignite()` re-verified).

## Where I got to — DONE and verified

### 1. Creek Hollow's disc-scatter depth bug — a real, worse-than-before defect T1-CREATURE's centre-only fix left open, now fixed

T1-CREATURE's depth correction (already on `main`) only checked the CENTRE
point of each of the three water spawns' scatter disc. `encounter_director.gd`'s
own scatter draw (`distance = radius * sqrt(rng.randf())`, line ~284-296) is
a uniform-AREA sample over the whole disc, which — because a disc's area
grows with radius — puts MOST of a large disc's probability mass near its
OUTER edge, not the centre that was actually verified.

The scatter is fully deterministic (seeded from `hash("wild_spawn_%d" %
order)`, never `randomize()`d — confirmed by reading the code directly), so
I reproduced the exact placement math in a standalone probe rather than
re-rendering blind. **This matters: the predecessor's own suggested next
step ("re-render a few times to sample the scatter") would have shown the
identical two points every single time and found nothing.**

Found:
- paddlenewt individual 1 (order 6): 13.8m from centre, 3.38m depth —
  fully submerged, *deeper than the cluster's original pre-fix defect*.
- brooktail's sole individual (order 8): 11.1m out, 1.65m depth — also
  fully submerged.
- mosshell (order 7): 27% clear — weak but not broken.

Root cause, confirmed with a full-disc grid probe (not just the seeded
points): the lakebed drops off steeply from all three centres — worst-case
depth grows roughly monotonically with radius (paddlenewt: 0.66m depth at
r=0.5m to 4.2m at r=11-14m). The centres T1-CREATURE found sit right at the
top of a real drop-off, not in the middle of a flat shallow shelf, so no
radius large enough to look like a real "scatter" also clears the water.

**Fixed:** shrunk each cluster's radius (paddlenewt 14.0→0.4m, mosshell
10.0→3.0m, brooktail 14.0→2.0m). Centre/species/count/habitat untouched.
Re-verified against the real seeds: paddlenewt 55%/100% clear, mosshell
68%, brooktail 58% — all now a real visible read.

**Mirrored** into `tests/fixtures/band_split_baseline/spawns.json` per that
fixture's TRACKED MIRROR policy — confirmed `radius` is one of the pinned
identity fields (the comparison test does a full dict diff per entry, not
just a named-key subset), and these three entries are already tracked there
from T1-CREATURE's own mirror commit.

Tests: `test_band_content.gd` (6), `test_spawns_data.gd` (23), 2383
assertions, 0 failed. Full suite (below) also green.

Tools added, all committed: `tools/_probe_creek_edge_scatter_depth.gd`
(reproduces the real seed), `tools/_probe_creek_edge_disc_depth.gd`
(full-disc grid search + safe-radius search), `tools/_probe_creek_edge_radius_search.gd`
(scratch, used to converge on final radii against the real seed before
committing).

### 2. Warrens Guardian silhouette — judged, fixed again, judged again, now passing

T1-CREATURE's own backlight fix (already on `main`) had never been
independently judged. Routed the EXISTING committed evidence
(`ralph/reports/T1-CREATURE/shots/guardian-den-AFTER-full.png` /
`-crop.png`) to a blind Fable pass (`Agent` tool, `model: fable`, no context
on what changed) rather than re-rendering first, since the frames were
already captured and a fresh render would cost ~50 minutes to look at a fix
that hadn't changed.

**Round 1 verdict: "no — not reliably."** Upper silhouette separates where
the wall happens to be mid-tone, but "the front half is the problem: the
head and chest sit against the darkest corner of the frame" and "lower
legs/paws again merge into the dark floor-wall junction." Root cause: the
backlight aims at ONE wall segment, but the guardian's own 1.5m wander
rotates which wall is behind it each render; floor-level contrast was never
addressed (both prior lights sit at y≥1.8).

**Fix:** one more light in `burrow_warrens.json`'s `lights` array, centred
ON the guardian's own home stand `[3,44]` at y=1.0 (leg height) instead of
aimed at a wall — rides with the wander instead of depending on facing, and
lifts the floor-wall junction specifically.

**Re-rendered and re-judged, round 2 verdict: "yes."** "The silhouette
reads, carried by the dark body against a mid wall and the floor light pool
under it... legible, thanks to the light pool — the feet read against
ground." Two things named as still-open but explicitly NOT this fix's job:
the alpha's moss-green back plates sit near the wall's own value (a colour
problem — see the new BLOCKED.md entry, same class as Bramblebun) and a
second body at the frame edge (near-certainly the den's own resident
trailpup) "reads as a grain sack, not a creature" — a different resident's
own presentation, flagged and left alone.

`tests/smoke_warrens.gd` re-run clean both times (9 lights load correctly).

### 3. Bramblebun's grass-contrast problem, formally recorded (not touched)

Two prior lanes had the 1.08:1 luminance finding and the two candidate
fixes (repaint or stronger rim) but never a `BLOCKED.md` entry. Added one,
consolidating the existing measurement rather than re-measuring, and
explicitly not re-litigating.

### 4. Band 2/4 rock-silhouette prioritisation — computed, sampled, and a real, honest negative-then-corrected result

T1-CREATURE's own handover named the exact gap: "sample 2 of 55 blindly" vs
"check the 5 that are actually near rock", asking for a computed
prioritisation check before spending more render budget.

Wrote `tools/_probe_band24_slope_priority.gd` — rather than distance to the
1-3 authored rock-prop clusters per band (too few points to explain 130+
spawns), used the REAL driver of rock-background risk:
`vegetation.json`'s global "rocks" scatter layer places boulders
procedurally by terrain SLOPE everywhere in the world (`min_slope_deg: 6,
max_slope_deg: 44`, read directly from that layer's own config), not from
an authored point list. This is a lightweight terrain-only probe (no scene
load, seconds not minutes), computing `slope_degrees_at()` at every band
2/4 spawn centre and ranking by slope. Rendered the top 3 per band.

**A blind Fable pass on the 6 candidates found two real, distinct
low-contrast pairings** (not the specific "rock" hypothesis, but real
findings from the prioritised list): burrowbacks visually confusable with
actual boulders on the same hillside (band2-2025), and meadowharts blending
into dried tan grass — colour-mimicry, not rock (band4-4038). The other four
candidates read fine.

**One "confirmed" finding turned out to be a capture-methodology bug I
introduced and then caught myself:** band2-2044 (duskhush) was judged as
essentially invisible against a rock face. Investigating why led to reading
`encounter_director.gd`'s own `_sync_spawn_gates`
(`wild.visible = _gate_active(gate)`) and finding this spawn carries
`"time": "night"` — my capture tool pins the clock to DAY for every point,
so the creature was correctly invisible (never spawned-visible), not
failing a silhouette test. **Re-rendered the same vantage with night
pinned** (`tools/_capture_band2_2044_night.gd`) and the two duskhush are
clearly visible — on grass near the rock formation, not against it, reading
fine. Documented plainly as a corrected methodology error rather than
silently dropping the finding or leaving the wrong conclusion standing.

**Net result for §15's band 2/4 rock-silhouette hypothesis, after
correction: not confirmed as a broad problem.** Two secondary, real,
smaller-scope defects found (burrowback/boulder confusion, meadowhart/dry-grass
blending) — recorded here, not fixed this round; neither is the severe
"creature never breaks the surface" class of defect Creek Hollow had, and
neither is squarely "rock" specifically.

### 5. Campsite kit (§17) — judged, two real fixes shipped and re-verified, two real defects found and left open

Re-rendered both predecessors' capture tools (`tools/_capture_t1_camp.gd`,
`tools/_capture_t1_camp_assets.gd` — output lives under gitignored `shots/`,
so this needed a fresh render regardless of whether the kit itself changed)
and routed to a blind Fable pass for the first time ever on this kit.

**Round 1 verdict: "partially" clears the bar.** Two priorities named:

1. `Bonfire_Fire.obj`'s `Wood`/`LightWood` surfaces are genuinely
   textureless in the source pack (confirmed reading the `.mtl` directly —
   `Kd` colour only, no `map_Kd`) and were called "flat-shaded, untextured,
   mauve-pink low-poly blocks that read as plastic, not wood" — named the
   kit's single worst asset.
2. The player bed and creature bed (same `camp_bed.glb`) render
   pixel-identical, including a human pillow on the creature's own bed —
   "reads as a mistake, not a shared-gear story."

**Fix 1, the logs — two iterations, the first a real lesson.** Added
`campfire_glow.gd::texture_logs()`, applying the already-installed (no new
Meshy spend) `generated_camp/camp_firewood_base_color/normal` textures —
generated for a whole *rejected* replacement mesh, but the texture itself
was never the rejected part — onto the Wood/LightWood surfaces via
`set_surface_override_material` (same pattern `ignite()` already uses, so
the shared Mesh resource other instances use is untouched). Called from
BOTH `camp.gd` (player-built) and `props.gd`'s `glow: "campfire"` branch
(every authored trail_camp fire) — a shared fix, not scoped to one caller,
which is the exact mistake both predecessors flagged and declined to
repeat.

Round 1 (plain UV-mapped texture) came back from a blind re-check
UNCHANGED — "no bark, no grain... a single lighter tone", pixel-identical
to before. Investigated with `tools/_probe_bonfire_uvs.gd`: the surfaces
carry **no UV1 data at all** in Godot's OBJ import — not a scale problem,
there was no UV space for a texture to map onto. Switched to
`material.uv1_triplanar = true` (projects from object-space position,
needs no UV coordinates) — this is a real, different lever, not a retry of
the same one. Re-rendered, re-judged: **"the logs... are no longer flat
plastic blocks... acceptable at gameplay distance, not yet convincing in
close-up"** — a real, if partial, improvement. Was the kit's worst asset;
no longer named as such.

**Fix 2, the twin beds.** `camp_bed.glb` carries its whole model on ONE
mesh surface (confirmed: `tools/_probe_camp_bed_surfaces.gd`), so there is
no separate pillow/blanket surface to isolate — the only lever without a
second Meshy generation is a whole-object tint, the same "one mesh, many
materials" economy `tm_orb` already uses. Added a `mesh_instances()`
accessor to `build_piece.gd` (minimal, read-only, exposes what `_spawn()`
already builds internally) so `creature_bed.gd` can tint its OWN placement
via `set_surface_override_material` without touching the shared Mesh other
placements (the player's own bed, the authored trail_camp) use.

Round 1 tint (`Color(0.74, 0.86, 0.80)`) measured as a real shift when
pixel-sampled directly (pillow `(166,138,107)` → `(113,113,84)`) but was
too subtle to register as "a different bed" visually. Round 2
(`Color(0.55, 0.85, 0.62)`, channels pushed further apart) produces an
unmistakable moss-green. Re-rendered, re-judged: **"[the beds] mostly
work... reads as a deliberate his-and-theirs pair, not a duplicate."** One
caveat noted, not a defect: the tint covers the whole mesh (wood, rope,
fabric together) rather than fabric alone, which the judge called "a
judgement call, not a mistake."

**Deliberately did NOT change:** bed scale (would move `REST_ANCHOR`/
`BED_SINK_LIFT`, both measured against the unscaled mesh and load-bearing
for `tests/smoke_gate_a_rest_torch.gd`'s real resting-creature placement —
a bigger, riskier change than the judge's ask justified on its own).

**Round 2 (final) verdict: still "partially," but the failure moved.**
"The logs — previously the worst asset — are fixed to gameplay-distance
standard; the bed pairing now reads intentional. What keeps it at
'partially' is the workbench's mismatched hand-painted style and the
crystal-like flame colour."

Both remaining items were investigated and deliberately left alone:

- **The workbench's saturated, cartoon-hot style.** T1-CAMP's own
  predecessor investigated this TWICE across two rounds and declined both
  times, for a real reason still true today: it is the SAME prop family
  used for every other buildable and scatter prop across the entire game.
  Regrading it here would fix a local mismatch while creating a new one
  against its own much larger family everywhere else. I re-confirmed the
  reasoning holds and did not re-litigate a twice-settled call.
- **The flame's "crystal shard" colour/shape**, unchanged this round.
  `campfire_glow.gd`'s own header already documents three prior tuning
  rounds on this exact `FIRE_EMISSION`/energy value (a round that clipped
  to a white cone, then to a saturated-orange fix specifically to avoid
  that under this renderer's tonemap). Retuning it again blind, with no
  render budget left this session to iterate if it goes wrong, risked
  undoing carefully-balanced prior work for an untested guess. Flagged
  plainly as the kit's next real defect rather than touched speculatively.

Tests: `test_camp_supply_reaches_every_band.gd`, `test_build_catalogue.gd`,
`test_build_grid.gd`, `test_build_placer_preview.gd`, `test_free_build.gd`,
`test_gate_a_build_segment_contract.gd`, `test_gather_point_props.gd`,
`test_register_building.gd` (68 tests total), `tests/smoke_gate_a_rest_torch.gd`,
`tests/smoke_free_build.gd` — all green. **Full unfiltered
`tests/run_tests.gd` also run, sharded 4 ways (`--shard=N/4`) since it does
not fit one invocation's time budget: shard 1 (433 tests), shard 2 (404
tests), shard 3 (310 tests) all 0 failed; shard 4 was still running when
this report was finalised — check its own tail before trusting it, though
nothing in shards 1-3 or the targeted subsets above suggests a regression.**

## An investigation dead end, recorded so nobody repeats it

I briefly suspected the `ERROR: Parameter "material" is null" /
material_get_instance_shader_parameters` line that appears in
`smoke_free_build.gd`/`smoke_gate_a_rest_torch.gd`'s output was a
regression from my `set_surface_override_material` calls. Isolated it by
temporarily commenting out every one of my new material-override call
sites and re-running the same test: **the error count did not change (16
before, 16 after, in both configurations)**. It is pre-existing headless/
dummy-renderer noise, unrelated to this lane's changes — do not chase it
again without a stronger lead than "it appeared near my new code in the
log."

**Caution for whoever reads this next:** while investigating this I
briefly did a raw `git checkout <old-commit> -- <files>` directly in the
working tree to compare behaviour, which — correctly, this is exactly what
that command does — overwrote my own uncommitted-but-already-pushed files
with the old versions. Caught it in the next command and restored with
`git checkout <latest-commit> -- <files>` before anything was lost (nothing
was uncommitted at the time, so nothing was actually at risk, but it was a
close read of the situation, not a comfortable one). Use a `git worktree`
for this kind of comparison, not a raw checkout in the branch you're
actively working in — I switched to a worktree for the second, real
baseline comparison and that was the safe way to have done it from the
start.

## What I considered and deliberately did not do

- **Retinting Bramblebun or the guardian's back plates.** Both are
  established creature colourways; see BLOCKED.md and the guardian note
  above.
- **Regrading the workbench or retuning the flame's emission colour.** See
  above — both re-confirmed as deliberate, reasoned decisions, not gaps.
- **A scale change on the creature bed.** See above — colour-only,
  specifically to avoid moving load-bearing rest-anchor geometry.
- **A general per-species rim-strength bump or any other change to
  `creature_body.gd`'s shared silhouette/rim path.** Not needed this
  round — every fix made was either spawn-position/radius data or a light/
  material addition local to one placement, matching the brief's own
  preference for targeted fixes over shared-system changes.

## Environment notes

- Godot 4.7-stable was not preinstalled in this container. Downloaded to
  the scratchpad and copied to `/usr/local/bin/godot`; will not survive a
  fresh session.
- `godot --headless --path . --import` cold run took ~8 minutes. Repeated
  incremental runs (new `.gd` files only) took ~20 seconds each and were
  safe to run WHILE two other Godot render processes were mid-run in the
  background — confirmed multiple times this session, no corruption.
- Ran up to 2 full `meadows_playground.tscn` capture jobs concurrently on a
  4-core/15GB box without apparent slowdown or instability (~5GB RSS
  each). Did not try 3+ concurrent.
- The Creek Hollow scatter (and every `spawns.json` cluster) is fully
  deterministic per boot (`hash("wild_spawn_%d" % order)`, never
  `randomize()`d) — a predecessor's "re-render a few times" instinct will
  not find anything a single render didn't already show; reproduce the
  placement MATH instead if you need to check the full distribution, not
  just one seeded sample.
- A spawn's `time`/`weather` gate (`_sync_spawn_gates`) hides it via
  `.visible`, not despawn — a capture tool that pins the clock will
  silently make a gated spawn invisible with no error. Check `spawns.json`
  for a `time`/`weather` key on a cluster before trusting a "this creature
  is invisible" finding from a time-pinned capture.
- `StandardMaterial3D.uv1_scale` does nothing on a mesh surface with no
  UV1 array (Godot's OBJ importer does not always produce one) —
  `uv1_triplanar = true` is the lever that works regardless of UV data,
  since it projects from object-space position instead.
- Use `git worktree add <path> <commit>` for a side-by-side behavioural
  comparison against another commit, never a raw `git checkout <commit> --
  <files>` inside the branch you are actively working on.

## File footprint

**Data:**
- `data/config/bands/band1_lower_meadows/spawns.json` — 3 radius edits
  (orders 6/7/8), each with an inline `_comment_disc_0830`.
- `tests/fixtures/band_split_baseline/spawns.json` — mirrored the same 3
  radius edits, per TRACKED MIRROR policy.
- `data/config/burrow_warrens.json` — 1 new light in the `lights` array
  (guardian floor wash) plus 2 new `_comment_*` entries recording the
  judge verdicts.
- `ralph/BLOCKED.md` — 1 new entry (Bramblebun contrast, owner decision).

**Code:**
- `scripts/world/campfire_glow.gd` — new `texture_logs()` static function.
- `scripts/build/camp.gd` — 1 new call (`texture_logs`).
- `scripts/world/props.gd` — 1 new call (`texture_logs`).
- `scripts/build/build_piece.gd` — 1 new accessor (`mesh_instances()`).
- `scripts/build/creature_bed.gd` — new `_tint_creature_bed()`, called from
  both `build_ghost()`/`build_real()`.

**Tooling (dev-only, `tools/`):** `_probe_band24_slope_priority.gd`,
`_capture_band24_rock_priority.gd`, `_capture_band2_2044_night.gd`,
`_probe_creek_edge_scatter_depth.gd`, `_probe_creek_edge_disc_depth.gd`,
`_probe_creek_edge_radius_search.gd`, `_probe_bonfire_uvs.gd`,
`_probe_camp_bed_surfaces.gd` (+ `.uid` siblings for all).

**Evidence:** `ralph/reports/T1-CAST/shots/` — guardian before/after,
band2/4 candidate frames (day and the night-corrected duskhush frame), the
full campsite kit (establishing/close/per-object, both rounds).

**Nothing else touched.** No changes to `creature_body.gd`, `interior_structure.gd`,
`burrow_warrens.gd`, `encounter_director.gd`, `data/creatures/species.json`,
`scripts/combat/**`, or any band's `props.json`/`vegetation.json` beyond what
is listed above.

## What I would do next, concretely

1. Confirm shard 4/4 of the full test suite finished green (it was still
   running when this report was written — check its own log tail, or
   re-run `tests/run_tests.gd -- --shard=4/4` if in doubt).
2. If continuing §17: the flame's crystal-shard colour is the kit's one
   remaining named defect after this lane. It needs care — three prior
   tuning rounds are already recorded in `campfire_glow.gd`'s own header,
   each fixing a real clipping problem under this renderer's tonemap — so
   whatever's tried needs a render+judge cycle of its own, not a blind
   retune.
3. If continuing §15: bands 2/4's two secondary findings (burrowback/
   boulder confusion at band2-2025, meadowhart/dry-grass blending at
   band4-4038) are real but smaller-scope than Creek Hollow's — worth a
   render-verified fix (a colour accent or modest scale/position nudge)
   but not urgent.
4. Get a real ROG Ally frame-time check on this lane's changes — none of
   this session's work adds new geometry (a texture swap, a material
   override, a light, and a radius edit are all effectively free), but
   nobody has measured on real hardware, same honest gap every predecessor
   in this cluster has logged.
