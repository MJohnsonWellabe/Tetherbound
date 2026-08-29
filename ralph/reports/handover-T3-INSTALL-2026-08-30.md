# Handover — T3-INSTALL, 2026-08-30

Branch `ralph/T3-INSTALL`, off `origin/main` at `cba700b5` (LAND-0830B).
Owner directive D-0830-2 (`ralph/OWNER_DIRECTIVES_2026-08-30.md`): *"if we
built it, turn it on, put it on the game, make it playable."*

**Godot was not installed in this container either** (same limitation the
dark-features audit itself recorded) — fetched it with
`tools/art_pipeline/setup.sh godot`, installed `libegl1`/`libegl-mesa0`/
`mesa-vulkan-drivers`/`xvfb`, and ran a full import + the real test suite +
real renders. Nothing below is static-analysis-only the way the audit's own
findings were; where a render or a test run backs a claim, the path is
named.

## Corrections to the brief's premise, found by inspecting current `main`

The brief said the five species meshes were "reference art only" per the
dark-features audit. **That was already stale by the time this lane
started**: `LAND-0830B` (the commit this branch is built on) already landed
real `.glb` files for all five at
`assets/creatures/tetherbound/<name>/models/creature_<name>_lod0.glb`, with
`.import` sidecars. The audit's §1 correction was itself already corrected on
`main`. Likewise `ralph/OWNER_DIRECTIVES_2026-08-30.md` and
`docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` (the audit's
**O1** finding, "stranded on an unmerged branch") are both present on `main`
at session start — already resolved.

The brief's "T1-NPC-CAST work (22/24 rigged; 2 blocked on pose)" undersold
what is actually on disk: **all 22 rig-able bodies are fully rigged,
animated (idle/walk/sprint/jump/throw/chop) and installed** at
`assets/characters/<slug>/`, each with a complete `art.json` `config_key`
entry. `campfire_traveler` and `traveling_merchant` are the two that failed
Meshy's auto-rigger (`422 Pose estimation failed` — a baked-in non-standard
arm pose, not a transient error, per `docs/ASSET_LEDGER.md`'s own
"Round 3" entry) and are genuinely un-rigged, un-installed. The real gap for
the 22 was not rigging — it was that **none of them were placed anywhere in
the world**. See "NPC cast" below for what this lane did and did not do
about that.

## 1. Creature expansion — Sparkit, Cindercub, Shadelet, Frostclaw, Bramblebun redesign

**Player-reachable now.** Moved all four new-mesh species out of
`data/creatures/species_pending.json` (which nothing loaded) into
`data/creatures/species.json`, pointing `placeholder.model` at their
committed `.glb`. Repointed `bramblebun`'s own `placeholder.model` at
`bramblebun_redesign`'s mesh (same species id — a redesign replaces the
asset, not a new species, per the brief). Moved their pre-authored
placements out of `spawn_tables.json`'s `_pending` block into the live
`tables` (`meadows_open`/`meadows_rock`, with the same tier/weather/region
gates the pending block already specified). Stats, types, moves, catch
rates were already fully authored by T3-CREATURES — untouched.

Orb/summon path: nothing species-specific to wire — catching, party slots
and the field-summon hotbar all key off `species.json` generically, so
these four are reachable through the same generic path bramblebun already
uses. No trainer roster carries any of them (correct — `T3-CREATURES`'s own
design and `test_no_evolved_form_spawns_wild`/roster tests don't apply here
since none evolves).

**Honest limitation, not previously recorded anywhere:** all five `.glb`s
(the four new species plus the Bramblebun redesign) are single-mesh, no-skin
Meshy exports — `skins: 0`, an empty `animations` array in the raw glTF.
Every other production creature/humanoid rig in this project ships six named
clips. `creature_body.gd::_build_animator()` already handles this
gracefully (warns, no-ops) rather than crashing, so each creature **stands
in the world at the correct scale and material** but does not play
idle/walk/attack/hit/faint. This is a real, separate follow-up item — a
Meshy `rig` + `animate_humanoid.py` bake, the same recipe the 22 NPC bodies
already went through — not a data problem this lane could close.

