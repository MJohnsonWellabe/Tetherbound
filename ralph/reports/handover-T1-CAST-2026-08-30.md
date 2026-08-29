# Handover — T1-CAST (§15 creature presentation + §17 campsite), 2026-08-30

DRAFT — being written incrementally while background renders complete. See
the end of this file for the "as of" marker on the last update.

**Branch:** `ralph/T1-CAST`, off `origin/main` (`a97f3e84`).

## What I was asked to do

Track 1 (Aesthetics) lane, continuing where `ralph/T1-CREATURE` (§15) and
`ralph/T1-CAMP` (§17) stood down. Both predecessors' work is already merged
to `main` via `ralph/LAND-0829B`. My brief named specific open items from
each predecessor's own handover:

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

## Where I got to

### DONE and verified

1. **Creek Hollow's disc-scatter depth bug — a real defect T1-CREATURE's own
   centre-only fix left open, now fixed and verified.** T1-CREATURE's depth
   correction only checked the CENTRE point of each of the three water
   spawns' scatter disc. `encounter_director.gd`'s own scatter draw
   (`distance = radius * sqrt(rng.randf())`) is a uniform-AREA sample over
   the whole disc, which — because a disc's area grows with radius — puts
   MOST of a large disc's probability mass near its OUTER edge, not the
   centre that was actually verified. The scatter is fully deterministic
   (seeded from `hash("wild_spawn_%d" % order)`, never re-rolled — confirmed
   by reading `encounter_director.gd:284-296` directly), so I reproduced the
   exact placement math in a standalone probe rather than re-rendering
   blind (re-rendering would have shown the identical two points every
   time — the predecessor's own suggested next step would not have found
   anything new).
   - **Found:** paddlenewt's individual 1 (order 6) landed 13.8m from centre
     at 3.38m depth — fully submerged, deeper than the cluster's ORIGINAL
     pre-fix defect. Brooktail's sole individual (order 8) landed 11.1m out
     at 1.65m depth — also fully submerged. Mosshell (order 7) landed at
     27% clear — weak but not broken.
   - **Root cause:** a full-disc grid probe (not just the two/one seeded
     points) found the lakebed drops off steeply from all three centres —
     worst-case depth grows roughly monotonically with radius (e.g.
     paddlenewt: 0.66m depth at r=0.5m to 4.2m at r=11-14m). The centres
     T1-CREATURE found sit right at the top of a real drop-off, not in the
     middle of a flat shallow shelf, so no radius large enough to look like
     a real "scatter" also clears the water.
   - **Fixed:** shrunk each cluster's radius (paddlenewt 14.0→0.4m, mosshell
     10.0→3.0m, brooktail 14.0→2.0m) after searching for the largest radius
     whose own worst-case point still clears meaningfully. Centre/species/
     count/habitat untouched. Re-verified against the real seeds:
     paddlenewt 55%/100% clear, mosshell 68%, brooktail 58% — all now a real
     visible read, not a coin-flip.
   - **Mirrored** into `tests/fixtures/band_split_baseline/spawns.json` per
     that fixture's TRACKED MIRROR policy (`radius` feeds the same seeded
     scatter identity `centre` does — confirmed by reading the policy block
     in `tests/test_band_content.gd` and the fact these three entries are
     already present in the baseline from T1-CREATURE's OWN mirror commit,
     `dd77a7f1`).
   - **Tests:** `test_band_content.gd` (6 tests) and `test_spawns_data.gd`
     (23 tests), 2383 assertions, 0 failed. `tests/smoke_warrens.gd` also
     re-run clean (unrelated file, touched by the guardian light change
     below, included here for completeness).
   - Tools added: `tools/_probe_creek_edge_scatter_depth.gd` (reproduces the
     real seed, direct depth check — the general-purpose instrument),
     `tools/_probe_creek_edge_disc_depth.gd` (full-disc grid search, finds
     the worst point and searches for a safe radius), and
     `tools/_probe_creek_edge_radius_search.gd` (scratch tool used to
     iterate candidate radii against the real seed before committing to
     final numbers — kept for reproducibility, not because it's likely to
     be reused as-is).

