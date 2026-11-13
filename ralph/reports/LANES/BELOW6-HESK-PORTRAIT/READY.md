STATUS: ride-along

# tb/below6-hesk-portrait: Rodkeeper Hesk's dialogue portrait matches his body (F41#8)

Direct data fix, no flag. G-below6-namedposts (tb/item-scout-1108 4c674d02), 3/3 on base and arm: "Rodkeeper Hesk's portrait shows a young dark-haired boy while the in-world speaker is a bearded man in a hat."

Cause: `distinct_bodies_1111` (ON) puts Hesk on the installed alpha_tracker body, which had no entry in `stormwood_dialogue_presentation.json npc_portraits.plates_by_profile`, so his lines kept the authored `villager_male` plate.

Change: `plates_by_profile` gains `alpha_tracker -> sorrel.png` (the installed plate rendered from that body) and `lost_traveler -> tobin.png` (profile fallback; Bryn's variant plate still wins). No new assets, no import.

Proof: `tests/test_stormwood_distinct_body_portraits.gd` (2 tests) with `test_stormwood_portrait_presentation.gd` and `test_dialogue_portraits.gd` pass; a CPU dialogue capture records `dialogue_portrait: sorrel.png` for `stormwood_rodkeeper_hesk_arrival`.

No GPU score of its own (it is on both sides of the BELOW6-NAMEDFACES arm). Batch it with any Stormwood landing.