Evidence: `ralph/reports/T3-INSTALL/shots/roster.png` — all nine creatures
this lane touched (five new + four Aspect variants), built through the real
`creature_body.gd::setup(species_id)` path against `species.json`, side by
side with a 1.8m trainer-height ruler. [FILL IN: pass/fail per creature,
what it actually looks like.]

## 2. Aspect variants — Nightburrow, Stormtrail, Riftfrill, Ashtusk

**Already fully wired on `main` before this lane started.** D1's fix
(`aspect_variant`/`aspect_source_species` keys, commit `6698ad3d`) is
already merged into `species.json`. Encounter placement was already live:
Nightburrow in band2, Stormtrail in bands 3+4, Riftfrill in band3 (all in
their bands' `spawns.json`), Ashtusk via the Sunstone→evolution path
(`playground_world.gd::_place_sunstone()`, wired and tested by
`test_evolution.gd::test_sunstone_branch_evolves_into_ashtusk...`). The
I1 SUNSTONE×PICKUPS merge hazard the audit warned about is also already
resolved on `main` — both `_place_item_caches()` and `_place_sunstone()`
are present and called.

This lane's job here was the one thing genuinely still open: **the render
pass**. Included in `roster.png` above — [FILL IN: do the four variants
visibly differ from their base species' textures, confirming D1 actually
renders correctly and not just parses correctly].

## 3. NPC cast

**Team Tether rank silhouettes (the one gap this lane could close safely):**
`grunt_a`/`grunt_b`/`grunt_c`, `officer_a`/`officer_b`, `captain_a`/
`captain_b` — seven fully rigged, animated bodies, wired into `art.json`,
used by **nothing** before this lane (every grunt/officer/captain
rendered as the shared `grunt` rig with a palette multiply and a badge,
which is the exact "one character repainted four times" defect a blind
render already caught once for ranks-vs-Warden). Added a `base_override`
parameter to `npc_ranks.gd::config_for()` (and threaded it through
`trainer_npc.gd::model_config()` via a new per-trainer `"base"` key) so a
named trainer can opt into a distinct body while keeping the rank's own
badge/palette on top. Assigned all 17 named grunt/officer/captain trainers
across all five bands' `trainers.json` a `base`, rotated so no two named
individuals in the same band share a body. Zero new Meshy spend — these
seven meshes were already paid for and sitting unused.

Evidence: `ralph/reports/T3-INSTALL/shots/rank_variety/` via the
already-existing `tools/_capture_rank_variety.gd` (it reads real trainer
entries through `TRAINER_NPC.trainer()`/`model_config()`, so it picked up
the `base` assignments with no tool changes needed). [FILL IN: do the
eleven captured individuals now show real silhouette variety.]

**The 15 civilian/trail bodies remain unplaced — scoped out of this pass,
not fixed.** `innkeeper`, `inn_helper`, `trader`, `craftsperson`,
`creature_caretaker`, `farmer`, `local_historian`, `young_trainer`,
`rival_trainer`, `field_researcher`, `wandering_trainer`, `lost_traveler`,
`alpha_tracker`, `courier`, `former_tether_member` all have a real rigged,
animated `.glb` and a complete `art.json` entry, and **none has a
`village_npcs.json`/`trainers.json`/`village.json` placement**. This is the
single largest remaining "install" opportunity in the game and this lane
did not attempt it, for a specific reason: every existing placement in this
codebase is measured against real collider/path clearances (see
`village_npcs.json`'s own `_comment_positions`, which cites exact metre
clearances from building footprints and path edges, derived from a headless
probe against the actual terrain). Three of these roles
(`young_trainer`/`rival_trainer`/`wandering_trainer`) are Battle roles that
would also need an authored team (species/moves/level) to be more than a
name — a design decision, not a wiring one. Placing all 15 properly (safe
positions + a greeting line each, trainer teams for the three battle roles)
is real, bounded, but non-trivial follow-up work; this lane chose not to
guess at positions blind and risk an NPC standing inside a wall, which would
be a worse "install" than leaving them dark with a clear list.

**Two subjects remain genuinely blocked**, unchanged from
`docs/ASSET_LEDGER.md`'s own record: `campfire_traveler` and
`traveling_merchant` failed Meshy's auto-rigger twice each on a baked-in
non-standard pose. Fixing this needs a fresh Meshy generation against a
resting-pose reference crop, which is a Meshy spend this lane has no more
ability to make than the lane that found it.

## 4. Tonic buff HUD (B1)

**Built.** `scripts/ui/playground_hud.gd` had a fully-built buff chip row
for the PLAYER's own food buffs (`player_vitals.gd::active_buffs`) but
nothing for a CREATURE's tonic buffs (`creature_instance.gd::apply_buff`/
`active_buffs`, applied from `tab_backpack.gd:1819` and
`playground_hud.gd:3007`) — a player could drink a tonic, see the one-time
toast, and then have no way to tell it was still running or had ended.
Added a second chip row to the existing "active companion" HUD block
(`_build_creature_buff_row()`/`_update_creature_buff_row()`), same visual
language as the player's row (small rounded chips, stat-initial letter,
"+N" overflow), reading the active party creature's `active_buffs` every
frame. Each chip's `tooltip_text` carries the full detail (stat, % scale,
seconds remaining).