2. **Warrens Guardian silhouette — routed to the judge, verdict is "no, not
   reliably", second light iteration applied but NOT yet re-verified.**
   T1-CREATURE's own backlight fix (`_comment_guardian_backlight_0829`,
   already on `main`) was never independently judged. I routed the EXISTING
   committed evidence (`ralph/reports/T1-CREATURE/shots/
   guardian-den-AFTER-full.png` and `guardian-silhouette-AFTER-crop.png`) to
   a blind Fable pass (Agent tool, `model: fable`, no context on what
   changed or that this was a "before/after" pair) rather than re-rendering
   first, since the frames were already captured and committed and a fresh
   render would just cost 50 minutes to look at the identical fix.
   - **Verdict, verbatim structure:** "no — not reliably." The upper
     silhouette separates where the wall happens to be mid-tone, but "the
     front half is the problem: the head and chest sit against the darkest
     corner of the frame" and "lower legs/paws again merge into the dark
     floor-wall junction." Also named: the room's flat single-value
     lighting gives the creature no stage, and the alpha's moss-green back
     plates are so low-chroma they read as black variations.
   - **Read against the mechanism:** T1-CREATURE's backlight is aimed at
     ONE wall segment (z≈46), but the guardian's own wander (radius 1.5m)
     rotates which wall is actually behind it in any given render, and
     nothing in either light sits below y=1.8 — floor-level contrast was
     never addressed at all.
   - **Second fix applied** (`data/config/burrow_warrens.json`'s `lights`
     array, one more entry): a light centred ON the guardian's own home
     stand `[3,44]` at y=1.0 (leg height) rather than aimed at a specific
     wall, so it rides with the 1.5m wander regardless of facing instead of
     depending on which wall happens to be in frame, and lifts the
     floor-wall junction the crop specifically named.
   - **NOT yet re-verified.** `tests/smoke_warrens.gd` confirms the JSON
     loads and the light count is now 9, but the actual silhouette read
     needs a fresh render + a second blind judge pass. That render was
     queued behind the campsite/band2-4 work (see "still running" below)
     and had not completed as of this section being written.
   - **What I did not touch:** the moss-green back-plate colour and the
     room's overall flat lighting. Both are real per the judge, but colour
     retinting an alpha's own established colourway and a broader
     room-lighting redesign are bigger moves than a second targeted light —
     flagging both as open rather than taking them on blind.

3. **Bramblebun's grass-contrast problem, formally recorded rather than
   re-investigated.** Two prior lanes (a repaint-or-rim decision flagged in
   commit `2f3deedb`, reconfirmed by T1-CREATURE) had the finding but no
   entry in `ralph/BLOCKED.md`. Added one, consolidating the existing
   1.08:1 luminance measurement and the two candidate fixes (repaint the
   canon colourway, or a stronger silhouette rim gated on re-differentiating
   an alpha's own tell first) as an owner decision. Did not re-measure or
   implement either fix.

### Still running / not yet judged

- **Band 2/4 rock-silhouette prioritisation.** T1-CREATURE's own handover
  named the exact gap: "sample 2 of 55 blindly" vs "check the 5 that are
  actually near rock", and asked for a computed prioritisation check before
  spending more render budget. Wrote
  `tools/_probe_band24_slope_priority.gd`: rather than distance to the
  1-3 authored rock-prop clusters per band (too few points to explain
  130+ spawns), I used the REAL driver of rock-background risk —
  `vegetation.json`'s global "rocks" scatter layer places boulders
  procedurally by terrain SLOPE everywhere in the world
  (`min_slope_deg: 6, max_slope_deg: 44`, confirmed by reading that layer's
  own config), not from an authored point list. Ran a lightweight
  terrain-only probe (no scene load, seconds not minutes, same pattern as
  `tools/_probe_sigil_gorge.gd`) computing `slope_degrees_at()` at every
  Band 2/4 spawn centre and ranking by slope. Result: Band 2's steepest
  spawn (order 2044, duskhush, 32.2°) stands out sharply above the rest
  (next is 16.7°); Band 4's ranking is more clustered (16.5° down to
  14.5° across the top handful). Rendered the top 3 per band
  (`tools/_capture_band24_rock_priority.gd`, queued behind the guardian
  render) — **frames not yet judged as of this section being written; see
  the render-status note below.**
