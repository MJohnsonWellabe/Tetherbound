# P2-045 tier-dressing candidate

The Stormwood and Tidewake ordinary-cache adapters previously called
`ItemCachePickup.setup` without the existing Meadows `band_pickups.dress`
treatment. A shared presentation adapter now delegates Good/Great/Rare Candy
to that exact treatment, gated by `candy_pickup_presentation.json.enabled`.
The flag defaults to false. No new candy mesh, item definition or grant path
is introduced. Skill Candy is not changed by this candidate.

Independent read-only reviewer `stormwood_dialogue_review` found no concrete
bugs: disabled mode mutates no presentation; enabled mode dresses newly
instantiated pickups once; residency/restoration rebuilds make new nodes;
glow registration updates the existing entry; no dependency cycle is added.
IDs, quantities, claims, positions and interaction nodes remain unchanged.

Focused regression run: 53 tests, 44,608 assertions, zero failures across
existing band-pickup, Stormwood pickup/NPC/trainer and Water personal-pickup
tests. Godot parser checks passed for the adapter and both call sites.

Native before/after sightings and visual acceptance remain outstanding. The
Skill Candy black-wrapper/marking contract in `water_crafting.json` is still
unfulfilled and needs its own native close read within this catalog item.
P2-045 remains open; no visual fix is claimed.
