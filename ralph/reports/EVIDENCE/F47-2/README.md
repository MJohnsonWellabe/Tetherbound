# F47#2 — four-character contention ledgers are solvent — PASS (required demand)

systems-a, Sun 11 Oct 2026 12:52 PM CT. Data-only census per the coordinator rulings (12:36 and 12:41 PM CT): `tools/economy_supply_census.mjs` (157 lines), `tests/test_economy_supply_census.mjs`; `node tools/economy_ledger.mjs --out f` fills `reachable_supply`.
`node --test tests/test_economy_supply_census.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs` → 20 pass, 0 fail. Meadows/Tidewake old-loop four-character units also PASS (9/80).

Supply (per band, 4 characters; surplus carries forward):
- world-stock sites: claims = 1 + floor(route days / respawn days), shared by all four (an upper bound);
- one-time pickups;
- Master chests ×4 (`masters.json` preparation_supplies + attuned_per_creature, paid by `breakthrough._master_supplies`);
- trainer reward tiers, the Warrens clear, chain grants, Ripplet caches/nodes;
- bounties (expected value, non-delivery slots);
- vendor stock (once);
- shed drops (expected value).
- Uncounted (listed in the output): Den groom, rematch rewards (post-boss), encounter-cycle nodes.

Demand:
- personal ×4: feasts (5 per Master), Harness + Charm at the matching tier, camp kit;
- shared once: station attachments and opening builds.
- Upgrade 0 is the verdict, because gear.json declares no required upgrade; +1 is also reported. Attuned ingredients are pooled across types; a per-type table is included and every type is solvent.

| Band | Required (upgrade 0) | Max column (upgrade 3, worst case) |
|---|---|---|
| Meadows | solvent (e.g. rootstone 306/1299, berries 200/461) | solvent |
| Tidewake | solvent (sluice_metal 248/1226) | solvent |
| Cloudreach | solvent (cliffglass_ore 248/998, skyplume 80/185) | **skyplume short 15 (200/185)** |
| Stormwood | solvent (sparkfur 80/218) | solvent |

Caveat for the owner: the solvency depends on the Master chests. Without them, required demand is short for Meadows berries (161/200), Cloudreach cliffglass_ore (198/248), windworn_heartwood (99/140) and skyplume (5/80), and Stormwood sparkfur (38/80). It assumes every character wins its own Master. Route hours are the f27 lower bounds and a day is 600 s (art.json). No numbers were changed.

Verdict: PASS (required demand solvent in all four bands; the only max-column shortfall is Cloudreach skyplume, 15 short)

## Skyplume max-column source (systems-b, Sun 11 Oct 2026, coordinator order 4:14 PM CT)
One bounded source: `cloudreach_encounters.json` reward_tiers.mentor (Keeper Maela, one trainer) skyplume 2 → 18, with `_why_skyplume`.
`node tools/economy_ledger.mjs` supply_census: solvent true, shortfalls [], max_shortfalls [] (Cloudreach skyplume was 200/185).
`node --test tests/test_economy_*.mjs` → 20 pass, 0 fail. Cloudreach reward units: 76 tests, 2 failed — both in `test_cloudreach_route_ledger.gd` (entry team / negative controls), failing identically on the base without this change (pre-existing, not this lane's).
