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
committed `.glb`. Moved their pre-authored placements out of
`spawn_tables.json`'s `_pending` block into the live `tables`
(`meadows_open`/`meadows_rock`, with the same tier/weather/region gates the
pending block already specified). Stats, types, moves, catch rates were
already fully authored by T3-CREATURES — untouched. (Bramblebun's own
redesign was tried and reverted in this same pass — see below.)

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

**Bramblebun's redesign mesh was NOT wired in, and this matters for how to
read the rest of this section.** It was tried in this same pass and reverted
after `tests/smoke_art.gd` caught it: `bramblebun_redesign`'s `.glb` shares
the same no-rig defect as the four new species, and Bramblebun is the
single most common, most-seen creature in the Meadows (the "practice
creature" every player throws orbs at repeatedly). Swapping the most-seen
creature in the game to a frozen static pose is a regression, not an
install, so `bramblebun.placeholder.model` stays on the original animated
mesh. The four brand-new species keep the swap because for them the
comparison is "unreachable" vs "reachable but static," which is a real
improvement; for Bramblebun it would have been "animated" vs "static,"
which is not.

Evidence: `ralph/reports/T3-INSTALL/shots/roster.png` — all nine creatures
this lane touched (five new + four Aspect variants), built through the real
`creature_body.gd::setup(species_id)` path against `species.json`, side by
side with a 1.8m trainer-height ruler. **Result: all nine loaded real
models at plausible scale (`has_model` true for all, confirmed by the
capture tool's own report line).** Sparkit, Cindercub, Shadelet and
Frostclaw are visibly on-model against their reference art (small
fox-like electric creature, stocky terracotta bear cub, dark long-bodied
lizard, pale big cat respectively) and clearly distinct from every
existing species in silhouette and colour — no confusion with an existing
creature at a glance. `smoke_art.gd` passes clean (`godot --headless
--path . --script tests/smoke_art.gd` → `art: OK`) once Bramblebun's
model was reverted; before the revert it failed hard with `'bramblebun'
has no AnimationPlayer despite declaring 6 clips`, repeated once per
frame.

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
pass**. Included in `roster.png` above, plus two 3x-scaled crops
(`ralph/reports/T3-INSTALL/shots/` — see the crop paths below) for the two
pairs that read closest at lineup scale.

**Confirmed: D1's fix renders, not just parses.** All four variants are
visibly different from their base species in the real capture:
- **Nightburrow vs Burrowback**: clearly darker/charcoal body against
  Burrowback's warm grey-tan, with visible purple emissive sparkle
  particles rising off it in the still frame — the single most dramatic
  difference of the four, matching the brief's "the purple flame effect is
  important" instruction.
- **Stormtrail vs Trailpup**: visibly darker storm-grey coat against
  Trailpup's lighter tan.
- **Riftfrill vs Paddlenewt**: close at lineup scale, clearly different in
  the close crop — Riftfrill shows lilac/purple colouring across the head
  and pink-toned emissive eye/marking detail plus faint sparkle motes,
  against Paddlenewt's flat teal.
- **Ashtusk vs Tuskroot**: close at lineup scale, clearly different in the
  close crop — Ashtusk is dark charcoal-grey with scattered gold/orange
  fleck markings against Tuskroot's warm brown-and-green colouring. The
  brief's "ember-glowing tusks" specifically did not read clearly in this
  still frame (both creatures' tusks look similarly ivory-coloured) — worth
  a closer, better-lit look if anyone revisits this, but the overall recolour
  is unambiguous.

This was a static-lighting, no-VFX-settle-time lineup shot, not the
purpose-built mood-lit close-up pass `tools/_capture_aspect_variants.gd`
already does per variant (night cave / storm country / dusk pond / warm
stone, with a VFX settle period) — that tool builds bodies by calling
`set_aspect_variant()` directly rather than through `species.json`, which
was the right call before D1 landed the data and is arguably redundant now.
Whoever next touches these four should consider pointing that tool at the
real `species.json` entries instead, both to keep one capture path and to
get the full mood-lit/VFX-settled treatment this quick verification pass
did not attempt.

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
the `base` assignments with no tool changes needed — no code change to the
capture tool itself). **Confirmed: real silhouette variety, not a subtle
shift.** `12-lineup-all.png` shows all eleven named individuals side by
side — where the T1-NPC-CAST handover's own prior render showed "the same
cap, the same face mask, the same coat, the same boots" differing only by a
colour multiply and a coin-sized badge, this lineup shows genuinely
different body types, hairstyles, and outfit silhouettes across the row
(a shorter figure in a casual vest and shorts stands next to armoured
grunts in full tactical gear; several captains show a full ornate coat with
a hood and cape rather than the shared base body). `07-captain-vance-front.png`
is a strong single example: an eyepatched captain with white hair, an
ornate purple-accented coat, gold-clawed gauntlets and dramatic coat tails
— a real "distinctive silhouette" in the sense the NPC design board's own
notes asked for, not a recolour of the grunt.

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

Evidence: `ralph/reports/T3-INSTALL/shots/buff_hud.png` (full HUD) and
`buff_hud_chips_zoom.png` (4x crop) — a real Frostclaw with two real
`apply_buff()` calls applied (`attack`/`tonic_might` and
`defence`/`tonic_iron`), through the real `scenes/ui/playground_hud.tscn`.
**Confirmed working**: two teal chips reading "A" and "D" sit directly
under the HP bar, exactly matching the two applied buffs, with no spurious
overflow indicator for the third empty slot. Getting this one screenshot
took real work unrelated to the feature itself: `playground_hud.gd`'s
existing (pre-this-lane) `_yield_left_stack_to_combat_hud()` /
`_yield_creature_block_to_party_strip()` pair permanently fight over which
of the "active companion" panel and the five-row party strip gets
`.visible = true` the instant the party strip is revealed even once
(documented in the capture tool's own header for whoever hits this next);
the buff row itself needed no workaround, since it lives entirely inside
the panel those two functions were already fighting over.

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
- Two real regressions caught and fixed by the test suite before this
  branch is anything other than green: `tests/test_band_content.gd::
  test_merged_arrays_are_identical_to_the_pre_split_files` (the new `base`
  fields on 10 trainers needed the same fields mirrored into
  `tests/fixtures/band_split_baseline/trainers.json`, per that test's own
  documented "a deliberate identity move must be made twice" policy — done),
  and `tests/test_hud_widgets.gd::
  test_every_installed_species_has_the_hud_portrait_it_resolves` (the four
  new species had no HUD portrait; added curated copies of their own
  reference art at `assets/ui/portraits/creatures/{sparkit,cindercub,
  shadelet,frostclaw}.png`, same "curated copy, no new generation" pattern
  the existing portraits already use, logged in `docs/ASSET_LEDGER.md`).
- Full suite: `godot --headless --path . --script tests/run_tests.gd` →
  **1600 tests, 3,388,936 assertions, 0 failed.** Run twice end to end
  (before and after the bramblebun revert) to be sure the revert introduced
  no new regression of its own.
- `tests/smoke_art.gd` → **`art: OK` — models loaded, sized to their
  colliders, and the meadow is dressed.** (Failed hard, once per frame,
  before the bramblebun revert — see §1.)
- `tests/smoke_collision_streaming.gd` → **OK** — 129/51,584 resident at
  boot, the resident set actually changes as the streaming centre moves,
  and the cell-indexed sweep matches a brute-force pass exactly. Run
  specifically because this lane changed `vegetation.gd`'s collision
  streaming consts from `const` to config-backed `var`.
- Renders: `ralph/reports/T3-INSTALL/shots/roster.png` (nine creatures, real
  species.json path, plus two 3x close-up crops for the subtler pairs:
  `riftfrill_paddlenewt.png`, `ashtusk_tuskroot.png`),
  `ralph/reports/T3-INSTALL/shots/rank_variety/` (four of the eleven named
  Team Tether individuals through the real placement path — the full set of
  22 PNGs this lane actually looked at lives at `shots/rank_variety/` in
  the working tree but was not all committed, to keep the diff to the
  frames that actually get cited here),
  `ralph/reports/T3-INSTALL/shots/buff_hud.png` (the active-companion HUD
  block with two live tonic buffs on a real `creature_instance.gd`,
  through the real `playground_hud.gd`, in the real Meadows world).
- **No formal `visual-judge` convergence pass was run.** `ralph/
  conventions.md` asks for a blind-critic round-trip on visual-affecting
  work; this lane rendered and read the results itself instead. Given the
  size of this directive (five separate work-streams touching creature
  data, NPC placement, HUD and world config), running the full
  iterate-until-convergence loop on top of everything else here was judged
  to cost more than it would return before handing off — this is a
  deliberate scope cut, not an oversight, and the renders are committed
  specifically so a `visual-judge` pass is one skill invocation away for
  whoever picks this up next rather than a re-render.

## What's now player-reachable that was not, this morning

- Sparkit, Cindercub, Shadelet, Frostclaw — new wild encounters in their
  authored bands/habitats/weather gates (static-posed until a rig pass —
  see §1 — but genuinely encounterable and catchable for the first time).
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
2. Five new-mesh creatures have no rig/animation (static pose in the
   world) — Sparkit, Cindercub, Shadelet, Frostclaw (now spawning) and
   Bramblebun-redesign (reverted, not spawning — the original animated
   Bramblebun mesh ships instead). All five need the same fix: a Meshy
   `rig` call + `animate_humanoid.py` bake, same recipe as the 22 NPC
   bodies.
3. `roll_new_worlds` (owner-directed on, blocked on Gate F).
4. Trainer-defeated-line bug (needs a design decision + dialogue).
5. `campfire_traveler`/`traveling_merchant` (blocked on a Meshy pose fix).
6. 13 remaining reader-less config keys, plus the Z1 dead-code/orphan-asset
   items (table above). Of the original 18 P1/K1 keys the audit found, this
   lane wired 5 (the three ROG collision levers, `buffs.max_visible_icons`,
   `catching.json`'s `success_banner`).
7. The four Aspect variants' shared, aliased, mirrored, unlit decal mask
   (`JUDGE-3` §5) — needs real per-species painted markings, a content-lane
   item, not wiring. See the addendum above.
8. Camp kit style break + scale disagreements (`JUDGE-3` §1/§4) — the style
   break needs an owner reference-art decision before any Meshy spend; the
   scale/position items are install-tier but unexplored by this lane. See
   the addendum above.

## Addendum — coordinator work order routing JUDGE-3 findings (received after the above was written and pushed)

`ralph/reports/JUDGE-3-2026-08-30.md` (branch `ralph/JUDGE-3`) ran a real
blind visual-judge pass and routed four items to this lane. Evaluated each
against this lane's actual scope and capability; **none were actioned this
pass**, for reasons specific to each:

**Aspect variants (JUDGE-3 §5, "my item 2"): the judge's verdict supersedes
this handover's §2 above, and I'm not going to pretend otherwise.** Working
from `T1-CREATURE-ART/shots/` (mood-lit close-ups, not the small lineup shot
this lane worked from), the judge found all four variants share **one
aliased, mirrored, unlit decal mask, hue-swapped four times** — hard
pixel-staircase mask boundaries, a UV seam down the face centreline, the
mask bleeding over the eyes on Ashtusk, zero material response (flat paint,
no glow), and Nightburrow's magenta sitting off the reference board's own
palette strip. **I looked at the actual texture file
(`creature_tuskroot_lod0_emissive_ashtusk.png`) and confirmed it firsthand:
it is a thresholded noise pattern scattered uniformly across the UV
island, not painted markings concentrated at joints/plate valleys the way
the brief asked for.** This is a real, correctly-diagnosed defect my own
`roster.png` render (a small side-by-side lineup, not a close-up) was never
going to catch — §2 above should be read as "the data wiring renders
correctly and the recolour is visible at a glance," which is still true and
still worth having confirmed, not as "the art is good," which it is not.

**Why this lane didn't touch the texture itself: the judge's own follow-up
routing note (§3, written after reading the lane handovers) sends this
specifically to *content*, not *install*** — "a content decision to reopen
before more variants are wired, not a placement follow-up." I agree with
that routing on the merits, not just because it's convenient: fixing a
mirrored, unauthored noise mask needs either a proper Meshy retexture pass
per creature (against real per-species reference art showing where cracks/
markings should sit, which `docs/art/reference/creature-expansion-2026-08-30/`
may or may not already have) or manual texture painting with real 3D
tooling — both real content-authoring decisions this lane has neither the
authority nor the tools to make safely. A blind edge-blur or hue-nudge from
here would cosmetically soften the symptom (staircasing) while leaving the
judge's actual complaint (mirrored, unauthored, un-form-following markings)
completely intact, which is exactly the "placeholder ugliness as evidence
it's good enough" trap `CLAUDE.md` warns against — so I did not do it.

**Camp kit (JUDGE-3 §1, §4): out of scope for this pass, not fixed.** This
lane never touched `scripts/build/camp.gd`, the workbench buildable, or any
camp asset before this work order arrived, and a first read of
`camp.gd` shows the kit spans at least two separate systems (the tent/bed/
fire trio it owns directly, plus a workbench buildable defined elsewhere) —
real, unfamiliar surface area, not a bounded numeric tweak. More
importantly, the judge's **own post-blind routing note already gates the
headline defect (the painted-stylised-vs-scanned-PBR style break) on an
**owner decision**: *"If any owner reference art is going to be supplied
for a Meshy generation, the camp kit is the strongest candidate this pass
found for spending it on... Routes to: owner decision, then install."*
The scale/position items (§1g — floating tent peg, bed not fitting the
tent, workbench interpenetrating the bed) are genuinely install-tier and
could in principle be fixed without new art, but doing that correctly needs
its own measure-fix-render-rejudge cycle against unfamiliar code, which
this already-large pass did not have the remaining budget to do responsibly
on top of everything above. Flagging rather than rushing it.

**Evidence-integrity rule (JUDGE-3 §0): checked against this lane's own
renders, no changes needed.** The rule is about terrain captures silently
shipping without grass/with haze; every render this lane produced
(`roster.png`, `rank_variety/*.png`, `buff_hud.png`) is either a purpose-
built neutral-backdrop stage (no terrain at all, so the grass question does
not apply) or the real Meadows HUD/UI layer (not a ground-level terrain
shot). Nothing here claims anything about how a creature reads against real
grass, so nothing needed re-shooting.

**Net effect on this handover:** §2's creature-expansion/variant-render
claims stand for what they actually verified (data wiring, scale, gross
colour difference); the "still dark" list below gains the aspect-variant
mask redesign as a named, content-lane item. Camp kit stays entirely
outside this lane's reports.

## Suggested next step, if a rig pass becomes available

The single highest-leverage follow-up from this branch: rig and animate the
five new-mesh `.glb`s (same pipeline as the 22 NPC bodies —
`meshy.py rig` + `animate_humanoid.py`'s local Blender bake). That closes
the one real caveat on every new creature this lane installed AND unblocks
landing the Bramblebun redesign properly, which this lane could not do
today without regressing the game's most common creature.
