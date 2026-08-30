# Handover — T3-COMBAT

**Branch:** `ralph/T3-COMBAT`, off `origin/ralph/LAND-0830I` @ `e8d82088`.

**The lane:** section I of `ralph/MEADOWS_EXIT_CRITERION.md` — *"Combat is
readable, responsive, spatial; the player pilots in real time; type matchups are
legible in the moment"* — evidenced by **fights, not config**.

Every number in this document comes from a fight that was played: real
`Input.action_press` on the real bindings, the trainer walking the last stretch
on the stick, the fight entered with `interact`, the creature piloted with
`combat_quick` / `combat_charged` presses inside the real
`meadows_playground.tscn`. Nothing here was computed from `type_chart.json`.
Where a data census appears it is labelled **context** and is never used as
evidence about how a fight feels.

---

## 1. What was built to get the evidence

| file | what it is |
|---|---|
| `tools/combat_pilot.gd` | A player, played by a machine, through the real input path. Two pilots — `BRAWLER` (walk in and hit) and `SPACER` (back out of the wind-up, spend the meter into the recovery). The gap between them is the measurement of whether the fight has skill in it. It heals nothing, repositions nothing mid-fight, and calls no damage function. |
| `tools/_probe_combat_matchup.gd` | Staged **non-mirror** wild encounters: one attacker against defenders that differ only in what the chart says about them. |
| `tools/_probe_combat_ladder.gd` | All 29 authored trainer rungs in route order, at the level and party size `data/config/chapter_curve.json` says the player arrives with, through the real `begin_trainer_battle()`. |
| `tools/_probe_captain_rebalance.gd` | Each regional captain fought **twice** — the roster that shipped, and the roster that shipped before the T3-ACTIVITIES rebalance, reconstructed from that entry's own note — same challenger, same pilot, back to back. |

### 1.1 One harness bug worth recording, because it looked exactly like a finding

The first ladder run reported `old_champion_bram` as a loss with **0 hits dealt
and 22 taken over 59.8 seconds**. That reads as a brutal wall. It was a broken
measurement.

`combat.json`'s `player_quick.range` is 2.6m, but
`combat_manager.gd::_with_reach_for_the_bodies()` grows the real reach with the
two creatures' radii, because `enemy.body_clearance` (2.75) already holds them
that far apart — against a Meadowhart the player's actual reach is **4.63m**, not
2.6m. A pilot closing to a fraction of the flat 2.6m is trying to stand 1.56m
from a creature whose own capsule stops it at 1.50m, so it walked into the body
forever and never pressed attack.

Fixed in `combat_pilot.gd::_reach()`, which now asks the same question the
manager asks, and every number below was re-measured afterwards. Recording it
because the failure mode is the one this repo keeps paying for: an instrument
that produces a plausible number about a game it is not actually playing.

---

## 2. Context (not evidence): what the ladder is made of

Counted from the five `data/config/bands/*/trainers.json` files. This frames the
played results; it does not stand in for them.

- **29 authored rungs, 70 trainer creature instances.**
- Types fielded: **Ground 41, Air 19, Water 10.** Nothing else.
- **Zero dual-typed creatures**, and **zero** instances of the five types
  T3-MATCHUPS added (fire, electric, ice, psychic, dark). The move types any
  trainer creature can throw are ground, water and air — only.
- **Nine of the 29 rungs field a mono-Ground team**, which hands any Water
  creature a 1.56× exchange for the whole fight: `practice_trainer`,
  `trainer_mira`, `south_bridge_grunt`, `tournament_quarter_mira`,
  `quarry_picket_dorn`, `relay_picket_hess`, `pasture_drover_juno`,
  `lost_creature_rue`, `stronghold_patrol`.

The captain rebalance addressed exactly two rungs. Nine others have the same
shape and were not touched.

---

## 3. Does the type chart read?

### 3.1 Four staged, non-mirror wild fights

`tools/_probe_combat_matchup.gd`, SPACER pilot, every creature level 12, every
fight walked to and engaged with `interact` on the same patch of meadow.

