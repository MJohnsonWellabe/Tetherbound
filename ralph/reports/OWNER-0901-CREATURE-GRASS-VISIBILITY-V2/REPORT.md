# OWNER-0901-CREATURE-GRASS-VISIBILITY-V2

Branch `ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2`. Owner, 2026-09-02,
after the first `OWNER-0901-CREATURE-GRASS-VISIBILITY` fix had landed and
grass had come back on: **"small creatures in grass still want fixed.
they're not super visible."**

## Why the first fix didn't hold

`OWNER-0901-CREATURE-GRASS-VISIBILITY` (`bbfaaa2d` etc., landed via
`LAND-MEGA-0901`) tuned `bramblebun`/`terrapup`/`mudsnout`'s `field_emission`
(a uniform per-channel albedo/emission multiply) against a creature/grass
luma-ratio target of 1.06-1.15, and shipped `field_emission: 0.9` for
bramblebun. `data/config/grass_field.json`'s own history shows
`grass_field.enabled` was flipped **off** at `20c6e78a` (2026-09-01, the
~10 FPS game-breaker revert) and stayed off through that entire session;
it only came back on the next day at `a07994b7` (`OWNER-0902-GRASS-ON`,
"grass needs to be on"), on a config `OWNER-0902-GRASS-RENDER` had already
cut ~5x (tuft_count 300,000 -> 75,000, and proportionally on
blades/stones/cover).

`tools/_probe_grass_separation.gd` prints `"grass field re-bound to the
probe camera"` only when the real-time field is actually enabled and bound;
that line is absent from the previous fix's own saved evidence, and its
"before" luma numbers for bramblebun (1.011/0.961) match a config with the
field off almost exactly (`BACKLOG-B2-GRASS-SEPARATION`'s own shipped-height
baseline, measured with the field OFF at the time: 1.015/0.967) far more
closely than they match anything measured with the field on in this branch.
So the tuning that shipped was measured and judged against baked scatter
foliage standing in for "grass," not the real-time carpet the owner actually
plays against. That is not a small methodological footnote — it is why a
fix that hit its own numeric target still reads as unfixed in the build the
owner has.

## Reproducing for real

Re-rendered the same probe, same throwing-range camera stand, against
current `main`'s actual shipped state (`grass_field.enabled: true`, the
5x-cheaper config, 78,312 tufts bound and confirmed in the log). Frames in
`ralph/reports/hud-catch/repro_grasson/`:

- `pipwing/grass-SHIPPED-0.76.png` — untouched by either fix, reads clearly:
  light blue-grey against green/brown is a genuine hue that exists nowhere
  else in the frame.
- `bramblebun/grass-SHIPPED-1.00.png` and `bramblebun_rimtest/` — the
  already-shipped `field_emission: 0.9` fix, real grass on. Visibly better
  than doing nothing, but at a glance the creature still reads as a mottled
  blob that partially dissolves into the field, especially where its own
  darker patches sit near real foreground foliage.
- `bramblebun_rimtest/grass-D-0.96-rim.png` — re-tested `field_rim` (shipped
  at 0.0, previously measured a no-op) now that the field is real. Still no
  meaningful help: a thin silhouette-edge highlight cannot fix blending that
  happens *inside* the silhouette, not at its boundary.

## Root cause, and where the earlier theory was wrong

First pass (see the `field_degreen` comments landed by this branch) matched
the shipped mesh's reference concept art — genuine moss/lichen patches
painted on bramblebun's back — against the meadow's own measured grass hue
(68.3°) and concluded the creature's own texture was hue-matching the field,
which a uniform brightness multiply can't fix since it brightens a green
pixel without moving its hue.

That mechanism is real and partially correct — `tools/_dump_bramblebun_materials.gd`
confirms the mesh is one MeshInstance3D, one material, one texture
(`creature_bramblebun_redesign_lod0_base_color.jpg`), and per-pixel sampling
at matched screen coordinates before/after the fix shows real hue movement
on the creature's own tan/brown surface (e.g. 42°/0.37 -> 5°/0.39,
39°/0.68 -> 23°/0.70 — the fix is visibly doing something to the mesh).

But the same pixel-matched comparison also shows this: **most of the
strongest, most visually dominant green in these frames (hue 58-96°,
saturation 0.5-0.85) sits at screen positions that are pixel-identical
between the before and after renders** — i.e. it belongs to real foreground
grass tufts and groundmat/clover plants standing between the camera and the
creature, not to the creature's own material at all. No per-species albedo
lever can change those pixels; they are a different mesh. This is genuine
geometric occlusion — a short creature standing among the field's tuft
carpet and the un-suppressed `groundmat`/`drygrass` broadleaf layers (which,
measured off these same frames, stand noticeably taller than the field's own
`height_near`/`height_far` 0.4-0.62m tufts) gets its silhouette physically
broken up by real plant geometry in front of it, independent of how bright
or what hue the creature itself is.

This also explains why the shipped `field_rim` and `field_emission` levers
both under-delivered: a rim only helps the silhouette's outer edge, and a
brightness multiply only helps pixels that are actually the creature's own
surface. Neither can do anything about a real leaf standing in front of a
real rabbit.

