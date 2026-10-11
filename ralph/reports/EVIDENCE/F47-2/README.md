# F47#2 — four-character contention ledgers are solvent — FAIL (balance finding)

systems-a, Sun 11 Oct 2026 12:40 PM CT. Data-only census (coordinator ruling 12:36 PM CT): `tools/economy_supply_census.mjs` (117 lines) + `tests/test_economy_supply_census.mjs`; `node tools/economy_ledger.mjs --out f` now fills `reachable_supply`.
`node --test tests/test_economy_supply_census.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs` → 16 pass, 4 fail (one solvency test per band). Earlier units: Meadows/Tidewake old-loop four-character tests PASS (9/80).

Model: world-stock sites shared by all 4 characters, harvests = 1 + floor(route_days / respawn_days) (an upper bound; first-pass lower bound also reported); one-time pickups once; route hours 5/3.5/3.5/3.5 (f27 lower bounds), day = 600 s (art.json). Demand = economy_ledger `four_character_raw` (personal ×4 + shared once), worst single-type team, at gear max upgrade 3 (per-upgrade verdicts included); surplus carries forward, deficits floor at 0.

| Band | Shortfalls at upgrade 3 (demand/supply) | At upgrade 0 |
|---|---|---|
| Meadows | rootstone 786/320, berries 200/161, attuned_* 40/15 each | berries short 39 |
| Tidewake | sluice_metal 728/506, rootstone 8/0, attuned_* 20/12 | — (only knock-on/attuned) |
| Cloudreach | cliffglass_ore 728/198, windworn_heartwood 380/99, skyplume 200/0 (no site source) | cliffglass 50, heartwood 41, skyplume 80, rootstone 2 |
| Stormwood | sparkfur 200/0 (no site source), rootstone 8/0 | sparkfur 80, rootstone 8 |

Caveats:
- The attuned_* shortfalls exist only under the worst case where all four players field single-type teams; with mixed types the total attuned supply exceeds demand.
- Skyplume and sparkfur come only from chance shed drops, which are not data-countable.
- Later-band rootstone shortfalls are knock-on from the Meadows deficit.
- Numbers are unchanged; tuning belongs to F47 balance.

Verdict: FAIL — insolvent in every band under this model; clear material shortfalls even at upgrade 0 in Meadows (berries), Cloudreach (cliffglass ore, windworn heartwood, skyplume) and Stormwood (sparkfur).
