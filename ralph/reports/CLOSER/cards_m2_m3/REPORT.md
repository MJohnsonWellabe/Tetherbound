# Cards M2 and M3: status and options (Closer lane, 2026-09-29, read-only research)

Sources read: `docs/ACCEPTANCE.md` §6 (chapter cards, §6.1), `docs/STATE.md` (card table, Cards lane rows, Meadows handoff),
`ralph/reports/COORDINATOR/dashboard/criteria.json` (`chapter_cards`, F03/F04 rows), `ralph/reports/CARDS/m2/*`,
`ralph/reports/CLOSER/bridge_proof/run2.txt`/`run3.txt`, `tests/smoke_four_biome_continuous.gd`, `tests/helpers/meadows_earned_hall_segment.gd`,
`tests/helpers/meadows_earned_warrens_segment.gd` (care/top-up), `tests/helpers/cloudreach_live_segment.gd` (`CampaignPilot`), `tools/combat_pilot.gd`,
`tests/helpers/combat_depth_pilot.gd`, `tests/smoke_meadows_named_c2c3.gd`, `docs/design/BOSSES.md` §4, `docs/design/PROGRESSION.md`.
Nothing was run (no Godot in this container). Figures below are from the recorded logs.

## 1. Card M3 (fights, activities and presentation): FAILING

### Exact clauses (ACCEPTANCE §6 card table, "Meadows / M3")
1. At least six qualified optional activities, including one in each principal region, satisfy §5.
2. Warrens guardian, relay officers and Warden each show distinct, readable tells and actual hit/avoidance at the normal fight camera.
3. C2/C3 pass, and a blind fight-footage verdict passes.
4. ART_DIRECTION's Meadows frame matrix, village topology, creature silhouettes, landmark/water presence and the device profile (§7) pass Bars A/B without a blocking domain defect.
(§6.1 adds: full Bars A/B code-blind verdict on every visual row; device profile is a 1920x1080 Compatibility capture judged for 7-inch readability.)

