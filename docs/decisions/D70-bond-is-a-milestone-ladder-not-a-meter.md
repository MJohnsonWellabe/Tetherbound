# D70 — Bond is a milestone ladder, not a meter

**Status:** owner directive implemented; the milestone TARGETS for 2-5 are
judgment calls flagged below for owner review, not settled canon.
**Decided:** 2026-09-01, owner playtest.

## The decision

The owner, on bond as it shipped (a 0-100 point meter, five raw-value
thresholds at 10/30/55/80/100):

> *"I don't understand bond. It just goes up. It needs to be a task. Like
> defeat 50 wild creatures together takes you from 0 to 1. Then visit
> whatever takes you to 2. Then travel x miles takes you to 3."*

Bond is now an **ordered ladder of five concrete, nameable tasks**
(`data/config/bond_milestones.json`, `scripts/creatures/bond_milestones.gd`).
A creature is always working toward exactly one named task — "38/50 wild
creatures defeated together" — never a bare percentage. Finishing a task
advances the tier by exactly one; a later task's counter climbing first does
not skip ahead.

The old points system — flat gains per action
(`bond.battle_won`/`successful_catch_start`/`per_day_in_party`), a raw 0-100
`bond` value, five point-thresholds — is gone. `bond_nodes()` (the "how many
nodes crossed" count everything downstream reads) now counts completed
milestones instead of crossed point-thresholds; nothing downstream of that
call needed to change.

## The ladder

| # | Task | Target | Source (canon, GAME_DESIGN.md §12) |
|---|---|---|---|
| 1 | `battles_fought` — wild creatures defeated together | **50** | fighting together. **The owner's own words, exact.** |
| 2 | `landmarks_visited_together` — landmarks discovered together | 3 | visiting ("visit whatever" — judgment call) |
| 3 | `distance_m_together` — meters travelled together | 4000 | travelling ("travel x miles" — judgment call on X) |
| 4 | `rest_nights_together` — nights rested together | 4 | resting (judgment call) |
| 5 | `feeds_together` — meals fed together | 10 | feeding (judgment call) |

Milestone 1 is unmodified owner input. Milestones 2-5 fill placeholders the
owner explicitly left open (2, 3) or left unstated entirely (4, 5, and the
ladder length) — **every target above is tunable data, not locked canon**,
and the owner should feel free to move any of them.

## Why five, and why these five

`bond_nodes()` already fed three real downstream systems before this
redesign, all built around a 0-5 count: `bond.effects_per_node` (a small
attack/defence scale per node), `traits.unlock_bond_nodes` (the second trait
reveals at node 5 — "fully bonded"), and the Mudsnout evolution gate
(`bond >= 55`, which under the old five-entry threshold table was exactly
node 3). Keeping the ladder at five milestones meant none of those three had
to change meaning, only how a node is *earned*. The evolution gate migrated
from a raw point value to `bond_tier: 3` — the same node, named directly.

The five tasks were chosen to land 1:1 on the five canon bond sources
prompt 67 already named (fighting / time together+visiting / traveling /
resting / feeding). The owner's own three examples (fight, visit, travel)
supplied the first three; resting and feeding — the two canon sources the
2026-08-22 audit found were never actually wired to bond — fill the last two
naturally, and feeding closes a real gap: it was named in design docs and
implemented nowhere.

## Judgment calls, flagged explicitly

- **Landmark target (3 of 9 shipped).** `data/config/map_landmarks.json`
  ships nine discoverable landmarks; three is reachable inside the first
  hour of ordinary exploration.
- **Distance target (4000 m).** No per-playthrough travel telemetry exists
  in the repo to calibrate against (no `route.csv`, no Gate F capstone
  distance log — checked before guessing). The one real measured number
  found was the critical-path spine itself: **11,519 m** in a single
  idealised straight walk (`ralph/GATE_F_EVIDENCE_2026-08-23.md`,
  `ralph/reports/gate-f-run-2026-08-23-1919/REPORT.md`). 4000 m is roughly a
  third of that one-way spine.
- **Rest-nights target (4).** `data/config/art.json`'s `day_length_seconds`
  (600s = 10 real minutes/day) puts a 3-4 hour session at 18-24 in-game
  cycles, but sleeping in a `creature_bed` is a deliberate build+use action,
  not automatic.
- **Feed target (10).** Feeding is the one task that is inherently
  per-creature and manual (the player picks one creature and one item per
  use) — unlike the other three, it cannot be advanced for the whole roster
  at once, so it is kept the lowest-effort of the four.

**Recalibration note:** the first pass at these four numbers (6000 m / 6
nights / 15 feeds) was lowered after an explicit follow-up from the owner
mid-session — *"you should be about to get full bond with your creatures
before leaving the meadows"* — clarifying that the goal is a full five-
creature team reaching all five milestones by the end of an ordinary
playthrough, not merely clearing the first one or two. Distance/landmarks/
rest credit every party member present at once (mirroring how
`battles_fought` and the old rest bonus already worked), so those three
track with total playtime regardless of who is piloted; feeding does not,
which is why its target stayed lowest.

## What was removed

- The flat per-action bond gains (`battle_won`, `successful_catch_start`,
  `per_day_in_party`) and the raw `bond.max`/`thresholds` config.
- The catch bond head start. A freshly caught creature now starts its ladder
  at 0/50 like every other creature — no hidden bonus math to explain.
- `creature_instance.gain_bond()` and the static `PROGRESSION.bond_nodes(bond,
  cfg)`/`PROGRESSION.rest_bond(cfg)` functions.

## What was preserved

- The legacy `bond: int` field itself (still on the instance, still
  round-trips through saves) — nothing reads it as a gate any more, but
  nothing needed to erase it either. `bond_nodes()` is the real answer now.
- `progression.json`'s `bond.effects_per_node` and `traits.unlock_bond_nodes`
  — what a node *buys* did not change, only how it is *earned*.
- Every existing save loads cleanly; `VERSION` moved 15 → 16
  (`scripts/save/save_game.gd::_migrate_v15`), the same "honest zero, history
  was never kept" pattern `_migrate_v13` used for `battles_fought`'s own
  siblings. (15 rather than 14 because this branch was rebased onto a `main`
  that had already shipped VERSION 15 for an unrelated feature, T3-ENCOUNTER's
  `world_seed` — see that migration step's own comment.)

## Verification

Branch `ralph/OWNER-0901-BOND-MILESTONES`. New tests in `tests/test_bond.gd`
pin the ladder's sequential behaviour (a task does not advance the tier
until fully met; a later task cannot be finished out of order) and every
crediting helper. `tests/test_progression.gd`, `tests/test_evolution.gd` and
`tests/test_combat_progression.gd` were updated where they encoded the old
points model. Full unit suite run locally (Godot 4.7-stable headless);
`tests/smoke_evolution.gd` run directly against the real Team-screen
ceremony.
