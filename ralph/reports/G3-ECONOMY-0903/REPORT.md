# G3-ECONOMY-0903 — progression curve, reward economy, rest rhythm, five-creature pressure

Lane: G3-ECONOMY. Gate 3. Branch `ralph/G3-ECONOMY-0903`, based on `origin/main` @ `3c73aab5`.
No PR opened per instructions; the Gate 3 coordinator (`session_01Rra117rfv84LPqbL5ACBn4`) lands it.

File ownership respected throughout: `data/config/chapter_curve.json`, `progression.json`,
`chapter_rewards.json`, `bond_milestones.json`, `creature_condition.json`, `vitals.json`,
`trade.json`, `tests/test_chapter_curve.gd`, `tests/test_chapter_rewards.gd`,
`tools/_probe_pacing.py`. Every `data/config/bands/*/` file was read, never edited.

## Headline finding

**`tools/_probe_pacing.py` — the tool this whole lane's priority 1 was built around — was
not stale, it was broken.** It modeled the Band 1 → Band 2 transition as `trainer_oskar`
handing over `south_bridge_key`, and never fought the three-round village tournament at
all. Both are wrong against the shipped game, and have been since **before** the probe's
own last recorded measurement (2026-08-22): the TOURNAMENT-1 owner directive, dated the
*same day*, moved the bridge key off Oskar onto a Team Tether grunt
(`south_bridge_grunt`) specifically so Oskar could become the tournament's final round,
and `data/progression/objectives.json` gates the whole tracked objective chain on
`tournament_won` — a flag only the tournament final writes. So the three-round tournament
is mandatory critical path, not optional content, and the recorded `3->8, 8->10, 10->13,
13->16, 16->20` team bands in `chapter_curve.json` were never a real measurement of the
shipped game. The probe was also crafting the Riding Saddle (`recipe_saddle`, a
tournament-final reward) before the tournament it now unlocks from — a route the shipped
game does not allow.

Fixed in `tools/_probe_pacing.py`: Band 1's beats now fight `trainer_mira`, `trainer_tam`
(pre-tournament training, unchanged), `tournament_quarter_mira`, `tournament_semi_tam`,
`tournament_final_oskar` (the three mandatory rounds), then `south_bridge_grunt` (the real
key-holder) before crossing. `CATCHES_PER_BAND` moved the fourth catch out of probe band 2
into probe band 1, matching `chapter_curve.json`'s own `band1_lower_meadows.temptations`
line ("the first four catches happen here") and `data/config/tournament.json`'s real,
wired `entry.min_party_size: 5` gate, which sits inside Band 1, before the bridge — a
player cannot reach the tournament board under five. The `trainers.json` dialogue-time
split (`DIALOGUE_BAND`) is now derived from the beat list itself instead of a stale
hand-counted fraction, so it can't drift the same way again.

## 1. Re-measured curve (priority 1)

`python3 tools/_probe_pacing.py --verbose`, run on this branch, current `main` content:

```
band                              travel fights  catch   talk  story  GRIND    total  levels
--------------------------------------------------------------------------------------------
Band 0 - Homebound                    0m     1m     0m     2m    16m     0m      20m   3->3
Band 1 - Lower Meadows                4m     6m     1m    17m     0m     0m      28m   3->9
Band 2 - Stone & Root                11m     4m     0m     0m    26m     0m      41m   9->12
Band 3 - The River Lock               4m     5m     0m     4m     1m     0m      13m  12->15
Band 4 - Upper Meadows / Ironwood     7m     5m     0m     1m     0m     0m      14m  15->17
Act VI - The Meadows Hall             1m     8m     0m    12m     5m     0m      25m  17->21
TOTAL                                26m    28m     2m    36m    49m     0m     141m

TOTAL: 2.35 hours (target 3-4h, D42)
  forced wild grinding: 0.00 hours across 0 extra fights (was 0.07h / 6 fights under the
  broken probe — the tournament + real bridge fight supply enough xp on their own)
  critical-path fights: 54 creature battles
  projected first completion: 4.71 hours (floor x 2.0)
  verdict: OVER the 3-4 hour target (D42)
```

`chapter_curve.json` updated to match (region `team.enter`/`team.exit`, all recorded with
the measurement and the reason in `_comment_measurement`):

| region | old enter→exit | **new enter→exit** | old expected_members | **new** |
|---|---|---|---|---|
| band1_lower_meadows | 3→8 | **3→9** | 3 | **5** |
| band2_stone_and_root | 8→10 | **9→12** | 4 | **5** |
| band3_the_river_lock | 10→13 | **12→15** | 5 | 5 |
| band4_upper_meadows_ironwood | 13→16 | **15→17** | 5 | 5 |
| band5_stronghold_approach | 16→20 | **17→21** | 5 | 5 |