### Status by clause
| Clause | State | Evidence |
|---|---|---|
| 1 Six activities | MET on function. F03 8/8 criteria met, strict re-check MET. | `criteria.json` F03 (pct 100); `ralph/reports/MEADOWS/f03/`; STATE "F03#0 is met". The `chapter_cards` M3 note ("F03 has 2 conditional activities") is stale. |
| 2 Tells and hit/avoidance | PARTIAL. F04 is 5 of 9 met. Met: Warrens guardian tell (#0), Warden tell (#3), real hit/avoidance witness (#4), specified timing (#5), no wild inherits a boss override (#8). | `criteria.json` F04; `ralph/reports/MEADOWS/f04/RECHECK_F04_3.md` |
| 2 open items | F04#1 relay officers: no visible lunge travel / path telegraph; last judge failed framing on the player's creature overlapping the opponent at contact range. F04#2 three captains: same contact-range separation. F04#6 aftermath: r5 judge failed; #437's fixes (in the consolidated PR #442) are not re-judged. F04#7 varied-size framing and C3 blind footage: contact-range separation plus a Vance face occlusion. | STATE Meadows handoff "Open defects"; `ralph/reports/MEADOWS/f04/final_F04_{1,2,6,7}/BAR.md`; `JUDGE_F04_1_relay_ccecb414.md`, `JUDGE_C3_small_257839f5.md`, `JUDGE_F04_6_aftermath_r5.md` |
| 3 C2 | MET on the Balance half (ruling 12, `ralph/reports/BALANCE/`); the C3 halves stay open (F04#7). | STATE Balance lane line |
| 3 Blind fight footage | NOT MET. Meadows R7 blind read: key art no, Palworld yes, tells "partly". | `criteria.json` M3 note |
| 4 Frame matrix, silhouettes, landmark/water, Bars A/B | NOT MET / Phase 2. Bars A/B are aspirational/open for the pass; Codex owns the Phase 2 catalog. | ACCEPTANCE §4; STATE "Bars A/B → Phase 2" |
| 4 Device profile | NOT MET. F10#6 r7 (7-inch sheet, two judges) contradicted each other on Q1 and the fight frames were missing, so tells and subject were not judgeable. Small HUD text is illegible at 7 inches (owner: HUD/F10#6, Stormwood lane). | STATE HEAD commits c937a95e, 11a86812; Cards row T2 |

### What M3 waits on
- F04#1, #2, #6, #7 (Meadows lane). Contact spacing (`tb/combat-spacing`) landed via #442 (STATE serial-closer line), so the F04#1/#2/#7-C3 renders that were waiting on it are now unblocked. STATE's final-round rules: one render per criterion against `BAR.md`, at most 2 render jobs at a time, F04#6 renders on main after #437's content merges, a fail records defects and ends that criterion's rounds.
- F10#6 (fight HUD column covering trainer/attack lanes) for the device-profile clause.
- Phase 2 Bars A/B (Codex) for clause 4. An agent may not lower the Bars to close the card (ACCEPTANCE §4).
- M2 is independent of M3 except that both wait on F04#1/#2/#6/#7.

### Recommendation (M3)
Do not chase the card as a whole yet. Next step: run the final-round F04 renders in STATE's order (F04#1, #2, #7 C3 on main now that spacing has merged; then F04#6). Then a one-line rescore of `chapter_cards` M3 (fix the stale note). Decision needed: none from the owner to render; the coordinator must confirm render-job budget. The device-profile and Bars A/B clauses need an owner ruling only if the coordinator wants M3 declared without the Phase 2 catalog (ACCEPTANCE says it may not be).

## 2. Card M2 (earned spine and economy): PARTIAL, blocked on Keeper Hald

### Clause
One fresh save reaches Cloudreach through every §6 gate with no teleport, state injection or mandatory wild replay; two-loss and four-character ledgers solvent (ruled solvent); save/reload at bridge, relay, Sigils and aftermath keeps exact rewards; no A7 empty route interval or WORLD §3.1 spacing violation (the Hall-exit walk of about 326 m is exempt). Relaxed proof (owner 2026-09-27) allows disclosed harness aids.

### What is proven now
- South Bridge guardian: FIXED and proven on main by the Closer runs. `bridge_proof/run2.txt`: `south_bridge_crossed`, wins 2, hits 30, failures [], exit 0, 1556 s. `run3.txt`: wins 2, hits 29, failures [], exit 0, 1719 s. With Meadows run 1 (hits 38) that is 3 of 3. The fix is `combat.json` `arena.trainer_ally_lateral_ranks` (lateral seat only for officer/captain/warden ranks).
- Opening through tournament 4/4 (M1). Past the bridge (earlier diagnostic runs): Warrens, relay (after the harness read of the captain's victory lines), three Sigil captains 3/3, Hall patrol and courtyard 3/3.
- Note `run3.txt` line 516 shows a "CONTENT WALK FAILURE" diagnostic (Bramblebun call-out) that did not fail the run (failures []); worth a look but it is not a blocker.

### Exact remaining blockers
1. **Keeper Hald (`stronghold_elite`, L18 Galecrest DIVER, L19 Burrowback, Trailpup, Duskhush, Mosshell WALL) beats the earned five 0/3** ("The actual captain encounter ended without victory: lost", `resume_hall1.txt` line 36, `resume_hall2.txt`, `resume_relayhall.txt`). `_fight_named` in `tests/helpers/meadows_earned_hall_segment.gd` (line ~252) makes `_on_exit` non-"won" a hard `_fail` and has no retry.
2. **The five arrive under-levelled and depleted.** Logged pre-Hald party: about L15-L17 (Hald's team is L18-19) with HP 44-179 of 173-228 and `"potions_left": 0` at every trainer top-up (`resume_hall1.txt` lines 34-38; potions are 0 from the relay onward in `resume_relayhall.txt`). Earlier gain is only +2 small potions per Hall fight. So even a perfect heal aid needs a healing source (bed/camp, or crafted potions), otherwise a retry replays the same loss.
3. **The pilot is the weak one.** `CampaignPilot` extends `tools/combat_pilot.gd` (SPACER: retreat when a wind-up shows, otherwise walk and hit), with `use_switching = false`. The READER in `tests/helpers/combat_depth_pilot.gd` also sidesteps cones and travelling lunge lanes (Hald opens with a DIVER) and reserves wind. ROUTE_FINDINGS says the earned pilot "plays like a masher"; ruling 12 says a masher loses at least one named fight in 94-100% of playthroughs, so this loss is by design.
4. Not yet reached: Warden, Veridian (M4 finale), Cloudreach crossing on one uninterrupted run. Also STATE says M2 "waits on F04#1, #2, #6, #7"; that dependency is counting only, not a code dependency.
5. `--resume-from` runs are `counts_as_proof: false` and stop after the Hall ("the Warden onward runs only from a new game", smoke_four_biome_continuous.gd ~line 184). So the closing M2 run must be fresh from the title.

### Options for Hald
| | (a) Heal-and-retry aid in the route harness | (b) Reader pilot for the Hald fight in the harness | (c) Balance change |
|---|---|---|---|
| Kind | Test-harness only, disclosed as a relaxed-proof aid (ruling 2026-09-27). | Test-harness only. | **Product change; needs owner/Balance-lane decision.** Combat numbers are frozen without the coordinator; do not propose as approved. |
| Code | In `meadows_earned_hall_segment.gd::_fight_named`: on `_on_exit` outcome "lost" stop calling `_fail`; instead record a `retry` receipt, replay what the player would (return to the post-loss respawn/camp, use the bed, `_prepare_for_trainer()`, re-approach the prompt, re-`_talk`), reset `_captain_*` counters, cap at N attempts (e.g. 3), and make `_captain_rounds/wins` checks per attempt. The `_on_exit` override (line ~ `_captain_active` in relay/hall observers) must not fail on the first loss. Note BOSSES says defeat "returns to the last regional camp and does not clear any captain", so the harness must walk back from the camp (real travel) or it becomes a teleport. Also needs a healing source: use the camp bed if one exists before Hald (BOSSES 4.4: the bed is after Hald, not before) or accept a disclosed heal write. | Swap `LIVE.CampaignPilot` for a Meadows-local `CampaignPilot` variant that ports READER logic (wind reserve, `_sidestep_cone`, `_clear_lunge_lane`, stagger/recovery read, and `use_switching = true` to use the matchup arrow); confined to `_fight_named` for `stronghold_elite`, or all Hall fights. Reuse from `combat_depth_pilot.gd` (which drives a wild on a flat fixture) needs adapting to the live director/rig input path (`_move_toward`, camera basis). | Options: raise earned levels/XP on the Hall spine, add potions from the Hall guards, or soften Hald. Any of these touches `data/config/bands/*`, `trainers.json`, or PROGRESSION economy, and must keep ruling 12 (reader >=75%, masher loses lead, reader cost <=55% of masher's). |
| Cost | About 1-2 days of Cards-lane work plus a new unit test; each verify is 40-55 min from the relay checkpoint. Low. | 2-4 days; the biggest risk is that a port of READER is still not enough (party is 1-3 levels under and at reduced HP), and each attempt costs ~40 min to reach Hald. Medium. | Cheapest to write, but it needs Balance seeds (24 per starter per fight, `smoke_meadows_named_c2c3.gd`) and a fresh route run; it also reopens F04#7's just-landed ruling. High process cost. |
| Risk | Proof is weaker: M2 would be "relaxed proof" with a retry (allowed by the owner ruling if disclosed). Risk of masking a real solvency defect (potions 0). | Might not win Hald at L15-17 even with a good reader; then falls back to (a). Also creates a second pilot to maintain. | Silent difficulty/economy decision; conflicts with the owner's harder-trainers direction unless the owner accepts it. |
| Owner decision? | No (harness aid; must be disclosed in the READY post/board). | No. | **Yes**, plus the coordinator releases frozen combat numbers. |

Recommended combination: (a) first, because it directly models what a player does after a loss and it is the choice named by ROUTE_FINDINGS and STATE; add (b) only if Hald still beats the pilot after one retry with full recovery. Plan the retry to include a real return-to-camp walk and bed recovery so the aid is not a teleport. Separately, flag to the coordinator that the pre-Hald party sits at L15-17 with zero potions: if the owner wants a masher to lose about once per playthrough that is intended, but a reader also needs to beat Hald at that level and the F04#7 reader-win check (>=75% at 24 seeds) says it does in the depth fixture; whether it does on the live route is exactly what (b) would measure.

### Restart command for M2
STATE Cards row (verbatim):
```
TB_WORLD_SEED=15 godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --route-ledger --m4-finale --through-meadows --resume-from=user://four_biome_checkpoints/relay_disabled_and_mill_crossed_19623
```
- That checkpoint was written in the Cards container only. **It does not exist here** (searched the filesystem; only `tests/fixtures/earned_saves/checkpoints/{c1_flight_trained,seed4_hall}` are in the repo, and neither is the seed-15 relay save). It was also written with `trainer_ally_lateral_m` 0.0, so it is debug only, `counts_as_proof: false`, and stops after the Hall.
- **Closing run (fresh container or otherwise): omit `--resume-from`** and run from the title:
```
TB_WORLD_SEED=15 godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --route-ledger --m4-finale --through-meadows
```
  Run on a main that contains the bridge fix and the relay harness fix (PR #442; the bridge proof used it). Godot is not installed in this container, so it needs the CI/Godot environment.
- Housekeeping between runs (STATE): clear `four_biome_*`, `worlds`, `saves` and the coverage jsonl; disk allowance is about 300 MB.
- Runtime, from the logs: fresh through the bridge 1556-1719 s (26-29 min); opening/tournament alone about 1159 s (M1); the relay checkpoint to Hald about 2220-2230 s (37 min; `resume_hall1/2`), 3226 s (54 min) for `resume_relayhall.txt` (relay through Hald). Estimate for a full fresh run through the Hall: about 1.25-1.5 hours. Warden, Veridian and the Cloudreach crossing have no timing yet (estimate a further 20-40 min, unmeasured). Plan on roughly 2 hours per full attempt, more with retries.

### Recommendation (M2)
Next step: assign the Cards lane to implement (a) in the Hall segment (test-only) with a unit test and a disclosed-aid line, verify with a resume run on a seed-15 Hall checkpoint, then run one fresh full M2. Decision needed from the coordinator: approve (a) as the accepted M2 harness aid (relaxed-proof) and confirm the run budget of about 2 hours per attempt; no owner decision is needed unless (c) is wanted. If the owner prefers that a reader alone clears Hald without a retry, it is a Balance-lane/owner call and combat numbers stay frozen until the coordinator releases them.
