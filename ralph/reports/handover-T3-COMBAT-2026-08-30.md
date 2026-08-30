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

## 0. The answer, before the working

**87 authored trainer battles were fought — the whole ladder three times, by two
different pilots and two different teams — and not one of them was lost. No
creature ever fainted. The four creatures behind the lead never came out.**

- The type chart **works and reads**: damage matches the chart exactly in played
  fights, the HUD arrow was right every time, and the mix carries effectiveness
  in three genuinely distinct sounds. Its verdict banner was firing on *every
  blow* — 22 events in a 14.6-second fight — and is now paced. **Fixed.**
- The captain rebalance **changed the config and not the fights**: one captain
  got marginally *easier* for the exact team it was written to stop, the other
  got five seconds longer and still landed zero blows.
- The reason nothing is dangerous is one number: **0.5 metres of backward
  movement defeats every attack in the game**, and a creature has 3.08 m of
  travel available during a wind-up to cover it.
- `smoke_combat.gd` was grading the type system on a **mirror matchup** and said
  so in its own comment. It now fights Water into Ground and **measures the
  damage** — verified to fail when the chart is patched out, and to pass on
  shipping code. **Fixed.**

Where it stops being fun: **at the end of Band 1.** For a player who never
learns to sidestep, the most expensive fight in the chapter is the *village
tournament final* — and the four bands after it never exceed it.

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

## 4. Did the captain rebalance change the fights?

