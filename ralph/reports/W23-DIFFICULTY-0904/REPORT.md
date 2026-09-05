# W23-DIFFICULTY-0904 — "Beating creatures and other trainers is way too easy"

Lane W23-DIFFICULTY. Branch `ralph/W23-DIFFICULTY-0904`, from `origin/main` @ `ef16544f`.
No PR opened, per the common brief; the coordinator lands it.
Decision: `docs/decisions/D77-the-baseline-fight-costs-something.md`.

## Headline

Measured first, then tuned. On shipped `main` an ordinary wild at a band's entry
level cost the pilot's lead **7–10 % of its health** and died in seven seconds having
landed two hits; the band's weakest trainer cost **11–21 %**; the tournament final at
its entry level and the Warden at L19 each cost the whole five **17 %**, and nothing was
ever lost by a pilot that never dodges and never uses an item. After this lane an
ordinary wild costs **15–21 % in every band**, the floor trainer **29–62 % of the lead**,
each band's top trainers knock the lead onto the bench, the tournament final costs the
five **45 %** and the Warden **31 %** (the elite 24 %, so W-1 holds). Everything is still
won by the five; fight *length* did not move (the pacing probe prints the same 2.37 h
floor before and after). Danger ×2–2.5, grind ×1.

## Files changed

| file | change |
|---|---|
| `tests/smoke_combat_baseline.gd` | **new** — the headless combat harness (below) |
| `tests/test_combat_difficulty.gd` | **new** — 9 unit tests pinning the overlay, `damage_scale`, the one-shot bound and the aggressor speed |
| `tests/test_chapter_curve.gd` | +2 tests: CL-G8 (no wild ceiling more than one under arrival), the `difficulty` block's shape |
| `data/config/combat.json` | `enemy.damage_scale` 1.6 (new), `enemy.reposition_time` 1.0→0.7, `enemy.first_attack_delay` 1.5→1.0; new `enemy_trainer` overlay block |
| `data/config/catching.json` | `aggression.chase_speed` 3.4→5.6 (the one block of that file this lane touched; it is the wild AI's tunable and `wild_creature.gd` is its only reader) |
| `data/config/chapter_curve.json` | band 4 `wild_band` [11,14]→[11,15] (CL-G8); new `difficulty` target block; band 4 `tuning` note rewritten |
| `scripts/creatures/wild_creature.gd` | `trainer_owned` flag; `_enemy_config_for_this_body()` lays `enemy_trainer` under the member's own block; `_spaced_config()` factored into a static `spaced_config_for()` that also applies `damage_scale` |
| `scripts/combat/encounter_director.gd` | one line: `body.set("trainer_owned", true)` beside the existing `combat_override` set in `_send_out_next_creature()` — the only touch outside the named ownership; a one-line add next to the line it belongs with |
| `tools/_probe_pacing.py` | a `danger_report()` section: enemy damage rate at even level from the same config, so a retune that adds danger without grind is visible in the probe |
| `docs/decisions/D77-…` | the decision and the targets |
| `docs/CURRENT_STATE.md` | §2 combat row rewritten; §3 new P1 (owner) row for CL-O5 with the numbers |
| `ralph/reports/W23-DIFFICULTY-0904/` | this report, before/after tables (`_baseline_before.txt/.json`, `_baseline_after.txt/.json`), pacing before/after, smoke summary |

`progression.json` and `creature_condition.json` were read and deliberately not changed
(D77 §5). No band `spawns.json`/`trainers.json`, no `burrow_warrens.json`, no
`combat_manager.gd`.

## What the player sees

- An ordinary wild in the field now takes a real bite: about a fifth of the lead's
  health at the band's entry level, from a first swing that comes a second in rather
  than two, and from an opponent that comes back in sooner after its back-off.
- A trainer's creature is drilled: it opens faster, presses harder and hits a little
  harder than the same species in the field, so a picket reads as a picket. Named
  opponents keep exactly the WALL / CHARGER / DIVER / CURRENT / ACE shapes G-3 gave
  them, scaled up with everything else.
- The band's weakest trainer costs roughly half the lead; its captains and the Hall
  knock the lead out and put the bench to work. Rest, a potion or a switch before the
  next fight is a real question now.
- An aggressive creature can actually catch a walking player. Escaping costs a sprint.
- Band 4's field now reaches level 15, the level the team arrives at, so a wild there
  is not beaten before it is met.

## The harness

`tests/smoke_combat_baseline.gd` — `godot --headless --path . --script tests/smoke_combat_baseline.gd`
(`-- --seeds=N`, `-- --all-trainers`, `-- --json=path`). For every `chapter_curve.json`
region at its `team.enter` level, the typical five (`difficulty.party`: terrapup,
bramblebun, mudsnout, pipwing, trailpup) fights (a) every wild species the region's
spawn table fields at the band's median level, count-weighted into one row, lead only;
(b) the band's weakest non-gate trainer, whole team, with the manager's own
auto-switch-on-faint; plus the tournament's three rounds at `entry.min_level` and the
elite and the Warden at L19. 24 seeded runs per row. One pilot: close to reach, quick
on cooldown, charged when the meter is full, chase when the opponent backs off, dodge
nothing, use nothing.

It is built from the real readers, not a copy of them: `combat_math.rolled_damage`,
`combat_ai.decide/duration_for/movement_for/speed_for`, `creature_instance` stats at
level, `move_db` and `type_chart`, `trainer_npc.team_of/creature_for` (moves and
`combat` overrides included), `wild_creature._enemy_config_for_this_body` and
`spaced_config_for`. What is modelled is the physics: a 2D plane, capsule contact as a
distance floor, the lunge as its integrated displacement, the opponent always facing.
It runs 15 rows in 2.5 s. **Cross-check against the real scene:** `smoke_combat`'s own
tally on `main` was five player hits to a faint and two hits taken in a band 1 wild
fight; the model's band 1 row before tuning is a 6.5 s fight with ~2 hits taken.

It asserts the `difficulty` targets (D77 §3) and G-3's one-shot rule, and it was seen
red for the right reason: on shipped `main` it failed nine rows (wilds under 15 %,
floors never costing anything), and the unit tests went 6-for-31 red when the overlay
merge, the scale multiply, the chase speed and the band 4 ceiling were each reverted
in turn, then green again on restore.

## Before → after

Before (shipped `main`, `_baseline_before.txt`):

```
row                                 team   foe |    win    sec  lead% party%  faint maxhit
band1 wild (median L4)                 3     4 |   100%    6.5    10%     2%     0%   0.08
band1 floor: trainer_mira              3     4 |   100%    7.0    11%     3%     0%   0.06
band2 wild (median L7)                 9     7 |   100%    7.6     9%     2%     0%   0.06
band2 floor: quarry_picket_dorn        9     9 |   100%   19.0    21%     5%     0%   0.05
band3 wild (median L10)               12    10 |   100%    7.6     7%     2%     0%   0.06
band3 floor: relay_picket_hess        12     8 |   100%   16.5    14%     3%     0%   0.04
band4 wild (median L12)               15    12 |   100%    7.9     7%     2%     0%   0.04
band4 floor: pasture_drover_juno      15    13 |   100%   21.1    20%     5%     0%   0.04
band5 wild (median L15)               17    15 |   100%    8.8     8%     2%     0%   0.04
band5 floor: stronghold_outer_watch   17    15 |   100%   19.6    14%     3%     0%   0.03
tournament: quarter_mira               5     8 |   100%   16.8    22%     5%     0%   0.06
tournament: semi_tam                   5     9 |   100%   22.3    34%     8%     0%   0.07
tournament: final_oskar                5    11 |   100%   38.6    71%    17%     0%   0.07
hall: stronghold_elite                19    19 |   100%   44.3    46%    11%     0%   0.05
hall: warden_aldis                    19    20 |   100%   61.7    71%    17%     0%   0.08
```

After (this branch, `_baseline_after.txt`; `prep` = a potion or a revive would be
needed afterwards):

```
row                                 team   foe |    win    sec  lead% party%  faint   prep maxhit
band1 wild (median L4)                 3     4 |   100%    6.5    21%     5%     0%     0%   0.13
band1 floor: trainer_mira              3     4 |   100%    7.0    29%     7%     0%     0%   0.13
band2 wild (median L7)                 9     7 |   100%    7.6    18%     4%     0%     0%   0.09
band2 floor: quarry_picket_dorn        9     9 |   100%   19.1    62%    15%     0%     0%   0.10
band3 wild (median L10)               12    10 |   100%    7.6    16%     4%     0%     0%   0.09
band3 floor: relay_picket_hess        12     8 |   100%   16.5    44%    11%     0%     0%   0.08
band4 wild (median L13)               15    13 |   100%    8.2    15%     4%     0%     0%   0.07
band4 floor: pasture_drover_juno      15    13 |   100%   21.0    56%    13%     0%     0%   0.08
band5 wild (median L15)               17    15 |   100%    8.8    16%     4%     0%     0%   0.06
band5 floor: stronghold_outer_watch   17    15 |   100%   19.5    38%     9%     0%     0%   0.07
tournament: quarter_mira               5     8 |   100%   16.8    68%    16%     0%    12%   0.13
tournament: semi_tam                   5     9 |   100%   21.5    97%    23%    50%   100%   0.14
tournament: final_oskar                5    11 |   100%   37.6   100%    45%   100%   100%   0.20
hall: stronghold_elite                19    19 |   100%   46.5    98%    24%    42%   100%   0.09
hall: warden_aldis                    19    20 |   100%   61.3   100%    31%   100%   100%   0.18
```

Every authored trainer at its band's entry level, after (`--all-trainers`, the ladder
inside each band is the point):

