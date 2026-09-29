# P2-106 disposition

**Deferred. Owner: Cloudreach atmosphere/art lane.** No fix or visual acceptance is claimed.

The original strongest evidence is a deliberately off-terrace riding view. A normal flying arrival is still needed to choose a cloud treatment; island-mist geometry and the cloud deck are separate render paths.

## Evidence and source audit

cloudreach_world.gd::_build_island_mist uses low-segment sphere meshes flattened vertically to 0.36 of their horizontal size, with the island_mist material. The main cloud sea instead uses a deck and cloud-volume shader proxies. That source distinction supports investigating the local mist collar, but does not by itself prove which geometry dominates the original riding frame. The regional still set does not replace the normal flying-arrival comparison requested in the catalog.

Original capture IDs and reproduction provenance remain in `../../catalog.csv` and the biome manifest. This disposition preserves the unresolved defect; source inspection is not a visual PASS.

## Required follow-up

Capture the terrace collar from normal approach, landing and outward views in day/night, identify the visible layer, then redesign its shape/material transition into the deck. Preserve the CloudSea node height used by fall recovery. No cloud candidate is enabled.
