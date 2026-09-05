# C4 — Camping made necessary

**Status:** design contract, W19-CONTRACTS lane, 2026-09-04. Written against `main` at
`ef16544f`. Read-only on code and data; every *do* is an instruction to an implementation
lane. **Source directive:** `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-6. Plan row:
CL-O6 in `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G; `docs/FINISH_THE_MEADOWS.md` Phase 2b
"Camping made necessary"; prompt `docs/prompts/61-EXPEDITION-rest-rhythm.md` is the
older quality goal this turns into a requirement.

The owner's words:

> Camping isn't necessary. It needs to be necessary.

And the rule this must be built inside, `CLAUDE.md`, restated by CL-O6 and by the
directive's own routing table: *"CLAUDE.md forbids harsher hunger/thirst and starvation
death. Necessity has to come from attrition, distance and recovery scarcity, not from a
survival meter."* **This contract fails if the proposal is a faster satiety drain.** It is
not. §1 freezes every hunger number in the game.

Every contract has an id (`N-…`), a **do**, an **owns**, a **tests** line and a **fails
if**.

---

## 0. What is there, and why it is skippable

The rest rhythm is built and works: `night_rest.gd` is the one definition of a night
(day advance, trainer heal, every occupied creature bed completes, autosave), reached from
the buildable camp (`camp.gd`) and from six authored rest points with beds
(`rest_point.gd`, `props.json` `rest` blocks in every band). `creature_bed.gd` heals an
occupant over 120 s of world time (`progression.json` `creature_bed.full_heal_seconds`)
whether or not the player stands there. `creature_condition.json` gives a creature
`rested` (expires after 45 awake minutes), `fed` and `happy`, gating the **tournament
only**. The day is 600 s (`art.json` `day_length_seconds`), dark from hour 18 to hour 5
by the `times` keyframes, so **a night is roughly 45% of every ten minutes**. The trail
is 11,594 m — 3.86 in-game days at a walk (D50), about two ridden.

It costs nothing to skip because nothing accumulates:

- **Potions restore everything.** `potion_small` heals 35, `potion_large` 80; a full
  potion restore leaves a creature exactly as it was. Revives (10 at the start, D40
  amendment; `revive: 0.5`) stand the fallen back up at half HP. Beds and nights heal the
  same HP a potion does, only slower. So a stocked player never needs a bed.
- **`rested` means nothing outside the village.** It gates Halda's board and nothing else.
- **Night changes the light, not the odds.** `smoke_night_ecology.gd` proves night
  species spawn (Duskhush, Nightburrow); nothing about a night fight is harder, and
  `is_dark()` is read by the look, the torch and the spawns, never by combat or the wild
  band.
- **Distance is free.** Satiety drains (0.8/min player, 1.1/min creature) and that is
  the whole cost of a kilometre, and it is answered by berries, not by stopping.

So the rhythm exists as a *service* and the owner is asking for it to be a *decision*:
`GAME_VISION.md` §5, "The player should sometimes choose to stop because the team needs
it." The four levers below make the team need it, and none of them is a meter.

---

## 1. N-1 — The satiety numbers are frozen

*Keep, byte for byte:* `data/config/vitals.json` `satiety.drain_per_minute 0.8`,
`hungry_below 0.35`, `critical_below 0.15`, the two debuffs;
`data/config/creature_condition.json` `nourishment.drain_per_minute 1.1`,
`resting_drain_scale 0.0`, `fed_at`, `hungry_below`; `happiness.*`. No new hunger, thirst,
cold, fatigue or exposure meter. No item's `satiety` value drops. The 2026-08-23 owner
ruling ("keep the satiety drain rate; teach it") stands.

*Owns:* nothing — this is a fence.
*Tests:* `tests/test_player_vitals.gd` and `tests/test_creature_condition.gd` gain one
assertion each pinning the shipped numbers, with a comment naming this contract, so a
lane cannot "tune" them as part of camping work. `tests/test_food.gd` pins every food
item's `satiety` at its shipped value.
*Fails if* any number above changes in any camping PR, or if a new vital appears on
`player_vitals.gd` or `creature_instance.gd`.

