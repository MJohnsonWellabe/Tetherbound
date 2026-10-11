# F04#2 Three captains: evidence (lane meadows-fights)

Run 2026-10-11 CT, Godot 4.7-stable headless.

## Result: FAIL (witness), because Captain Field's dodge witness is at its margin.

**Code check.** Each captain has a distinct named pattern in `combat.json`:
- Oreth: "Patience then sustained pressure".
- Halder: "Range control; long narrow charge".
- Vess: "Endurance with a flank/landing ace".

The sequences are wall/charger/diver/current rows ending in each captain's own ace attack (`oreth_pressure`, `halder_range` + `charger_double_rush`, `vess_flank`).

| Commit | Command | Result |
|---|---|---|
| ea3a1ebb | `smoke_named_fight_hit_avoid.gd -- --trainer=relay_officer_dell,relay_captain,captain_riverwatch,captain_field,captain_ridge` | Oreth PASS, Halder PASS (1 of 4 dodged), Vess PASS |
| d885d383 | `smoke_named_fight_hit_avoid.gd` (default: three captains + Warden) | Oreth PASS, **Halder FAIL (0 of 4 dodged)**, Vess PASS, Warden PASS |

**Why Halder fails.** Every dodged strike is the lead Duskhush's `current_zone`, a field with a 2.5 m radius. Its marker tracks for the first 30% of the 1.1 s tell, clamped to the 8 m range along the line to the target. The witness dodges by backing straight away from the opponent, so it stays on that line. It finished 8.3–9.8 m out, still within marker radius + body radius (about 4 m) of a marker 8 m out. The one avoided field at ea3a1ebb backed 5.6 m to 11.4 m. The d885d383 change (DIVER leap arrival) does not touch fields.

The game behaves as authored (`safe_escape: outside`). The witness's escape direction is the weak part. Changing that harness policy (for example, a lateral escape for `field` strikes like the one it already uses for CHARGER lanes) needs the coordinator's approval, which has been requested.