```
band1 (L3):  practice 47%  mira 29%  tam 47%  shepherd 68%  wanderer 48%  bram 74%  oskar KO  bridge grunt KO
band2 (L9):  dorn 62%  kest 55%  farro 59%  pell 75%
band3 (L12): hess 44%  orrin 35%  relay captain 76%  dell KO(33% of runs)  riverwatch KO
band4 (L15): juno 56%  ridgeline 49%  ridge captain 55%  rue 60%  field captain 72%
band5 (L17): outer watch 38%  patrol 62%  checkpoint 74%  courtyard KO  elite KO  Warden KO (36% of the five)
```
(`KO` = the lead is knocked out and the bench finishes it; all won.)

The Warden's measured length: 61.7 s before, 61.3 s after (no HP moved), the elite
44–47 s. W-1 (he opens no softer than the elite): 31 % of the five against 24 %.

Pacing probe (`python3 tools/_probe_pacing.py`): 2.37 h floor, 4.74 h projected, OVER
D42 — **identical before and after**, as intended (CL-G9 stays Gate 4's). The new danger
line: enemy hit 12.8 every 2.49 s at even level, 3.09 dps against the player's 8.18
(ratio 0.38, up from 0.19).

## Targets recorded (D77 §3, `chapter_curve.json` `difficulty`)

wild at band entry costs the lead 15–30 % (band 1 exempt); floor trainer 25–80 % of the
lead and never a five-wipe more than 25 %; tournament won ≥ 75 % at its entry level;
Warden won ≥ 50 % at L19 and no cheaper for the five than the elite; no single hit
≥ 50 % of a full-health entry-level creature. **The brief's "floor lost 1 in 4" was
re-argued** (D77 §3): with auto-switch a loss is a five-wipe, and a weakest trainer
that wipes an equal-level five a quarter of the time makes the band's strongest a wall
and the tournament unwinnable at L5. The target is read as the lead paying for
arriving unprepared, and the wipe rate is guarded from the other side.

## Tests and smokes run

| command | result |
|---|---|
| `godot --headless --path . --script tests/smoke_combat_baseline.gd` (before, on shipped numbers) | FAILED 9 rows — the finding |
| same, after tuning | **OK, 15 rows, 24 seeds** (`--all-trainers`: OK, 41 rows) |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_combat_difficulty.gd,test_chapter_curve.gd,test_encounter_combat_override.gd` | **36 tests, 543 assertions, 0 failed** |
| same two files with the mechanisms reverted (red check) | 31 tests, **6 failed** (overlay ×2, scale ×2, aggressor, CL-G8), restored |
| `-- --only=test_combat_ai.gd,test_combat_math.gd,test_combat_progression.gd,test_trainers_data.gd,test_spawns_data.gd,test_progression.gd,test_catch,test_encounter,test_band_content.gd,test_type_chart.gd` | **262 tests, 4963 assertions, 0 failed** |
| `python3 tools/_probe_pacing.py` before / after | 2.37 h / 2.37 h, `check_sites_are_current()` passes |
| `tests/smoke_combat.gd` on `main` (model cross-check) | OK — 5 hits on the enemy, 2 on the ally, 2 misses, 210 action frames |
| the six verify smokes on this branch | see `_smokes_after_summary.txt` and the section below |

Run by the finisher session, this branch, godot 4.7-stable `--headless`, no
rendering driver, each log grepped for `^ERROR:` and `SCRIPT ERROR`:

| smoke / test | result |
|---|---|
| `smoke_combat.gd` | OK — 5 hits landed, 2 taken, 3 misses, 208 action frames, won |
| `smoke_boss.gd` | OK — barrier holds, gate signal counts as expected, boss smoke test passed |
| `smoke_trainer_battle.gd` | OK — trainer beaten once through its team, re-challenge refused, reward paid exactly once |
| `smoke_aggression.gd` | OK — the peaceful creature never initiates (900 frames, nothing); the aggressive one starts from 9.1m |
| `smoke_tournament_bracket.gd` | OK — final won in 2181 frames, all three rounds fought, saddle pattern granted, champion state steady |
| `smoke_gate_e_finale.gd` | OK — roster decision resolved, region state answers, objective chain terminated |
| `smoke_combat_baseline.gd` (re-run) | OK, 15 rows, 24 seeds each — reproduces `_baseline_after.txt` exactly |
| `test_chapter_curve.gd` | included in the 36-test/543-assertion run above; both new tests (CL-G8 ceiling bound, `difficulty` shape) pass |
| `test_encounter_combat_override.gd` | included in the same run; all 5 pass |

All eight of the brief's named smokes/tests green, first attempt. The only
`^ERROR:` in any log is `ERROR: Parameter "material" is null.` from
`material_get_instance_shader_parameters` during creature-body dressing
(`creature_body.gd:492`), one occurrence per world boot — the known-benign
CL-G7 finding (`docs/GATE2_GATE3_CLOSURE_PLAN.md`: "seen by four lanes, chased
by none, non-fatal in all"), unrouted and not this lane's; the set did not
grow. Full detail: `_smokes_after_summary.txt`.

While verifying, one stale line in `data/config/combat.json`'s
`_comment_damage_scale` was fixed: it still described the pre-final `1.5`
tuning value and the old "lost one run in four at the floor" reading; it now
names the shipped `1.6` and the measured 29–62% floor-trainer cost, matching
D77 §4. No numbers changed, only the comment.

## Known limitations, and what was deliberately not done

- **A model plus the real-scene smokes, not a played run.** The harness steps the real
  decision table and the real arithmetic on a plane; it does not run the physics or the
  camera. The scene smokes prove the wiring still resolves; the first owner report after
  this lands decides whether `damage_scale` moves again, in either direction — it is
  one number.
- **The scripted pilot is the floor of competence.** It never dodges, never switches
  on type, never uses a potion; a real player takes less than every number above.
- **Band 2's wild ceiling stays at 8** (CL-G8 half-applied). It is pinned by the
  Warrens' weakest resident (9), which `test_the_warrens_fights_above_its_field…` keeps
  strictly above the field, and `burrow_warrens.json` is not this lane's. The exact diff
  for the coordinator, both halves in one commit:
  - `data/config/burrow_warrens.json`: residents `9, 10, 10, 11` → `10, 11, 11, 12`
    (guardian 14 unchanged; still inside band 2's `trainer_levels` [9,14]);
  - `data/config/chapter_curve.json` band 2 `wild_band` `[6, 8]` → `[6, 9]`.
- **The G-2 profile numbers were not retuned** — they are scaled with everything else by
  `damage_scale`; distinguishability (G-3's fails-if) is unchanged by construction.
- **No AI-side mid-fight switch for trainers** (the brief's "if the rules allow"): the
  director fields a team sequentially and the rules do not have the AI switch; adding
  one is a new mechanic and is recorded, not built.
- **Not run:** the full 28-minute unit suite; CI on the push is the first full run.
- Known red on `main` (`verify-unit-tests (3)`, `test_item_icons.gd`) is another
  lane's and was not touched.

## Commit and branch

Branch `ralph/W23-DIFFICULTY-0904`, pushed. The branch tip after this report's
own commit carries every fix described above; its parent, verified green by
the finisher session, is `0a84d911f7a4d84e66b42ce4e2a1ded00ae97b1f`. Check
`git log ralph/W23-DIFFICULTY-0904` on the pushed branch for the exact tip.
