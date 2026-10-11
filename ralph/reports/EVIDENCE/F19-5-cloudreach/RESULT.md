# F19#5, Cloudreach part: earned checkpoint saves at each segment boundary

All times are US Central. Run date: 2026-10-11, 06:50–08:42 CT. Base: main 9e39d0086, branch tb/ev-cloudreach-route.

- **Commands:** `GODOT=godot tools/earned_saves/run_cloudreach_chain.sh tests/fixtures/earned_saves/cloudreach_arrival_generated <root>` (segments 01–04, commit 2c1d38f09). Segment 05 was re-run from the 04 checkpoint with `... <root> 05_stronghold` (commit 3596183f2).
- **Per piece:** `godot --headless --path . --script tools/earned_saves/cloudreach_chain_runner.gd -- --segment=<id> --from=<prev> --out=<dir>`. Clock is 1x; no `--accelerated`.
- **Protocol:** fresh process per piece. The production title is driven by controller focus: Load Game → Autosave (slot 0). The piece runs a verbatim slice of `cloudreach_live_segment.gd::_run_route()` on `f49_cloudreach_chapter.gd`, then `Game.save_game(0)`. There are no teleports and no flag, inventory, party or HP writes.
- **Completion check:** each piece is proven by its terminal flags. A script error can never pass a piece.
- **Handoff check:** each piece compares its loaded ordered UIDs, flags and inventory with the previous piece's saved after-state.

| Seg | Result | Checkpoint | Notes |
|---|---|---|---|
| 01 arrival + lower-cliffs gate | PASS | tests/fixtures/earned_saves/cloudreach_01_arrival_gate | Loaded UIDs equal the generated start's order. |
| 02 broken causeways | PASS | tests/fixtures/earned_saves/cloudreach_02_broken_causeways | Senn won; handoff matches. |
| 03 flight training | PASS | tests/fixtures/earned_saves/cloudreach_03_flight_training | Maela won; aerie rest; Fly ring trial; handoff matches. |
| 04 aviary/roost (High Roost shrine) | PASS | tests/fixtures/earned_saves/cloudreach_04_high_roost | Shrine landing, vanes, Sora, windlass, return flight to the aerie; handoff matches. |
| 05 stronghold | FAIL | none written (05_stronghold.receipt.json) | Lost Officer Voss. |
| 06 Veyra + relay | NOT RUN | none | Blocked by 05. |
| 07 Stormward handoff | NOT RUN | none | Blocked by 05. |

## Gaps

1. **05: Officer Voss is unwinnable for the party this route produces.**
   - Voss fields stormcapra L41, cloudfang L42 and skyrill L42 (`cloudreach_chapter.json` level_band 41–42).
   - The required-path route reaches him with the generated five still at L31 and full HP after the summit bivouac. The required beats (Senn, Maela) gave little XP. `redesign_level_curve.json` expects 39–42 by upper Cloudreach.
   - Live SPACER pilot result: all five fainted. Hits 69 dealt / 31 taken; damage 732 dealt / 1568 taken.
   - The progression between arrival L31 and the Voss band is not supplied by the required route or the helper. This needs a curve/route decision; no small code fix exists.
2. **Static cliff-shoulder stall (open game defect).** On the 05 first attempt, the capsule stopped dead (velocity 0, floor normal y 0.93) on the counterweight pass at (-791.8, 641.4, 3536.3), against `WindscarCounterweightPassCliffShoulders/Ridge003`. This is the same family as the witness-route C1 stalls.
   - The runner now carries the witness route's disclosed stick-sidestep recovery.
   - The 05 re-run passed that spot without needing it (`static_sidesteps: []`).
3. **Stale resource prompt on a day roll (helper defect).**
   - The generated arrival clock is 512.7 s into a 600 s day, so `Game.day` rolls about 87 s after load. `cloudreach_resource_patch.gd` then rebuilds its DailyHarvest child, and the helper's pre-walk prompt reference is freed: SCRIPT ERROR in `_arrival_gather`.
   - Without the completion check, the earlier runner would have saved a false PASS here.
   - The runner's Piece re-reads the prompt after the walk (disclosed). The shared helper is unchanged.

## Disclosures

