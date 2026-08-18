# RG19-spec — Define creature condition for tournament readiness

## Goal
Write the missing canonical design/technical specification for **rested / fed / happy** creature condition so the local tournament can gate on understandable, persistent state without inventing three disconnected meters.

This item produces a `docs/decisions/` entry (next available D-number) plus any small data-schema documentation/probes needed. It does **not** build the tournament bracket.

## Owner-approved intent
The village tournament is the early-game proving ground. The intended entry shape is a full five-creature team that has been trained and cared for: appropriately levelled, **well rested, well fed, and happy**. Winning then pays coins and sends the player toward Team Tether.

Numeric thresholds are tunable. Do not turn an arbitrary first-pass number into permanent canon.

## Reuse existing state before adding new state
Inspect current main for all relevant systems:
- `creature_instance.gd` already stores per-creature level, HP, fainted state and **bond**;
- existing progression config defines bond behavior/thresholds;
- `creature_bed.gd` + `creature_bed_panel.gd` already provide a real per-creature rest/recovery interaction;
- current player satiety system/D29 exists, but determine whether creature feeding already has per-creature state elsewhere before assuming player satiety can represent it;
- food/item systems and any creature feeding interactions;
- save serialization of creature instances;
- creature/team UI and existing `bond_meter.gd`.

The design preference is **derive condition from systems the player already understands** instead of adding redundant meters.

## Required decisions to document
### Rested
Define what event/state makes a creature rested, how it becomes tired, how quickly that state changes, and how the player restores it.

Strong default seam: creature-bed use should be the primary recovery path because the game already asks the player to build a pal/creature bed in RG18. If a suitable per-creature rest timestamp/charge does not exist, specify the smallest persistent field needed.

Rest must not become real-time micromanagement after every fight. Pick a forgiving tunable model suitable for the early tournament.

### Fed
Determine whether the repo already has a creature-specific satiety/feeding model. If so, reuse it. If not, specify a lightweight per-creature fed state driven by existing food/berry interactions; do **not** misuse the human/player satiety number as five creatures' shared hunger.

Preserve D29 philosophy: soft condition pressure, no starvation death. Fed is a readiness/care signal, not a punishment spiral.

### Happy
First inspect whether existing `bond` is semantically sufficient. Bond is already per creature, persistent, visible via `bond_meter.gd`, and tied to relationship/progression. Prefer deriving "happy" from bond/recent positive-care state if that matches current canon rather than creating a second affection stat.

If bond is too permanent to express current wellbeing, specify the minimum additional transient condition and clearly explain why bond alone cannot do it. Do not casually duplicate relationship systems.

## Legibility requirement
A condition cannot gate entry unless the player can understand it **before** being refused.

The spec must define a compact creature/team UI presentation showing, for each of the five:
- rested state;
- fed state;
- happy state;
- level/readiness;
- what action will improve a failing condition.

Use simple states/icons/labels rather than hidden floating-point values. Tournament organizer dialogue may explain requirements, but UI must let the player check them away from the organizer.

## Persistence / data model
Specify exactly where each state lives:
- species data is never the place for individual condition;
- prefer `creature_instance` or an existing per-creature persistent component;
- update save format/version and migration if new fields are required;
- old saves receive safe/default states that do not corrupt parties or fabricate permanent bonuses.

Condition is individual: one well-fed creature cannot make another qualify.

## Tunables
Put decay/recovery/threshold values in data config. Label them TUNABLE. Include recommended starting values only as implementation defaults, not hard design law.

Avoid wall-clock/offline decay unless the project already has that concept; in-game time/day progression is safer and deterministic.

## Preserve
- five creatures ever;
- pals/creatures are peers, not disposable workers;
- no starvation death;
- existing bond/progression semantics;
- creature bed/recovery behavior;
- save migration discipline;
- controller-readable UI.

## Deliverable / acceptance criteria
The decision doc is sufficient for another Ralph firing to build RG19 without asking:
1. precise semantics for rested/fed/happy;
2. authoritative storage/source for each;
3. change/recovery triggers;
4. UI representation and guidance;
5. persistence/migration plan;
6. tournament-readiness query/API shape;
7. tunable thresholds in data, not magic numbers;
8. explicit reuse decisions for bond, food/satiety and creature beds;
9. edge cases: fainted creature, newly caught creature, save/load, bed use, feeding at full state, five-creature cap.

## Definition of done
There is one canonical, implementable creature-condition model that makes the player's pre-tournament loop—**train them, feed them, let them rest, build a relationship**—visible and meaningful without creating redundant survival meters.