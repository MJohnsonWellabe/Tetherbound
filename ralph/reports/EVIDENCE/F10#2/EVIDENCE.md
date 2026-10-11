# F10#2: Stormwood named fights, C2/C3

Branch `tb/ev-fights-c2c3`; the game source is `00d4a639` (origin/tb/ev-coordinator). Run 10:42 AM–12:06 PM CT, Sun 11 Oct 2026, Godot 4.7-stable headless Linux.

## Command (one process per case, all three starters)
```
godot --headless --path . --fixed-fps 60 --script tests/smoke_stormwood_b_named_c2c3.gd -- --seeds=24 --case=<id> --json=<out>
```
Cases are the six `stormwood_encounters.json` named encounters (BOSSES §7): hollows_alpha, capacitor_alpha, crown_guardian, old_rodfolk_hall_guardian, blackwater_elder and glass_field_alpha. All runs exited 0. 864 fights; no stalls and no errors.

## Inputs, disclosed
No save is used. The fixture party is the retained five at each region's entry level, computed by the smoke as the Calm band midpoint + 1: L45, 47, 49, 51, 51 and 52. Those levels fall inside the `chapter_curve.json` Stormwood regional team ranges. Foes come from production data through `stormwood_encounter_catalogue.gd::named_combat`. The arena is a flat collider: no storm strikes and no terrain. No tuning was applied.

## Result: PASS for C2 and the measured half of C3, all 18 case/starter rows
| Case (L, profile) | Reader win | Reader median lead cost | Masher median lead cost | Worst hit | Tells |
|---|---|---|---|---|---|
| hollows_alpha (48 CHARGER) | 1.00 ×3 | 0.000 | 0.82 / 1.00 / 1.00 | 0.079 | 0.80 |
| capacitor_alpha (50 DIVER) | 1.00 ×3 | 0.03–0.10 (ratio 0.11–0.19) | 0.26–0.54 | 0.053 | 0.80 |
| crown_guardian (51 WALL) | 1.00 ×3 | 0.000 | 0.40 / 0.76 / 0.98 | 0.077 | 0.85 |
| old_rodfolk_hall_guardian (53 ACE) | 1.00 ×3 | 0.000 | 0.34–0.57 | 0.089 | 1.10 (heavy holds) |
| blackwater_elder (53 CURRENT) | 1.00 ×3 | 0.000 | 0.32–0.65 | 0.040 | 0.80 |
| glass_field_alpha (54 CHARGER) | 1.00 ×3 | 0.000 | 0.91 / 1.00 / 1.00 | 0.071 | 0.80 |

Rules applied (the smoke's own verdicts): reader median lead cost ≤ 0.55 × masher; reader win ≥ 0.90; no hit ≥ 0.50; every tell ≥ 0.8 s; heavy tells ≥ 1.1 s.

Observation for the reviewer, not a gate: every single hit is ≤ 9% of HP, and the reader is almost never touched. These fights pass by a wide margin rather than near the bar.

## Scope and open items
- This covers the six named wilds, which is the smoke the criterion names. The Stormwood named trainers (the Marrow finale and others) are measured under F22#4.
- The other half of C3 is still open: framing at actual scale, readable lightning/phase cues, and the code-blind footage verdict. These are capture items, and CAPTURE-READY has been sent.
