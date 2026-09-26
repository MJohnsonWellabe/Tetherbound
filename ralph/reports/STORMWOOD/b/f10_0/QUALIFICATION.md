# F10#0: Stormwood side-chain qualification (ACCEPTANCE §6.1 F10 + §5)

**Criterion:** "All six selected Stormwood chains satisfy §5 with distinct lure/action/payoff/acknowledgement." §5 needs all six: a lure, a distinct action or decision, a useful reward, an acknowledgement, saved completion and a normal-play route.

**Sources:**
- Targets: `docs/design/WORLD.md` "Stormwood — six existing chains made concrete".
- Chain data: `data/config/stormwood_chapter.json::side_chains`.
- Runtime: `scripts/world/stormwood_{chapter,arch_runtime,pims_parcels,crown_records,glass_for_bryn,encounter_hub}.gd`.
- Dialogue: `data/dialogue/stormwood.json`.

**Branch and commits:**
- Branch: `tb/stormwood-b-f10-0-chains`, cut from origin/main `32bd3307`.
- Fix commit: `3a74ccf41bdb0fe6e28ed03d3928d5de3cad7bfd`.
- This record is in the next commit on the same branch.

**Overall verdict: F10#0 is NOT met.**
- **4 of 6 chains are MET on source and tests:** Pim's Parcels, What the Crown Remembers, Glass for Bryn and Raise a Road.
- **Deepwood Circuit is a GAP:** the authored Electric TM reward does not exist.
- **Dark Arches is MET on source and unit tests,** after this branch's map-layer fix. The live map rendering has not been captured.
- **All six chains are missing a normal-play witness.** No chain has been played from an unfixtured save through ordinary travel. The two-peer receipt proof (F10#1, `ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f10_side_chain_receipts/PROOF.md`) set the prerequisite main-route flags as fixtures and moved players with `explore_at` debug travel. It proves the actions and receipts, not the ordinary route.

## Common lure layer (all chains)

- **Journal:** each chain has a `revealed_by` flag. When that main-route fact is set, `scripts/world/quest_log.gd` adds the chain to the quest log with the current step `label`, so every chain gets a journal lure.
- **World lure:** each chain also has an in-world lure, listed per chain below. Each is either an NPC greeting that switches to the side-chain conversation (branches in `stormwood_chapter.gd::npc_spec`, `stormwood_pims_parcels.gd::branches_for` and `stormwood_glass_for_bryn.gd::branches_for`) or a prompt on an object.

## stormwood_dark_arches (Ashfoot→Deepwood)

| Field | Finding |
|---|---|
| Lure | **Journal:** the chain appears after `stormwood:ashfoot_arch_relit`. **World:** the four dark arches c_rodline, c_lantern, d_hall and d_giant stand as visible dark structures once `rootgate_released`, each with a "Relight <name> · 3 Stormglass" prompt. **Dialogue:** Hesk's early lines name the dark arches. |
| Action | Try or relight a dark arch; the first attempt is the inspection count fact. Pay 3 Stormglass per end through the ledger (`stormwood_relight_arch`), 12 in total for both pairs. Then tell Hesk. |
| Payoff vs WORLD target | **Target:** "Those physical routes become reusable and visible on known map … no duplicate material reward." **Reusable:** lit pairs are traversable arch passages (`travel_for_peer`). **Visible on known map:** this was **missing on main** (no arch appears in `stormwood_world.json` landmarks and nothing writes a map marker). This branch fixes it: each end of a pair with both ends lit becomes a `gate` marker on the player's Stormwood map, named "<arch> · road to <twin>". **No material reward:** confirmed; none is granted. |
| Acknowledgement | `stormwood_hesk_dark_arches_report`: Hesk describes Rodfolk crews moving from the Hall to the deep trunks. The chapter emits step 3 when the report finishes. |
| Saved completion | World-scoped flags `stormwood:side_dark_arches_{1,2,complete}` plus the inspection count flags. The two-peer PROOF showed they survive a reload. |
| Ordinary route | Requires `ashfoot_arch_relit` and `rootgate_released` (main route) and ordinary Stormglass from Breaks. Steps 1–3 run through production prompts and NPCs. **No normal-play witness yet.** |
| Evidence | `test_stormwood_dark_arches` (5 tests). New `test_stormwood_b_dark_arches_map` (3 tests): fails before the fix (parse error: `sync_dark_arch_map` not found) and passes after. `smoke_stormwood_arches` PASS with the new sync running on the live runtime (0 SCRIPT ERROR). |
| Verdict | **MET on source and unit tests** after this branch. **Open:** (a) no in-engine capture of the markers on the minimap or full map; (b) no normal-play witness. |

## stormwood_pims_parcels (Lantern Pools)

| Field | Finding |
|---|---|
| Lure | **Journal:** after `lantern_pools_linked`. **World:** Pim's greeting switches to `stormwood_pim_parcels_offer` ("my sealed parcels have sat on this ledge…"). |
| Action | Accept the parcels, then deliver them by finishing the conversations with Marl (Ashfoot), Oswin (Rodline Post) and Lio (Lantern Hollow): three count flags, no inventory items. Return to Pim. |
| Payoff vs WORLD target | **Target:** residents visibly receive supplies, and each eligible character gets 2 small potions once. **Match:** a crate prop (`PimParcel_<recipient>`) appears at each household once delivered. `reward_grant` pays `potion_small` ×2 per stable character once, through the reward-delivery receipt. |
| Acknowledgement | Each recipient has a delivery line. Pim's return line, then her thanks line. |
| Saved completion | World-scoped step and delivered flags, the delivery journal, and the player-scoped `pims_parcels_reward_received` greeting preference. Proved on two peers. |
| Ordinary route | Deliveries follow the lit arch roads. Lio needs Lantern Hollow (Rootgate) first, which the progress line states. **No normal-play witness yet.** |
| Evidence | `test_stormwood_pims_parcels` (7 tests) pass. |
| Verdict | **MET on source and tests.** **Open:** normal-play witness. |

## stormwood_crown_remembers (Hollow Crown)

| Field | Finding |
|---|---|
| Lure | **Journal:** after `crown_reached`. **World:** three glass-scored record stones with cyan glyphs and "read" prompts around the heartstone grove (`stormwood_crown_records.gd` RECORDS). |
| Action | Read all three records to their last line (count facts), then speak to Wen after the main truth conversation. |
| Payoff vs WORLD target | **Target:** complete account plus an already-authored Crown cache location, with the original cache reward counted once and no Heartstone shortcut. **Match:** `stormwood_wen_crown_records_return` gives the complete account and points to the existing island store ("north-west of the grove where Neri keeps watch"). The runtime grants no item and writes no main flag; the cache keeps its own one-time pickup receipt. |
| Acknowledgement | Wen's records-return conversation. |
| Saved completion | World-scoped record, step and completion flags. Proved on two peers. |
| Ordinary route | Needs the Crown (a built arch pair) and the guardian settled for Wen. **No normal-play witness yet.** |
| Evidence | `test_stormwood_crown_remembers` (4 tests) pass. |
| Verdict | **MET on source and tests.** **Open:** normal-play witness. The cache location is given only as words; there is no map pin (WORLD does not require one). |

## stormwood_glass_for_bryn (Conductor Run)

| Field | Finding |
|---|---|
| Lure | **Journal:** after `bryn_met`. **World:** Bryn's greeting switches to the glass offer and request branches. |
| Action | Speak to Bryn. Hand over 3 ordinary Stormglass and 2 Conductor Vine once, in a host-owned single journaled delta. Inspect the repaired supplies at Rodline Post. |
| Payoff vs WORLD target | **Target:** the rod shelter becomes a usable safe care point with one creature bed, with no duplicate rod disable or Calm multiplier. **Match:** a `rest_point.gd` care offer "Rest at the rod crews' shelter" plus one creature bed at a reserved index. No rod flag, camp rod or Surge change (tested). |
| Acknowledgement | Bryn's thanks. The shelter changes visibly: supplies and the bed appear. |
| Saved completion | World-scoped `side_glass_for_bryn_*` and `_thanked`. Proved on two peers. |
| Ordinary route | Bryn is on the main route at Rodline Post, and the materials are ordinary harvests. **No normal-play witness yet.** |
| Evidence | `test_stormwood_glass_for_bryn` (13 tests) pass. `smoke_stormwood_glass_for_bryn` OK: 50 assertions, 0 failures. |
| Verdict | **MET on source and tests.** **Open:** normal-play witness. The shared-file finding from WO-F10-09 still applies: a guest's rest vote is lost until the host has rested (`scripts/world/night_rest.gd` mounts SleepVote lazily). It limits a co-op guest's use of this payoff. |

## stormwood_raise_a_road (optional footings, including Deepwood)

| Field | Finding |
|---|---|
| Lure | **Journal:** after `arch_recipe_known`. **World:** optional footings show "Choose this footing for your road" until two are chosen. |
| Action | Choose 2 of verge_road, hollows_road, capacitor_grove and deepwood_road. Build and bind a Stormglass Arch at each through `build_place`, within `player_pair_limit`. Travel both directions (two departed flags). Report to Ondra. |
| Payoff vs WORLD target | **Target:** a durable player-selected shortcut pair, with no refunded cost or fourth pair; the travel itself is the payoff. **Match:** a placed-building arch pair with the pair cap in `stormwood_arch_build_rules.gd`; no refund. Optional, and no story gate depends on it. |
| Acknowledgement | `stormwood_ondra_raise_a_road_report`. |
| Saved completion | World-scoped chosen, departed and step flags plus the placed buildings. Proved on two peers. |
| Ordinary route | Footings are available on the main route after Ondra's recipe, and the materials are ordinary. **No normal-play witness yet.** The two-peer proof used Free Build, so materials were not charged. |
| Evidence | `test_stormwood_raise_a_road` (5 tests) pass. `smoke_stormwood_road_arrival` exists (9/0 per WO-F10-09); it was not rerun here. |
| Verdict | **MET on source and tests.** **Open:** normal-play witness; no charged-material run. |

## stormwood_deepwood_circuit (Deepwood)

| Field | Finding |
|---|---|
| Lure | **Journal:** after `lantern_hollow_reached`. **World:** Rook's greeting switches to `stormwood_rook_circuit_offer`. |
| Action | Accept the circuit. Defeat any 3 distinct trainers of the 5 in `group: deepwood_circuit`; earlier wins count. Return to Rook. |
| Payoff vs WORLD target | **Target:** "Team acknowledgement and one authored Electric TM reward through existing entitlement/receipt … No infinite rematch tier." **Missing:** completing the chain grants nothing. No code or data path ties `side_deepwood_circuit_complete` to a TM or any `reward_grant`; grep across `data/config/stormwood_*.json` and `scripts/world/stormwood_*.gd` finds no TM. Electric TMs exist as items (`tm_static_snap`, `tm_voltaic_whip`, `tm_thunder_break`, `tm_stormfall` in `data/moves/tms.json` and `stormwood_pickups.json`), but each already has its own world pickup source. |
| Acknowledgement | `stormwood_rook_circuit_return` ("Three posts, one continuous road…"). |
| Saved completion | World-scoped step and win count flags. Proved on two peers; the wins were fixtured there. |
| Ordinary route | The trainers are real hosted fights on the Deepwood loop. **No normal-play witness yet.** In the two-peer run, pressing at Rook always opened his conversation. |
| Evidence | `test_stormwood_deepwood_circuit` (3 tests) pass. `smoke_stormwood_deepwood_circuit_wiring` OK. |
| Verdict | **GAP.** **Missing piece:** a once-per-character Electric TM `reward_grant` on the circuit's completion (Rook's return), the same pattern as Pim's rate, with its receipt. **Needs a decision:** which authored Electric TM to use. Reusing a TM that already has a world pickup would give that TM two sources, so this choice is a PROGRESSION/CREATURES decision and was not made here. |

