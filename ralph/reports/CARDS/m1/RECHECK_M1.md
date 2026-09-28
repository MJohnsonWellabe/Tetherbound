VERDICT: MET

# Strict re-check: card M1, "Meadows opening and village"

This re-check was independent and read-only. It wrote only this file and did not run Godot. It checked out main at `3dad15f4`, which includes `9e29d30e`, the cards-lane M1 run on `e35e2611`. It also read `tests/smoke_gate_b_continuous.gd` at `8c6657a5e` on GitHub, and GitHub run metadata for run 36269360016.

Scoring rules applied:
- ACCEPTANCE §6.1 "relaxed proof starts": disclosed fixtures, harness fights and skipped sub-parts do not make a claim partial, but co-op rows still need two-peer evidence.
- STATE §1 ruling 1 (relaxed proofs) and ruling 4 (in Phase 1, Bars A/B move to the Phase 2 catalog).

The card is scored as a composite: the integrated run `m1_run_e35e2611.txt` plus the F01 feeders.

## Clause 1: fresh controller run, beats in the specified order

Every line below is from `m1_run_e35e2611.txt`.

| Beat | Log line | Finding |
|---|---|---|
| Fresh title and new game | l.4-8 (`+0.12s title interactive` ... `new game world entered`) | Fresh scratch slot (l.3). |
| Starter | l.61-62 (`starter picker order [...]; 0 ui_right press(es) to 'terrapup'`; `starter selected and named (terrapup, uid ...)`) | Picked in the real picker. |
| Naming | l.62 (same line as the starter) | The name is confirmed as the named starter. The gate-B harness asserts the nickname is `CHOSEN_NAME`. |
| Real practice fight | l.66-68 (`engaged exact live target Wild_bramblebun_0_2`, `naturally weakened to 29/106 HP`) | Live combat, no HP fixture (l.69). |
| Practice catch | l.77-107 (throw 1 missed at l.81-82; strike at l.93; `catch complete; exploration resumed with two-creature party` at l.107) | l.108 reads `no seeded progress, HP pinning or reload`. |
| Village gate | l.109-111 (`village key earned and consumed by the real gate`) | Earned. |
| NPCs and tools | l.112-124 (Mira, Tam, Oskar, Bram dialogue cycles; axe, pickaxe and knife gathers) | Played. |
| Team built | l.125-209 (three more live Bramblebun engagements at l.125/169/183, natural weakening, earned orbs 47→44→43) | There is no per-catch "complete" line for the later catches. The five-member party at the reload (l.437) corroborates them. |
| Camp | l.210-372 (materials stage passed at l.354; l.372 `placed paid bedroll ... placed 3 creature beds through the build menu, one per entrant`) | Paid, not granted. |
| Three-bed tournament consent | l.374-375 (walk to the tournament marshal), l.376-383 (walk to beds 1, 2, 3 and the bedroll), l.385 (receipts `bed_assigned` 3/4/5 for party 0/1/2, plus care and `night_completed`) | See the note below. |
| Save/reload | l.386-440 (`flags 59 -> 59 (lost [], gained [])`; party, inventory and condition identical; `camp re-found from the save (beds [3, 4, 5], bedroll 2)`) | Production save path. |
| Bracket round 1 | l.447 (`tournament_quarter_mira won through 2 real opponent defeats and 23 landed attacks`) | Played. |
| Bracket round 2 | l.452 (`tournament_semi_tam`, 2 defeats / 29 hits) | Played. |
| Bracket round 3 | l.457 (`tournament_final_oskar`, 3 defeats / 56 hits) | Played. |
| Result | l.459 (`"failures":[]`, `"reached":"tournament_won"`, `"counts_as_proof":true`); l.460 `EXIT 0` | Passed. |

**Order.** The order is starter → naming → practice fight/catch → camp → three-bed consent/readiness → quarter → semi → final. It matches the card, and the log line numbers are monotonic. The gate, NPC, team and materials beats between the catch and the camp are the authored route. They are not out-of-order card beats.

