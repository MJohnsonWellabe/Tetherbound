# Stormwood scatter freshness repair

Status: **repaired and focused-check green.** The official bake regenerated the
trusted metadata against the current authored inputs. The runtime fail-closed check
remains unchanged.

## Root cause

`scripts/world/vegetation.gd` accepts a non-Meadows realm scatter only when
`ScatterBake.is_fresh()` matches the live realm seed and fingerprint. Stormwood's
fingerprint deliberately covers these six authored inputs:

- `data/config/stormwood_vegetation.json`
- `data/config/stormwood_settlements.json`
- `data/config/terrain_stormwood.json`
- `data/config/stormwood_world.json`
- `scripts/world/stormwood_heightfield.gd`
- `scripts/world/stormwood_scatter.gd`

The tracked bake exists: its manifest names 108 region files and all 108 are present.
It is stale, not missing. The current four-biome tree adds the authored
`water_departure` transition to `data/config/stormwood_world.json`, while the existing
manifest still records fingerprint `2832947544431512` from the prior input. Because
the whole world config is an intentional fingerprint source, that edit correctly
invalidates the bake and produces:

`Missing or stale stormwood scatter bake; rebuild before playing this realm.`

The new transition does not change the placement algorithm's consumed route, bounds,
landmark, sightline, vegetation, settlement, terrain, or heightfield data. The
official bake is nevertheless required to restamp the trusted fingerprint in the
manifest and binary region headers; hand-editing the manifest would leave the region
headers inconsistent and bypass the repository's generation workflow.

## Repair and verification

The official entry point is:

`godot --headless --path . --script scripts/world/bake_stormwood_scatter.gd`

The official bake ran in the coordinated writer window and reported:

`STORMWOOD SCATTER { "regions": 108, "bytes": 1244185, "kept": 33773, "drained": 0 }`

The generated placement count, region count, and byte count are identical to the
previous bake. Accordingly, none of the 108 binary region files changed. The only
generated diff is `data/scatter/stormwood/manifest.json`, whose
`config_fingerprint` moved from `2832947544431512` to `2915883326895985`. That is the
minimal expected result for an authored transition-point edit which changes a hashed
source document but no placement-consumed data.

The focused guard command was:

`godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_scatter_bake.gd::test_stormwood_scatter_bake_is_committed_and_fresh`

Result: **1 test, 1 assertion, 0 failed.** It calls the same
`ScatterBake.is_fresh("stormwood", seed, StormwoodScatter.fingerprint())` decision as
production vegetation. Generated-output inspection and this check establish that:

1. the bake exits successfully with more than 1,000 retained placements;
2. the generated manifest and region set are complete;
3. the focused `test_stormwood_scatter_bake.gd` production freshness decision passes;
4. the generated diff is limited to the expected Stormwood manifest fingerprint,
   with no unnecessary binary-region churn; and
5. `vegetation.gd`'s fail-closed non-Meadows behavior remains untouched.