- **Campsite kit (§17) blind judge pass.** Both predecessors' capture tools
  (`tools/_capture_t1_camp.gd`, `tools/_capture_t1_camp_assets.gd`) exist
  and were re-run (queued) but their output lives under `shots/`, which is
  gitignored — nothing was ever committed as evidence, so this needed a
  fresh render regardless of whether the kit itself changed. **Not yet
  judged as of this section being written.**
- **Twin-bed differentiation opinion.** Blocked on the campsite judge pass
  above — I deliberately did not implement a material-variant fix
  speculatively; see "what I considered and did not do."
- **Bonfire log texture** (`Bonfire_Fire.obj`'s `Wood`/`LightWood` surfaces,
  genuinely textureless — confirmed by reading the `.mtl` directly, no
  `map_Kd` line on any of the three materials). Investigated but not
  attempted. See below.

## What I considered and deliberately did not do

- **A texture fix for `Bonfire_Fire`'s logs.** This is real (both
  predecessors independently found and deferred it) and shared across every
  campfire in the game — `Bonfire_Fire.obj` is loaded by mesh path directly
  in band1/3/4's authored `props.json` trail-camps AND the player-built
  `camp.gd`, so a fix has to live at the resource/shared-material level (a
  helper analogous to `imported_materials.gd::make_dielectric`, which
  already runs a similar shared-surface-detection pass for the unrelated
  black-metal defect) rather than scoped to one caller — the repeated
  mistake both predecessors named and refused to repeat. I confirmed
  `props.gd`'s scatter path does NOT call `BUILD_MATERIAL_FINISH.apply()`
  (only `build_piece.gd`'s player-built path does), so whatever fix lands
  has to be a new shared pass, not a reuse of the existing one, and it
  has to be re-verified against `campfire_glow.gd::ignite()`'s
  surface-name match on `Fire` (untouched by a Wood/LightWood-only fix, but
  the predecessor's own caution about proving this stands). Given the
  render budget already committed to the guardian/campsite/band2-4 work
  this session, I did not have room to implement AND verify this safely and
  left it as a clearly-scoped, still-open item rather than rush a
  shared-asset change with no render budget left to check it.
- **A material-variant fix for the twin beds** (player bed vs. creature
  bed, literally the same `camp_bed.glb`). `docs/ASSET_LEDGER.md` documents
  a "one mesh, many materials" economy already used for `tm_orb`, so the
  lever exists, but no code path currently supports it for `build_piece.gd`
  placements (checked: `build_piece.gd` has no per-instance albedo
  override hook, only a ghost-tint state). I did not build this
  speculatively — per `ralph/conventions.md`'s "do not grade your own
  visual work" rule and the campsite predecessor's own explicit ask ("get
  a real judge opinion, not a guess"), whether this needs fixing at all is
  the judge's call to make first.
- **Retinting Bramblebun or the guardian's back plates.** Both are
  established creature colourways; see the BLOCKED.md entry and the
  guardian note above.

## Environment notes

- Godot 4.7-stable was not preinstalled in this container (same gap every
  prior lane's handover names). Downloaded to the scratchpad and copied to
  `/usr/local/bin/godot`; will not survive a fresh session.
- `godot --headless --path . --import` cold run took ~8 minutes this
  session (matches prior lanes' estimate). A second incremental run (after
  adding new `.gd` tool files, no binary assets touched) took ~20 seconds,
  and running it again WHILE two other Godot render processes were mid-run
  in the background did not corrupt anything or conflict — confirmed
  safe in this session, contrary to my own initial caution.
- Ran up to 2 full `meadows_playground.tscn` capture jobs concurrently on a
  4-core/15GB box without apparent slowdown or instability (each process
  used ~5GB RSS). Did not try 3+ concurrent.
- The Creek Hollow scatter is fully deterministic per boot
  (`encounter_director.gd:284-285`, seeded from `hash("wild_spawn_%d" %
  order)`, explicitly never `randomize()`d) — worth stating plainly since a
  predecessor's own suggested next step ("re-render a few times to sample
  the scatter") would not have found anything, and I nearly followed it
  before reading the actual placement code.

---

**Status marker:** this file was last updated while the guardian re-render,
band2/4 priority render, and campsite kit renders were still running in the
background. It will be updated again once those complete and are judged —
if you are reading this and the sections above still say "not yet judged",
the render/judge step did not finish before this session ended; check
`ralph/reports/T1-CAST/shots/` for whatever frames did get captured and
pick up from there.