`expected_members` for band1/band2 moved because the old 3/4/5/5/5 progression
contradicted the file's own `band1_lower_meadows.temptations` line and the tournament's
`min_party_size: 5` mechanic, both already inside Band 1. Band 5's exit level (21) is the
level *after* the Warden's own xp is banked, not a pre-fight advantage — the team still
enters his fight at L19, one below his ace (20), exactly as the region's own `tuning` note
intends; only the recorded number was stale.

**`wild_band` per region is untouched.** Two regions are now worth a second look by
whoever owns their spawns, flagged in the JSON's own `tuning` fields and not acted on
here because BAND2/BAND4 lanes are authoring content against these numbers right now:

- **band2_stone_and_root**: wild ceiling 8 vs. corrected entry 9 — every wild creature in
  the region is already at or below the team's own arrival level, not just by the region's
  exit.
- **band4_upper_meadows_ironwood**: wild ceiling 14 vs. corrected entry 15 — same shape,
  one level worse.

Neither breaks `test_a_catch_is_a_real_option_in_every_region` (margin 1 in both, against
`max_catch_level_deficit: 2`), so the five-slot mechanism still bites, just with less
room than before. Routed to the coordinator rather than retuned unilaterally.

**Total pacing verdict: OVER the 3-4 hour D42 target, both before and after this fix**
(4.74h → 4.71h projected). Fixing the tournament/bridge-grunt bug did not change the
verdict — it confirmed OVER was real, not an artifact of the probe skipping content. XP
curve / trainer difficulty retuning to close that gap is Gate 4's charter
(`docs/ROADMAP.md`: "XP curve, trainer difficulty... target-hardware performance"), not
this lane's; recorded in `chapter_curve.json`'s `_comment_measurement_pacing` so nobody
reads a corrected Gate 3 curve as a solved overall pace.

## 2. Reward economy (priority 2)

`data/config/chapter_rewards.json` had the **identical staleness** as the pacing probe,
for the identical reason: its `trainer_oskar` row still claimed `"required": true` with
`south_bridge_key` and "the reward IS the progression. Opens Band 2" — but the live
`trainer_oskar` trainer entry has carried neither `south_bridge_key` nor `gate_fight`
since TOURNAMENT-1, and there was no row at all for `south_bridge_grunt`, the actual
key-holder. Fixed: `trainer_oskar`'s row is now `required: false` (his village challenge
still pays 15 coins, nothing else) with a note pointing at the real row; a new
`south_bridge_grunt` row carries the key and the "opens Band 2" claim. A new test,
`test_the_audited_bridge_key_matches_who_actually_holds_it`
(`tests/test_chapter_rewards.gd`), pins the real holder against the audit so this can't
drift back silently — it reads the live `trainers.json`, not a literal.

Recomputed coin income directly from `trainers.json`'s reward blocks (the file's own
"Mira's store" row previously cited "860 plus 30 starting", which both predated the
tournament rows a 2026-08-22 audit pass added and still counted the stale
`trainer_oskar`/key row as required income):

- **Required-path only** (practice, Mira, Tam, the three tournament rounds,
  `south_bridge_grunt`, the Warrens clear, the four-fight relay ladder, the three
  captains, the three stronghold fights, the Warden): **975 coins + 30 starting = 1005.**
- **Every trainer row plus the Warrens clear** (adds every optional field trainer —
  `quarry_picket_dorn`, `warrens_watch_pell`, `old_champion_bram`, `shepherd_the_rise`,
  `wanderer_trail_camp`, and the six BAND1-ECOLOGY/WORLD-CONTENT field trainers in bands
  2-5): **1467 coins + 30 starting = 1497.**