## What this branch ships

`scripts/creatures/creature_body.gd::_brighten_node()` gets a second,
independently opt-in per-species lever, `field_degreen` (0.0 default/no-op,
alongside the existing `field_emission`): it suppresses the green channel's
share of the same brightness multiply, so a green-hued patch on a creature's
*own* surface shifts toward its coat's own warm tone instead of just getting
brighter without changing hue. Bramblebun ships `field_degreen: 0.75` (swept
0.0/0.5/0.65/0.8/1.0 against real grass-on renders — response is sharply
non-linear, 0.0/0.5 read almost identically and 0.65+ all land at
essentially the same strong warm/pink separation, so 0.75 sits past that
threshold with margin rather than pinned at the lever's own ceiling).
`tools/_probe_grass_separation.gd` gained `--extra-degreen=` to sweep it.
Mudsnout, terrapup, pipwing, sparkit are all solid-coloured or blue/tan in
their own reference art (checked directly) and get no change — this lever
is a no-op for them at 0.0.

**Verification:** `tests/smoke_art.gd` (`art: OK`), `tests/run_tests.gd
--only=creature,test_evolution_links.gd,test_creature` (52 tests, 112
assertions, 0 failed), `tests/run_tests.gd --only=test_wild_alphas.gd`
(7 tests, 112 assertions, 0 failed).

**Blind visual-judge pass** (independent sub-agent, no knowledge of what
changed, shown `bramblebun_final/grass-TEST-g0.00.png` as before and
`grass-SHIPPED-1.00.png` as after, plus pipwing and the project's reference
art/Palworld bar): confirmed the change is real, not broken-looking ("pale
cream body with rust/orange ear accents reads as ordinary, plausible rabbit
coloring... no banding, no clipping, no garish or uncanny hue"), but called
it a **modest, not dramatic** improvement, and specifically flagged that the
result is still closer to a value-contrast read than the hue-contrast pop
pipwing gets for free from a colour that exists nowhere else in the scene.
Given the pixel-level finding above, this tracks: a material tint can only
move the fraction of visible pixels that are actually the creature, and most
of what's still dragging bramblebun down in these frames is foreground
plant geometry the fix cannot touch.

**Cost:** one extra `Color.duplicate()`+multiply per surface per creature
spawn, identical order of magnitude to the already-shipped `field_emission`
path it rides alongside — no new draw calls, no shader change, no asset.

## Density ladder (started, then stopped on direct instruction)

Between the two passes above, the coordinator relayed a separate, time-sensitive
owner request: render a four-step grass density ladder (75k/150k/225k/300k
tufts, landscape + creature shots, primitive counts at `band1_open`) so the
owner could pick a density with actual frames in front of him, since
`OWNER-0902-GRASS-ON` had shipped a ~5x-cheaper field as a side effect of a
performance fix, not a separately-chosen look. `tools/_capture_grass_density_ladder.gd`
was built for this (one world boot, rebuilding only the `GrassField` node
between steps rather than re-booting four times) and completed steps A
(75k) and B (150k) — both pushed — before a follow-up instruction arrived:
**the density question is decided (keep the shipped 75k config, no change),
based on two independent judges finding density was not the actual lever
for either "does it look like the key art" or creature visibility.** The
render was killed at that point; C and D were never produced. The tool is
left in the branch in case a future density pass wants it, but per direct
instruction `data/config/grass_field.json` was never touched by this branch.

That same instruction is why the section below exists: the two judges'
finding was that a creature standing *inside* a flowering cover-tier bush,
not grass density, was the dominant legibility problem — which reopened the
"what's not fixed" gap this report originally left as a recorded next step
rather than attempted work.

## Second pass: local suppression, and the VP merge

**The whole grass system was rewritten out from under this branch mid-session.**
`origin/main` moved to `b03cdb94` (PR #20, the Meadows Visual Parity program —
per-tile culling, distance LOD, far thinning, per-tier reach on
`grass_field.gd`, plus `scatter_rules.gd`, `vegetation.json` and a scatter
re-bake) while this branch was mid-flight. Every render up to that point was
against the pre-VP field. Merged `origin/main` forward (not rebased) at
`cf349e16` — clean, zero conflicts, since this branch never touched any file
VP owns — and re-verified `field_degreen` on the merged tree
(`ralph/reports/hud-catch/repro_grasson_vp/bramblebun/grass-SHIPPED-1.00.png`):
still reads clearly, the fix survives the rewrite intact.

A blind visual-judge pass on this branch's own frames (run separately by the
coordinator, alongside a second independent judge) named the real, dominant
defect directly: **the creature is standing *inside* a green flowering
cover-tier bush, its outline broken by real leaf geometry that overlaps its
body** — exactly the occlusion mechanism this report's first pass diagnosed
from pixel evidence, now confirmed from a second, independent angle.

The engineering estimate in this report's earlier draft (a new shader
uniform threading creature positions into `grass_field.gdshader` and its
stone/cover-tier siblings) turned out to be unnecessary: **`grass_field.gd`
already has exactly this mechanism**, built for the "grass grows through the
floor" defect (`village.gd`/`burrow_warrens.gd` join a `grass_clear` group
with a `grass_clear_radius` meta value; the field reads every member's
*current* position live each time its ring moves, and clears every tier —
tufts, stones, bushes, flowers, litter, the far sheet — around it; all four
field shaders already read the same `built[]` uniform). `creature_body.gd`
now joins every creature body — wild, piloted, ally — to that same group at
build time, radius = its own collider radius + a fixed 0.6m margin (not
scaled per-species: a bigger creature already clears more by having a bigger
collider, and a margin that grew with size would turn a legendary's own
footprint into a visible bald disc). This reuses tested, shipped machinery
rather than adding a second clearing system, and needed no shader change.