**Note on consent.** The log has no explicit "consent" or "3-of-5 selected" line. The marshal visit precedes the bed assignment (l.374-375), the three beds go to three of the five members (l.385), and the bracket cannot run without entry.
- F01#4's gate-B chain asserts `tournament_entered` in ladder order.
- It also asserts that the starter is in `tournament_selection_ids` (`smoke_gate_b_continuous.gd` `_save_and_reload`).

That is adequate. A future run should print the selection explicitly.

Every README row checked against these lines is accurate. The README's "l.59-62" and "l.66-108" references are correct, and so are its figures of 29/106 HP, throw 1 missed, +125 s, flags 59→59, and 2/23, 2/29 and 3/56.

**Result: MET.** The disclosed shortcuts are harness-driven `InputEvent`s, harness fights, headless play, and a single seed and starter.

## Clause 2: WORLD §3.2 through-road and side lane; overhead plan

- F01#0 is met: `test_village_road_topology.gd`, `plan_old_new.png`, full CI 36280097924 green.
- F01#1 is met: the lane walks have max_off_road 0.00, and full CI 36276939256 is green.

The topology test re-derives the graph from the same config polylines the game uses (`terrain_playground.json` `paths.*`, clipped to the village fence). **MET.**

## Clause 3: day/night ordinary-camera walk; every gate, NPC and interaction

- `ralph/reports/MEADOWS/f01-walks/` exists.
- `day_d41ff2f0/` and `night_d41ff2f0/` exist.
- `code_blind_judge_verdict_day_d41ff2f0.md` and `code_blind_judge_verdict_night_d41ff2f0.md` exist.
- `RECHECK_F01_2.md` and `RECHECK_F01_3.md` exist, and both open with `Result: MET`.

Both walks start `--from-title` and use joypad events only. Each visits 11 of 11 targets: Grandpa, Mira, Oskar, Tam, Bram, Halda, the old key, the camp, RoadGate, PondGate and TrailGate.

**Coverage limit.** "Every NPC" is covered in the F01 sense, "every opening NPC, camp and gate", not all 18 placed villagers (l.29 `[village_npcs] placed 18 of 20`; the other 2 are held back by `place_when` and are not defects). In the walks, the camp, PondGate and TrailGate count as reached by proximity alone and are never operated (RECHECK_F01_2 aid 7). The integrated run adds real operation of RoadGate (l.111), the four NPC dialogue cycles (l.112-124), three tool gathers (l.117-119) and camp building (l.372).

Under the relaxed rule this skipped sub-part does not make the claim partial, provided it is disclosed. It is not yet fully disclosed; see Disclosures. Ruling 4 moves Bars A/B to Phase 2. **MET.**

## Clause 4: save/reload agree

- The integrated run passes: l.437-440 show zero flags lost, identical party, inventory and condition, and the camp re-found.
- F01#5 is met: the gate-B reload inside the chain, per starter, plus `MEADOWS-PAYOFFS/earned-bridge/RESULT.md`.

**MET.**

## Clause 5: two-peer layout agree

F01#6 is met, with the following evidence:
- The opening two-peer test (`MEADOWS-PAYOFFS/REPORT.md` l.493-499): 117 assertions, production host/join, both peers choose and name a starter, and "the full map draws the other player".
- A tournament two-peer test: 57 passed, 0 failed.

Its gap text reads "cold reconnect and road-layout agreement remain". That gap does **not** sink the clause under the relaxed rule:
- **Two-peer evidence exists.** §6.1's "co-op rows still need two-peer evidence" is satisfied by real two-peer opening and tournament state evidence. It is not a substitute such as a single-peer run.
- **The missing piece is a skipped sub-part, not a contrary result.** The two-peer opening witness predates the F01 road rebuild. The new through-road has never been walked by two peers. Nothing shows that the peers disagree.
- **The layout agrees by construction.** It is authored config: `terrain_playground.json` polylines and `village.json`, both loaded from `res://` on each peer. `TB_WORLD_SEED` only drives `spawn_tables.gd` and creature rolls, not roads. A disagreement would require the peers to run different builds.
- **Cold reconnect is outside M1's wording.** It is F01#6's own residual, and the card says "two-peer layout agree", not reconnect.
- **The README discloses it** (third shortcut bullet).

