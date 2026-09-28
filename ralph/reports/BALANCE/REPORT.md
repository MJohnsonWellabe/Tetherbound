# Balance lane: F10#2 starter parity and F04#7 Meadows difficulty

Owner decisions of 2026-09-27 23:55 (STATE ruling 11). Base: `tb/integration` at `73157990`.

## F10#2 C2: starter parity. **Met.**

**Change.** Data only; no fight is special-cased.

| | Before | After |
|---|---|---|
| `ripple_jab` windup/recovery | 0.14 / 0.18 s | 0.22 / 0.24 s |
| `gale_peck` windup/recovery | 0.12 / 0.15 s | 0.22 / 0.34 s |
| Ripplet HP/ATK/DEF | 105/24/17 | 110/23/18 |
| Galewisp HP/ATK/DEF | 92/27/14 | 105/24/17 |

Terrapup (120/22/20, `pebble_toss` 0.22/0.24) is the reference and is unchanged. Each species keeps its role, element, move set and feel:
- Terrapup is still the tank.
- Galewisp still has the highest attack and the thinnest armour.
- Ripplet sits between the two.
- Both keep their short melee quick with a lunge.

**Why it works.** The old 0.12–0.14 s windups let a *mashing* Ripplet or Galewisp poise-lock Capacitor Alpha without ever being caught mid-swing, so reading the fight bought nothing:
- Ripplet's masher took 2.0 hits a fight; its reader took 2.8.
- With the change, the masher takes 6–10 hits, as Terrapup's masher does, and the reader's hits barely move.

Stat changes alone did not move the ratio (`f10_2/SWEEP.md`).

**Why Galewisp's windup stays at 0.22 s.** Its extra commitment goes into recovery instead. A 0.24–0.26 s windup no longer fits a CURRENT's 0.55 s recovery window: the reader then took 113–241 s against Oreth's Brooktail, against 21–43 s now.

**Measurement.** `tests/smoke_stormwood_b_named_c2c3.gd --seeds=24`, harness unchanged. Bar: reader/masher lead-cost ratio ≤ 0.55.

| Capacitor Alpha | Before | After |
|---|---|---|
| terrapup | 0.42 PASS | 0.42 PASS |
| ripplet | 0.98 FAIL | **0.50 PASS** |
| galewisp | 0.71 FAIL | **0.41 PASS** |

All 18 Stormwood named rows (six fights × three starters) pass after the change (`f10_2/RUN_stormwood_named_24seeds.txt`). The worst single hit is 0.105, and reader win is at least 0.96.

**Knock-on.** `ripple_jab` and `gale_peck` are shared moves: about a dozen catchable Water and Air species use them, including torrentoad, riverdrake, craghorn and aeriex. Those species are a little slower to swing when the player pilots them. Wild and trainer foes are unaffected, because their timing comes from `combat.json` `enemy`, not from the move.

Water regression: every Water named row that passed before still passes. That is 27 rows across the named wilds, the Pell floor fight and the ladder (`water_regression/SUMMARY_TABLE.md`).

## F04#7 C2: harder Meadows named trainers. **Not met: blocked on an owner decision.**

**Delivered.** The DIVER exemption in `tests/smoke_meadows_named_c2c3.gd`. BOSSES §2 allows the DIVER's 0.4 s tell only with a long positional cue. In built data that cue is the travelling dive, whose ground lane is drawn through the tell, entered from a reposition of 7 m or more. Such tells are now held to a 0.4 s floor and reported as `diver_tell`. Every other tell is still held to 0.8 s. This removes the `C3 tell 0.40 < 0.80` reason from Vess, Hald and the Warden.

**Not delivered.** Meadows trainer data is unchanged. No tuning that respects the constraints below reaches the 0.25 masher team-wipe bar for all three starters, so none is committed. Committing a half-measure would make the fights harder without closing the criterion.

**The constraints that bind.** None of these is mine to relax:
- **Tells and telegraph timings** are unchanged (owner).
- **No HP sponge.** BOSSES §2/§4.5: "A name, larger scale and more HP do not satisfy this contract."
- **C3 ceiling.** No single hit may reach 50% of an entry creature's HP.
- **Level pins** in `tests/test_trainers_data.gd`, which encode the PROGRESSION curve:
  - Relay teams stay within Band 3's L8–12.
  - Captains stay within L10–16.
  - No critical-path step jumps more than four levels.
  - Nothing in the stronghold out-levels the Warden's ace.