Also wired `data/config/vitals.json`'s `buffs.max_visible_icons` (previously
a config key with zero readers) to size BOTH buff rows, replacing a
hardcoded `3` — loaded once in `_ready()` before either row is built.

Evidence: [FILL IN once rendered — a party creature with an active tonic
buff, showing the new chip row under its HP/energy bars.]

## 5. Config sweep (P1/K1/Z1)

**P1 — done.** `vegetation.gd`'s `COLLISION_STREAM_RADIUS`/
`COLLISION_STREAM_CELL` and `playground_world.gd`'s
`COLLISION_STREAM_INTERVAL` were hardcoded consts; one of the two doc
comments already (falsely) claimed the cell size was "tunable in
`data/config/performance.json`" while nothing read it. All three now read
`collision_stream_radius_m`/`collision_stream_cell_m`/
`collision_stream_interval_s` from `performance.json` via the same
`performance_config.gd::config()` pattern `interaction_arbiter.gd`'s
`interaction_grid_cell_m` already used, falling back to the old hardcoded
values if the key is absent. The config file's shipped values are
byte-identical to the old hardcoded ones, so this is a **behavioural
no-op today** — it only starts mattering the moment someone (the owner, on
the ROG Ally) actually edits `performance.json`, which is the entire point:
previously editing that file would have silently done nothing.

**K1 — one item wired.** `catching.json`'s `resolve.success_banner` had no
reader; `combat_hud.gd::_on_catch_resolved()` had `2.4` hardcoded as a
duplicate literal. Now reads the config key (same no-op-today caveat as
above — the shipped value matches).

**Everything else in P1/K1/Z1 — deliberately not touched, and why:**

