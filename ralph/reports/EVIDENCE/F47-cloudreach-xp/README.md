# F47 Cloudreach XP: designed play carries the curve (owner ruling A)

US Central, 2026-10-11. Branch tb/ev-cloudreach-xp. The owner chose (A) at about 12:42 CT, superseding the 1A bonus tune.

- **Finding:** the earned chain (fixtures cloudreach_01..04) reached the stronghold at L31. Arrival→stronghold paid 579–1512 XP per creature, against 18,781 for L31→L39. The chain fights no wilds, spends no Altar essence and feeds no candy.
- **Interim 1A tune, now reverted:** Senn +8500 and Maela +10500 XP. The chain then arrived at 35/39/39/39/31 (members down at the end of a fight miss the bonus) and beat Voss. But test_f27_route_ledger failed: Stormwood entry L50 vs 42 and the L60 ceiling. Any bonus above 0 failed F27; see the sweep in the coordinator log.
- **Ruling A, now shipped:**
  - Senn/Maela xp_bonus are 0; cloudreach_encounters.json is byte-identical to before the tune.
  - The Cloudreach route ledger (tests/test_cloudreach_route_ledger.gd) now:
    - credits wild defeats with the production hybrid award (×0.35; it was unscaled);
    - adds RD-03 Altar income using F27's model (tools/f27_route_ledger.mjs): wild-defeat and research essence, 7 Home Key care visits, the master_t4 Tether Candy ×2, spent lowest-first before each required fight and the exit;
    - enters at F27's own cloudreach_entry, read from ralph/reports/TRAINING/f27/route-ledger/report.json (regenerated with `--write`; levels unchanged at L34 ×5);
    - keeps the original negative controls and all thresholds.

| Ledger phase | Levels before the fight |
|---|---|
| Senn (ace 36) | 37 36 36 36 36 |
| Maela (ace 37) | 39 39 39 39 39 |
| Voss (ace 42, need 40/37) | 42 41 41 40 40 |
| Veyra (ace 44, need 43/40) | 44 43 43 42 42 |
| Exit (need 45/42) | 45 44 44 44 43 |

- **Unit tests** (13:00 CT):
  - test_cloudreach_route_ledger 10/10 (controls still fail as designed).
  - test_f27_route_ledger 7/7.
  - chapter_curve, redesign_chapter_curve, level_curve_policy, f19_curve, f47_exploit_matrix, cloudreach_encounters: 66 tests in total, 0 failures.
  - tests/test_f19_curve.mjs fails identically on base (Meadows band1).
- **Voss re-proof**, piece 05, 12:55–13:27 CT:
  - Start: the disclosed generated boundary `cloudreach_stronghold` (new in generated_boundary_profiles.json): the earned 04 flags and landing pose, five creatures at L40, template inventory, NOT earned. L40 is the conservative F27 Voss arrival (F27 gives L41–42).
  - Result: WON by live SPACER controller piloting with no timeout. 74 hits dealt / 24 taken; 1015 / 1152 damage. Survivors 2 of 5.
- **Not proven:** the 05 summit tail (reported separately), Veyra (06), and that the earned chain's own play spends essence (F27 models it; the helper does not).
