# F19#5 Stormwood: dynamo -> marrow_aftermath re-run with the homecoming flag fix (routes, Mon 12 Oct 2026, CT)
Commit 91fd9a7a26 (tb/ev-routes; carries the regional_homecoming WORLD_FLAG fix and the Session input-fence watchdog). No TB_WORLD_SEED. Injections: 0.
Runner: `godot --headless --path . --audio-driver Dummy --script tools/earned_saves/stormwood_chain_runner.gd -- --segment=<id> --from=<prev> --out=<dir>`.

Input (disclosed generated, NOT earned): `generate_boundary_save.gd --profile=stormwood_rootgate_crown --slot=0` (22:04 CT, 54 s).
Generated L50 five, act-II flags, one paid Crown-arch record. Claims no earned PASS (profile disclosure in generated_boundary_profiles.json).
Shortcut disclosed by the runner: simulation clock 8x at 480 Hz with an 8-step cap; helpers switch fights and walks to 1x.

1. dynamo: PASS, 22:05-23:12 CT, 4052 s, 17,736 frames (median 198 ms, p99 998 ms).
   Nysa, Sera and Kestrel defeated; Deepwood, Dynamo and all rods disabled; core reached.
   Handoff not checked: the generated input has no receipt.
2. marrow_aftermath (one process): PASS, 23:12-23:25 CT, 724 s, handoff from dynamo checked and equal (UIDs, species, flags, items, portals, realm).
   - Captain Marrow's five rounds won by piloted play (Tanglevolt L54, Stormraven L54, Stormbrush L54, Sparkit L55, Voltarach L55).
   - All four conduits struck; the Stormheart was released automatically.
   - Own offer answered Yes at five: the Team-tab ceremony kept the Stormheart and released belt row 4. The world offer fact and personal receipt were saved.
   - The homecoming aftermath opened and drained on this earned path: `stormwood_homecoming_aftermath`, since redesign_ending_runtime_enabled=true. The earlier r14/r17 runs never opened it.
   - Then waterward_revealed, realm_key_water and stormwood:chapter_complete.
   - The ending fired `stormwood:legendary_freed`, the flag regional_homecoming.WORLD_FLAG now reads.

Checkpoint: tests/fixtures/earned_saves/stormwood_09_marrow_aftermath (save, receipt, PROVENANCE). Input for home_key/homecoming -> credits (F49#0).
Logs and receipts: r2026-10-12/ (dynamo.log.gz, marrow_aftermath.log.gz, *.receipt.json, gen_rootgate_crown.log.gz).
Still open in Stormwood: crown_build (r19 soft-lock at still_grove_shelter; systems' fence watchdog is now on this branch) -> rootgate.
Named-wild detours: Codex.