| item | why not this pass |
|---|---|
| `buffs/max_visible_icons` | Wired — see §4 above, no longer belongs in this table. |
| `menu_creatures` (`input_contexts.json`) | This whole file's own header says "nothing in the game reads this file at runtime" — it is a static collision-checker `tests/test_input_context_collisions.gd` walks, not a runtime config, so "no reader" is by design for every context in it. The real question the audit's framing implied — does `tab_creatures.gd` need to claim this context via `input_owner.gd` for real input isolation — is a behavioural question about whether two verbs can actually collide while the Creatures tab is open, and answering it safely needs play-testing, not a data edit. Left open. |
| `reveal_read`, `rise_seconds` (`stronghold_climax.json`) | Legendary finale timings — the single most story-critical, least-tested sequence in the chapter. Wiring these blind, with no way to play through the climax and confirm timing still reads correctly, is exactly the kind of risk this lane should not take unsupervised. |
| `spread_deg` (`rift_collapse.json`) | Same reasoning — a late-chapter set-piece with no cheap way to verify a timing/geometry change did not break the read. |
| `approach_bearing_deg` (`relay_site.json`, `tether_relay.json`) | Two files, likely two call sites; needs the same site-approach code both reference, not inspected this pass. |
| `ramp_steps`, `tether_trim` (`stronghold.json`) | Stronghold structure generation — untouched per this lane's own hard-rule list ("changing the stronghold structure" is an ask-first item in `CLAUDE.md`). |
| `branch` (`burrow_warrens.json`) | Not inspected this pass — one key, unclear blast radius without reading the warrens layout code first. |
| `blend_sharpness`, `mipmap_bias`, `one_way`, `rejoins` (`terrain_playground.json`) | Terrain generation levers on the world's own ground truth — the highest-blast-radius file in the sweep. Not touched without a render to confirm a change doesn't visibly break the terrain blend. |
| `indoor_position` (`opening.json`) | Already correctly marked in the file's own comment as knowingly parked — not a defect. |
| `Z1` — `party.gd::all_fainted()`, `boot.tscn`, `cinder_burst`/`mind_ripple` moves, six orphan meshes | Deletions and a possible missing-feature question (`all_fainted()`), not installs. `docs/ASSET_LEDGER.md`/licensing sign-off needed before deleting committed assets; whether `all_fainted()` wants a real black-out screen is a design question, not wiring. Left exactly as the audit found them. |

## Explicitly out of scope, per this lane's own brief

- `roll_new_worlds` (D-0830-1) — not touched. Precondition (Gate F
  re-baseline) is the coordinator's call, not this lane's.
- The trainer-defeated-line bug (T1 in the dark-features report) — needs a
  new third conversation state and ~27 dialogue lines; a design decision,
  not touched.
- Any new Meshy generation, including the two blocked NPC poses and a rig
  pass for the five new creature meshes — no API key in this lane, same as
  every other lane that has hit this wall.

## Tests and evidence

- `tests/test_dual_type.gd::test_the_worst_multiplier_the_real_data_can_produce_is_one_double_weakness`
  updated: the test's own comment predicted this exact day ("Cindercub...
  is expected to join Ashtusk here... that is a second name in the list
  below, not a new number") — now asserts exactly two pairings
  (ashtusk, cindercub), both via a water move, matching the design note's
  own reasoning rather than widening or deleting the assertion.
- [FILL IN: full suite result — `godot --headless --path . --script
  tests/run_tests.gd`]
- [FILL IN: smoke_art.gd result]
- Renders: `ralph/reports/T3-INSTALL/shots/roster.png` (nine creatures, real
  species.json path), `ralph/reports/T3-INSTALL/shots/rank_variety/`
  (eleven named Team Tether individuals through the real placement path).
  [FILL IN: visual-judge pass or honest note that it was not run, and why.]

## What's now player-reachable that was not, this morning

- Sparkit, Cindercub, Shadelet, Frostclaw — new wild encounters in their
  authored bands/habitats/weather gates.
- Bramblebun — now renders as its intended redesigned mesh instead of the
  old one.
- 17 named Team Tether grunts/officers/captains — 7 previously-generated,
  never-used bodies now give real silhouette variety instead of one shared
  body with a palette multiply.
- Any creature holding an active tonic buff — now has a persistent HUD tell
  instead of a one-time toast.
- `performance.json`'s three collision-streaming levers and
  `catching.json`'s `success_banner` — now actually tunable, not silently
  ignored.

## What's still dark, ranked by player impact

1. 15 civilian/trail NPC bodies, fully generated and rigged, placed nowhere.
2. Five new creature meshes have no rig/animation (static pose in the
   world).
3. `roll_new_worlds` (owner-directed on, blocked on Gate F).
4. Trainer-defeated-line bug (needs a design decision + dialogue).
5. `campfire_traveler`/`traveling_merchant` (blocked on a Meshy pose fix).
6. 16 remaining config keys (P1/K1/Z1 table above).
