# F33#0 — creature Harness and Charm slots, four tiers, +1..+3

Criterion: Creatures have Harness and Charm slots in Rootiron, Tidesteel, Skyglass and Stormglass tiers, each upgradable +1 to +3.

- Branch/base: tb/ev-systems-b from origin/tb/ev-coordinator 00d4a639 (no source change).
- Host: Linux, Godot 4.7-stable headless, after a full `--import`.
- Command: `godot --headless --path . --script tests/run_tests.gd -- --only=test_creature_gear.gd`
- Result: **PASS** — 8 tests, 303 assertions, 0 failed, exit 0 (`unit_output.txt`).
- Run: Sun 11 Oct 2026, ~10:45 AM CT.

What closes the audit gap ("no test loads creature_gear.gd, its slots or the 24 upgrade links"):
- `test_four_live_tiers_each_have_harness_and_charm_from_plus_0_to_plus_3`: loads `scripts/creatures/creature_gear.gd` config; the four live tiers are rootiron/tidesteel/skyglass/stormglass in biome order; for each tier × {harness, charm} × upgrade 0..3 the item exists in the item DB, carries slot/tier/upgrade, fits only its own slot (`slots_errors`), and each +0..+2 upgrades exactly one step while +3 is the maximum (all 24 upgrade links).
- `test_equip_at_the_den_then_upgrade_at_the_forge_to_plus_3`: equip then real forge upgrade path to +3.
- `test_bonus_rises_with_tier_and_with_each_upgrade`, `test_gear_refusals`, plus host-side gear application tests.

Shortcuts/generated inputs: none (unit fixtures inside the test file only).