- **At most five creatures.** The Warden's test enforces the §5 five-creature limit.

**What the measurements show** (`f04_7/EXPERIMENTS_8seeds.md`, `f04_7/RELAY_SWEEP.md`, `f04_7/RUN_meadows_24seeds.txt`):
1. **The reader already reads most members.** It takes 0–1 hits from baseline, WALL, CURRENT and ACE members. Its only real damage comes from travelling-lunge members (the CHARGER and DIVER), which hit the reader more than the masher. With the final move timings, the reader wins 100% in every variant tried.
2. **Power alone does not reach the bar.** Each readable member costs a masher about one creature, then dies. Power is capped by the 0.5 hit ceiling: the sequential worst hit is about 1.6× the isolated one, through the stagger crit ×1.5, variance ±10% and type ×1.25.
3. **Levels do little.** Even +12 levels (Vance at L23–24, far outside the pins) left a three-creature Vance at 0.56–0.62 masher party cost.
4. **The closest legal shape still falls short.**
   - Every captain and Hald field five, adding band-pool Burrowback, Mosshell, Trailpup, Duskhush or Tuskroot.
   - Levels go to each pin's ceiling.
   - Readable members get power 22–38 and poise 60.
   - Result: the masher loses 0.62–0.97 of its party. Galewisp-led runs wipe 12–88%; Terrapup- and Ripplet-led runs mostly do not.
5. **Tell-free pacing helps only two starters.** Attack cooldown 0.3 s and reposition 0.2 s on readable members give Ripplet 38–50% and Galewisp 88% wipes. Terrapup stays at 0.84–0.90 with no wipes, and the worst hit reaches 0.66, over the C3 ceiling.
6. **Why the masher's fifth creature survives.** The harness party order is fixed: starter, bramblebun, mudsnout, pipwing, trailpup. The masher consistently loses exactly four creatures, and Trailpup finishes the last foe at 50–100% HP. With pipwing last instead, the same team wipes the masher 50% of the time. Terrapup's 9 m ranged quick also lets its "masher" chip foes while they walk in.
7. **Independent confirmation.** Tidewake's F14#0 reached the same finding: in top fights the masher's team never wipes (`ralph/reports/TIDEWAKE/f14_named_c2c3/REPORT.md`).

**24-seed record on the final data** (`f04_7/RUN_meadows_24seeds.txt`; Meadows trainers unchanged, new starters, DIVER exemption):
- **Before:** 18 of 21 rows failed; 9 of them also failed C3 on the 0.40 s DIVER tell.
- **After:** 18 of 21 rows still fail, all on the masher wipe (0.00 against the 0.25 bar), and some also on the masher lead-faint rate. C3 passes on every row, with a worst hit of 0.335. The Warrens guardian passes for all three starters.

**Owner options** (any one unblocks F04#7):
- **(a) Relax the level pins.** Allow Meadows named trainers above the band ranges and above the four-level step, then re-tune with five-member teams. Point 3 suggests this alone is not enough.
- **(b) Allow a new Y or named heavy attack** for the last readable member of each captain. That is a new tell, which the current ruling forbids.
- **(c) Restate the top-fight bar for Meadows** as a masher lead-faint rate plus a reader/masher party-cost ratio, rather than a team wipe of a five-creature party at entry level. This is the same question F14#0 raises for Tidewake.
- **(d) Accept five-member captains as the harder Meadows**, which clears Galewisp only, and record Terrapup and Ripplet as exceptions.

## Tests

- **Focused unit run:** `--only=` over band_content, chapter_curve, charger_lunge, combat_*, trainers_data, named_fight_*, moves, progression, save_format, starters, stormwood/water data and 19 more. 743 tests, 22,376 assertions, **1 failed**.
- **The failure is pre-existing:** `test_charger_lunge.gd::test_only_named_charger_profiles_opt_in` flags the DIVER `lunge_travels` bodies. It fails identically on `tb/integration` `73157990` with this lane's changes stashed, so it is not caused here, and it is left for its owner.
- **No unit test pins the changed starter stats or move timings.** The CREATURES §5 table was updated to the new source values.

## Reproduce

```
godot --headless --path . --fixed-fps 60 --script tests/smoke_stormwood_b_named_c2c3.gd -- --seeds=24 --case=capacitor_alpha --json=<path>
godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd -- --seeds=24 --json=<path>
```
