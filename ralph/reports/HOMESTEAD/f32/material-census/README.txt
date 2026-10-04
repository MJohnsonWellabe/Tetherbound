F32#0 per-biome gather census (tests/smoke_f32_material_sites.gd --ordinary)
Command: godot --headless --path . --script tests/smoke_f32_material_sites.gd -- --realm=<realm> --ordinary --output=<dir>
For each tier material in data/schema/material_tiers.json: the lowest-ID ungated registered renewable
site, up to 4 candidates. A placement production refuses is SKIPPED and the next site of that material is
tried. Real scene, production mount, controller walk >= 3 m, prompt, host transaction, owner save + ACK.
The disk gain, journal, receipt and consumed stock are read from the decoded save.
Fixture: every ItemDB tool granted at setup (before admission); the item's gathered_with tool equipped.

Stormwood @ a898ca39 + fixture fix: exit 0 (stormwood-report.json)
  thunderwood conductor_run_076, stormglass cinder_verge_003, conductor_vine cinder_verge_001,
  glowmoss cinder_verge_002, voltcap glowmoss_hollows_042. sparkfur: shed-only (no node, by design).
  Needed a81fea49 (hub hosts with the F22 action fence).
Meadows / Tidewake additional candidates: 3/3 Sunleaf and 3/3 Tide Pearl pass (fixture-registered while
  the flags are OFF). The ordinary census is still to run for both biomes.
Cloudreach: FAIL, training_actor_baseline_not_ready on every tool gather (cloudreach-diagnostic-report.json:
  actor_baseline_before.directors == []). Root cause: session.gd FOUNDATION_DIRECTORS matches exact script
  paths, and Cloudreach's director is res://scripts/world/cloudreach_scene_encounters.gd (built by
  cloudreach_world_runtime.gd:8), which is not listed. So _training_actor_baseline_proposals finds no host and
  refuses. Fix: list that path (patch D, sent to the coordinator).
  Separately, 3 sites are refused by production placement as "slope not walkable" (heartwood_upper,
  cliffglass_observatory, cloudberry_cliffhold); 3 have no baked ground on a 6 m ring (gale_fiber_bridge,
  gale_fiber_gate, cloudberry_waycamp).
Observation: equipping a tool the character doesn't own made every later gather in that run refuse with
  source_or_revision_changed, including tool-less ones. The fixture now grants all tools; the cascade itself
  is not yet root-caused.
