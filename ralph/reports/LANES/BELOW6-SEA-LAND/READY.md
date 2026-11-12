STATUS: land

# tb/below6-restored-sea-land: restoring the currents changes the sea (F39#17)

**Verdict:** GPU High, G-below6-swim-sea-r5 (`ralph/reports/GPU-PASS/1108/G-below6-swim-sea-r5.md` on tb/item-scout-1108 5c800b97): F39#17 6.08 -> 6.27 (+0.19, 2/3 prefer); S3 waterfall and S4 sunset restored +0.10 (no loss). "The restoration reads again: navy channel, sandbar surf rings, flow streak."

**Flag:** `data/config/water_current_flow_visual.json restored_sea_1112`, ON with `_why_on`.
**Code:** `scripts/world/water_restored_sea.gd` (new), attached in `scripts/world/water_veilfall.gd` beside the flow view and drift markers.
**Tests:** `tests/test_below6_restored_sea_landed.gd` (pin), `tests/test_water_restored_sea.gd`; with the current-flow tests: 0 failed.

**Scope:** client presentation driven by the existing replicated world fact `water_currents_restored`, read once a second: sea shader values by time-of-day preset and the visibility of the existing drift floaters. No flow vector, strength, physics, route, save or authority change.

**Known remainders:** the surf rings read as "flat concentric shader bands" to one judge (break them into irregular surf and foam lanes next). On BASE, restored S1 and the sunset frame show a red-brown clump mid-water that 2/3 say "leans toward oxblood"; it is not from this arm and needs a look.

The row is still below 7.5; this landing is a judged gain, not a close.
