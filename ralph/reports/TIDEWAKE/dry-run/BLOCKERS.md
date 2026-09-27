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
| Salt Crown → Sluice → Veilfall → Nerissa → tether (human swim) | segment ready (`late`), not reached: waits on B1 | — | — |
| Guardian invitation and full-belt decline | wired (`ending`), not reached | — | — |
| Six local chains, eight pockets, the side islands | not yet composed; B5 | — | — |
| Return home (Stormwood → Cloudreach → Meadows → Grandpa) | no harness; B6 | — | — |

## Blockers
| ID | Where (world x, y, z) | Symptom | Root cause | Owning file | Status |
|---|---|---|---|---|---|
| B1 | Tidal Cradle, Aquaryn fight ≈ (599.5, 34.0, 1392.4) | The fight stalls; after the first hits neither side lands a hit for 150+ s | **Stale host Wind in shared encounters.** The host advances a participant's Wind only when they act (`_advance_participant_wind` from probe/`commit_wind`). Each published record carries the frozen value, and the client's `_sync_authoritative_wind` overwrites its locally regenerating Wind with it about every 7 frames. The Wind bar sticks near empty while the player waits. Trace: local Wind sawtooths 0 → 1.8 (18/s for about 7 frames) for 150 s. | `scripts/net/encounter_host.gd` (shared), `scripts/combat/combat_manager.gd` (shared) | SHARED-FILE REQUEST with a verified patch (`patches/host_wind_publish.patch`) |
| B2 | same fight | The pilot never attacks | The harness pilot kept the charged's Wind in reserve while the charged was **Energy**-gated (only landed quicks build Energy). A low-nourishment Wind cap (the soft low-food drawback) made it permanent. | `tests/helpers/water_combat_pilot.gd` | Fixed be48991b (paid quicks while Energy-gated) |
| B2b | Aquaryn challenge | "challenge does not win at the physical outside stance" (intermittent) | The stance is computed once while Aquaryn keeps moving | `tests/helpers/water_tidal_segment.gd` | Fixed be48991b (re-approach up to 4×, naming the rival) |
| B3 | Late route (Salt Crown onward) | The only existing late composition (`water_earned_swimmer_preparation_segment` → `water_earned_late_segment`) **releases a duplicate species** and rides the caught swim mount throughout | WORLD data marks every late critical-path crossing `human_level_0` (`*_sheltered` in `water_world.json`), so the main line needs no mount. **New:** `tests/helpers/water_human_late_segment.gd` (85fb8bfc) swims the same sheltered polylines with the same five, idling on each authored rest shoal. It is wired as checkpoint `late`; unexercised until B1 clears. **Remaining design tension:** Drowned Garden and Deep Watch are reached only by `swim_mount` routes (672 m / 315 m), and only Water species are swim mounts. Their two local chains and pockets therefore require catching a swimmer, which with the five-creature cap means releasing a companion. That is optional content asking the player to give one up. | Tidewake lane (segment); design note for the owner | segment written; the side-island tension is recorded, not decided |
| B4 | Veilfall exterior, Venn ≈ (311.8, 141.2, 3894.4) | C3: the fight camera sits in or behind the rock wall (code-blind judge, `../f14_c3_judge/VERDICT_r1.md`) | Venn stands in a V-trench: ground rises 69 m within 16 m; no open 11 m pad within 70 m. The nearest open pads are on the Veilfall landing beach, about 105 m away (e.g. (359.8, 2.3, 3796.4)) | `data/config/water_characters.json` (placement, geography decision) + V24 trench grading (`water_heightfield.gd`) + camera (Codex) | open: needs a decision (move Venn to a beach pad vs grade a pad in the trench) |
| B5 | Six chains / pockets | Not composed into the dry run | `smoke_tidewake_b_chain_route.gd --continuous` (Tidewake-B, WIP on `tb/tidewake-b`) drives them; not on main | Tidewake-B | coordinate |
| B6 | Walked return | No harness walks Stormwood → Cloudreach → Meadows. F15#2 is data-level and PARTIAL: 2 A7 gaps each in Cloudreach and Meadows | other lanes' data; SHARED-FILE REQUESTs posted on #330 | open |

Known from earlier reports, still to be met in this run: the Deep Watch strand after Tidecoil (no wading path back without a swimmer; Tidewake-B `f13_3_lures/PROOF.md`), and the Calder 180 s timeout (`../f13_earned_continuous/REPORT.md`).

## Update 2026-09-27 10:20: full run from the declared start (tb/tidewake 193e08f4 + X05 host-Wind fix)
One run with a reload after every segment: start → Pell → Reedhaven → Brine → Shellwatch → **Tidal PASS** (Aquaryn beaten in about 47 s; B1 is fixed by X05's `encounter_host.advance_wind`, merged from `tb/x05` 7ff64a15) → **late**:
- **Human sheltered crossings PASS**, same five: Tidal → Salt Crown (461.7 m, 4 rest shoals), Salt Crown chart, Salt Crown → Sluice (430.7 m, 4 rest shoals). Stamina never dropped below 100% at a shoal, so the rests are effectively unneeded at level 0 on these routes.
- **Bex beaten**; the west control and the Sluice camp recovery pass.
- **B7: the Calder fight exceeded the late segment's 180 s bound.** That is a harness bound, not a game fault: reader medians against Calder are 214–329 s (`../f14_confirm_main/TABLE.md`). Fixed in 5b67ea91: the fight bound and watchdog are overridable, and the human segment uses 600 s and 120 min.
- Island groups reached in this run: first_shores, marsh_channels, tidal_cradle, outer_reaches (Salt Crown), tether_current (Sluice). Veilfall is pending the resumed run (`--from=tidal --through=late`).