**MET under the relaxed rule.** The two-peer road-layout walk is still an unproven sub-part and must stay disclosed.

## Clause 6: all three starters, opening-to-bridge, without another starter

F01#4 is met. Its evidence is render runs 36269170273, 36269360016 and 36269361827 at `8c6657a5e`. Run 36269360016 was confirmed on GitHub: `render mc-tourn-ripplet @ 8c6657a5e...`, conclusion success, 2026-09-26 20:23Z.

**Starter exclusivity.** The board note "Fixture fixed to grant non-starters in batch #316" raised the risk that the cited runs used the old filler list.
- Before #316, main's fixture list was `["terrapup","ripplet","galewisp",...]` (read from `cb9c5eb4^1`).
- That list would have granted terrapup as the third member, which is another starter.
- The file at `8c6657a5e`, the SHA the renders ran, already has `["trailpup","riftfrill","galecrest","mudsnout","bramblebun"]` and the comment "never a second starter".
- #316 merged that fix to main.

So the cited witnesses did not obtain another starter.

**Scope of "opening-to-bridge".** The gate-B full chain asserts all 12 ladder flags in order, with the tracked objective ending on "South Bridge" (`CLOSING_OBJECTIVE`). That is ROADMAP Gate B's own end line, "objective to leave for South Bridge". The disclosed shortcuts in that chain are:
- It grants the third member and the levels.
- It sets `road_gate_open` by flag.

Both are allowed by the relaxed rule. The integrated M1 run earns the gate for real (l.111).

**MET.**

## South Bridge guardian regression (`../m2/BRIDGE_GUARDIAN_REGRESSION.md`)

On main `e35e2611`, the fresh earned party now fails the `south_bridge_grunt` fight in three of three runs. The failure is attributed to `trainer_ally_lateral_m: 2.4` from `3f04ece8` (F04#2), and it passes 2 of 2 with the value at 0.

This does not affect M1:
- M1's clause is an "opening-to-bridge witness", and the Gate B definition ends at the bridge objective, not the crossing. Crossing is Gate C/M2/F02.
- The M1 integrated run stops at `tournament_won` (l.459).
- The F01#4 witnesses end on the South Bridge objective.

**Caveat.** The F01#4 witnesses are from `8c6657a5e`, which predates `3f04ece8`. Nothing shows that a starter-parity regression in the pre-bridge chain happened on main. The M1 run shows that the terrapup chain through the tournament still passes on `e35e2611`. The regression is a real open defect for M2 and F02, and it must not be counted toward M1.

## Required disclosures (to keep on the board and in the README)

1. **Harness and seed.** Input is harness-driven joypad `InputEvent`s through the live InputMap, fights are harness-driven, the run is headless, and it uses seed 15 and the terrapup starter only. l.6 `ERROR: Couldn't create an ENet host.` is headless chatter, and the run is otherwise failure-free.
2. **Gate-B fixtures.** F01#4's gate-B chains grant the third member (non-starters) and the levels, and they set `road_gate_open` by flag.
3. **Two-peer layout.** The new road layout has not been walked by two peers. The two-peer opening witness predates F01's road rebuild. Cold reconnect is unproven (F01#6 gap). Layout agreement rests on shared authored config.
4. **Walk coverage.** "Every NPC/interaction" means the 11 opening targets of the F01 walks plus the integrated run's played beats, not all 18 villagers. In the walks, the camp, PondGate and TrailGate are reached by proximity only. **The README does not state this yet; add it.**
5. **Consent logging.** Tournament consent and the three-of-five selection are not printed as a distinct beat in the integrated log. They are inferred from the marshal visit, the bed receipts and bracket entry, and gate-B asserts them.
6. **Visual bar.** Bars A/B for the walks move to the Phase 2 catalog (ruling 4).
7. **Out of scope.** The South Bridge guardian regression on main is outside M1 and stays open for M2 and F02.