| ally → foe | chart | HUD arrow | damage per hit | blows to kill | fight | damage taken | HP at the end |
|---|---|---|---|---|---|---|---|
| ripplet → burrowback | **1.25** | ▲ +1 | **18.7** | 11 | 10.2s | 27.6 | 84% |
| ripplet → mosshell | 1.00 | +0 | 15.4 | 15 | 13.3s | 35.6 | 80% |
| trailpup → burrowback | 1.00 | +0 | 15.3 | 15 | 14.2s | 16.9 | 90% |
| galewisp → burrowback | **0.80** | ▼ −1 | **12.2** | 16 | 14.6s | 69.2 | **55%** |

**The chart reaches the damage, exactly.** 18.7 / 15.35 / 12.2 against the
1.25 / 1.00 / 0.80 the chart promises is a match to within the ±10 % variance —
this is measured out of a played fight, not read off a table.

**The HUD arrow agreed with an independent lookup in all four fights.**

**The exchange is where the chart bites, not the damage.** Compare the two
attackers against the same Burrowback: `trailpup` (neutral both ways) finishes
at 90 % health, `galewisp` (0.80 out, 1.25 in) at 55 %. Four times the damage
taken. The type system's real teeth are the *exchange ratio*, which is what
T3-TYPECHART designed for and what a player feels as "I am losing this".

**And yet:** the player won all four, including the doubly-bad one, at 55 %
health. A bad matchup in a wild fight costs health and about four seconds. It
does not cost the fight. See §7.

### 3.2 The banner told the player 22 times in a 14.6-second fight

The verdict banner is how the chart is taught — there is no tutorial, no matchup
screen, and no codex (`grep` for `type_chart`: it is referenced by
`combat_manager`, `combat_math`, `move_db` and `ui_tokens`, and nothing else).
The probe counted what the HUD handler actually received:

| fight | verdict events | over | banner-time at 0.7s each |
|---|---|---|---|
| ripplet → burrowback | 11 (all `+1`) | 10.2s | 7.7s — **75 % of the fight** |
| galewisp → burrowback | 16 `−1` on the foe **plus** 6 `+1` on the ally | 14.6s | 15.4s — **more banner than fight**, alternating between "WEAK — it shrugged that off" and "it hit YOUR weakness" |

`combat_hud.gd`'s own comment already states the rule — *"a banner that fires on
every blow is a banner nobody reads"* — and then fires on every blow, because it
was written for the case where most hits are neutral and a non-mirror matchup
makes **every** hit non-neutral.

**Fixed** (`scripts/ui/combat_hud.gd`, `data/config/combat.json`): a verdict is a
fact about the pairing, not about the swing. It is now said when it becomes
true, again if it changes direction, and again after
`effect_banner.repeat_seconds` (6.0, tunable) for a player who looked away — and
re-armed by a new fight and by a mid-fight switch, so every creature a trainer
sends out is still judged fresh and no verdict the player has not been given can
be silenced.

### 3.3 What the player actually has to read a fight with

Not a defect list — this is the channel inventory, verified in the code and on
disk:

| channel | state |
|---|---|
| type verdict banner | present; was firing continuously, now paced (§3.2) |
| effectiveness in the **mix** | real and well-formed: `impact_weak` / `impact_normal` / `impact_super`, three variants each, genuinely distinct files (19 KB / 26 KB / 40 KB — the strong hit is literally the biggest sound) |
| matchup arrow on the enemy plate | present, correct in all four fights, and shows the **best** of your two equipped moves |
| dual type on the plate | present (`GROUND/FIRE`) |
| wind-up telegraph | a red ring at the opponent's feet for exactly the wind-up beat |
| impact flash | coloured by the **move's element**, sized by quick vs charged — not by effectiveness (the mix carries that) |
| **damage numbers** | **none anywhere.** The only magnitude channel is the HP bar |

The last row is the honest limit on §I1's *"legible in the moment"*: a player can
tell **that** a hit was strong, and cannot tell **how** strong. With chart
magnitudes of 1.25 / 0.80 and a ±10 % damage roll, the difference between a good
and a bad matchup is roughly one extra blow in fifteen. That is real, and it is
below the resolution of a health bar. Changing either the magnitudes or adding
damage numbers is an owner call — flagged in §8, not made here.

*(sections 4 onward: the ladder, the captains, the verdict)*
