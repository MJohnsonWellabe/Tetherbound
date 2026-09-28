# P2-054 disposition

**Deferred. Owner: Cloudreach-owned shared pickup presentation lane.** No fix or visual acceptance is claimed.

Source audit finds inconsistent mushroom dressing between BandPickups and ItemCachePickup. A shared, texture-preserving variant treatment still needs matched production-camera proof; changing the common mesh globally would affect all three mushroom items.

## Evidence and source audit

data/items/items.json assigns Speed, Stamina and Wild mushrooms the same mushroom_pickup.glb and world_model_scale=0.5, but distinct item colors/descriptions. band_pickups.gd applies MUSHROOM_LOOK per item, while item_cache_pickup.gd::_build_visual instantiates the shared resource and scale without that dressing. Its pickup highlight uses item color separately. This is a concrete presentation-path difference consistent with the original identical-cluster finding, not proof that a copied tint is a good-looking fix on every surface of the PackedScene.

Original capture IDs and reproduction provenance remain in `../../catalog.csv` and the biome manifest. This disposition preserves the unresolved defect; source inspection is not a visual PASS.

## Required follow-up

Centralize the intended three visual variants across both pickup paths while preserving textured materials and non-mushroom props. Capture Speed/Stamina/Wild at normal distance by day/night in both paths and obtain a blind discrimination/cohesion verdict. Item effects, inventory identity and pickup transactions stay unchanged. No variant candidate is enabled.