---

## 2. Attrition — N-2 — Strain: the damage only rest takes off

The lever the brief names first: *"HP/condition that only rest restores past a floor."*

*Do:* a creature gains **strain** — a fraction of its max HP that potions cannot reach.
`creature_instance.gd` gains `strain: float` (0..`strain_cap`), and **effective max HP
while strained is `max_hp × (1 − strain)`**. `heal()` (potions) clamps to the strained
ceiling; `heal_fully()` (a completed bed rest, a night, home) clears strain to 0 and heals
to true max. Strain is *earned* by the road, in `data/config/creature_condition.json`
under a new `strain` block, all TUNABLE:

| key | start | meaning |
|---|---|---|
| `per_damage_fraction` | 0.20 | one fifth of every point of damage taken in a fight becomes strain, at the fight's end |
| `on_faint` | 0.25 | fainting adds a quarter of max HP as strain, on top of the damage that caused it |
| `on_revive` | 0.10 | a Revive stands the creature up (at `revive: 0.5` of the **strained** ceiling) and adds a tenth — it gets you moving, not whole |
| `cap` | 0.40 | strain never exceeds 40% of max HP: a strained creature is always at least a 60% creature, never a dead slot |
| `clears_on` | `["bed_rest_completed", "night_rest", "home_recovery"]` | the three things that are *rest*; nothing else clears it |
| `bed_clears_per_second` | 1 / 120 | a bed occupant's strain also drains at the bed's own heal rate, so a creature left in a bed at a camp while the player keeps fighting comes back whole in the same 120 s the bed already takes |

What this means on the road, with `chapter_curve.json`'s own numbers: a lead creature
that takes 60% of its HP across three field fights carries 12% strain; a hard fight that
faints it carries 12 + 25 = 37%, near the cap. Potions then top it up to 63% of true max
and no further. **Nothing about a fight got harder** — the same hits do the same damage —
but the third fight of a day is fought by a smaller creature than the first, and only a
bed or a night makes it the first again. That is attrition, and it is the "one creature
is hurt badly enough that continuing has a cost" beat `GAME_VISION.md` §2 asks for.

**What strain is not:** it is not a hunger, it does not tick with time, it does not
apply to the trainer, it never kills, it never takes a creature out of the party, and it
is never hidden — see N-7.

*Owns:* `scripts/creatures/creature_instance.gd`, `data/config/creature_condition.json`,
`scripts/combat/combat_manager.gd` (one call at `_finish()`: apply
`per_damage_fraction` of each participant's damage taken), `scripts/creatures/home_recovery.gd`
(`heal_fully()` clears strain), `scripts/build/creature_bed.gd` /
`autoload/game_state.gd::_tick_creature_bed_recovery()` (the per-second clear),
`scripts/save/save_game.gd` (**one new per-creature field**, `strain`, with a migration
that reads absent as 0.0 — the only save-format change any of the four contracts makes;
VERSION 16 → 17).
*Tests:* `tests/test_fainting.gd` and a new `tests/test_strain.gd`: damage of 30% then a
potion leaves the creature at ≤ 94% of true max (30% × 0.2 = 6% strain) and never above;
a faint then a Revive leaves strain at min(0.06 + 0.25 + 0.10, 0.40) and HP at half the
strained ceiling; `heal_fully()` clears both; the cap holds across ten faints; a bed
occupant's strain reaches 0 within `full_heal_seconds`; `tests/test_save_format.gd`: a
VERSION 16 save loads with `strain 0.0` on every creature and a VERSION 17 round-trip
keeps a non-zero one. Each is seen red first by removing the clamp.
*Fails if* strain can be cleared by an item, by time, by satiety or by the tournament
board; if a potion can heal past the strained ceiling; if the cap can be exceeded; or if
strain reads as damage in the HUD (it is a ceiling, drawn as one — N-7).

---

## 3. Recovery scarcity — N-3 — What is rare, and what a bed is for

*What is there:* Grandpa's pack is 50 orbs, 3 potions, 5 berries, 10 Revives (the 10 is
owner-decided, D40 amendment, and stands). Band harvest tables author one Revive and one
or two potions per band. `trade.json` sells potions at Mira's; elixirs are never sold
(D47). The addendum (§C) is about to add **100–150 placed pickups** including potions and
Revives, with its own *fails if*: "findables become so common that potions/revives erase
recovery/camping pressure."