## Map-layer fix (this branch)

- **What changed:**
  - `scripts/world/stormwood_arch_runtime.gd` gains `DARK_MAP_PREFIX`, `DARK_MAP_ICON`, `dark_arch_map_markers(flags)` and `sync_dark_arch_map(map, flags)`.
  - `restore_progression_from_game` calls the sync against `Game.bind_realm_map("stormwood")` on every progression or world revision change.
- **Behaviour:**
  - Markers are derived from world lit flags through `RULES.linked_twin`: both ends must be available and lit.
  - Stale markers are removed, so a character in a world with dark arches shows none.
  - A repeated sync makes no revision bump.
  - No flag, save field or shared file changes. The existing map save keeps dynamic markers, and they are re-derived on load.
- **Scope choice:** only the dark pairs C and D get markers. Story pairs A and B and the Crown are unchanged.
- **Rendering (read from the code, not captured):**
  - The minimap draws dynamic markers as a cream dot, the same as camps.
  - The full map draws the `gate` icon.
  - The d_giant marker sits on the Fallen Giant landmark's position, so on the minimap the lower-priority icon yields when they overlap.
- **SHARED-FILE REQUEST (optional polish, not required for the target):** give the arch-road marker its own shape on the minimap.
  - **File:** `scripts/ui/minimap.gd` `_draw_landmarks`, the dynamic branch.
  - **Change:** draw ids with prefix `stormwood_arch_road_` using the gate or arch glyph instead of the generic camp dot.
  - **Why:** on the minimap a relit road end currently reads as a camp.

