# D74 — A world pickup is its place, not its item; recovery arrives before attrition

**Decided:** 2026-09-04, lane W17-DENSITY-B2-B3, under the standing rule that small
design calls are recorded here rather than asked (`docs/00_START_HERE.md`).
**Status:** accepted unless newer owner direction says otherwise.

## The decisions

1. **An authored world pickup's persistent identity is its placement id, never its
   item id.** `data/config/bands/<band>/pickups.json` gives every placement a globally
   unique `id` (`b2_candy_quarry_ledge`), and that id is the save's once-flag
   (`cache:<id>`). `item_cache_pickup.gd::setup()` gained an optional `flag_key` for it.
   The four `CACHE_AT` caches in `playground_world.gd` keep keying on their item, exactly
   as before.

2. **Candy tier is told at instancing, from one mesh.** Good / Great / Rare are one
   `candy_pickup.glb` with a `material_override` tint, an emissive medallion on the
   crown in the item's own `items.json` colour, and two small primitive wings on Rare
   only. Mushrooms are tinted the same way; the Wild Shroom's broader cap is a
   non-uniform scale. No second mesh, no generation.

3. **The addendum's tiering is applied literally, per band.** The critical path carries
   two Good candies per band and nothing better; side ground carries Good; the band's
   authored detours (`terrain_playground.json` `trail.loops`), named places and harder
   optional fights carry Great; the two Rare per band sit on the rarest wild
   (Nightburrow, Stormtrail, Riftfrill) or the deepest branch (band 2's far-west
   pocket).

4. **Recovery is placed before the attrition it supports, never inside a gauntlet.**
   Revives and potions sit on the approach to the Warrens mouth, before Kest, at the
   camp before the relay barricade, and on the far landing after the crossing. Nothing
   that heals is authored between Hess and the restored crossing
   (`GATE3_ENCOUNTER_CONTRACTS.md` P-3.1), and no Warrens interior pickup exists
   (prompt 63: the dungeon is not a free hotel).

## Why

The addendum (§B) says "one persistent pickup identity per authored location so
save/load cannot duplicate a collected candy." The existing seam keyed its flag on the
item, which was right for one elixir and wrong for thirty Good Candies: the first one
taken would have silently deactivated the other twenty-nine on the next boot.
`tests/test_band_pickups.gd` was seen red on exactly that before the key landed.

The tiering and the recovery rule answer the owner directly (OWNER_DIRECTIVES
2026-09-04-C §2–3): candy must answer *"why should I explore over there?"*, and the
pickup economy must support the attrition/camping loop rather than erase it. A Rare on
the road, or a revive inside the relay, would have been the placements that break both.

## What this does not decide

The chapter-wide counts (about 100 candy, 100–150 findables) are the addendum's and are
tuned from route evidence, not from this file. Bands 4–5 are the W18 lane's batch.
Whether a candy can cross the level cap, and whether funnelling every candy onto one
creature trivialises a required fight, are the progression-safety questions the
addendum reserves for the candy item's own effect, not for placement.
