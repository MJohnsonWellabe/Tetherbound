# Glass Field R1 — static candidate handoff

Status: **awaiting production render and independent visual judgment**. No PASS or
POLISH claim is made by this static lane.

## Candidate

The canonical Glass Field had no location-owned visual presentation: current frames
show ordinary grass and repeated vegetation in front of the distant Stormheart mass.
This candidate mounts a non-colliding, location-specific corridor along the existing
Glass Field → Dynamo Outer Works route:

- eight fused strike seats with 50 deterministic, faceted stormglass shards;
- three branching glow fissures at every strike seat;
- four installed dead-tree silhouettes marking the blasted field edges;
- two installed Team Tether banner rigs at the final-approach threshold; and
- three restrained local cyan lights for a readable night cadence.

The 28–48 m lateral placement of the major clusters leaves the existing 14 m
critical-road half-width open. All dressing is visual-only. The map/discovery seat,
critical route points, level-42 catchable Voltarach alpha at `[-250,100,5080]`, Ember
Bivouac, terrain, scatter, pickups, fight logic and progression are unchanged.

## Evidence prepared

- Focused identity coverage constructs the complete visual layer, checks its count and
  hierarchy, enforces the open route corridor, proves no `CollisionObject3D` was added,
  and pins the existing route and named encounter contract.
- The production capture harness loads `scenes/world/stormwood.tscn`, leaves ordinary
  world content live, hides only the HUD, and records three real-terrain approach views
  by day and night to `GLASS-FIELD-R1`.

## Static validation

- `stormwood_glass_field.json` parses successfully: 8 clusters, 4 blasted trees,
  2 Tether standards.
- Every shard cluster retains more than the configured 14 m road half-width after its
  full 5.4 m spread.
- `git diff --check` is clean for all five candidate source/test/tool files.
- Per brief, this lane did **not** run Godot, rendering, headless tests, stage or commit.

## Required next gate

Run `test_stormwood_glass_field_identity.gd`, then the dedicated production capture.
An independent reviewer must inspect all six frames against the reference bar. Reject
or iterate if the field still reads as debug spikes, the banners dominate, the shards
intersect creatures, the processional route is unclear, or night collapses around the
local lights.
