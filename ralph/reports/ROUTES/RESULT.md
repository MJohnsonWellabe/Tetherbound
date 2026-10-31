# Routes lane (tb/routes-f49), F49#0 Tidewake: result at owner STOP, 31 Oct 2026

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
