# F47#0 — preparation-depth levers if the playtest runs short (systems-b, 5:20 PM CT; none applied)

Data-only levers per PROGRESSION §4 (deepen preparation, not padding). Added time = agent estimate at the f27 ledger rates (node harvest 2 min, catch/release 3, alpha 5, refight 1.5, bounty 10), for a solo five-creature team over four chapters.

1. `masters.json` preparation_supplies: halve the raw-material share (keep potions/feast inputs). The gathering moves back onto the route's own nodes. **+1.5–3 h**, which is about 45–90 node harvests.
2. `masters.json` attuned_per_creature 1–2 → 3 (each Master). This adds attuned-herb gathering per feast across the eight home crops and biome nodes. **+0.5–1 h.**
3. `gear.json`: make +1 the recommended (not required) tier for each chapter boss in the boss_proof/recommendation text, and price the +1 upgrade with one biome material. The extra gathering is optional but surfaced. **+0.5–1.5 h.**
4. `feasts.json`: each tier's feast also takes one optional-region material (an activity reward item). That ties Masters to the 6–10 optional activities. **+1–2 h** of activities that are now motivated.
5. `rematches.json`: Master rematch rewards carry the next-tier feast's attuned herb, so rematches become a preparation route, not a repeat. **+0.5–1 h.**
6. `bounties.json`: add material-delivery templates for each band's gear metal (cliffglass, sluice metal, sparkfur). The board then steers the gear loop. **+0.5–1 h.**
7. Traits: raise trait-seed weight on optional alphas (`alpha_respawns` trait roll) so the team-building choice pays. **+0.5–1 h** of optional hunting.

Combined, levers 1–4 ≈ +3.5–7.5 h, which brings the 8.8–12.5 h agent estimate to about 12–20 h. Every lever is a config number with a `_why`; the economy ledger (`node tests/test_economy_*.mjs`) and the F47#2 census must re-run after any change.
