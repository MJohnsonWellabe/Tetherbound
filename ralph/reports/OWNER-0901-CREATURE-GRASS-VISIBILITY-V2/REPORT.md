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

## What's NOT fixed, and the honest next step

The dominant remaining defect is occlusion by real grass/plant geometry, not
creature colour. `CLAUDE.md`'s own allowance covers this directly: *"A
local suppression or flattening of grass immediately around a creature is a
legitimate option if it's genuinely the right fix."* Given this branch's own
evidence, it is the right fix — but it is a real shader/engineering change
(the field's tufts, stones and cover tiers are all GPU-hashed from world
position with no per-instance CPU transform to suppress individually; doing
this properly means passing a small set of "active nearby creature" world
positions into `shaders/grass_field.gdshader` and its stone/cover-tier
siblings as a uniform and having the vertex stage collapse any tuft/prop
within some clearance radius of one), not a data tweak, and touching those
shaders is real risk to a system that was only just re-measured and landed
at a deliberately cheap config. It deserves its own dedicated pass with its
own render-based verification, not a rushed addition here. Recorded as the
concrete next step rather than attempted in the time left on this branch —
this branch's owner also has a live, explicit, time-sensitive request in
flight (a grass density ladder for a separate decision) that took priority
over spending further render cycles on a bigger creature-visibility change.

**Not touched, per the brief's own hazard warning:** `data/config/
grass_field.json` and `vegetation.json` — no density, radius or
suppress-layer values changed anywhere in this branch.

## Files

- `scripts/creatures/creature_body.gd` — `field_degreen` lever.
- `data/creatures/species.json` — bramblebun's `field_degreen: 0.75` +
  documented reasoning.
- `tools/_probe_grass_separation.gd` — `--extra-degreen=` sweep support.
- `tools/_dump_bramblebun_materials.gd` — throwaway, confirms the mesh's
  single-material/single-texture structure.
- `ralph/reports/hud-catch/repro_grasson/**` — every render referenced
  above.
