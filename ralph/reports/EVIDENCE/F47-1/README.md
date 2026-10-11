# F47#1 — essence/material ledgers: no mandatory grinding; optional grinding measurably speeds progress — PASS

systems-a, Sun 11 Oct 2026 1:30 PM CT, on tb/ev-coordinator bc0f5631 (ruling A: Cloudreach Senn/Maela bonus back to 0), Node 22, no Godot.
`node --test tests/test_f27_route_ledger.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs tests/test_economy_supply_census.mjs` → 27 pass, 0 fail. `node tools/f27_route_ledger.mjs [--write]`: the committed report.json is unchanged by --write.

| Biome | Ordinary path reaches | Best grind loop (lvl/h) | Measurably faster |
|---|---|---|---|
| Meadows | L24 (target 20) | wild refights 5.41 | yes |
| Tidewake | L34 (target 31) | 2.2 | yes |
| Cloudreach | L44.8 (target 42) | 2.26 | yes |
| Stormwood | L60 (exit target 55) | 2.2 | yes |

Verdict fields:
- `mandatory_repeat_grinding: false`, no deficits; `plausible_team` also has no deficits.
- break-even wild-site engagement 0.39.
- `optional_grind_measurably_faster_every_biome: true`.

History: on bd3c20ba (with 0d323864's Cloudreach bonus) the test FAILED "stormwood grind rate": Cloudreach was reached at L50 and Stormwood grinding added 0 lvl/h. Ruling A restored the curve.

Disclosed: an arithmetic ledger on authored data (`acceptance_verified:false` by design). Supply is not measured on a played route. The engagement assumption (≥0.39 of main-path wilds) needs F47#0's agent-piloted route to confirm.

Verdict: PASS