Either total comfortably clears the audit's own `coin_income_covers_at_least_n_expensive_tms:
2` invariant (the two priciest TMs are 300+260=560) with a wide margin, so "money has
useful sinks" holds at both the minimal and the completionist end of play.

Everything else in the reward audit — material tiers, TM placement, Orb pricing, building
affordability, the Rootstone/Ironwood supply-vs-recipe-cost figures the pacing probe's own
`material_report()` prints (rootstone 35 available against 12 needed by the two
critical-path recipes; ironwood 57 against `orb_prime`'s 4) — was read and cross-checked
against `chapter_rewards.json`'s existing invariants and reads as sound; no further
changes made there. This was a targeted fix of one real, evidenced bug plus a recompute
of the one number that bug fed, not a full re-derivation of the whole audit from scratch.

## 3. Rest rhythm (priority 3)

**Camp infrastructure exists in every band**, contrary to what a `map_landmarks.json`-only
read would suggest (only `band1_trail_camp` and `band2_ranger_camp` are registered map
landmarks). Reading the band-owned `props.json`/`harvest.json` files directly finds real,
bed-and-fire camps this lane did not build and does not own:

| band | camp | bed? | siting note (from the band's own file) |
|---|---|---|---|
| band1 | `band1_trail_camp` | yes | registered landmark |
| band2 | `band2_ranger_camp` | yes | registered landmark |
| band3 | `riverwatch_rest` | yes (T5-CADENCE added the bed+fire) | "60m short of the first picket" — sited before the four-fight relay gauntlet, not inside it |
| band4 | ironwood camp pad, `ridge_patrol_camp`, eastern-loop field-camp | yes (ironwood pad) | three separate rest/supply points across the chapter's longest single leg |
| band5 | "the Waystop" | yes (T5-CADENCE added bed+fire, closing a prior audit FAIL) | last stop before the Hall, per prompt 66's own ask |

Attrition, estimated from `data/config/combat.json`'s own numbers (same derivation style
`tools/_probe_pacing.py` already uses for player DPS, applied to the `enemy` block):
enemy per-hit damage at an even level match is `power(8) * scale(2) * 0.5 = 8`, on an
attack cycle of `max(attack_cooldown, telegraph+recovery) = 1.3s`, giving an enemy DPS of
about 6.15 unmodified (≈3.7 at the same 0.6 hit-efficiency discount the pacing probe
applies to the player). Player DPS at the same discount is ≈8.18. Since one fight's
duration is `enemy_hp / player_dps`, damage taken scales with the enemy/player DPS ratio
(≈0.45) times the enemy's own max HP — and because both sides share the same
`base_hp * (1 + 0.06*(level-1))` growth curve, that means **an even-matched fight costs
the active creature roughly 40-50% of its own max HP.** Two such fights back-to-back with
no healing puts a creature at or near fainting; the four-fight relay ladder or the three
stronghold fights (patrol/courtyard/elite) in immediate succession cannot be soloed by one
creature without a potion, a rest stop, or a switch — which is exactly prompt 61's
intended shape ("one creature becomes badly injured; another is low or unavailable"), and
the five-creature roster plus the potions those same trainers pay out are the intended
answer. This is an estimate from the combat model (same caveats `_probe_pacing.py`
states about its own DPS derivation — no dodge/positioning skill, no miss chance modeled
beyond the flat efficiency discount), not a played measurement; a real playtest is the
next step to confirm the feel matches the number.

`creature_condition.json`'s bed contract (owned by this lane, unmodified — it already
matches prompt 61's ask): gradual real-time HP regen while resting, `rested` cleared on
faint, no starvation-equivalent penalty beyond soft debuffs (`vitals.json`'s satiety
`stamina_regen_scale`/`move_speed_scale` softening, never damage). `full_heal_seconds:
120` in `progression.json` is the passive-regen time if the player never sleeps; sleeping
through the night (the intended overnight cycle) completes any occupied bed immediately,
so the real player choice is "sleep now" vs. "push on with a partial heal," not a timer.
No changes made here — the existing numbers already satisfy the acceptance bullets
(gradual, honest on save/load per the file's own contract, no invisible mandatory
camping); this lane's contribution is the attrition-vs-recovery evidence above, not a
retune.

## 4. Five-creature pressure (priority 4)

Distinct wild-catchable species per chapter_curve region, computed from the live merged
spawn table against this file's own `z_to` boundaries:

| region | distinct species |
|---|---|
| band1_lower_meadows | 11 |
| band2_stone_and_root | 6 |
| band3_the_river_lock | 14 |
| band4_upper_meadows_ironwood | 8 |
| band5_stronghold_approach | 7 |
| **total distinct, whole route** | **15** |

`five_slot.min_distinct_wild_species` (6) was measured against a stale comment claiming
"the roster is 17 species and the spawn table currently fields 12 distinct ones" — both
numbers are now wrong (species.json has grown to 25 entries; the live spawn table fields
15 distinct non-starter species, up from 12 when that comment was written, evidently from
WORLD-CONTENT/BAND1-ECOLOGY's additions since). Corrected in the JSON's own
`_comment_options`, including the per-region breakdown above. 15 against a 5-creature cap
means a player who wants to "collect" has to pass on **10 of the 15** they can plausibly
meet — real, structural pressure, well above the file's own floor of 6.

What a spawn-table count cannot answer on its own is prompt 67's actual acceptance
question — whether those 15 read as *plausibly desirable*, not just distinct. The
strongest evidence toward "yes" already lives in the design, not in anything this lane
added: Meadowhart (the traversal mount) appears in spawn clusters across all five regions,
so the traversal creature is never a one-time pickup competing only once; Mudsnout
(the one normal evolution line, branching Tuskroot/Ashtusk per D71) appears in four of
five regions, so the evolution temptation recurs rather than being a single early
encounter forgotten by the Hall. Both are exactly the kind of "temptation" mechanism
`chapter_curve.json`'s own per-region `temptations` fields already describe. Confirming
that a normal (non-completionist) player actually *meets* — not just could theoretically
meet — enough of these 15 before the Hall to name a real "I wanted a sixth" moment needs a
played run, not a static probe; this lane's contribution is the hard species-availability
floor and the recurrence evidence, not a playtest verdict.

## 5. Tests added/strengthened

- `tests/test_chapter_curve.gd`:
  - `test_band1_expects_the_party_size_its_own_tournament_requires` — ties
    `band1_lower_meadows.team.expected_members` to `tournament.json`'s live
    `entry.min_party_size`, so the two can't drift apart again the way the old 3/5
    mismatch did.
  - `test_expected_members_never_exceeds_the_cap_or_goes_backwards` — `expected_members`
    stays ≤ `PARTY.MAX_CREATURES` and never decreases region to region.
- `tests/test_chapter_rewards.gd`:
  - `test_the_audited_bridge_key_matches_who_actually_holds_it` — pins the real
    `south_bridge_key` holder in `trainers.json` against the audit row that claims it,
    and asserts no *other* row still claims the key. This is the regression test for the
    exact bug this report opens with.

## 6. Verification run on this branch

- `python3 tools/_probe_pacing.py` / `--verbose`: ran repeatedly during this session
  (output above); no crash, `check_sites_are_current()` (the probe's own drift guard)
  passes.
- JSON validity: `python3 -c "import json; json.load(open(...))"` on
  `chapter_curve.json` and `chapter_rewards.json` after every edit — both parse clean.
- Godot 4.7-stable installed fresh in this container (none was present); a full
  `--import` was run before any GDScript test.
- `godot --headless --path . --script tests/run_tests.gd -- --only=test_chapter_curve.gd`:
  **20 tests, 465 assertions, 0 failed** (includes the 2 new tests).
- `-- --only=test_chapter_rewards.gd`: **10 tests, 139 assertions, 0 failed** (includes
  the 1 new test).
- `-- --only=test_progression.gd`: 44 tests, 113 assertions, 0 failed (spot check —
  `progression.json` is owned by this lane and untouched this session, confirming no
  incidental drift).
- `-- --only=test_spawn_tables.gd`: 27 tests, 7749 assertions, 0 failed (spot check on
  the spawn table this lane's species count and `region_at()` resolution depend on).

Not run: the full 1728-test suite (28+ min) — time-boxed to the files this lane actually
touched plus targeted spot checks on files this lane's changes depend on; the
coordinator's own merge should still run the full suite before landing, per
`docs/AGENT_WORKFLOW.md`.

## Summary of every number changed, and why

| file | what changed | evidence |
|---|---|---|
| `tools/_probe_pacing.py` | Band 1 critical path: added tournament (3 rounds) + `south_bridge_grunt`, removed the stale `trainer_oskar`-pays-the-key beat; `CATCHES_PER_BAND` moved the 4th catch into band 1; `DIALOGUE_BAND`'s trainers.json split now derives from the beat list | `tournament.json` `min_party_size:5`, `objectives.json`'s `tournament_won` gate, `recipes_rootstone.json`'s `recipe_saddle` unlock, `trainers.json`'s real `south_bridge_grunt`/`trainer_oskar` reward blocks |
| `data/config/chapter_curve.json` | all 5 regions' `team.enter`/`team.exit`; `expected_members` band1 3→5, band2 4→5; `five_slot._comment_options` species counts 17/12 → 25/15 with per-region breakdown | corrected probe run (above); live spawn table count |
| `data/config/chapter_rewards.json` | `trainer_oskar` row required→false, key claim removed; new `south_bridge_grunt` row added; "Mira's store" row's coin-income figures recomputed | `trainers.json` reward blocks, direct sum |
| `tests/test_chapter_curve.gd` | +2 tests (expected_members ties to tournament gate; monotonic/cap-bounded) | above |
| `tests/test_chapter_rewards.gd` | +1 test (bridge-key holder pinned) | above |

`wild_band` per region, `max_catch_level_deficit`, `min_distinct_wild_species`'s numeric
value (6), and every `data/config/bands/*/` file are **unchanged**. The band2/band4
wild-ceiling-vs-corrected-entry-level tension is flagged in the JSON and above, routed to
the coordinator, not acted on.
