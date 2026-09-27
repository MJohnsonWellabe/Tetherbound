# Tidewake chapter dry run — blockers

**DRY RUN — fixture start, does not count.** Its purpose is to find every route blocker before the counting run from the earned handoff.

Driver: `tests/smoke_tidewake_dry_run.gd`. The only fixture is the declared start: gate flags `realm_gate_water_unlocked` + `stormwood:waterward_revealed`, key consumed, belt sparkit/mudsnout/bramblebun/terrapup/brooktail at L44, knife/axe. The world is built at its production arrival. Every beat after that is an existing segment helper driven by controller input: no pose, flag, ledger, HP or inventory writes. After each segment: production `Game.save_game` → world destroyed → `reset_for_new_game` → `Game.load_game` → fresh Water scene. Each save is copied to `cp_<name>/`; `--from=<name>` resumes there while debugging.

## Progress (latest head)
| Beat | Result | Wall time | Reload |
|---|---|---|---|
| start (fixture) → Pell lesson | PASS | 48 s | drift 0.00 m, same party |
| Reedhaven dock repair | PASS | 199 s | drift 0.00 m |
| Brine Steps trial (Tovin) | PASS | 213 s | drift 0.00 m |
| Shellwatch liberation (Solm, Irva, pump) | PASS (the earlier Irva loss did not reproduce) | 431 s | drift 0.00 m |
| Tidal Cradle: Aquaryn, Swim Stone, Iona recipe | **BLOCKED**: B1 (B2 fixed) | — | — |
| Salt Crown → Sluice → Veilfall → Nerissa → Guardian | not reached; B3 | — | — |
| Six local chains, eight pockets, the side islands | not yet composed; B5 | — | — |
| Return home (Stormwood → Cloudreach → Meadows → Grandpa) | no harness; B6 | — | — |

## Blockers
| ID | Where (world x, y, z) | Symptom | Root cause | Owning file | Status |
|---|---|---|---|---|---|
| B1 | Tidal Cradle, Aquaryn fight ≈ (599.5, 34.0, 1392.4) | The fight stalls; after the first hits neither side lands a hit for 150+ s | **Stale host Wind in shared encounters.** The host advances a participant's Wind only when they act (`_advance_participant_wind` from probe/`commit_wind`). Each published record carries the frozen value, and the client's `_sync_authoritative_wind` overwrites its locally regenerating Wind with it about every 7 frames. The Wind bar sticks near empty while the player waits. Trace: local Wind sawtooths 0 → 1.8 (18/s for about 7 frames) for 150 s. | `scripts/net/encounter_host.gd` (shared), `scripts/combat/combat_manager.gd` (shared) | SHARED-FILE REQUEST with a verified patch (`patches/host_wind_publish.patch`) |
| B2 | same fight | The pilot never attacks | The harness pilot kept the charged's Wind in reserve while the charged was **Energy**-gated (only landed quicks build Energy). A low-nourishment Wind cap (the soft low-food drawback) made it permanent. | `tests/helpers/water_combat_pilot.gd` | Fixed be48991b (paid quicks while Energy-gated) |
| B2b | Aquaryn challenge | "challenge does not win at the physical outside stance" (intermittent) | The stance is computed once while Aquaryn keeps moving | `tests/helpers/water_tidal_segment.gd` | Fixed be48991b (re-approach up to 4×, naming the rival) |
| B3 | Late route (Salt Crown onward) | The only existing late composition (`water_earned_swimmer_preparation_segment` → `water_earned_late_segment`) **requires a duplicate species to release** and then rides the caught swim mount throughout | The keep-the-same-five goal conflicts with the harness's mounted late route. Human-swim hops exist (`smoke_water_hop_walked.gd`, Tidewake-B, 24/24) but no late segment drives Salt Crown/Sluice/Veilfall by human swim | Tidewake lane (new late segment); design question noted | open |
| B4 | Veilfall exterior, Venn ≈ (311.8, 141.2, 3894.4) | C3: the fight camera sits in or behind the rock wall (code-blind judge, `../f14_c3_judge/VERDICT_r1.md`) | Venn stands in a V-trench: ground rises 69 m within 16 m; no open 11 m pad within 70 m. The nearest open pads are on the Veilfall landing beach, about 105 m away (e.g. (359.8, 2.3, 3796.4)) | `data/config/water_characters.json` (placement, geography decision) + V24 trench grading (`water_heightfield.gd`) + camera (Codex) | open: needs a decision (move Venn to a beach pad vs grade a pad in the trench) |
| B5 | Six chains / pockets | Not composed into the dry run | `smoke_tidewake_b_chain_route.gd --continuous` (Tidewake-B, WIP on `tb/tidewake-b`) drives them; not on main | Tidewake-B | coordinate |
| B6 | Walked return | No harness walks Stormwood → Cloudreach → Meadows. F15#2 is data-level and PARTIAL: 2 A7 gaps each in Cloudreach and Meadows | other lanes' data; SHARED-FILE REQUESTs posted on #330 | open |

Known from earlier reports, still to be met in this run: the Deep Watch strand after Tidecoil (no wading path back without a swimmer; Tidewake-B `f13_3_lures/PROOF.md`), and the Calder 180 s timeout (`../f13_earned_continuous/REPORT.md`).
