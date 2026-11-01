# Routes lane (tb/routes-f49), F49#0 Tidewake: result 1 Nov 2026 (resume), 08 -> 09 MATCHED; Tidewake late chain complete

## 1 Nov resume: seams matched and pushed
- **07b → 07c MATCH** (02e8f4cb; a79aa8f7): fixed the 07c trainer death. Diagnosis (health/position trace): 07c climbed the Veilfall exterior spine and then walked straight to Venn's stance at the landing camp, stepping off the plateau near (320,142,3881) (vy −90 m/s, health 100 → 0 at (346,17,3819)), leaving the whole Satchel in a death satchel. 07c now takes spine point 1 only (07d walks points 2..4 to the cave) and fails if a death satchel is left. Venn beaten in 1651 s with every stack kept.
- **07c → 07d MATCH** (84972b98, Nerissa beaten) and **07d → 08 MATCH** (829ef377, Tidewake ending), Satchel kept. `f49_tw_07c/07d/08` replaced; the earlier dead-trainer versions are superseded.

## 08 → 09 MATCH (06453bef)
- Diagnosis (local traces, not pushed): the held boss_relic hand-off does re-read the live Satchel (record and live both 24/24, no lock). The slot freed by the Satchel Drop was taken at once by Nerissa's held coin payout (coin x456 as a second stack; the carried stack is at the 999 cap). Not a game bug: two free slots deliver both. 09 now frees room for coin + portal key (fiber x3, rootstone x19 dropped, disclosed) and passes in 397 s; seam `tw_08__tw_09.json` matches.
- Cloudreach 01 load check (`tw_09__cr_01_loadcheck.json`): loads `f49_tw_09`, passes the carried-knife gate, walks 703 m, then fails "Optional arrival gather produced gale_fiber" (Satchel full). That piece is tb/routes-sky-storm scope; the likely fix is the same approved Satchel Drop before Cloudreach gathers.

## Earlier blocker record (resolved above)
- Attempt 1 (02e8f4cb): `09_cloudreach_handoff` FAIL "F49 relic hanging produced no actual portable relics_hung state". Cause: with the Satchel carried full, the Nerissa hand-off `boss_relic` duty is refused on every retry with `boss_handoff_make_satchel_room` (`scripts/net/foundation_actions.gd:305-307`: `give_stack(bag, cloudreach_portal_key)` on `death_satchel_rules.inventory_from(current.inventory)`), so neither the relic (`relics_held`) nor the Cloudreach portal key arrives. (The earlier dead-trainer 08 got both only because its Satchel was empty.)
- Attempt 2 (1b8dea2f): the piece first freed a slot through the approved Satchel Drop (`free_slots_for`; log: `satchel_room_dropped fiber x3 slot 10`), then waited 1800 frames. The duty kept logging `held: boss_handoff_make_satchel_room` after the drop, so the hand-off still did not deliver. **Open question for Systems:** which inventory does the boss_relic host context read as `current.inventory` (the last saved/journaled owner snapshot rather than the live Satchel?), and does a held hand-off re-read it after a Satchel Drop? Either a save after the drop or the grant reading the live Satchel is needed. A real player who fills the Satchel before Nerissa hits the same stall: the relic and portal key never arrive.
- Evidence: `/home/user/rb/tw_09.log`, `fail_tw_09.log` (container-local). Input `f49_tw_08` is committed.
- Cloudreach 01 load check was not reached.

## Earlier: result at owner STOP, 31 Oct 2026 (item 1 below is fixed by 02e8f4cb)

Scope was narrowed to Tidewake by the coordinator (31 Oct). Stopped on the owner usage STOP. Godot 4.7 on CPU (xvfb-free headless), one process at a time.

## Seams passed (saves `tests/fixtures/earned_saves/f49_tw_*`, seams `ralph/reports/ROUTES/f49-1031/seams/`, all `matches: true`, `differences: []`)
- **T1** `f49_ms_tidewake_handoff` → Tidewake `01_opening` (`f49_tw_01`): replaces the generated `tidewake_arrival_generated` start. All six Meadows predecessor receipt hashes equal the committed fixtures (cross-runner seam JSON).
- Tidewake 01 → 02 → 03 → 04 → 05 on that lineage.
- 05 → 07a1 → 07a2 → 07a3 → 07a4 → 07a5 (Bex) → 07a6 → 07b (Calder) → 07c (Venn) → 07d (Nerissa) → 08_ending → 09_cloudreach_handoff: replaces the generated L44 `tidewake_07_human_late` jump.

## Open
1. **Tidewake 09 cannot feed Cloudreach 01 (blocker, real defect).** In `07c_venn` the trainer dies from a fall (the only trainer damage, `player_vitals.apply_landing`) on the walk from Veilfall spine point 1 (374.7,6,3822.9) toward point 2 (344.5,196.9,4346.4); death at about (346,17,3819). The whole Satchel goes into `death_satchel_1` and the helper never notices or retrieves it, so 07c onward carries only coin/home_key/revive and Cloudreach 01 fails "requires the carried knife". The close-1020 L31 07c receipt shows the same loss, and the legacy `tidewake_09_cloudreach_handoff` fails Cloudreach 01 the same way (run 31 Oct). A health-drop diagnostic was killed at the STOP before it reached the fall. Next: find the fall point, then either route the climb by authored ground waypoints or recover the satchel in-piece, and add a "trainer alive and satchel intact" exit check to the late pieces. Then rerun 07c → 09 (two prior 07c attempts were watchdog, not this cause).
2. **Tidewake T3 (Ione) on an earned lineage.** `f49_tw_*` descends from the untrained `f49_ms` Meadows lineage (L20/cap20, no master_t1/t2), so Ione (Lv30 Master) cannot load it. The T3 loop from the generated `tidewake_t3_ione_independent` boundary is already proven by receipts (close-1020), so it was not rerun (owner: do not reprove). It closes on an earned lineage only after tb/routes-meadows lands a trained Meadows handoff and its cross-cut manifest.

## Harness fixes (smallest, each from a reproduced failure)
- a2e34527 Reedhaven: Satchel 23/24 full on the earned lineage → driftwood `inventory_full` (diagnosed from the foundation reply). The helper now uses the approved Satchel Drop (`free_slots_for`) first.
- 544e5866 split late-piece watchdog 240 s → 20 min and 9846e94c full late-piece watchdog 30 → 60 min. They measure wall clock; diagnostics showed every waypoint reached, just slow on the CPU host. `test_water_earned_late_segment.gd` pin updated (10 tests pass).
- Process note: `pkill -f <pattern>` from a shell whose own command contains it kills the shell (exit 144); kill by PID.