**Verified in isolation** (`tools/_probe_grass_clear.gd`, new): same fixed
camera/site/creature, with vs without group membership, forcing the field's
own `_apply_built()` refresh the way a walking player's footsteps would (a
static-camera probe never triggers the ring-move that does this for free) —
`ralph/reports/hud-catch/grass_clear_probe/bramblebun-{with,without}-clear.png`.
The foreground grass immediately around the creature's feet is measurably
thinner with the group joined; the effect's *size* depends on how much
vegetation happened to be at this particular spawn point (this site had no
dense bush cluster directly on the spawn point, so the visible difference
here is real but modest — a creature that spawns literally inside a bush,
the coordinator's own worst-case example, should see a much larger effect,
since bushes are one of the tiers this same mechanism clears).

**Verification on the merged tree:** `tests/smoke_art.gd` (`art: OK`),
`tests/run_tests.gd --only=creature,test_evolution_links.gd,test_creature,
test_grass_field.gd,test_wild_alphas.gd` (77 tests, 88,030 assertions, 0
failed — `test_grass_field.gd`'s own suite, unmodified by this branch, is
green with every creature body now a member of the group its tests already
exercise).

**A final blind visual-judge pass on the combined result** (both fixes
together, independent sub-agent, no knowledge of what changed): confirmed the
same read — "a real but small improvement... it only fixes the base contact
line," the lower silhouette (where grass blades used to cross the chest/front
legs) reading cleaner, everything above that unchanged since it was never the
problem. Flagged the contact shadow as "a flat dark blob rather than a shaped
cast shadow — reads as a placeholder," matching the coordinator's own
ground-contact finding independently. Also flagged the grass scatter itself as
reading "too regular/uniform... procedural placement rather than authored
planting" and the scene as "flat-lit," both of which are the ground-material
work now owned by the VP program, not a creature-level fix.

## What's still not fixed

No ground-contact shadow or flattened-grass ring under a creature — it reads
as floating on the texture rather than anchored to it. The same two judges
named this as a third, independent contributor, and it was not attempted
here: it is a real rendering feature (a decal, a per-instance shadow-caster
tweak, or a small terrain-mask push), out of scope for a data/grouping-level
fix and not touched by the `grass_clear` mechanism above. Left as a named,
recorded gap rather than a rushed addition.

**Not touched, per the brief's own hazard warning:** `data/config/
grass_field.json` and `vegetation.json` — no density, radius or
suppress-layer values changed anywhere in this branch, including during the
density-ladder work (killed before it produced a recommendation, per direct
instruction to leave the density decision alone).

## For the record: the meadow's own defect (not this branch's task)

The two judges' single highest-impact recommendation for the meadow ground
itself, carried here for the record per the coordinator's instruction: the
single-blade tuft reads as "hair on a lawn" against the key art's own
overlapping-blade-with-mass reference
(`docs/reference/moong-01-mounted-in-tall-grass.jpg`) at any density tested
(75k or 150k) — replacing it with a clump card (3-5 blades per instance,
wider base, dark-to-light root-to-tip gradient, ±30% height variation) at
the *current* instance count was judged the fix, not more tufts. That is
`grass_field.gd` art direction, now owned by the VP program, not this
branch's task.

## Files

- `scripts/creatures/creature_body.gd` — `field_degreen` lever (colour) and
  the `grass_clear` group join (local suppression).
- `data/creatures/species.json` — bramblebun's `field_degreen: 0.75` +
  documented reasoning.
- `tools/_probe_grass_separation.gd` — `--extra-degreen=` sweep support.
- `tools/_probe_grass_clear.gd` — isolates the group-join fix from
  `field_degreen`, with a forced `_apply_built()` refresh for a static
  camera.
- `tools/_capture_grass_density_ladder.gd` — density-ladder tool, built and
  partially run per a since-superseded request; `data/config/
  grass_field.json` was never changed.
- `tools/_dump_bramblebun_materials.gd` — throwaway, confirms the mesh's
  single-material/single-texture structure.
- `ralph/reports/hud-catch/repro_grasson/**`, `repro_grasson_vp/**`,
  `grass_clear_probe/**`, `grass_density_ladder/**` — every render
  referenced above.
