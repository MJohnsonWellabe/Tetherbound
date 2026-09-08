# Stormwood -> Water ordinary solo playable-path audit — 2026-09-07

## Outcome

Static audit at observed repository HEAD `1a6bf406dceed5a51fd24e81cddf35d60a8808e4`
found one definite main-path blocker: **ordinary play can earn the Water key, but
there is no production Stormwood -> Water gate or other production caller of
`Game.enter_realm("water", ...)`.** The Settings debug teleport reaches Water by
deliberately bypassing story gates; it is not an ordinary campaign transition.

The production code after arrival is connected from `water_chapter_started`
through `water_currents_restored`. No second static dead-end was found in that
flag chain. That is not continuous-play acceptance: existing runtime evidence
tests isolated subpaths with teleports, injected prerequisites, materials, or a
freed-Guardian fixture. A normal, uninterrupted solo Stormwood ending -> Water
ending run has not been executed.

This was read-only production/test inspection plus existing-log inspection. No
Godot process was started and no production, test, or configuration file was
changed.

## Exact production trace

### Stormwood ending and Water entitlement

| Step | Durable fact | Production emitter / consumer |
|---|---|---|
| Marrow completes | `stormwood:marrow_defeated` | `scripts/world/stormwood_dynamo.gd::_complete_marrow()` emits `trainer:marrow_defeated` after the fourth-conduit completion. `data/config/stormwood_chapter.json` maps that event to the fact. |
| Captive released | `stormwood:legendary_freed`; grants `realm_heart_stormwood_earned`, `stormwood:long_storm_ended` | Host `scripts/world/stormwood_ending.gd::_process()` observes Marrow and emits `dynamo:release`; chapter data requires Marrow. |
| Offer settled | `stormwood:legendary_offer_made` | The nearby, character-addressed ceremony is reserved and persisted by `stormwood_ending.gd::_claim_for()`. `_settle_for()` emits `legendary:offer_shown` after the ordinary five-slot choice settles. Declining the offered creature still settles this shared story step. |
| Spark placed | `realm_heart_stormwood_placed`, then `stormwood:spark_placed` | The real `realm_heart_shrine` is built at Lantern Hollow. The common shrine writes the placed flag; `stormwood_ending.gd::_process()` then emits `shrine:stormwood_placed`. |
| Waterward viewed | `stormwood:waterward_revealed`; grants `realm_key_water`, `waterward_route_revealed`, `stormwood:chapter_complete` | `WaterwardView` is a real proximity prompt on the high platform. Host `_reveal_for()` requires the Spark and a nearby authoritative actor, then emits `aftermath:waterward_view`. The exact grants are in `stormwood_chapter.json`. |

`scripts/world/realm_chapter_events.gd` supplies the ledger writer, and
`scripts/world/realm_chapter_progression.gd` checks each objective's
`requires_flags`, matches its `completion_event`, and writes `grants_flags` plus
the objective flag. In solo play `Game.current_realm == "stormwood"` admits the
events; the same adapter also admits a host-owned Stormwood simulation shell.

### The broken transition seam

- `data/config/realm_hearts.json` registers Water's real scene and names
  `realm_key_water` as its entry key. `Game.can_enter_realm()` consequently
  returns true after the Waterward reward, and `Game.enter_realm()` can load the
  scene if called.
- `data/config/water_world.json::entry_anchors.from_stormwood` provides the real
  First Shore arrival (`water_arrival_from_stormwood`) and describes
  `realm_gate_water_unlocked` / `realm_key_water`.
- No production script reads those Water entry metadata fields. Repository-wide
  production search found no `enter_realm("water"...)`, no
  `setup("water"...)`, and no `RealmGate` named for Water.
- `scripts/world/stormwood_world.gd::_build_return_gate()` builds only
  `CloudreachReturnRealmGate`, targeting Cloudreach. Its world config contains
  only the Cloudreach entry/return transition points.
- `scripts/world/stormwood_ending.gd::_build_waterward_view()` explicitly builds
  a non-colliding horizon and describes it as “a horizon, not a gate.” The
  Stormwood ending report likewise explicitly assigns the later gate to Water.
- `data/config/stormwood_chapter.json::rewards.next_realm_enterable` remains
  `false`, consistent with the missing ordinary crossing.

There is also a contract mismatch that must be resolved in the same repair, not
papered over:

- `data/config/water_authority.json` requires an atomic transaction that clears
  `realm_key_water` and sets reusable `realm_gate_water_unlocked`.
- Generic `scripts/world/realm_gate.gd::try_unlock()` intentionally retains all
  realm keys and performs only a `set_world_flag` for the unlock.
