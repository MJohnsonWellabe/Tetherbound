# Meadows 09/12 strict 43-row acceptance audit — current evidence

**Audited revision:** `440569701b` (`codex/all-branches-integration-0913`)

**Scope:** all 17 Tier 0, 7 Tier 1, 12 Tier 2, 2 Tier 3 and 5 Tier 4
rows in `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`.

**Supersedes:** `STRICT-43-ROW-AUDIT-2026-09-12.md`, which was a static
source audit at `e0db2f86` and explicitly left 27 rows awaiting evidence.

## Strict result

| State | Rows | Count |
|---|---|---:|
| Accepted on current production source and retained evidence | T0 `1–17`; T1 `1–7`; T2 `1–12`; T3 `1–2`; T4 `1–5` | **43** |
| Awaiting evidence | none | **0** |
| Missing production source | none | **0** |
| Total |  | **43** |

This count does not promote visual work from automated checks. Visual rows below
name retained production captures with independent judgments. Runtime rows are
bound to production smokes or current unit contracts, not config intent alone.

## Row-by-row reconciliation

| Row | Accepted evidence on the current source line |
|---|---|
| T0 #1 | The production village-gate opening contract and current regression coverage pass; accepted before the `e0db2f86` baseline audit and unchanged. |
| T0 #2 | Beside-not-behind formation passed production capture and independent review in `final-companion-06`, with later camera-depth protections retained (`eba02eff`, `04d07d49`). |
| T0 #3 | Saddle warning is state-transition bounded by the current riding-saddle contracts; accepted before the baseline audit. |
| T0 #4 | Outside-combat orb input no longer repeats a toast; current HUD/input contracts retain the accepted baseline behavior. |
| T0 #5 | Party order remains stable across combat; accepted current combat/HUD contracts. |
| T0 #6 | Poise/stagger, wind, telegraph and burst-step production systems are covered by `test_combat_stagger.gd`, `test_combat_wind.gd` and `test_combat_burst.gd`; source checkpoints include `9c77c1e6` and `b92d2e5f`. |
| T0 #7 | Combat tracking/framing repair `e570daaf` remains covered by the current camera contracts. |
| T0 #8 | Cleared-cluster cooldown/load behavior passed the production smoke and was accepted in `31403f39`. |
| T0 #9 | Co-located remote trainer body and identity passed the fresh two-peer proof retained at `net-meadows-identity-fresh-join-20260913T0335CDT/REPORT.md`. |
| T0 #10 | Minimap/full-map heading contracts pass in `test_map_player_heading.gd`; accepted before the baseline audit. |
| T0 #11 | Full-satchel feedback passed the production pickup path and was accepted in `330cc965`. |
| T0 #12 | Live saddle/back and rider/seat fitting passed the production riding smoke and independently judged `final-riding-08/REPORT.md`. |
| T0 #13 | Authored Terrapup `rest` animation passed 16 tests / 201 assertions and the independent day/night R41 review recorded in `docs/HANDOFF_MEADOWS_CLOSEOUT_2026-09-13.md`. |
| T0 #14 | Stamina Shroom copy matches its real stamina effect; accepted item-data contract from the baseline audit. |
| T0 #15 | Creature power-move statistics remain reachable at the bottom of the panel; accepted UI-layout contract from the baseline audit. |
| T0 #16 | Halda's enter/ready-per-round consent flow passes `smoke_tournament_consent.gd`; accepted baseline behavior. |
| T0 #17 | Teleport destinations collapse by biome and expand on request; production map-interaction acceptance is retained by `d6f7e0eb`. |
| T1 #1 | Live objective beam implementation `6ad66637` passed the production views accepted in `final-wayfinding-pulls-05/REPORT.md`. |
| T1 #2 | Road NPC dialogue reveals actionable locations through the production dialogue/map path covered by `test_dialogue_map_reveal.gd`; accepted baseline behavior. |
| T1 #3 | The South Bridge level/bond prompt passed the standalone Nessa production route smoke (`4961955d`), including save/load and no replay. |
| T1 #4 | The pond/alpha route prompt passed the same production prompt family and accepted baseline route behavior. |
| T1 #5 | Personal persistent map markers passed production map interaction and the remote full-map proof (`6d751bb8`, `bdb3f3db`). |
| T1 #6 | The empty south-trail stretch was repaired in production (`621612b5`) and its forward-visible creature cadence is retained by `test_road_creature_visibility.gd`. |
| T1 #7 | Peripheral/off-path signals passed independent production judgment in `final-wayfinding-pulls-05/REPORT.md`. |
| T2 #1 | Opening-village street/layout repair passed independent production judgment in `final-village-06/REPORT.md`. |
| T2 #2 | Mira's shop sign and street read passed in the same accepted `final-village-06` production set. |
| T2 #3 | Bramblebun low-light color passed the production comparison and independent report `bramblebun-low-light-02/REPORT.md`. |
| T2 #4 | Cloth banner treatments passed independent day/night production judgment in `final-banner-treatments-07/REPORT.md`. |
| T2 #5 | Burrow Warrens approach, rooted passage and guardian den passed 9/9 production frames, 8 tests / 135 assertions and independent blind review in `final-warrens-62-desktop-01/BLIND_REVIEW.md`. |
| T2 #6 | Stonewater Reach composition passed independent production judgment in `final-stonewater-06/REPORT.md`. |
| T2 #7 | Riding silhouette, tack contact and seat fit passed the independent `final-riding-08/REPORT.md` judgment. |
| T2 #8 | First Ironwood texture, workyard and story path passed production evidence in `final-ironwood-03/REPORT.md` plus the live story smoke. |
| T2 #9 | Distant Cloudreach prominence was reduced and atmospheric separation accepted in `final-far-country-thin-woods-03/REPORT.md`. |
| T2 #10 | Walkable thin-woods density variation passed the same independently judged production set. |
| T2 #11 | Sela's shortened dialogue tree was accepted in the baseline audit and remains covered by current dialogue contracts. |
| T2 #12 | Tether Relay scale/material hierarchy passed independent production judgment in `final-relay-04/REPORT.md`. |
| T3 #1 | Multiple optional visual pulls and reward-bearing detours passed the independently judged `final-wayfinding-pulls-05/REPORT.md`. |
| T3 #2 | Small Potion value/economy repair `1e42c062` passes the real project potion harness. |
| T4 #1 | Second-player map presence passed the serialized remote-map production proof (`bdb3f3db`). |
| T4 #2 | Compact chosen-name tags passed the fresh two-peer production proof retained in `net-meadows-identity-fresh-join-20260913T0335CDT/REPORT.md`. |
| T4 #3 | Per-player selected character bodies replicate in that same fresh two-peer proof. |
| T4 #4 | Fresh joins start in Grandpa's Village in that same serialized proof. |
| T4 #5 | A fresh join receives exactly one starter in that same serialized proof. |

## Separate closeout ledgers

The owner-playtest audit is **43/43**. The named-location visual ledger is
separately **23/23**, including current accepted production evidence for The
Rise, Old Quarry, Old Mill Crossing and Burrow Warrens. Neither total by itself
closes Meadows: regression/export verification and the continuous non-Quick
campaign must still prove A1–A11.
