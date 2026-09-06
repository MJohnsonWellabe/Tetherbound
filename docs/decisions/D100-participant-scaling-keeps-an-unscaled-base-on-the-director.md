# D100 — §10's participant scaling keeps an UNSCALED BASE on the director, and is applied after the record is live

**Date:** 2026-09-06
**Status:** settled
**Lane:** MP-F1-F2 (Stage B), closing finding F1 of `ralph/reports/MP-ROWS-8-21-0906/REPORT.md`
**Touches:** `scripts/combat/encounter_director.gd`, `scripts/creatures/wild_creature.gd`
**Contract:** `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §10 / D-MP12

> There is an unrelated D100 in the save work (the character/world split named in
> `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`'s v22 bullet). That number was
> taken in a lane's prose, never as a record in this directory; this file is the
> first `docs/decisions/D100`. Where the two are cited together the save one is
> "D100's split" and this one is "D100's base".

## What was wrong

`encounter_director.gd::_scale_opponent_for_the_session()` was called from
exactly one place — `_send_out_next_creature()`, immediately after the creature
was popped off the trainer's queue and **before** `_start_fight()` opened or
resumed the encounter record it reads its multiplier off. So:

- the **first** creature of a roster found no record at all and returned on
  `_encounter` being empty;
- **every creature after it** found a participant list that §9 empties at each
  round boundary (`combat_manager.gd::_finish()` submits `disengage` at the end
  of every round), re-stamped through `scaling_for(0)` — the identity — so the
  scaler read 1.0/1.0 and returned on its own `is_equal_approx` guard. The
  re-seat that restores the row to 1.1/0.85 runs inside `_start_fight()`, after
  the scaling call.

Measured on the Warden at two participants: burrowback and galecrest both fought
at their **authored** attack, defence and cooldown while the record beside them
was stamped `stat_multiplier` 1.1. Rule 6 / §10 / D-MP12 — "an encounter gets
harder with more players" — reached nothing in any trainer or boss battle.

Nothing had caught it because every §10 test asserted on the TABLE
(`encounter_host.gd::scaling_for()`) or the RECORD (`host.scaling(id)`). No test
had ever asserted that the multiplier reaches a creature.

## The decision

**Move the scaling call to after the record is live, and keep an unscaled base
for the opponent on the DIRECTOR.**

Moving the call alone is not enough and is why the previous lane refused to make
it. §10 re-derives its row every time `participants` changes, so the scaler is
asked about the same live creature more than once — on a mid-fight join, on a
leave, on the host's re-derivation after every landed strike, and again for each
creature of a roster. The old scaler multiplied `attack`/`defence` **in place
with no unscaled base kept**, which is safe exactly once; the second call squares
the multiplier.

Every write is now `base × row`, never `live × row`.

### The base is kept, not re-derived from the species curve

The alternative considered was re-deriving the authored numbers from
`creature_instance.gd::from_species` at each re-stamp. Rejected:

- **A trainer's creature is not a pure function of species and level.**
  `trainers.json` authors `level_bonus`, `stat_bonus`, `body_scale`, a title, a
  per-member `combat` block and a shiny roll, and the world adds alpha/elder
  treatment on top. Re-deriving would silently discard every one of them the
  first time somebody joined a fight — a scaling change that quietly retunes an
  authored encounter is a worse bug than the one it fixes.
- **It would couple §10 to the progression curve.** A species-curve retune would
  then change what a mid-fight join does to a creature that is already standing
  on the field, which is not a relationship anybody asked for and not one a test
  would notice.
- **The base is exact and free.** Three floats and a dictionary, taken once, off
  the very numbers the fight was authored with.

### The base lives on the director, not on `creature_instance.gd`

- `creature_instance.gd` is **saved** (`character_save.gd`, `save_game.gd`). A
  scaling scratch field has no business in a save file, and adding one would put
  a multiplayer tuning detail into the format every solo save is written in.
- The opponent of a networked fight lives and dies inside one battle, which is
  exactly the director's own lifetime. The base is taken the first time a
  creature is scaled, dropped the moment the opponent changes, and dropped again
  when the battle's record closes.
- Nothing else needs to read it. It is bookkeeping for one function.

### Where it is applied

Two call sites, both after the record exists:

1. `_start_fight()`, after `_open_encounter_if_networked()` has minted or resumed
   the record — so a creature stepping up into a fight two people are already in
   is scaled as it arrives;
2. `_host_after_encounter_change()`, the host's one choke point for `join` and
   `leave` — so §10's "re-derived when `participants` changes, including a
   mid-fight join or leave" reaches the creature already on the field and not
   only the record's stamped row. An unchanged row returns on the scaler's own
   guard, so the strike path costs nothing.

### The identity is a real answer, not a return

`_session_scaling_row()` answers the **identity** — not "don't touch anything" —
whenever this process is not the host of a multi-peer session or holds no live
record. That is what puts a creature BACK when the last other participant leaves:
`_is_multi_peer()` goes false the moment a two-person session is one person
again, and a scaler that merely returned there would leave the boss carrying a
multiplier for a fight nobody else is in any more.

A creature that was never scaled is untouched by this: no base is taken at the
identity, so a **solo game does not read or write one number of any of it**.

### The cooldown has to be pushed to the body

`wild_creature.gd::set_engaged()` snapshots `_enemy_config_for_this_body()` into
`_combat_cfg` when the fight opens — which is **before** the record this scaler
reads even exists. A `combat_override` written afterwards would sit on the
instance and never reach a single swing. `wild_creature.gd` therefore gains
`refresh_combat_profile()`, which re-reads that config, and the director calls it
after writing the override. Only the config is re-read: `_cooldown`, `_beat_left`
and `_intent` are the swing already in flight and are left alone, so a shorter
cooldown takes effect from the NEXT swing rather than cutting short the telegraph
the player is currently reading.

At the identity the authored `combat_override` dictionary goes back **verbatim**
rather than being rebuilt at `base × 1.0`: a creature that authored no
`attack_cooldown` (the Warden's opening burrowback authors none — finding F3)
must not acquire one just for having been in a fight that emptied out.

## What is deliberately NOT changed

- **HP is never multiplied by players.** §10's one outright prohibition. This
  function does not read or write `hp` or `max_hp`, `multiplayer.json` carries no
  key a future edit could use as one, and the rule is now asserted at every row
  including the identity in both smokes below.
- **Scope stays trainer-owned opponents.** Lane 4.D scoped this to a trainer's
  creature deliberately (the function's own header says so), and this lane did
  not widen it to wild fights. Whether a shared wild fight should scale is a
  design question with its own blast radius, and is recorded as open rather than
  answered here.
- **It is not a level bump.** Spec §11 / D30: a level is a real level and the
  world does not move to meet you. Nothing here touches a level.
- **`multiplayer.json`'s numbers are unchanged.** No bar was discovered by
  running until something passed.

## What proves it

- `tests/smoke_encounter_scaling.gd` (new) — three rounds of one roster, at one,
  two and three participants, with a join, eleven re-derivations and two leaves.
  66 assertions. Red on the tree before this decision with 18 failures, at
  exactly the authored numbers; red with 6 failures under a deliberate break that
  scales the live value instead of the base; red with 6 failures under a break
  that makes `refresh_combat_profile()` a no-op.
- `tests/smoke_net_shared_boss.gd` — the same claim over a real ENet link against
  the real `session.gd`, tightened from printing the numbers to asserting them.
