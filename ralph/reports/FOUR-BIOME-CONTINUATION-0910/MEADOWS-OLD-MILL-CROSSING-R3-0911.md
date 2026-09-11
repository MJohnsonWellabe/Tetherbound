# Meadows named location — Old Mill Crossing R3 (2026-09-11)

## Disposition

**POLISH, held for independent review.** The current production scene now gives
Old Mill Crossing a clear mill/wheel/bridge silhouette from the ordinary south
road, and bounded warm working pools at both human thresholds. It does not yet
claim strict PASS: the practical source reads pale at gameplay distance, the
south-arrival roof apex has little frame margin, and a shared Galecrest cluster
still intrudes into the mill three-quarter proof.

## Bounded changes

- Removed one measured baked `CommonTree_2` at `(-155.38, 4183.53)`, scale
  `1.29`, through a one-metre clearing. The neighbouring sapling 1.4m away and
  all grass/flowers remain.
- Installed exactly two `Lantern_Wall` practicals: one on the mill loading-door
  face, one on a 1.9m timber support beside the south-bank workbench. Each owns
  a small visible amber emitter and a 6m, energy-2.35 warm pool. Neither adds
  collision.
- Kept road, river, channel, bridge, gate, mill prefab/colliders, interactions,
  progression, harvestables, encounters, and geography unchanged.
- Added a dedicated production harness with four route-authored views in day
  and night. The clock is authored then frozen; weather is clear; HUD and the
  independent SubmersionOverlay are hidden; no state or content is injected.

## Scatter receipt

Authoritative Meadows bake completed with exit 0:

- fingerprint `6083690860057306`
- 823,832 kept / 3,469 drained placements
- 256 regions / 29,744,962 bytes
- exact Git-changed generated scope: 255 canonical paths (manifest plus 254
  region binaries); no noncanonical scatter output

## Validation

- Full focused cycle: **19 tests / 282 assertions / 0 failed**
  (`test_band_vegetation.gd`,
  `test_scatter_fingerprint_covers_bands.gd`,
  `test_scatter_perf_budget.gd`, and
  `test_old_mill_crossing_visual_identity.gd`).
- Final post-spacing R3 gate: **8 tests / 56 assertions / 0 failed** (scatter
  freshness/performance plus Old Mill identity).
- Production capture: **8/8 frames, 0 failures, exit 0**, written 08:28:06–
  08:28:28 local.

Evidence (generated, not intended for commit):
`ralph/reports/FOUR-BIOME-CONTINUATION-0910/OLD-MILL-CROSSING-IDENTITY-R3/`

## Honest remaining gaps

- The work practical has a real installed lantern and warm pool, but its small
  source tends toward pale cream under the production tonemap rather than a
  saturated amber read.
- The south-arrival composition shows the destination much more clearly after
  removing the exact trunk, but the mill roof apex is still very close to the
  upper frame edge.
- The Galecrest crop in view 03 is owned by the shared encounter-spacing pass;
  no mill-local creature deletion or relocation was made.
