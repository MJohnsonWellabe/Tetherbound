# F19#5 Meadows piece `hall`: PASS (meadows-route-b)

- **Run:** 2026-10-11, about 2:05–2:26 PM CT, Godot 4.7 headless. Source `088adb0f` (exact clean commit; the runner checks this).
- **Command:** `godot --headless --path . --script tools/earned_saves/earned_chain_runner.gd -- --segment=hall --generated-fixture --save-dir=<root>/hall/save --receipt=<root>/hall/receipt.json`
- **Result:** `passed: true`, no failures, wall time 1263 s.
- **Beats:**
  - Hall gauntlet: stronghold_patrol, stronghold_courtyard, then stronghold_elite (Keeper Hald), each 5 rounds, 5/5 wins.
  - `defeated_stronghold_elite` set.
  - Hall passage crossed, tether_approach → warden_arena.
  - The same five are retained throughout.

**Disclosures**
- **Generated input.** The new `hall` profile in `tests/fixtures/earned_saves/generated_boundary_profiles.json`, added under the owner's 2026-10-11 chunked-proof rules after the earned `sigils` piece failed twice (`sigils.md`):
  - Relay/Mill, the three captain defeat flags and `hall_approach_open` are set.
  - The five are at L18 (band4 team.exit), healed.
  - The pose is just past the opened Sigil Gate, (58.0, 7410.5), with no Sigils carried and no captain rewards added.
- **Runner opt-in.** `earned_chain_runner.gd` now accepts `hall` as a generated start, alongside relay and sigils.
- No earned captain or Sigil Gate play precedes this piece.
