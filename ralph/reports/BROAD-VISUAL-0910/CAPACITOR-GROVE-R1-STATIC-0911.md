# The Capacitor Grove — R1 static recovery candidate

## Baseline disposition

`FAIL`. The latest accepted catalogue day frame is dominated by a clipped hot-magenta creature and competing lime/purple/scarlet accents; the night frame is nearly black except for the same near surface. The named grove and trainer relationship do not read.

The obstruction has an authoritative cause: the map landmark, `capacitor_alpha`, and a one-time pickup all occupy `(-1080, 3020)`. The generic catalogue uses that same point as its camera/player seat. Those placements are gameplay content and remain unchanged.

## Bounded candidate

- Retain the canonical landmark, named encounter, pickup, Conductor Run roads, and functional arch footing.
- Dress the existing footing at `(-1040, 3070)` as a three-bank capacitor crescent, reusing the Dynamo's installed tether-pylon finish.
- Keep the nine-metre socket open. Every added piece is visual-only and owns no collision.
- Use one restrained cyan stormglass accent and a 17 m local light rather than the baseline's competing saturated palette.
- Provide dedicated production views from the road, west profile, and footing threshold; none uses the stacked encounter/pickup seat as a camera position.

## Static evidence

- `data/config/stormwood_capacitor_grove.json` owns only the visual bank arrangement and local light budget.
- `scripts/world/stormwood_capacitor_grove.gd` builds three grounded pylon banks, nine charge rings, one overhead collector, and three converging conductor arcs.
- `scripts/world/stormwood_arch_runtime.gd` mounts this visual-only child only for the `capacitor_grove` footing.
- `tests/test_stormwood_capacitor_grove_identity.gd` asserts hierarchy, restrained light, zero collision, open socket clearance, production mount, and unchanged landmark/footing/encounter/pickup positions.
- `tools/capture_stormwood_capacitor_grove.gd` is a six-frame day/night production harness. It was parse-checked only in this no-render lane.

## Expected disposition

`POLISH`, pending fresh production frames. The candidate establishes a named-location silhouette and coherent night focal story while removing the categorical evidence failure caused by the generic stacked camera seat. It is not claimed `PASS` without rendering: foliage occlusion, terrain grounding, and live alpha wander still require visual judgment in the dedicated frames.
