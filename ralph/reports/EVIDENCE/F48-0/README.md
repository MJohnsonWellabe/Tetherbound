# F48#0 — two-peer co-op loop: PASS

- **Command:** `GODOT_BIN=<godot 4.7> tools/net/run_net_smoke.sh f48_coop_loop` (two real ENet processes).
- **Source:** `tb/ev-coop-loop` working tree on `8955fd19` (`tb/ev-coordinator` including `e47d3c61`) plus the portal-leg and timeout edits in the commit that adds this file.
- **Run:** 2026-10-11, 1:38–1:53 PM CT. `ALL CHECKS PASSED`, 0 FAIL, exit 0.
- **Files:** `SUMMARY.md`, `F48_COOP_LOOP.json` (per-leg records) and `run_checks.txt` (every check plus each leg's new receipts).
- **Legs:**
  1. Hub: Satchel Home Key to the Crossing Hall.
  2. Craft: the host plants a Kitchen through the paid build press; the guest crafts a potion there and keeps it; the host's stock doesn't change.
  3. Portal: host first, then guest, each crosses the Hall's Meadows biome arch (`portals.json` id `home`, biome meadows) into the Master's biome. Each arrival is journaled once.
  4. Master: each player wins against `master_t1` and opens the chest for one recipe.
  5. Feast: each player cooks at the host's Kitchen (exact cost) and feeds its own Pup (cap 10 → 20).
  6. Boss: Warden; each participant gets one key and one relic.
  7. Relic hang: each player hangs its own relic on the Shrine Room pedestal; the chooser is deferred.
- **Checks after every leg:**
  - New receipts name only that player's own character or creature.
  - New receipts are absent from the other player's record.
  - No receipt is duplicated.
  - Exactly one receipt per paid kind.
  - The host's admitted record of the guest equals the guest's own record.
- **End:** the host saves and reloads, the guest leaves and rejoins as its saved character, and both records (items, caps, wins, recipes, relics, receipts) are unchanged.
- **Disclosed fixtures (before admission):**
  - Each player: Lv 10 Terrapup, Lv 40 Bramblebun, opening flags, Home Key and one cook's ingredients.
  - Guest only: the potion's ingredients.
  - No recipe is seeded.
- **Disclosed fixtures (during the run):** fixture teleports to the Kitchen, Master and Warden stances; Warden `enemy_hp_ceiling` 6 (as in `smoke_net_veridian_relic_key`); a re-press, at most twice, when the host refuses with "revision changed".
- **Local only, not committed:** `multiplayer.json` `test_budgets` raised to 900 / 3600 / 7200 for this slow host.
- **CI:**
  - Registration: `net_shards.py` `ROSTER`, floor 74, `SHARD_COUNT` 14 (the `ci.yml` matrix was changed to match).
  - Time: 1100 s is an estimate; locally the smoke took 15 min.
  - Timeout: this smoke is alone on its shard. Its header `# net-timeout-seconds: 1620` raises its timeout in `run_net_lanes.sh` above the default 1200 s, while staying inside the 30-minute job limit.
- **Not covered:** the host's own station craft (its Kitchen use is the feast cook), and F48#1–#3.
