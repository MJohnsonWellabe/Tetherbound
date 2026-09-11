# Meadows Realm Shrine Circle — 2026-09-10

## Outcome

The approved crescent shrine is now a single Valheim-like home ritual site in
Grandpa's Village: four identical large stones, one for Meadows, Cloudreach,
Stormwood and Water, arranged around a shared open center. Each copy is fitted
to a 4.8 m footprint and 4.0 m height; the circle is 12.4 m across. The old
remote Realm Heart sockets were removed from Cloudreach, Stormwood and Water.

Relic placement is now a return-home power choice, not a biome-route gate.
Stormwood's Waterward reveal follows the resolved Stormheart roster decision;
the Spark can be carried back and placed later without blocking the next realm.
Reward dialogue in all four chapters points the player back to the Meadows
circle.

## Art and generation evidence

- Approved reference: `docs/art/reference/48_Tideglass_Compass_Shrine.png`.
- Meshy preview tasks: `01a08d51-0538-7696-aab8-246317269246`,
  `01a08d51-0ea8-7770-abdb-dbba48bdb06a`, and
  `01a08d51-1803-741b-a5a2-2e064d6d0176`.
- Refine task: `01a08d54-671f-7035-b23c-f1c27e2a1533`.
- Spend: 90 credits total (60 preview + 30 refine), 1170 -> 1080.
- Installed GLB: 3,976,420 bytes, SHA-256
  `005600DE09A2EE7959D74CC6BCF384620C3D91AEF338CF16C02867258B3D2699`.
- Godot-imported geometry: one mesh/surface, 15,996 vertices, 12,102
  triangles. Runtime texture import policy passes for all 404 sidecars.

This spend is covered by the owner's direct shrine-specific instruction. One
mesh is reused four times; no additional shrine candidates and no creature were
generated. Blender was not installed, so visual approval and geometry counts
come from the actual Godot 4.7 import/render path rather than a Blender report.

## Production visual verification

Fresh real-renderer frames are retained locally under
`.artifacts/broad-visual-0910/meadows-shrine-circle-close/`:

- `01-south-approach.png`: ordinary ground-level read from the village path.
- `02-southeast-three-quarter.png`: trainer-scale and cross-circle spacing.
- `03-raised-circle.png`: all four stones and the open ritual center in one
  frame.

The first terrain probe found the south stone 0.402 m above the sloping lawn.
Production now grounds every member independently. The repeated probe measured
all four base-to-terrain deltas at 0.000 m (within printed precision), and the
fresh captures confirm that the plinths no longer hover.

## Verification

- `test_realm_world_components.gd`: 6 tests, 26 assertions, 0 failed.
- `test_water_relic.gd`: 4 tests, 52 assertions, 0 failed.
- `test_stormwood_ending.gd`: 6 tests, 30 assertions, 0 failed.
- `test_stormwood_earned_waterward_handoff.gd`: 7 tests, 48 assertions, 0
  failed.
- `smoke_meadows_realm_handoff.gd`: pass — an earned remote relic places at
  its Meadows stone; single-active power and disk persistence remain intact.
- `smoke_water_guardian_ceremony.gd`: 32 checks, 0 failures — the Compass is
  earned in Water and waits unplaced for the home circle.
- `smoke_stormwood_chapter_prefix.gd`: pass — remote Spark shrine absent.
- `smoke_stormwood_water_gate_path.gd`: pass — roster decision to Waterward
  reveal and ordinary Water arrival.
- `tools.art_pipeline.test_meshy`: 3 tests, 0 failures.
- `texture_import_policy.py --check`: pass, 404 runtime 3D sidecars at mode 2.
