# F14#1 — Captain Nerissa by input in the actual Water world

**Status: partial evidence, not a closing proof.** The preparation is a fixture, and it is disclosed in every run's JSON:
- a granted party: the original five at L43, Ripplet leading;
- the player placed in front of Nerissa in the Heart Chamber;
- her two upstream pump flags set (`water_veilfall_intake_stopped`, `water_veilfall_return_opened`).

There is no HP, damage, victory or roster injection. The production summon, the challenge prompt, the hosted trainer roster and CombatManager are all real. The shared READER/MASHER pilot (`tests/helpers/combat_depth_pilot.gd`) presses the real input actions. Movement is mapped through the production CameraRig, as a player's stick is.

Harness: `tests/smoke_tidewake_named_inworld_c2.gd`, one fight per process (a fresh world each run), seeds 1–12 per pilot, `--fixed-fps 60`, headless. Config at head 94d9008e and later, including the Break Tether 1.1 s / 0.9 s Riptusk.

## Result (SUMMARY.txt)

| Pilot | Runs | Win | Wipe | Median lead lost | Median party lost | Median s | Max hit | Tells seen | Reached all 4 |
|---|---|---|---|---|---|---|---|---|---|
| READER | 12 | 1.00 | 0.00 | 0.480 | 0.104 | 330 | 0.135 | 0.80–1.10 s | 12/12 |
| MASHER | 12 | 0.00 | 1.00 | 1.000 | 1.000 | 159 | 0.165 | 0.80 s | 0/12 |

- **C2** (top trainer; reader win ≥ 90%, masher wipe ≥ 25%): met in-world. 12 seeds is a small sample; it agrees with the 24-seed flat-arena runs on main (`../f14_confirm_main/`).
- **C3 timing**: the largest single hit is 16.5% of entry max HP (< 50%). Ordinary tells are 0.8 s; Riptusk's heavy tell is 1.1 s, observed in all 12 reader runs.
- **Difference from the flat arena**: the reader loses more lead HP in-world (median 0.48 against 0.19–0.21 flat). No reader lead fainted; party loss stays low (0.10).
- **Seed 0** was run before the Riptusk change (r0: won, 334 s, all tells 0.8 s). It is not in this table.

## Why this does not close F14#1
Under the strict board rule, a granted party and a position write make the claim partial. The closing witness is Nerissa reached and fought by ordinary play from an earned party. That follows the Tidewake chapter dry run.