## Commands and results (Linux container, Godot 4.7.stable)

These runs were made after `git sparse-checkout disable` and two `godot --headless --path . --import` runs.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_b_dark_arches_map` (before the fix) | 1 failed: parse error, `sync_dark_arch_map` not found. This is the expected pre-fix failure. |
| `… --only=test_stormwood_dark_arches,test_stormwood_pims_parcels,test_stormwood_crown_remembers,test_stormwood_glass_for_bryn,test_stormwood_raise_a_road,test_stormwood_deepwood_circuit` (baseline) | 37 tests, 1148 assertions, 0 failed, 0 SCRIPT ERROR. |
| Same six plus `test_stormwood_b_dark_arches_map` (after the fix) | 40 tests, 1163 assertions, 0 failed, 0 SCRIPT ERROR. |
| `… --only=stormwood_arch,realm_map,map_realm_view` (after the fix) | 42 tests, 425 assertions, 0 failed, 0 SCRIPT ERROR. |
| `godot --headless --path . --script tests/smoke_stormwood_glass_for_bryn.gd` | Exit 0: "STORMWOOD GLASS FOR BRYN OK: 50 assertions, 0 failures". |
| `… tests/smoke_stormwood_deepwood_circuit_wiring.gd` | Exit 0: "Rook -> any three distinct real trainer facts -> Rook". |
| `… tests/smoke_stormwood_arches.gd` (after the fix) | Exit 0: "STORMWOOD ARCHES: PASS", 0 SCRIPT ERROR. |

## Remaining gaps (what closes F10#0)

1. **Deepwood Circuit Electric TM reward.**
   - Needs an owner or PROGRESSION choice of which TM. A TM that already has a world pickup must not end up with a second source.
   - The implementation is then Stormwood-owned: a `reward_grant` on Rook's return, with a receipt test.
2. **Normal-play witness for all six chains.** This means a recorded run from an earned save, not flag fixtures or `explore_at`, showing each lure at the normal camera and each completion.
3. **In-engine capture of the relit dark-road markers** on the minimap and on the Tab map.