Strain (N-2) is what squares that circle: **potions and Revives can be as findable as the
density pass wants, because they no longer restore the thing only rest restores.** A
player with twenty potions still fights the day's fourth fight at 70%. So scarcity is
applied to the *whole* answer, not to the *quick* one:

*Do:*

1. **No full heal on the road except rest.** No NPC, shop, shrine or item restores past
   the strained ceiling. Corin (C3, the mill peddler) and Wilhelm (C3, the trail camp
   host) sell recovery at **capped stock per in-game day** (`trade.json` gains a
   `per_day` cap: 2 potions + 2 Revives at Corin, 3 food at Wilhelm), so a shop on the
   route is a top-up, never a well. Halda's champion gift and the every-trainer
   milestones (C2 T-8) are one-time.
2. **Home is far.** `home_recovery.gd` at Grandpa's clears strain (it is rest). It is
   also 1.3–7.5 km back up the corridor. The haul road and the ferry landing
   (`MEADOWS_MACRO_LAYOUT.md` §3.2) make going home a *real* option, not a free one, and
   riding halves it — which is fine: a rider who goes home to rest has still stopped.
3. **A bed is the road's full heal.** Six authored rest points with beds already exist,
   one per band or two in Band 4; the buildable Creature Bed costs 6 wood / 8 fiber. C2's
   camping chain pins them. A creature in a bed is unavailable (exit criterion H3) and
   comes back whole; that trade — *lose it for two minutes now, or fight the next three
   with it at 70%* — is the decision.
4. **Revives are for the fallen, not the tired.** Unchanged (D40). With `on_revive`
   strain they are also not a substitute for a bed after a wipe.

