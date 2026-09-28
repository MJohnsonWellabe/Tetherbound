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

## F04#7 C2: harder Meadows named trainers. **C2 met under the owner's restated bar (ruling 12, 2026-09-28).**

**Decision.** The owner delegated the call, with the intent that an unprepared masher should lose to Meadows named trainers about a quarter of the time.
- **Why not per fight:** the per-fight 25% masher team wipe cannot be reached inside the constraints below (history in `f04_7/EXPERIMENTS_8seeds.md` and `f04_7/RELAY_SWEEP.md`).
- **The bar, per top fight and starter at 24 seeds:**
  - reader win ≥ 75%;
  - the masher loses its lead in every run;
  - the reader's median party cost is ≤ 55% of the masher's.
- **The 25%, judged per chapter:** a masher loses at least one of the six named trainer fights in ≥ 25% of playthroughs, computed as 1 − Π masher win rate with the fights taken as independent.
- **Scope:** the same bar applies to Tidewake F14#0.
- **Recorded in:** COMBAT §7, BOSSES §9, the ACCEPTANCE C2 row and STATE ruling 12.

**Constraints kept:**
- Tells, recoveries and profiles are unchanged.
- No HP sponge.
- C3's 0.5 hit ceiling holds.
- The `test_trainers_data` level pins hold: Band 3 ≤ 12, captains ≤ 16, the four-level step rule, and the stronghold below the Warden's ace.
- Teams stay at five creatures or fewer.

**What ships** (`data/config/bands/*/trainers.json`, mirrored in `tests/fixtures/band_split_baseline/trainers.json`):

| Fight | Team (added members in bold) | Levels |
|---|---|---|
| Vance | Galecrest, Duskhush, **Burrowback**, **Mosshell**, Tuskroot CHARGER | 12 ×5 (was 11/11/12) |
| Oreth | Mosshell WALL, Trailpup, **Burrowback**, **Duskhush**, Brooktail CURRENT | 16 ×5 (was 13/14/15) |
| Halder | Duskhush, Tuskroot CHARGER, **Burrowback**, **Mosshell**, Meadowhart CURRENT | 16 ×5 (was 13/14/15) |
| Vess | Trailpup, Duskhush, **Trailpup**, **Tuskroot**, Galecrest DIVER | 16 ×5 (was 14/15/16) |
| Hald | Galecrest DIVER, Burrowback, **Trailpup**, **Duskhush**, Mosshell WALL | 18/19/19/19/19 |
| Warden | unchanged team | 18/18/19/19/20 |

- **Added members** are baseline bodies from each band's own pool, with a 0.9 s tell.
- **Readable (non-lunge) members** get per-body `power` of 17.5–32, set from each body's measured worst hit, and `poise_max` 60.
- **Lunge members** (CHARGER and DIVER) are unchanged.
- **Player-visible text:** the stronghold duty board now reads "HALD — 5", and Vance's and Oreth's challenge lines say "Five of mine".

**Harness.**
- **DIVER exemption:** a tell from a body with a tell under 0.8 s whose dive travels after a reposition of 7 m or more is held to 0.4 s (BOSSES §2).
- **Bar:** the verdict now applies the ruling-12 bar and prints a `MEADOWS_C2C3_CHAPTER` line per starter.

**24-seed result** (`f04_7/RUN_meadows_after_24seeds.txt`, printed by the committed harness, one run per starter): all 21 rows pass. The before-tuning run is `f04_7/RUN_meadows_before_24seeds.txt`.
- The reader wins 100% everywhere.
- The masher loses its lead in 100% of runs.
- The reader/masher party-cost ratio is 0.00–0.49.
- The worst hit is 0.448.
- Chapter masher-loss (terrapup, ripplet, galewisp):
  - 1 − Π: 1.00, 0.97, 0.94 (the `MEADOWS_C2C3_CHAPTER` lines).
  - Observed over seed-indexed six-fight playthroughs: 24/24, 24/24, 22/24. Each fight's seed is its own hash, so these pairings are independent draws, not one shared playthrough.
- Known bias: the harness party order is fixed and always ends on Trailpup, which finishes the last foe. That makes the masher-loss figures conservative.
- The chapter-level 25% is the Balance lane's reading of the owner's intent, not the owner's words. Per fight, Vance (L12 Band 3 pin) and Vess (DIVER ending) never beat a masher. If the owner wants a per-fight 25%, the one-line option is to raise the Band 3 pin for Vance.

Per-fight masher loss:

| Fight | Terrapup | Ripplet | Galewisp |
|---|---|---|---|
| Oreth | 100% | 96% | 83% |
| Halder | 8% | 25% | 29% |
| Warden | 0% | 4% | 33% |
| Hald | 0% | 0% | 25% |
| Vance | 0% | 0% | 0% |
| Vess | 0% | 0% | 0% |

**Before** (`tb/integration` data, 24 seeds): 18 of 21 rows failed. The masher's party cost was only 0.14–0.61, and the masher lost no fight.

**Still open on the board.** Varied-size framing and the C3 blind fight-footage verdict, so F04#7 stays partial.

## Tests

(First landing; see the PR for the full sharded unit run on the merged head.)

- **Focused unit run:** `--only=` over band_content, chapter_curve, charger_lunge, combat_*, trainers_data, named_fight_*, moves, progression, save_format, starters, stormwood/water data and 19 more. 743 tests, 22,376 assertions, **1 failed**.
- **The failure is pre-existing:** `test_charger_lunge.gd::test_only_named_charger_profiles_opt_in` flags the DIVER `lunge_travels` bodies. It fails identically on `tb/integration` `73157990` with this lane's changes stashed, so it is not caused here, and it is left for its owner.
- **No unit test pins the changed starter stats or move timings.** The CREATURES §5 table was updated to the new source values.

## Reproduce

```
godot --headless --path . --fixed-fps 60 --script tests/smoke_stormwood_b_named_c2c3.gd -- --seeds=24 --case=capacitor_alpha --json=<path>
godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd -- --seeds=24 --json=<path>
```
