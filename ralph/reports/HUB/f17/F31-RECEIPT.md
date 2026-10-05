# F31 Homestead stations and upgrades — lane A receipt (tb/f17)

ACCEPTANCE §6 F31, per criterion. Device play and owner play remain BLOCKED_OWNER.

| # | Criterion | Status | Proof |
|---|---|---|---|
| 0 | Workbench, Forge, Kitchen, Altar, Den, Farm (plus chests) buildable on the homestead plot | PASS (local) | `tests/smoke_f31_station_paid_path.gd`: all six base stations placed through the real ghost + Place press at the exact price, journal binds (Altar on its own version-1 journal). Chests are the Storage piece (`smoke_menu_focus`). Placement refusals now say what is wrong (occupied/slope/ground/reach). |
| 1 | One attachment per biome per station, recipe tier requires the attachment | PASS (unit) | `test_station_attachment_gates` 8/14; paid smoke snaps Forge Meadows to slot 1, effective tier 1, dismantle order + refund. |
| 2 | Meadows tier from start; relic hang unlocks next tier; one chosen relic power | Built, unit-proven; inert while F18's portal runtime is off | `test_relic_hang_attachment_blueprints` 4/13, `test_relic_power_selection` 3/18, `test_crossing_hall_relic_hang` 4/10; two-peer smoke: guest relic power refused with the runtime off. |
| 3 | Single next-upgrade target per station | PASS (unit) | station gate tests. |
| 4 | No automation | PASS (unit) | `test_homestead_no_automation` 4/16. |
| 5 | Co-op: world-owned buildings, personal tiers/recipes, guest crafts at host tier and keeps output | PASS (CI) | `tests/smoke_net_homestead_station_craft.gd` (peers: 2): render.yml 37285031027 @ 4071a284 and 37289152116 @ 81e045f0, success. Guest gathers two world finds through the host's ledger (journaled reward delivery; host takes item/count from its own world), host authority equals guest satchel, guest crafts at the host's tier-1 Kitchen and keeps the potion, host stock untouched, reconnect re-grants nothing. Evidence: `f31-5-craft-2peer-r8/`, `f31-5-craft-2peer-r9/`. |
| 6 | Stations read as distinct objects at the normal camera (code-blind judge) | PASS (code-blind judge, r14) | `f31-stations-r14/judge.md`: all six read as distinct and purpose-identifiable by day and at night, none confusable, no red/oxblood. Path: r4 PARTIAL → r9 4/6 → r13 PARTIAL (Workbench a bare table, Altar a headstone) → r14 PASS after the Workbench tool wall/vice/half-built crate and the Altar sigil/cloth/offering bowl. Optional polish noted by the judge (altar top block, kitchen food, forge stone material) is not required. |

Fixes found on the way (all with proofs): station panels never settled on a saved homestead action (`01c64ec0`, paid smoke fails without it); completion announced on every poll (`cf138d82`, 6 → 1); guest world finds never reached the host's character authority (`4071a284` + `81e045f0`, `test_guest_pickup_delivery` 9/31). Independent review: `review-f31-coop.md` (nothing blocking).

Open, routed by the coordinator: guest harvest/vegetation batching and the F32 receipt cap (lane A, next); disconnect-before-replay window (F27); guest re-admission semantics (owner question).