- `Game.can_enter_realm("water")` reads only `realm_key_water`, not
  `realm_gate_water_unlocked`. Therefore implementing the authority file's key
  consumption without changing the router/gate handoff would make the newly
  unlocked gate call a router that refuses entry.

### Water chapter start

`scripts/world/water_world.gd::_ready()` places the local player at the authored
First Shore anchor, adds swimming, builds `WaterChapter`, docks, encounters,
Aquaryn, Veilfall and pickups, then marks `_shell_ready`. A pending entry is
settled by `Game.complete_realm_entry("water")` after two physics frames.

`scripts/world/water_chapter.gd::build()` calls
`apply_personal_event(..., "arrival", "water")` for a real local Water player,
which writes the personal `water_chapter_started` flag. Pell's completed
conversation emits `water:water_swim_lesson_briefed`; the chapter verifies the
nearby local actor and writes personal `water_swim_lesson_briefed`. The host's
physical swim observer writes world `water_swim_lesson_complete` only after the
lesson route completes.

### Water objective and ending chain

The ordered main flags in `data/config/water_objectives.json` all have production
writers:

| Objective fact | Production source |
|---|---|
| `water_dock_reedhaven_repaired` | Nearby dock action; requires the swim lesson and atomically charges 6 `reed_fiber` + 4 `driftwood`. Water pickup data contains 47 reed and 45 driftwood harvests. |
| `water_dock_brine_steps_trial_won` | Host `WaterDocks` aggregation after `defeated_water_trainer_tovin`; encounter translation gives every authored trainer the exact `defeated_` + trainer id flag. |
| `water_dock_shellwatch_residents_freed_and_pump_disabled` | Aggregates the physical resident-release and pump actions, respectively gated by Solm and Irva victory. |
| `water_swim_stone_earned` | Aquaryn resolve grants the participant's personal Stone; the current source also has the host-validated nearby-Iona late-join attunement path after shared resolution. |
| `water_swim_saddle_recipe_learned` | Iona's guarded completed dialogue calls the personal event, conditional on the Stone. The recipe then charges 8 reed, 6 driftwood, 4 reef stone. |
| `water_dock_salt_crown_landing_charted` | Physical Salt Crown chart action after `water_aquaryn_resolved`. |
| `water_dock_sluice_isle_both_controls_disabled` | Aggregates west/east physical controls after Bex/Calder victories. |
| `water_captain_nerissa_defeated` | Veilfall reparents the authored Nerissa NPC and four-member trainer encounter into the interior, requires the return sluice, and overrides the defeat flag to this finale fact. |
| `water_guardian_freed` | Nearby `guardian_tether` control requires Nerissa, then `water_guardian_reward.gd::release()` atomically journals `water_tether_disabled` and `water_guardian_freed`. |
| `water_currents_restored` | The nearby freed-Guardian offer reserves a durable claim for the stable character. `water_capture_claims.gd` uses the ordinary `Game.pending_catch` five-slot flow. Only after the character receipt is saved and acknowledged does the host commit `water_guardian_settled`, `water_currents_restored`, and `realm_relic_water_earned`. `water_world.gd::current_at()` consumes the restored-current flag. |

The Guardian can be accepted or declined without blocking settlement: the same
durable transaction receipts the choice and acknowledgment advances the world.
The physical Tideglass Compass shrine subsequently places
`realm_relic_water_placed`; placement is a post-ending relic interaction, not a
prerequisite for `water_currents_restored`.

## Evidence boundary

### Proven focused behavior already recorded

- `ralph/reports/FOUR-BIOME-BUILD/stormwood-ending/REPORT.md` records **35 tests /
  507 assertions / 0 failures** for the ending/chapter logic. Its production
  prefix smoke mounted the ending nodes, but the log was cache-dirty and it did
  not play the release -> choice -> shrine -> view chain.
- `tests/smoke_stormwood_transition.gd` physically proves Cloudreach ->
  Stormwood -> Cloudreach, including both real gates and arrival anchors. It
  does not mention Water.
- `ralph/reports/WATER-PROGRESS/runtime-wave-1.md` records the real 60.143 m swim
  lesson subpath.
- `ralph/reports/WATER-PROGRESS/density-census-wave2.md` records 32 checks / 0
  failures for real dock prompts, charging, barrier/current state and save/load.
  It explicitly injected lesson and trainer flags and did not travel the route.