*Owns:* `data/config/trade.json` (the `per_day` cap and two new stalls, shared with C3
V-7), `scripts/ui/shop_panel.gd` (draws remaining stock), `scripts/world/village_npcs.gd`
(no change expected).
*Tests:* `tests/test_trade.gd` (extend): a capped stall refuses the third purchase until
`advance_day()`; `tests/test_strain.gd`: no item in `items.json` carries an effect that
clears strain (walk the item table's effect keys — real data, not a grep of scripts).
*Fails if* any purchasable or findable item clears strain, if a route shop's stock is
uncapped, or if the density pass's pickup placement is used as an argument to weaken
N-2's numbers rather than the other way round.

---

## 4. Distance — N-4 — The road is measured in nights, and the camps are where they fall

*What is there:* the trail is 3.86 in-game days at a walk, about 2 ridden; the four
authored camp *sites* in `MEADOWS_MACRO_LAYOUT.md` §5 were chosen from "roughly a night
every 3,000 m of trail"; six rest points with beds are built.

*Do:* state the rhythm as a **measured contract**, then make the world keep it:

| From | To | Trail | At a walk | Ridden (×2.0) | Rest point on the leg |
|---|---|---|---|---|---|
| the village | the South Bridge | 2,384 m | 0.8 days | 0.4 | Trail Camp (345.6,935.4) |
| the South Bridge | the Warrens mouth | ~1,500 m | 0.5 | 0.25 | Ranger Camp (−256.4,2260.1) |
| the Warrens | the relay | ~1,900 m | 0.6 | 0.3 | Riverwatch rest (215.3,3697.0) |
| the relay | the mill crossing | ~800 m | 0.3 | 0.15 | — (the crossing is a gate; the far bank's ruined camp is *not* a rest point, by design) |
| the crossing | the Field Captain | ~1,300 m | 0.4 | 0.2 | wind-ridge rest (276.7,5652.5) |
| the Field Captain | the Ridge Captain | ~1,700 m | 0.6 | 0.3 | watchtower rest (−239.1,6472.2) |
| the Ridge Captain | the Hall | ~1,500 m | 0.5 | 0.25 | approach rest (−21.0,7456.6) |

With strain on, the question a player asks at each of those is not "am I hungry" but
"who is at 70%, and is the next fight the captain". The **distance** lever is therefore
not a new cost per metre — it is that **every leg carries enough authored fights to put
strain on the lead before the next bed**, which is exactly the density pass's job (CL-O4,
`FINISH_THE_MEADOWS.md`'s "density before the level gate"). This contract gives density a
number to hit:

*Do:* per leg above, the authored critical-path opposition (trainers + the wilds a walker
meets on the spine at the band's `wild_band`) must deal, in `tools/_probe_pacing.py`'s
model against `chapter_curve.json` `team.enter` stats, **at least 120% of the lead
creature's HP in cumulative damage before the leg's rest point**, i.e. ≥ 24% strain at
`per_damage_fraction 0.2` — enough that the leg's last fight is fought short-handed by a
player who never stops. Legs that fall short are the density pass's list.

*Owns:* `tools/_probe_pacing.py` (a `--strain` mode that prints per-leg cumulative
damage, strain at the rest point and the ceiling the lead would fight the leg's last
opponent at), `docs/specs/C4_CAMPING_NECESSARY.md` (this table, re-measured after density
lands).
*Tests:* `tests/test_chapter_curve.gd` (extend): the probe's per-leg strain-at-rest-point
is ≥ 0.24 for every leg once the density pass has landed — until then the assertion is
written and **marked expected-fail with the leg names**, so it goes green leg by leg as
density lands and cannot be forgotten.
*Fails if* the distance lever is implemented as a per-metre cost, a fatigue meter, a
timer, or a forced camp; or if a leg reaches its rest point with the lead under 10%
strain after density has landed.

---

## 5. Night — N-5 — The dark is where the road bites

*What is there:* night is 45% of the clock; `smoke_night_ecology.gd` proves night species;
the torch (D53) is carried; `wild_creature.gd`'s `aggressive` flag decides who starts a
fight; `chapter_curve.json` `wild_band` is resolved from position only ("never
player-scaled").

*Do:* three night rules, all data, all read through `day_cycle.is_dark()`:

1. **Night wilds are the band's top, not its spread.** After dark, a spawn rolls its level
   from the *upper half* of its region's `wild_band` (`[9,12]` becomes `[11,12]`), and
   `aggressive` species' engage radius scales by `night.aggressive_radius_scale 1.5`
   (`spawns.json` / `spawn_tables.json` read it; `wild_creature.gd` applies it). Still
   position-scaled, still inside the band, still not the player's level — a level-3 player
   at the Hall at night meets 16–17s exactly as a level-19 one does.
2. **Night fights strain more.** `strain.per_damage_fraction` × `night.strain_scale 1.5`
   after dark: the same damage leaves more of a mark when you fought it in the dark. This
   is the one place night touches N-2 and it is a multiplier on an existing number.
3. **The companion says so.** The addendum §E's "visibly hurt/tired" reaction plays at
   ≥ 25% strain **and** at night, so the creature the player is walking beside is the
   thing that tells them to stop — before the HUD does.

What night does **not** do: drain satiety faster, damage the trainer, spawn anything the
day does not have somewhere, or lock a road. A player who walks through the night can; it
costs them the next day's fights.

*Owns:* `data/config/spawn_tables.json` / `data/config/spawns.json` (a `night` block),
`scripts/creatures/wild_creature.gd`, `scripts/world/day_cycle.gd` (no change expected),
`data/config/creature_condition.json` (`strain.night_scale`), prompt 73's companion
reaction layer (the tired reaction's trigger only).
*Tests:* `tests/smoke_night_ecology.gd` (extend): at `--time=night` every spawned wild's
level is in the top half of its band and a Duskhush engages from 1.5× its day radius;
`tests/test_spawn_tables.gd`: the night roll never leaves `wild_band`; `tests/test_strain.gd`:
the night multiplier applies only when `is_dark()`; `tests/test_day_cycle.gd`: the dark
window is unchanged (18 → 5).
*Fails if* night changes any satiety number, if a night spawn can exceed its band, or if
the night rules apply in the village clearing (the practice meadow and the tournament
ground are inside `village_boundary.json` and are exempt — the opening's first catch is
a day fight and must stay one).

---

## 6. The rest itself — N-6 — What a night pays

*What is there:* `night_rest.pass_the_night()`: day advances, the trainer heals, every
*occupied* creature bed completes (with `rested`), `rest_bonus` XP (5) to the party,
autosave, `player_slept_at_home`. Non-resting party members **keep their current HP** —
the Gate A contract's "meaningful preparation trade-off."

*Do:*

1. **A night clears strain on every party member, bedded or not**, and heals *to the
   strained ceiling* only the ones in beds (the Gate A rule stands: a creature not in a bed
   wakes with its HP where it was, but its *ceiling* is back). So a player with one bed
   and five creatures chooses who gets the bed — the same decision as today, with a
   reason attached.
2. **`rested` matters on the road.** A creature whose `rested` has expired (45 awake
   minutes, `stays_rested_minutes`) or was never earned gains strain at
   `per_damage_fraction × 1.25` (`strain.unrested_scale`). Rested creatures wear the road
   better. This gives the existing condition model a job outside the tournament without
   adding a state.
3. **Rest bonus XP goes up to 5% of the party's next-level cost**, capped at the current
   `rest_bonus` × 8, so a night is a small, visible progression event (prompt 73 shows it
   as an XP tick) rather than a number nobody has ever noticed.
4. **The Meadows' day/night must actually reach night on the shipped build.** CL-O2 ("there
   is no night time", owner-reproduced) is a prerequisite for N-5 and for any of this being
   *felt*: until the real build's clock reaches `is_dark()`, N-5 never fires and the rhythm
   is one lever short. This contract does not own that fix; it names it as the dependency
   it is.

*Owns:* `scripts/world/night_rest.gd`, `data/config/creature_condition.json`
(`strain.unrested_scale`), `data/config/progression.json` (`xp_award.rest_bonus_fraction`,
`rest_bonus_cap`).
*Tests:* `tests/smoke_gate_a_rest_torch.gd` / `tests/smoke_home_sleep.gd` (extend): after a
night, every party member's strain is 0, the bedded one is at true max, the un-bedded one
is at its pre-sleep HP with its true max restored; `tests/test_creature_condition.gd`: an
unrested creature's strain gain is 1.25×; `tests/test_progression.gd`: the rest bonus is
capped.
*Fails if* a night heals an un-bedded creature's HP (the Gate A trade-off is the whole
reason beds exist), or if `rested` becomes a second hidden strain.

---

## 7. Legibility — N-7 — Necessity the player can see

Nothing above works if the player cannot see it. Prompt 73 (CL-W6) owns the feed; this
contract owns what strain looks like in it.

*Do:*

- **The HP bar draws the strained ceiling** as a hatched cap on the right end of the bar
  (party strip, combat HUD, Team screen, creature bed panel), so "why won't the potion
  fill it" is answered by the bar itself. No number, no new bar.
- **The Team screen's condition column** reads "Strained 30%" beside "Rested"/"Tired"
  and "Fed"/"Hungry" — the same slot, the same tokens (`ui_tokens.gd`).
- **A one-line hint** on the feed the first time strain reaches 20% on any creature
  (`strain_hint_shown` flag, once per save): *"Potions can't reach that. A bed or a night
  will."* And a second, once, the first time a fight starts at night: *"After dark, the
  road bites harder."*
- **The companion's tired reaction** (addendum §E) at ≥ 25% strain.
- **C2's camping chain** pins the next rest point, and its `how` line says what a camp
  clears.

*Owns:* `scripts/ui/party_strip.gd`, `scripts/ui/combat_hud.gd`, `scripts/ui/tab_creatures.gd`
(the ceiling cap and the condition word), `scripts/ui/creature_bed_panel.gd`,
`data/progression/tasks.json` (the two hints ride the feed as `find`-less events; no
task), prompt 73's feed for the two hints.
*Tests:* `tests/test_hud_widgets.gd` (the cap's width equals `strain × bar width` within a
pixel); `tests/smoke_combat_hud_left_column.gd` / `tests/smoke_hud_handheld_legibility.gd`
(the cap is visible at the Ally floor); `tests/test_strain.gd`: each hint fires exactly
once per save.
*Fails if* strain is visible only in a menu, if the cap is drawn as damage (a darker
fill rather than a hatched ceiling), or if either hint fires twice.

---

## 8. The numbers to tune, in one place

All in `data/config/creature_condition.json` `strain` and `data/config/spawns.json`
`night` unless noted. Starting values, TUNABLE; the evidence run (§10) moves them.

| Lever | Key | Start | Direction if camping is still skippable | Direction if it is a chore |
|---|---|---|---|---|
| strain per damage | `per_damage_fraction` | 0.20 | up to 0.25 | down to 0.15 |
| strain on faint | `on_faint` | 0.25 | up to 0.30 | down to 0.20 |
| strain on revive | `on_revive` | 0.10 | up to 0.15 | 0.05 |
| strain cap | `cap` | 0.40 | 0.45 | 0.35 (never below 0.30: the ceiling must be felt) |
| unrested multiplier | `unrested_scale` | 1.25 | 1.4 | 1.1 |
| night multiplier | `night_scale` | 1.5 | 1.75 | 1.25 |
| night level band | `night.level_half` | upper half | top third | full band |
| night aggro radius | `night.aggressive_radius_scale` | 1.5 | 2.0 | 1.25 |
| bed clear time | `creature_bed.full_heal_seconds` | 120 (unchanged) | — | — |
| shop cap per day | `trade.json` `per_day` | 2 potions, 2 Revives, 3 food | 1/1/2 | 3/3/4 |
| rest XP | `xp_award.rest_bonus_fraction` / `rest_bonus_cap` | 0.05 / 40 | — | — |
| the leg floor | `test_chapter_curve` strain-at-rest-point | ≥ 0.24 | ≥ 0.30 | ≥ 0.18 |
| **satiety, all of it** | `vitals.json`, `creature_condition.json` `nourishment` | **frozen** | **never** | **never** |

---

## 9. Implementation slices

| Slice | Do | Owns | Tests | Size |
|---|---|---|---|---|
| **C4-S1 fence** | N-1: pin every satiety number | tests only | `test_player_vitals`, `test_creature_condition`, `test_food` | S |
| **C4-S2 strain** | N-2, N-6 (1) and (2): the field, the ceiling, the clamps, the clears, the save field, the night's clear | `creature_instance.gd`, `creature_condition.json`, `combat_manager.gd` (one call), `home_recovery.gd`, `creature_bed.gd`, `game_state.gd` (bed tick), `night_rest.gd`, `save_game.gd` (VERSION 17) | `test_strain.gd` (new), `test_fainting.gd`, `test_save_format.gd`, `smoke_gate_a_rest_torch.gd`, `smoke_home_sleep.gd` | M |
| **C4-S3 visible** | N-7: the ceiling cap on every bar, the condition word, the two hints | `party_strip.gd`, `combat_hud.gd`, `tab_creatures.gd`, `creature_bed_panel.gd` | `test_hud_widgets.gd`, `smoke_combat_hud_left_column.gd`, `smoke_hud_handheld_legibility.gd` | M |
| **C4-S4 scarcity** | N-3: capped route stalls, the no-item-clears-strain fence | `trade.json`, `shop_panel.gd` | `test_trade.gd`, `test_strain.gd` | S |
| **C4-S5 night** | N-5: the night block, the top-half roll, the aggro radius, the night strain scale, the village exemption | `spawns.json`/`spawn_tables.json`, `wild_creature.gd`, `creature_condition.json` | `smoke_night_ecology.gd`, `test_spawn_tables.gd`, `test_day_cycle.gd`, `test_strain.gd` | M |
| **C4-S6 distance** | N-4: the probe's `--strain` mode, the per-leg floor written as an expected-fail that density turns green | `tools/_probe_pacing.py`, `test_chapter_curve.gd` | `test_chapter_curve.gd` | S |
| **C4-S7 rest pays** | N-6 (3): the rest XP fraction and cap | `progression.json`, `night_rest.gd` | `test_progression.gd` | S |

**Order:** S1 first (it is the contract's own *fails if*, and it must be red-able before
any other slice lands). S2 before S3, S4, S5 and S7 (they all read `strain`). S6 any time;
its assertion is expected-fail until density lands. **S3 depends on prompt 73's feed**
for the hints only; the bar cap does not. **S5 is gated on CL-O2** ("no night time") being
root-caused on the shipped build — it can land and be tested in the harness before that,
but it is not *felt* until the real clock reaches night, and the evidence run in §10
counts only nights the shipped build actually reaches.

---

## 10. Evidence the lane scores

The probe first (`tools/_probe_pacing.py --strain`), then a played path:

- **A no-rest run of Band 3** (the South Bridge to Vance, `smoke_relay`'s own route with
  the harness's fight driver) arrives at Captain Vance with the lead creature's ceiling at
  or below **75%** of true max and at least one party member under 60%, and loses or
  barely wins the fight it wins comfortably after a night at the Riverwatch rest point —
  both runs recorded, both from the same seed.
- **The same run with one night** at the Riverwatch rest and one creature bedded arrives
  whole.
- **A night walk** through Band 4's old-growth meets wilds two levels above the day's,
  and the companion's tired reaction plays before the HUD's hint.
- **A potion in the harness** cannot raise a strained creature above its ceiling, and a
  bed can — `test_strain.gd` red first, then green.
- **The satiety numbers are unchanged** on the branch, asserted by a test that has been
  seen to fail by changing one.

A tester who plays Band 3 without reading anything can say why they stopped at the
Riverwatch rest, and it is not "I was hungry."

---

## 11. What this deliberately does not do

- No faster satiety drain, no thirst, no cold, no exposure, no starvation, no fatigue
  meter, no forced camp, no "you must rest" prompt, no timer.
- No change to what a bed *is* (120 s, unavailable while in it, completes on a night).
- No change to the trainer's own HP or death (`player_death.gd`, satchels).
- No new rest point, no new item, no new mesh.
- No reduction of Grandpa's 10 Revives.

---

## 12. Where this touches other contracts

- **C1:** riding halves the road, not the fights on it; a rider still meets night and
  still strains. A mount in a bed is unavailable as a mount — the traversal slot pays the
  same price.
- **C2 T-12:** the camping chain pins the rest points this contract makes necessary; its
  `how` line names strain.
- **C3 V-7:** Wilhelm and Corin are the two capped route stalls.
- **The addendum §B/§C** (candy and findables): potions and Revives may be as common as
  that pass wants; strain keeps them from erasing the pressure. Candy raises levels and
  therefore true max HP, and leaves `strain` (a fraction) exactly where it was.
- **D75:** a level gate that turns a player back is a player who fights more on the way
  back, and therefore strains more; the gate and the rest rhythm point at the same camp.
- **Prompt 73 / CL-W6:** every strain event (gain, hint, clear on rest) rides the one
  progression feed; there is no second banner system.
