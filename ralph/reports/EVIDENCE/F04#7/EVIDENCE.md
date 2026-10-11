# F04#7: Meadows named fights, C2/C3 (and varied-size framing)

Branch `tb/ev-fights-c2c3` at `00d4a639` game source (origin/tb/ev-coordinator; later lane commits are evidence only). Run 10:42 AM to 12:03 PM CT, Sun 11 Oct 2026, Godot 4.7-stable headless Linux.

## Command (one process per starter, all eight cases)
```
godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd -- --seeds=24 --starter=<terrapup|ripplet|galewisp> --json=<out>
```
Raw output: `run_<starter>.txt` (stdout) and `run_<starter>.json.gz` (every run). Exit code 1 for all three, meaning a verdict failed.

## Inputs, disclosed
- No save is involved. The smoke builds a fixture party: the retained five (starter, bramblebun, mudsnout, pipwing, trailpup) at each band's `chapter_curve.json` `team.enter`. That is L9 for the guardian, L12 for band 3, L15 for band 4 and L18 for band 5.
- Foes come from the production trainer data through `trainer_npc.gd::creature_for` and the burrow_warrens guardian block.
- The flat-collider fixture uses the production CombatManager and WildCreature AI. No terrain, no guardian 1.35 scale, no gear.
- No tuning was done.

## Result: FAIL (C2). The measurable half of C3 passes.
| Case | Terrapup | Ripplet | Galewisp |
|---|---|---|---|
| warrens_guardian (named wild) | PASS | **FAIL** reader lead cost 0.440 > 0.55 × masher 0.350 | PASS |
| relay_officer_dell | **FAIL** masher lead faint 0.29 < 1.00 | PASS | PASS |
| relay_captain, captain_riverwatch, captain_field, captain_ridge, stronghold_elite, warden_aldis | PASS | PASS | PASS |
| **Chapter: masher loses ≥1 named fight (1−Π win), bar ≥0.25** | **0.21 FAIL** | **0.21 FAIL** | **0.23 FAIL** |

The masher wins nearly every trainer fight. Its losses come only from captain_riverwatch (win 0.79/0.79/0.96), stronghold_elite (0.92, Galewisp) and warden_aldis (0.88, Galewisp). Reader win is 1.00 in every case.

C3:
- Worst neutral-matchup single hit is 0.467 (captain_riverwatch), within the 0.50 ceiling.
- The worst any-matchup hit, reported but not gated, is 0.510: Riverwatch against Ripplet, at ×1.25 type.
- Minimum tell is 0.85 s for the guardian and 0.90 s for the trainers, so the 0.8 s floor holds. Heavy tells are observed up to 1.40 s.

Reader fight length is 93–207 s for trainers, inside the 2–5 min named-fight band.

## Repair attempts (1:57 PM CT, Sun 11 Oct 2026)
1. **Dell bar (kept, `bde5cacad`).** Dell is a mid-band officer, so `relay_officer_dell` is now judged on COMBAT §7's floor bar (COMBAT.md:142, ACCEPTANCE.md:38) and still counts in the chapter product. Terrapup, before → after: FAIL (masher lead faint 0.29) → PASS (reader/masher lead 0.176/0.932, reader win 1.00).
2. **Reader pilot (reverted, `da1163323`).** A scratch diagnostic of the Ripplet guardian fight found every hit landed inside the drawn shape, so the cue is honest. The reader was committed for about 26 of the 54 tell frames.
   - Gate A (no quick while the foe's cooldown is under windup + recovery + 0.25 s): guardian 0.44 → about 0.11 (6 seeds). But Nerissa's reader win fell 1.00 → 0.46 with 13/24 stalls, and Venn's to 0.83–0.96.
   - Gate B (only 0 < cooldown < commit): Nerissa back to 1.00 (4 seeds), guardian back to about 0.34 against the masher's 0.35.
   - Two failed attempts, so the pilot is back to its original code. The Ripplet guardian row still FAILS (0.440/0.350).
3. **Chapter tune (reverted).** Warden non-lunge power ×1.15 (24 seeds × 3): masher win went from 1.00/1.00/0.88 to 1.00/1.00/0.83 (Terrapup/Ripplet/Galewisp). The neutral worst hit reached 0.471–0.479, near the 0.50 ceiling. With the rest of the party carrying the masher, power within the C3 ceiling does not reach the 0.25 chapter bar. The probe's reader rows ran on gate A and are not used.

## Not done / open
- **Varied-size framing and the C3 code-blind footage verdict are capture items.** CAPTURE-READY has been sent to the coordinator.
- **No tuning was attempted.** Lifting the chapter masher-loss rate means raising foe pressure. Neutral worst hits already sit at 0.41–0.47, against C3's 0.50 ceiling. No declared per-fight tuning range was found in BOSSES/COMBAT. BOSSES §4.3 says the F04#7 powers were set per body from measured worst hits. COMBAT §7 calls the chapter 25% "the Balance lane's reading". Retuning is therefore a balance/design call, not a smallest fix.
