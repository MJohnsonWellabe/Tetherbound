# F47#0 — preparation-depth levers if the playtest runs short (systems-b, 5:20 PM CT; original options below)

Data-only levers per PROGRESSION §4 (deepen preparation, not padding). Added time = agent estimate at the f27 ledger rates (node harvest 2 min, catch/release 3, alpha 5, refight 1.5, bounty 10), for a solo five-creature team over four chapters.

1. `masters.json` preparation_supplies: halve the raw-material share (keep potions/feast inputs). The gathering moves back onto the route's own nodes. **+1.5–3 h**, which is about 45–90 node harvests.
2. `masters.json` attuned_per_creature 1–2 → 3 (each Master). This adds attuned-herb gathering per feast across the eight home crops and biome nodes. **+0.5–1 h.**
3. `gear.json`: make +1 the recommended (not required) tier for each chapter boss in the boss_proof/recommendation text, and price the +1 upgrade with one biome material. The extra gathering is optional but surfaced. **+0.5–1.5 h.**
4. `feasts.json`: each tier's feast also takes one optional-region material (an activity reward item). That ties Masters to the 6–10 optional activities. **+1–2 h** of activities that are now motivated.
5. `rematches.json`: Master rematch rewards carry the next-tier feast's attuned herb, so rematches become a preparation route, not a repeat. **+0.5–1 h.**
6. `bounties.json`: add material-delivery templates for each band's gear metal (cliffglass, sluice metal, sparkfur). The board then steers the gear loop. **+0.5–1 h.**
7. Traits: raise trait-seed weight on optional alphas (`alpha_respawns` trait roll) so the team-building choice pays. **+0.5–1 h** of optional hunting.

Combined, levers 1–4 ≈ +3.5–7.5 h, which brings the 8.8–12.5 h agent estimate to about 12–20 h. Every lever is a config number with a `_why`; the economy ledger (`node tests/test_economy_*.mjs`) and the F47#2 census must re-run after any change.

## Routes candidate, 14 Oct — optional +1 gear inputs move onto authored sites

`tb/routes` changes only the two raw ingot/plate inputs in each `masters.json` preparation bundle. Meadows splits its revised allotment across Orin and Mira. Potions, attuned feast ingredients, other station/camp supplies, gear recipes and drop/respawn rates are unchanged. The proposed per-character chest inputs are:

| Chapter | Raw pair | Before | Candidate |
|---|---|---:|---:|
| Meadows, Orin + Mira combined | Rootstone / Ironwood | 240 / 147 | 100 / 60 (Orin 80 / 45, Mira 20 / 15) |
| Tidewake, Ione | Sluice Metal / Reef Stone | 180 / 100 | 80 / 50 |
| Cloudreach, Aster | Cliffglass Ore / Windworn Heartwood | 200 / 128 | 80 / 45 |
| Stormwood, Rowan | Stormglass / Thunderwood | 200 / 128 | 80 / 45 |

Ten optional +1 Harness/Charm upgrades consume 20 ingots or plates per character, refined from 40 primary and 20 secondary raw inputs. The four-character census now places each chest below the +1 demand (Meadows 400/240 versus 466/266; Tidewake 320/200 versus 408/260; Cloudreach and Stormwood 320/180 versus 408/220), so a player choosing +1 must use authored gathering or activity rewards. The baseline required scenario remains solvent in every chapter; the +1 scenario remains solvent when counted world sources are used. This offers a home-craft and regional-resource route without adding a repeat-farming gate to config; the played route must still verify that those sources are reachable.

Focused check with the candidate applied: `node --test tests/test_f27_route_ledger.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs tests/test_economy_supply_census.mjs` returned **27 pass, 0 fail**. The supply census is source arithmetic, not a played route, and its site coverage does not prove accessibility, contested co-op timing or a 15–25-hour clear. The earlier option estimated +1.5–3 h for a smaller raw-material reduction; even if that full increase applies here, the current 8.8–12.5 h agent estimate would become only about 10.3–15.5 h. F47#0 remains OPEN; no new duration is claimed. Preserve TRAINING's 0.35 automatic XP, chosen Altar spend, Master/feast gates and the five-owned cap.

Independent economy review found a save compatibility defect in the live candidate: `scripts/net/character_action_delivery.gd` replays retained `master_chest` rows against current `masters.json` supplies and requires the exact saved after-state. Its historical fallback covers candy/recipe-only chests, not the larger preparation bundles already awarded. `autoload/world_state.gd` validates pending and accepted rows on load/selection, so a reduced live payout can reject an existing earned save. The review also confirmed that optional +1 gathering need not increase a normal clear at all. The live `preparation_supplies` grants in `masters.json` were restored. The exact numeric proposal now sits under top-level `_f47_0_dormant_clear_time_proposal` metadata in that same config; runtime Master rewards do not use it. Any later payout change must preserve exact historical chest replay and prove an old saved row survives load/reconnect without loss or duplication, then measure the agent route and obtain the owner's play confirmation. No F47#0 acceptance or F49#3 passing commit follows from the arithmetic check.

Focused independent re-review of the dormant config revision: all five live `masters[].preparation_supplies` equal the pre-candidate values. `scripts/creatures/breakthrough.gd` selects only rows under `masters` and reads their `preparation_supplies` for chest staging, so the top-level proposal changes no grant or retained-row replay. `scripts/net/build_fingerprint.gd` hashes all config bytes, so peers need the same build fingerprint after this metadata-only commit; that is the normal version-match rule. The same four focused ledger/census files returned **27 pass, 0 fail** with the metadata present. F49#3 is not ready: F49#0 has no passing earned chain or landed passing commit to publish.
