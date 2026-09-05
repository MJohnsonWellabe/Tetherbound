# D74 — The baseline fight costs something

**Date:** 2026-09-04 · **Decided by:** lane W23-DIFFICULTY, on the owner's
hardware reproduction of the same day (`docs/owner/OWNER_PLAYTEST_2026-09-04.md`,
OP-0904-5): *"Beating creatures and other trainers is way too easy."*
**Amends nothing in G-2/G-3** (`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`): the
per-encounter profiles keep their shapes exactly; this moves the floor they stand on.

## 1. What was measured before anything moved

`tests/smoke_combat_baseline.gd` fights the typical five (starter plus the four
most-fielded Band 1 species) at every region's `team.enter` level, against that
region's whole wild spawn table at the band's median level and against its
weakest non-gate trainer, through the real `combat_ai`, `combat_math`, creature
stats, move and type tables, trainer teams and the real per-body config merge —
24 seeded runs per row, one pilot policy: close to reach, quick on cooldown,
charged when full, chase when it backs off, **dodge nothing, use nothing**. That
is the floor of competence. Shipped numbers, before this decision:

| at band entry | ordinary wild costs the lead | the band's floor trainer costs the lead | ever lost |
|---|---|---|---|
| Band 1 (L3) | 10 % | 11 % | no |
| Band 2 (L9) | 9 % | 21 % | no |
| Band 3 (L12) | 7 % | 14 % | no |
| Band 4 (L15) | 7 % | 20 % | no |
| Band 5 (L17) | 8 % | 14 % | no |
| tournament final at L5 | — | 71 % of the lead, 17 % of the five | no |
| the Warden at L19 | — | 71 % of the lead, 17 % of the five | no |

An ordinary wild died in about seven seconds having landed two hits. The
arithmetic behind it: the pilot swings every 0.8 s; the opponent's whole cycle
(recovery 0.75 + reposition 1.0 + walk back + telegraph 0.55) was ~2.7 s, at
power 8 against a quick of 9 — roughly a fifth of the player's damage rate. The
real-scene `smoke_combat` cross-checks the model: five player hits to a faint,
two hits taken.

## 2. The decision

**An ordinary fight has to cost something, and the cost has to be the opponent
mattering, not the player's hits mattering less.** Four numbers and one rule:

1. **`combat.json` `enemy.damage_scale: 1.6`** — every opponent's `power` is
   multiplied by this *after* the per-body G-2 merge
   (`wild_creature.gd::spaced_config_for`). **Why a new key rather than raising
   `power`:** the authored profiles carry absolute power against the 8.0 baseline
   (WALL 12.0, CHARGER 10.4, DIVER 7.2, CURRENT 6.4, ACE 14.4). Raising `power`
   to 12 would have made a CURRENT relay picket hit *softer* than a field
   bramblebun — inverting the contract's table in band files this lane does not
   own. The scale keeps every ratio and is not an override key, so no band file
   can author it. The player's quick (9) and charged (38) are untouched.
2. **Cadence:** `enemy.reposition_time` 1.0 → 0.7, `first_attack_delay` 1.5 →
   1.0. One more swing per fight; the back-off is still readable, and the
   baseline still sits between the two profiles that are *about* this number
   (CURRENT 0.5, DIVER 1.6). `recovery` (the punish window) and `telegraph` (the
   only warning) are deliberately untouched.
3. **A trainer's creature is drilled:** new `combat.json` `enemy_trainer` block
   (first beat 0.7, cooldown 0.9, reposition 0.6, chase 5.2, power 10.4), laid
   over `enemy` for every trainer-owned body (`wild_creature.trainer_owned`, set
   by `encounter_director` when it fields a team member) and *under* the
   member's own `combat` block. 25 of 31 authored trainers carry no profile;
   this is what makes their pickets read as pickets. A wild never sees it.
4. **The aggressor can catch you:** `catching.json` `aggression.chase_speed`
   3.4 → 5.6. The trainer walks at 5.0 and sprints at 8.6; at 3.4 an aggressive
   creature could never reach a player who simply kept walking. Escaping now
   costs stamina, and is still always possible.
5. **Band 4's wild ceiling 14 → 15 (CL-G8).** The corrected entry level is 15;
   a field whose best creature is already a level under the arriving team is not
   opposition on arrival. Widened from the top with the floor kept (D69's rule,
   read for levels: the end that was right does not move). **Band 2 is not
   moved:** its ceiling (8) is pinned by the Warrens' weakest resident (9), which
   must stay strictly above the field, and `burrow_warrens.json` is not this
   lane's file. The exact diff is in the lane report.

## 3. The targets, and why these

Recorded in `chapter_curve.json` `difficulty` and asserted by the smoke, so
softening the game back below them fails a build:

| target | value | argument |
|---|---|---|
| ordinary wild at band entry, lead HP cost | 15–30 % | a real dent that adds up over a leg and makes the camp worth reaching; never a wall. Band 1 exempt (its median wild out-levels the L3 arrival by design; the tutorial reads it) |
| floor trainer at band entry, lead HP cost | 25–80 % | about half the lead: the next trainer in the band is a real question of rest, potion or switch |
| floor trainer, five-creature wipe | never more than 25 % | a floor may hurt; it may not wall |
| tournament at its entry level | won ≥ 75 % | `smoke_tournament_bracket` must keep winning it |
| the Warden at L19 | won ≥ 50 %, costs the five no less than the elite | W-1: he opens no softer than Hald |
| any single hit | < 50 % of a full-health entry-level creature | G-3's fails-if is a one-shot; half leaves the ACE a two-hit lesson |

**On "lost one time in four":** the brief asked that the floor trainer be lost by
this pilot about one run in four. Measured, that target is wrong for a *floor*.
With the manager's auto-switch-on-faint a loss means all five down, and a band's
weakest trainer that wipes an equal-level five a quarter of the time makes its
strongest a wall and the tournament unwinnable at its own entry level — the
final already knocks the lead out every run at L5. So the target is read as
**the lead pays for arriving unprepared** (half its health at the floor, knocked
out at the band's top), and the wipe rate is guarded from the other side.

## 4. Measured after

| at band entry | wild costs the lead | floor trainer costs the lead | band's top trainer |
|---|---|---|---|
| Band 1 (L3) | 21 % | 29 % (Mira) | Oskar / the bridge grunt knock the lead out |
| Band 2 (L9) | 18 % | 62 % (Dorn) | Pell 75 % |
| Band 3 (L12) | 16 % | 44 % (Hess) | Dell and the Riverwatch captain knock the lead out |
| Band 4 (L15) | 15 % | 56 % (Juno) | the Field captain 72 % |
| Band 5 (L17) | 16 % | 38 % (the outer watch) | courtyard, elite, Warden knock the lead out |
| tournament final at L5 | — | lead out every run, 45 % of the five, still won every run |
| the Warden at L19 | — | lead out every run, 31 % of the five (elite 24 %), won every run, 61 s |

Fight *length* is unchanged (no HP moved): the pacing probe prints the same
2.37 h floor before and after. Danger went up ×2–2.5; grind did not.

## 5. The ceiling, stated

To make the no-dodge pilot *lose* the Warden a quarter of the time,
`damage_scale` would need ~2.5, which puts an ordinary wild past 30 % and the
tournament final into wipes at L5. That is a second round after owner play,
not this one, and `damage_scale` is the first number to move in either
direction. What was considered and left alone: `progression.json`'s
attack/defence growth (symmetric — it shortens fights without changing what
they cost), enemy HP (lengthens fights: that is grind, not danger), and an
AI-side mid-fight switch for trainers (a new mechanic; not in any contract).