`tools/_probe_captain_rebalance.gd`. Each captain fought twice, back to back,
same challenger at level 15 (the level `chapter_curve.json` puts the player at
when they reach Band 4's captains), same pilot, same ground. The "pre-rebalance"
roster is the swap the trainers file's own `_why_t3_typechart_rebalance` note
describes, put back.

### Field Captain, met by the mono-Water team the rebalance exists to stop

| roster | result | fight | party HP left | damage taken | verdicts on them |
|---|---|---|---|---|---|
| **shipped** (duskhush / tuskroot / meadowhart) | won | 30.9s | **95.3 %** | 27.4 over 4 hits | 22 strong, 13 weak |
| **pre-rebalance** (burrowback / tuskroot / meadowhart) | won | 29.0s | **92.5 %** | 43.7 over 6 hits | 32 strong, 0 weak |

**The rebalance made this fight slightly easier for the exact challenger it was
written to stop.** The verdict mix moved precisely as designed — a third of the
player's hits went from strong to resisted — and the Water team came out of the
shipped roster **healthier** than out of the old one, taking 27.4 damage instead
of 43.7.

The reason is in the stats, not the chart. The swap took out the *weakest*
member by level and put in a creature that is also weaker in raw numbers:
**Burrowback is 110 HP / 23 defence, Duskhush is 96 / 18.** Removing a −35 %
discount from one of three opponents is worth less than 14 hit points and 5
defence. And Duskhush's own Air move is 1.25 into Water, but it never landed one
— every blow the player took in either fight was a resisted Ground hit from
Tuskroot and Meadowhart.

Run twice, on separate boots, with the same direction both times (93.9 % vs
93.1 % on the first run; 95.3 % vs 92.5 % on the second).

### Ridge Captain, met by the mono-Ground team

| roster | result | fight | party HP left | damage taken |
|---|---|---|---|---|
| **shipped** (trailpup / duskhush / galecrest) | won | 32.4s | **100.0 %** | **0.0 over 0 hits** |
| **pre-rebalance** (pipwing / duskhush / galecrest) | won | 27.7s | **100.0 %** | **0.0 over 0 hits** |

Here the swap went the other way — Pipwing (78 / 20 / 10) out, Trailpup
(105 / 23 / 15) in — so the fight genuinely got 4.7 seconds longer. And in both
versions one of the chapter's three Sigil captains **did not land a single blow
in a three-round battle**.

### The answer

*Does the captain rebalance actually change the fights it was authored to
change, or only the config?* **Only the config.** One captain became marginally
easier for the team it was meant to punish; the other became five seconds longer
and stayed untouchable. The swaps do exactly what their notes say to the
multipliers — the multipliers were never what made those fights easy. See §5.

---

## 5. The thing under all of it: 0.5 metres beats every attack in the game

This is the largest finding of the lane, and it explains most of the numbers
above.

`combat_ai.gd` commits the opponent to its wind-up on purpose, and says why:
*"An enemy that can cancel its own telegraph makes the telegraph worthless."*
`combat_manager.gd::_on_enemy_strike()` then tests whether the blow connects
from the position the creature was standing in when the wind-up finished.
D07 is explicit that this is the design — *"There is still no dodge button:
movement is the dodge."*

The trouble is how little movement that takes. Working it out for the two
creatures the Ridge fight actually put on the field, from `combat.json`:

- the opponent holds station at `preferred_range`, floored to
  `(r_mine + r_theirs) × body_clearance` — for Trailpup (0.43) and Galecrest
  (0.65) that is **2.97 m**;
- its swing reaches `preferred_range + 0.5` = **3.47 m**;
- so the gap between where it stands and where its reach ends is **0.5 m**,
  and it always is, for every pair of creatures in the game, because both
  numbers are derived from the same product;
- a creature moves at `creature_movement.speed` 5.6 m/s, and the wind-up lasts
  `enemy.telegraph` 0.55 s — **3.08 m of travel available to cover a 0.5 m
  requirement.**

A player who learns one thing — *step back when the ring lights* — becomes
literally unhittable, with six times the movement they need. That is what the
SPACER pilot is: not a superhuman reflex test, a creature walking backwards for
a third of a second. It took **zero** damage from a regional captain.

**This is flagged, not fixed.** Every way of closing it changes a combat
mechanic: making the strike resolve from the post-lunge position would give
attacks tracking; shortening the telegraph or widening reach trades against
readability; and `CLAUDE.md` names dodge/block as an owner decision, which this
is the other side of. The numbers above are what an owner would need to pick
between those.

What it means for everything else in this report: **the ladder's difficulty is
almost entirely "have you noticed the wind-up ring yet"**, and type advantage,
levels and team composition are all second-order to it. §6 measures both sides
of that.

---

## 6. `smoke_combat.gd`: a check that can now actually fail

### What was wrong with it

The file adopted a `terrapup` (Ground) and walked to the practice cluster
(`spawns.json`'s `roles.practice` → `bramblebun`, Ground). **Ground into Ground
is 1.00 in both directions**, so every fight this file has ever graded the type
system on was a mirror — and its own comment said so:

> *"a mirror matchup (verdicts all 0) is a legitimate run"*

Its type assertions all check **agreement**: the verdict the fight emitted equals
an independent lookup. On a mirror, every expected value is 0 and every reported
value is 0, so they pass identically with the type system switched off.

### What it does now

1. `_ensure_ally()` adopts a **`ripplet`** — Water into Ground is 1.25 one way
   and 0.80 the other, so the same walk, the same engage and the same fight now
   carry a verdict in both directions. **No extra runtime**: it is the same
   fight, against the same opponent, at the same point in the file.
2. The pairing itself is asserted. If a `spawns.json` role edit or a typing
   change collapses this fight back to a mirror, it **fails and names the fix**
   rather than quietly grading nothing again.
3. `_the_advantage_was_worth_what_the_chart_promised()` measures the **damage**.
   Every blow that lands is recorded with which button threw it, and summed
   against a prediction built from the real `combat_math.base_damage` over the
   real stats of the two creatures that actually met — once with the chart, once
   without.

### Proof that it fails

Both damage call sites in `combat_manager.gd` were patched to pass `1.0` instead
of `type_mult` — leaving the verdict signals and the HUD arrow completely
untouched, which is the regression shape the old check could not see — and the
test was run:

```
type chart reached the fight: 3 verdicts, ally water vs foe ground (hit 1 / -1, arrow 1)
9 blows landed for 127.4 damage (the chart says 162.6; a chart-less fight would say 130.1)
combat FAIL: 9 blows dealt 127.4 damage, but water into ground (quick x1.2500,
  charged x1.2500) should have dealt 162.6 — and a fight with no type chart at
  all would have dealt 130.1. The multiplier the HUD advertises is not the one
  the damage is resolved with.
```

Observed 127.4 against a chart-less prediction of 130.1: a 2 % match to the
broken build, 22 % away from the correct one. **Every pre-existing assertion in
the file passed on that patched build** — the verdicts were still emitted, the
arrow was still `+1` — and only the new check caught it.

`combat_manager.gd` was then restored from backup (`git diff` clean, byte-
identical to the branch point) and the same test re-run on the shipping code:

```
type chart reached the fight: 3 verdicts, ally water vs foe ground (hit 1 / -1, arrow 1)
6 blows landed for 129.9 damage (the chart says 123.4; a chart-less fight would say 98.7)
combat: OK — a fight can be entered, piloted, won and left.
```

Observed within 5.3 % of the correct prediction against a 12 % tolerance, and
32 % clear of the chart-less one. Both directions verified: **it passes what
should pass and fails what should fail.**

### Is the tolerance marginal? No — three clean runs

`damage.variance` is ±10 % per hit, so the check's headroom is worth measuring
rather than assuming. Three separate runs on shipping code:

| run | blows | observed | chart says | chart-less would say | deviation |
|---|---|---|---|---|---|
| 1 | 6 | 129.9 | 123.4 | 98.7 | +5.3 % |
| 2 | 6 | 126.2 | 123.4 | 98.7 | +2.3 % |
| 3 | 6 | 125.7 | 123.4 | 98.7 | +1.9 % |

Worst deviation 5.3 % against a 12 % tolerance, and every run sits 27–32 % above
the chart-less prediction the failing build landed on. The window is wide enough
not to flap in CI and narrow enough that a missing multiplier cannot hide in it.

---

## 7. The ladder, walked twice

All 29 authored rungs, in route order, at the level and party size
`chapter_curve.json` says the player arrives with, at full health, fought
through `begin_trainer_battle()` — **three times**, 87 trainer battles in all:

- **SPACER + Ground team** — reads the telegraph, catches what is in front of them
- **BRAWLER + Ground team** — walks in and hits, never looks at the telegraph
- **SPACER + Mixed team** — reads the telegraph, and prepared a type-diverse five

The Ground team is terrapup, bramblebun, mudsnout, trailpup, meadowhart. The
mixed team is terrapup, ripplet, galewisp, mosshell, duskhush.

**"Lead HP left" is the number that matters.** Switching was off in both runs and
no creature ever fainted, so only the lead creature ever fights and the party
average hides what the fight cost. It is derived from the party average and the
party size, which is exact when the bench is untouched — and it was.

### 7.1 The headline

| | BRAWLER + Ground | SPACER + Ground | SPACER + Mixed |
|---|---|---|---|
| rungs lost | **0 of 29** | **0 of 29** | **0 of 29** |
| creatures fainted | **0** | **0** | **0** |
| median fight | 23s | 28s | 28s |
| median lead HP left | 73 % | 88 % | 88 % |
| worst rung | **39 %** `tournament_final_oskar` | **70 %** `warden_aldis` | **66 %** `warden_aldis` |

**87 authored trainer battles were fought and not one of them was lost, by any
pilot, with any team.** The five-creature belt never came out: no fight in the
chapter put the lead creature low enough to need it.

### 7.2 Where it is trivial, where it is a wall, and where it stops teaching

**There is no wall.** The whole ladder, for a naive player, is a band between
95 % and 39 % lead health, and it never crosses into losing.

**The peak is in the first hour.** For BRAWLER the most expensive fight in the
chapter is `tournament_final_oskar` — a **Band 1** village tournament final, at
39 % — and nothing in the remaining four bands is harder. The Warden is second
at 44 %.

**The curve saws rather than rises.** `relay_picket_hess` (Band 3) leaves the
lead at 84 %, easier than `practice_trainer` (Band 1, 78 %). `captain_riverwatch`
(Band 3, 46 %) is harder than both Band 4 captains (66 % and 76 %) and harder
than `stronghold_elite` (69 %). A player is not steadily meeting more.

**It stops teaching after Band 1.** Bands 2–4 for the SPACER pilot sit between
79 % and 94 % lead health — twelve consecutive rungs where nothing the player
does or fails to do changes the outcome. That is where combat stops being
interesting, and it is a long way from the end.

**The Warden is, structurally, the event it should be.** It is the longest fight
in the chapter by a wide margin (61s / 73s against a 23s / 28s median), the only
five-creature roster, and — for the skilled pilot — the single most expensive
fight, at 70 % against a next-worst of 78 %. It is also the fight where **playing
well matters most**: the gap between the two pilots is 26 points there
(44 % vs 70 %), the widest on the ladder. What it is not is dangerous: neither
pilot ever came close to losing a creature.

### 7.3 Is there skill in it?

Yes, and it is worth about fifteen points of health.

SPACER finishes with a median of 88 % lead HP against BRAWLER's 73 %, so reading
the telegraph roughly halves the damage taken. It costs tempo — SPACER's fights
run about 20 % longer and it misses swings BRAWLER never does (BRAWLER records
**zero** misses on 24 of 29 rungs, because it simply stands inside reach) — which
is a real and well-shaped trade.

But the skill never decides anything, because nothing was ever at stake. And
per §5 the "skill" is 0.5 m of backward movement during a 0.55-second wind-up,
with 3.08 m of travel available to do it in.

### 7.4 Does bringing the right creatures matter?

The ladder was walked a third time with a **type-diverse** team — terrapup
(Ground), ripplet (Water), galewisp (Air), mosshell (Water), duskhush (Air) —
against the mono-Ground team, same SPACER pilot, same levels.

| | Ground team | Mixed team |
|---|---|---|
| rungs lost | 0 of 29 | 0 of 29 |
| median lead HP left | 88 % | **88 %** |
| worst rung | 70 % (`warden_aldis`) | 66 % (`warden_aldis`) |
| median fight | 28s | 28s |

**A prepared team and a naive one produce the same chapter.** The chart is
working (§3.1 shows it reaching the damage exactly), and nine rungs hand a Water
creature a 1.56× exchange for free (§2) — and none of it changes an outcome,
because none of the outcomes were ever in doubt. Type advantage is currently a
discount on a bill nobody was struggling to pay.

### 7.5 Is switching a real decision?

**No — and not because the mechanic is broken.** `switchable_indices()`,
`can_switch()` and `cycle_active()` all work, and D32's lockout is enforced. The
problem is that no fight in 58 battles ever produced a reason to press it: the
lead creature never fainted, never dropped below 39 %, and the four creatures
behind it never came out.

Two things compound into that:

1. **A single faint ends the whole trainer battle.**
   `encounter_director.gd::_on_trainer_round_ended()` treats any non-win outcome
   as the end of the battle, so the belt is not a gauntlet buffer — it is only
   useful if the player switches *before* a creature falls. `combat.json`'s
   `switch` block documents "no auto-switch-on-faint" as deliberate (D32), and
   `GAME_DESIGN.md` §14 says "trainer fights are team-vs-team", which the
   trainer's side is and the player's side is not. **Flagged, not changed** —
   whether a faint should cost the round or the battle is an owner decision.
2. **Nothing gets low enough to switch out.** Even if it did, the player would be
   switching a healthy creature in, which the current numbers never reward.

This is the finding with the most weight for the chapter's own premise. The
five-creature limit exists so each creature matters (`CLAUDE.md`, VISION §6);
in combat as played, one creature carries all 29 rungs and the other four are
XP-share recipients.

---

## 8. What this means, and what is an owner's call

### 8.1 Fixed in this lane

| what | where |
|---|---|
| The type verdict banner fired on **every blow** — 22 events in a 14.6s fight, more banner-time than fight-time. Now said once per verdict, re-armed by a new fight, a new opponent and a mid-fight switch, with a tunable repeat window. | `scripts/ui/combat_hud.gd`, `data/config/combat.json` |
| `smoke_combat.gd` graded the type system on a **mirror matchup** and said so. Now fights Water into Ground and **measures the damage**, verified to fail when the chart is switched off. | `tests/smoke_combat.gd` |

### 8.2 Flagged, not changed — these are owner decisions

1. **0.5 m of retreat beats every attack in the game** (§5). Closing it means
   giving attacks tracking, or shortening the telegraph, or widening the
   spacing — all of them changes to how dodging works, which `CLAUDE.md` puts
   on the owner's side of the line. The arithmetic and both pilots' numbers are
   in §5 and §7.3.
2. **A single faint ends a whole trainer battle** (§7.4), against
   `GAME_DESIGN.md` §14's "team-vs-team".
3. **The difficulty curve peaks in Band 1** (§7.2). Raising the back half is
   ordinary tuning, but which rungs and by how much is a design call that should
   be made against the intended 3–4 hour shape, not by this lane.
4. **Type magnitudes (1.25 / 0.80) sit below the resolution of a health bar**
   (§3.3). The chart is correct, reaches the damage, and is announced — the
   player still cannot feel the size of it, because there are no damage numbers.
   Changing either is a type-system or HUD decision.
5. **Nine rungs still field mono-Ground teams** (§2), the same shape the captain
   rebalance was written to fix on two. If that rebalance is worth repeating, it
   should be repeated with §4's finding in hand: the swap changed the
   multipliers and not the fight.

### 8.3 The one-line answer

**Combat works, reads and has a real skill in it — and it is never dangerous.**
It stops being interesting at the end of Band 1, around the village tournament,
and the four bands after it are twelve rungs where nothing the player does
changes the outcome. The Warden pulls it back at the very end: it is the longest
fight, the only full five, and the one place playing well is worth 26 points of
health. But nothing between the tournament and the stronghold gate asks the
player for anything.

---

## 9. The raw evidence

`ralph/reports/t3-combat/` holds the output every table above was built from:

| file | what |
|---|---|
| `ladder-ground-spacer.tsv` | all 29 rungs, SPACER pilot |
| `ladder-ground-brawler.tsv` | all 29 rungs, BRAWLER pilot |
| `captains.txt` | both captains × both rosters |
| `ladder-mixed-spacer.tsv` | all 29 rungs, SPACER pilot, type-diverse team |
| `matchup-spacer.txt` | the four staged non-mirror wild fights |
| `smoke-negative-chart-off.txt` | `smoke_combat.gd` failing with the chart patched out |
| `smoke-positive-shipping.txt` | the same test passing on shipping code |

To reproduce any of it (Godot 4.7, `--headless`):

```
godot --headless --path . --script tools/_probe_combat_matchup.gd
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=ground
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=ground --pilot=brawler
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=mixed
godot --headless --path . --script tools/_probe_captain_rebalance.gd
godot --headless --path . --script tests/smoke_combat.gd
```

Every one of them runs at wall-clock speed — headless Godot still steps physics
at 60 Hz — so a full ladder is about half an hour of real time. That is the cost
of driving the real input path, and it is the reason this lane's evidence is
fights rather than assertions.

---

## 10. The Warden's creatures were fighting under the arena floor

Routed to this lane by the coordinator after the reliability lane (T2-FLAKE)
found it and correctly declined to guess at a `scripts/combat/**` fix at the end
of its budget. Their diagnosis is in
`ralph/reports/handover-T2-FLAKE-2026-08-30.md` §5; I verified it against the
code and reproduced it before changing anything.

### 10.1 What it is

`combat_manager.gd::_place_fighters()` anchors both fighters off
`_player.global_position`, and `_stand_the_trainer_aside()` — the last thing that
same call does — then **moves the player**. A trainer battle calls
`combat_manager.begin()` once per creature, and the manager has no idea a
previous round existed, so round two anchors off wherever round one left the
trainer, round three off round two, and so on.

With the shipped `arena` block (`deploy_offset` 2.6, `separation` 5.0,
`radius` 11.0) the sidestep is `centre + side × 6.05 − forward × 1.2`, which is
**about 7.2 m of displacement per round**. The Warden fields five creatures.

Out past the room's slab, `built_floor.gd`'s deliberately generous 10 m claim
margin still answers the Warden Arena's floor height, so `place_on_ground()`
sets the body down on a floor that has no collider under it — and
`creature_body._physics_process()`, which grounds on `is_on_floor()` rather than
on the claim, drops it the 5.6 m to the terrain below.

**The margin is not the bug and I did not touch it**, per T2-FLAKE's explicit
warning: 10 m is already wide enough to hand a body a floor that is not there,
which is step two of the chain. The drift is the bug.

### 10.2 The fix

`encounter_director.gd` now records `_trainer_battle_anchor` — where the trainer
was standing when the battle was accepted — and restores the player to it at the
top of `_send_out_next_creature()`, **before** anything is staged off their
position (`_send_out_spot()` reads it, and so does `_place_fighters()` a few
lines later through `_start_fight()`).

The director is the right owner: it is the only thing that knows a trainer
battle is one encounter with several creatures in it. The manager stays
round-agnostic, and single wild fights are untouched.

The anchor is restored verbatim, Y included, rather than re-asking the world for
a ground height. This is not a horizontal move to somewhere new — which is what
D09's "ask the world, never carry a Y" is about — but a return to a spot the
player stood on moments earlier in the same scene, and re-asking would invite a
different answer inside a building, which is the failure being fixed.

It is deliberately **not** used to teleport the player home when the battle
ends: the trainer still finishes standing beside the fight they just won.

### 10.3 Measured

**The drift, measured in a played fight.** `tools/_probe_combat_ladder.gd` now
prints where the trainer is standing as each round of a battle opens. Fighting
the Warden's five creatures on `--only=warden_aldis`, on the **unfixed** build:

```
[drift] round 1 opens with the trainer at 54.0, -61.9 — 0.00m from where round 0 opened
[drift] round 2 opens with the trainer at 60.1, -65.8 — 7.23m from where round 1 opened
[drift] round 3 opens with the trainer at 66.2, -69.7 — 7.37m from where round 2 opened
[drift] round 4 opens with the trainer at 71.8, -73.5 — 10.18m from where round 3 opened
[drift] round 5 opens with the trainer at 70.5, -75.2 — 2.44m from where round 4 opened
```

**The Warden fight travels 21.2 m between its first round and its last** — from
(54.0, −61.9) to (70.5, −75.2) — and the per-round steps match the 7.2 m the
`arena` block predicts. This is measured in the open meadow, where there is
ground everywhere and the fight merely walks; in the Warden Arena the same 21 m
carries it off the slab, which is the reported defect.