- `ralph/reports/WATER-PROGRESS/runtime-wave-3.md` records the real Aquaryn
  combat -> Stone -> Iona -> material-consuming saddle -> mount subpath. Player
  position and materials were fixtures; the Aquaryn fight was dry rather than
  an amphibious route encounter.
- `ralph/reports/WATER-PROGRESS/FINAL-REPORT-AND-FRESH-SESSION-TAIL.md` records a
  31-check Veilfall interior path, a 16-check Nerissa/release path, and a
  35-check Guardian ceremony/current/relic path. Those respectively supplied
  upstream/proximity/party or freed-Guardian fixtures.

These are historical logs from the constituent lane branches plus source
inspection on the merged tree. This audit did not rerun them and does not
promote them to current-HEAD continuous acceptance.

### Explicitly not proof of ordinary progression

- `tests/smoke_realm_teleport.gd` reaches all four real scenes from Settings, but
  first proves the story keys are absent and uses the intentional debug bypass.
- `tests/test_four_biome_debug_teleport.gd` pins Water's menu row and entry id;
  it is catalogue/unit coverage, not a story gate.
- `tests/smoke_net_water_alpha.gd` directly injects both `realm_key_water` and
  `realm_gate_water_unlocked`, then calls `Game.enter_realm` through its harness.
- The Water subpath smokes begin with `game.current_realm = "water"`; they do
  not prove the Stormwood seam.
- No checked test walks the ordinary ordered objective chain from First Shore
  to the Guardian without teleporting or setting prerequisite flags.

## Ranked repair / proof list

1. **P0 — implement the missing ordinary Stormwood -> Water crossing.** This is
   a demonstrated static dead-end. The lane should own
   `scripts/world/stormwood_world.gd`, `data/config/stormwood_world.json`, an
   explicit Water gate/authority adapter (new file if the atomic special case is
   kept), `autoload/game_state.gd`, and the relevant Water entry metadata. Do not
   make debug teleport the campaign route.
2. **P0 — settle key-versus-unlock semantics atomically.** Either make the
   Water-specific gate consume the key and make the router accept the durable
   unlock, or deliberately amend the Water authority contract to the generic
   retained-entitlement model. The former matches the current authored
   contract. Test save failure/rollback and repeated use; never clear the key in
   one commit and open the gate in another.
3. **P1 — add the missing ordinary Water -> Stormwood return.** Water config has
   `return_to_stormwood`, but production builds no return `RealmGate`. This does
   not block reaching the Water ending, but without debug teleport it traps an
   ordinary player in Water and leaves authored return metadata inert.
4. **P1 proof gap — run one continuous solo main path.** No further static flag
   disconnect was found, but the composed route is unproven. The run must earn
   rather than inject all Water objective prerequisites and materials, use
   ordinary locomotion/combat/interactions, survive the long mounted crossings,
   and complete the Guardian choice. Treat the first real physical failure as a
   product defect, not a reason to seed the next flag.
5. **P2 contract gap — enforce or remove inert mounted-crossing metadata.** The
   Water dock rows' `required_personal_flags` and
   `requires_compatible_active_swim_mount` have no production consumer. That
   currently weakens sequence enforcement rather than blocking progress, but a
   continuous test should pin the intended Stone/saddle/mount barrier before the
   long crossings.

## Exact next tests

- Add `tests/smoke_stormwood_water_transition.gd`, modeled on
  `smoke_stormwood_transition.gd`: real mounted Water gate, no-key denial,
  earned/ledgered ending entitlement, atomic unlock, save/reload, real Water
  scene arrival at First Shore, settled pending entry, and real return gate.
- Add a focused transaction test such as `tests/test_water_realm_gate.gd` for
  proximity/authentication, atomic key-spend + unlock, save rollback,
  idempotence, and router acceptance after the key is gone. Extend
  `tests/test_realm_world_components.gd` only if the generic gate contract is
  intentionally changed for every realm.
- Add `tests/smoke_stormwood_water_continuous.gd` for the physical ending
  sequence: Marrow completion -> release -> five-slot accept/decline -> Spark
  placement -> Waterward prompt -> gate -> Pell briefing. It must not call
  `set_flag` for any flag under test.
- Add/extend `tests/smoke_water_continuous.gd` for the entire ordered solo Water
  path. Start from the real Stormwood gate result, harvest exact resources, and
  forbid teleport/flag fixtures. Log each island arrival and objective emitter
  so a route, stamina, collision, combat, or prompt failure is localized.

Until those tests pass, the accurate status is: **menu teleport works; the
ordinary Stormwood -> Water campaign handoff does not exist; Water's internal
ending is implemented and has strong isolated evidence, but the complete solo
chapter remains unproven.**
