# F47#2 — four-character contention ledgers are solvent — PARTIAL (needs a ruling)

systems-a, Sun 11 Oct 2026 12:40 PM CT, on bd3c20ba.

| Band | Proof | Result |
|---|---|---|
| Meadows | `run_tests.gd -- --only=test_meadows_economy_solvency.gd` (four players each owed the whole payout; required route pays two losses) | PASS |
| Tidewake | `--only=test_tidewake_b_four_character_ledger.gd` (supply ≥150% of four personal kits + shared structures once, emergency reserve before Veilfall) | PASS |
| (both) | 9 tests, 80 assertions, 0 failed | |
| Cloudreach, Stormwood | none | no four-character material ledger exists |
| New loop (feasts, gear, attachments), all bands | `node tools/economy_ledger.mjs` | demand computed per band × type × upgrade (personal ×4 + shared once); `reachable_supply: null`, status "UNAVAILABLE: on-route harvest claims and loss/recovery consumption not measured" |

The Meadows and Tidewake tests are old-loop material ledgers. No existing tool measures new-loop supply, so the criterion cannot be closed for all bands without a supply census, i.e. a new harness.
Proposed scope: a per-band census of renewable sites × respawn days over each band's route hours, fed to `economy_ledger.mjs` as `reachable_supply`.

Verdict: PARTIAL (Meadows/Tidewake PASS; Cloudreach/Stormwood and new-loop supply unproven)