- The start save is the generated arrival (`prior_earned_play: false`).
- The helper's camp rest snaps the day cycle to night (F47#4, helper-disclosed).
- Fly climb uses held jump (owner's Fly exception).
- Each checkpoint's PROVENANCE.json and receipt.json carry its own command, commit, start save and disclosures.

## Separate finding: cliff-shoulder collider stops the trainer dead on the counterweight pass (world-collision defect)

- **Where:** `AuthoredRoutes/WindscarCounterweightPassCliffShoulders/Ridge003/Collision`, on route `windscar_counterweight_pass` between waypoints (-820, 620, 3480) and (-720, 700, 3680).
- **Body stopped at:** (-791.83, 641.39, 3536.28). That is on the route centreline: the closest centreline point is about (-791.8, 642.5, 3536.3).
- **Contact:** a single contact with floor normal (-0.159, 0.934, -0.320).
- **Body state:** velocity 0, last_motion about 5e-5. Stick input was (0.22, -0.98), wanted direction (0.45, 0, 0.89), walk speed 5.0. The trainer had no modal open, no fight, no hazard and no mobile contact.
- **Log:** `05_stronghold.attempt1.log.gz` (collision_block row).
- **Not deterministic:** the 05 re-run walked past the same spot without stalling.
- **Same family:** the witness route already records this collider type (Windscar Ridge003, lower causeway Ridge000, summit road Ridge001).
- **Current handling:** recovered by the disclosed stick sidestep. The defect itself is open (coordinator ruling 2026-10-11).

## Pieces 06–07 from a disclosed generated post-05 boundary (coordinator ruling 2026-10-11)

- **Input:** `tools/earned_saves/generate_boundary_save.gd -- --profile=cloudreach_veyra --slot=0 --out=<dir>`. The profile is in `generated_boundary_profiles.json`.
  - Same five template UIDs, L40, full HP, on the summit deck at (100, 1160.13, 5350).
  - Act-III flags through `summit_extraction_engine_reached` are generated. The input is NOT earned.
  - See `generated_after_05.PROVENANCE.json`.
- **06 run a** (08:52 CT, log `06_veyra_relay.run4a.log.gz`):
  - The live pilot won all three of Veyra's rounds: aeriex, cloudfang, galecrest.
  - The battle never ended. It timed out at the helper's 36000-frame limit with no victory or loss callback.
- **06 run b** (09:17 CT, log `run4b`), with a read-only director dump:
  - `boss_pending_win: true`, `encounter_id: ""`, `retained_boss_participants: []`, manager outcome `won`, `is_host: true`, `redesign_boss_handoff_runtime_enabled: true`.
- **Root cause (game defect, F19#2 live path):**
  - `encounter_director.gd::_open_encounter_if_networked` mints the host encounter record only for multi-peer, master or rematch battles.
  - A solo boss with a chapter hand-off (Veyra; by the same code, the other `chapter_rewards.json` boss_handoffs on base-director paths) never gets a record.
  - `session.gd::foundation_boss_outcome` then returns non-durable on every retry, and `_finish_trainer_battle` keeps `_boss_pending_win` forever.
  - The unit tests `test_f19_boss_handoffs` and `test_f19_participant_delivery` pass (30 tests, 0 failed, with and without the attempt). They do not cover this live solo path.
- **Fix attempt 1** (commit aab341e1, reverted in a86b733b): extend that exception to bosses with a hand-off. Run 09:41 CT (log `run4`): round 1 resolved `fled` after 2 frames, so the battle reported a loss.
  - Minting the ordinary record in solo is refused further in (likely the ordinary reward-owner install).
  - The next option would invent a solo encounter identity for a durable journal. That is a transaction-semantics decision; coordinator ruling needed.
- **Result:** 06 FAIL (Veyra never resolves solo); 07 NOT RUN.

## 05 Officer Voss: WAITING ON OWNER (level-gap decision deferred to the end; no XP or level numbers changed)

- **Team at Voss:** the five ordered template creatures, all L31, full HP after the summit-bivouac rest. Order: terrapup, bramblebun, bramblebun, mudsnout, bramblebun.
- **Opponents:** stormcapra L41, cloudfang L42, skyrill L42 (`cloudreach_chapter.json` officer_voss_summit_approach, level_band 41–42).
- **Fight (live SPACER pilot):** lost; all five fainted.
  - Hits: 69 dealt, 31 taken.
  - Damage: 732 dealt, 1568 taken.
  - Inputs: 129 quick, 17 charged; 0 switches.
- **Route XP earned, arrival through piece 04:**

  | Creature | Arrival | After 04 | XP gained |
  |---|---|---|---|
  | terrapup | L31 / 0 xp | L31 / 898 | 898 |
  | bramblebun | L31 / 0 xp | L31 / 1185 | 1185 |
  | bramblebun | L31 / 0 xp | L31 / 1512 | 1512 |
  | mudsnout | L31 / 0 xp | L31 / 1196 | 1196 |
  | bramblebun | L31 / 0 xp | L31 / 579 | 579 |

  No level-ups. Senn and Maela were the only fights; wild fights and optional trainers are not on the required route.
- **After 05**, which includes the Voss loss and the stronghold walk: terrapup L31/1584, bramblebun L32/155, bramblebun L32/131, mudsnout L31/1196, bramblebun L31/1273.
- **The gap:** `redesign_level_curve.json` expects team L39–42 by upper Cloudreach. The required route ends 05 at L31–32.

## F19#2 solo boss hand-off fix (coordinator ruling "solo is a session of one"; commit 34df191a, guard included)

- `encounter_director.gd`: a solo host mints the same host encounter record for any trainer in `chapter_rewards.json` boss_handoffs, with the local character as the single participant. This is the path masters and rematches already take.
- `session.gd::ordinary_combat_reward_owner`: a trainer outside the `trainers.json` per-round table now answers "not applicable" (`enabled: false`). Before, it answered "unavailable", which aborted the round as `fled`; that was attempt 1's failure.
  - The same "unavailable → fled" applied to every co-op Cloudreach trainer fight by that code.
  - `_install_ordinary_combat_reward_owner` already accepts "not applicable".

**Proofs:**
- **Units** (`unit_f19_and_director.fix.log`): 206 tests, 4950 assertions, 0 failed.
  - Suites: test_f19_boss_handoffs, test_f19_participant_delivery, test_ordinary_actor_vitals_recovery, test_combat_progression, test_f24_host_commands, test_director_join_snapshot, test_cloudreach_director_client_veyra, test_cloudreach_finale, test_trainer*.
  - One interim failure from an unguarded `_session.config()` on a test stub was fixed, not skipped.
- **Live solo Veyra (piece 06, 10:10 CT, log `06_veyra_relay.fixed.log.gz`):** won live.
  - Durable boss defeat receipt `defeat:boss_captain_veyra_storm_anchor_<hash>:character-cb1b…`.
  - `relics_held: [cloudreach]`, `stormwood_portal_key` ×1, coin +150, rare_candy +1.
  - Relay phase and chapter complete.
- **Save/reload, no duplicate:** piece 07 loaded the 06 save. Handoff check matched (UIDs, flags, inventory); `stormwood_portal_key` still 1 and the relic held once. The key was consumed only by entering Stormwood.
- **Solo Warden:** `tests/smoke_boss.gd` passes with the fix (log `smoke_boss.fix.log.gz`). However, that smoke runs without an active session, so it does not exercise the hand-off journal. An earned solo Warden through the title-loaded session path remains for the Meadows chain, which currently stops at Hall.
- **Co-op unchanged: NOT PROVEN HERE.** `tools/net/run_net_smoke.sh shared_boss` and `boss_rewards_each_participant` both failed before any gameplay with "not every peer said hello within 180 s". The peers were still building Meadows (peer logs). This happened twice: once alongside a live run, once alone.
  - The budget is `multiplayer.json` test_budgets `hello_budget_s`, with no env override.
  - Environment-speed limit of this 4-core container; needs a run on CI or a faster box.

## Pieces 06–07 (disclosed generated L40 input)

| Seg | Result | Checkpoint |
|---|---|---|
| 05 generated boundary (input) | generated, unearned | tests/fixtures/earned_saves/cloudreach_05_generated_veyra_boundary |
| 06 Veyra + relay | PASS (with the F19#2 fix) | tests/fixtures/earned_saves/cloudreach_06_veyra_relay |
| 07 Stormward handoff | PASS | tests/fixtures/earned_saves/cloudreach_07_stormward_handoff |

- **07 in the new order:** the physical Stormward gate is a retired crossing (`legacy_physical_crossings` false; RD-17/F18#2) and offers nothing. The handoff is therefore the F49 portal leg: Home Key, hang the Cloudreach relic, Stormwood arch, ending at (-300, 32.3, 180) in Stormwood.
  - The relic-power choice panel that a successful hang opens was dismissed with `menu_cancel`; no power was chosen.

## Co-op regression for the F19#2 fix (coordinator ruling 11:11 CT)

- **Disclosed budget change:** a LOCAL, UNCOMMITTED edit to `data/config/multiplayer.json` test_budgets, reverted after the runs. `hello_budget_s` 180→900, `smoke_step_budget_s_2peer` 300→3600, `smoke_step_budget_s_wide` 1500→7200. No assertion or gameplay bound touched.
- **Protocol:** each smoke ran alone, with the box otherwise idle.

| Smoke | Code | Result |
|---|---|---|
| `tools/net/run_net_smoke.sh shared_boss` | fix (3ffeb9fc) | **PASS** ("ALL CHECKS PASSED", exit 0) |
| `tools/net/run_net_smoke.sh boss_rewards_each_participant` | fix (3ffeb9fc) | FAIL |
| `tools/net/run_net_smoke.sh boss_rewards_each_participant` | main (9e39d0086's two files) | FAIL, identically |

- **shared_boss (fix):** co-op Warden world facts were committed once with no per-participant receipt, retained across reload on both peers, and the state hash agreed. Log `net_shared_boss.fix.budgets.log.gz`.
- **boss_rewards_each_participant (fix):** join, 2 participants and phase checks passed. It then failed "peer 0 beat Bryn's whole team (no verdict)". Log `….fix.budgets.log.gz`.
- **boss_rewards_each_participant (main):** the same checks passed and it failed at the same step with "(no verdict)". Log `….main.budgets.log.gz`.
  - So this failure is pre-existing, not caused by the fix.
  - Neither changed branch applies to Bryn: `practice_trainer` is in the `trainers.json` table and is not a chapter boss.
  - It remains an open defect outside this criterion.
- **Plain 2-peer Cloudreach trainer fight:** no such smoke exists. `smoke_net_cloudreach_veyra_reconnect` uses a disclosed fixture victory hook (`_record_trainer_defeat`), which bypasses fight start where the `fled` abort happened.
  - The claim that pre-fix co-op Cloudreach trainer fights abort as `fled` is INFERRED from code: the same `ordinary_combat_reward_owner` "unavailable" answer for non-trainers.json trainers. It is not observed in a co-op run.
