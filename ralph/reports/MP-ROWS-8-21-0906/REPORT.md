# MP-ROWS-8-21-0906 — rows 8 and 21 of the Stage B acceptance contract

Lane: Stage B, rows 8 (**a boss encounter together**) and 21 (**disconnect and
reconnect**) of `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` §17. Base
`claude/tetherbound-roadmap-next-jrcjs8`; pushed to `claude/mp-rows-8-21`. No
pull request.

Both rows were named in that file's "Known-open, carried deliberately" list.
This lane owned both and nothing else.

## The verdict, up front

| row | before | after |
|---|---|---|
| **8** — a boss encounter together | **owed.** No net smoke had ever put two pilots in the Warden fight; row 7's trainer payout was "an argument, not evidence" | **`smoke_net_shared_boss` — 81 checks, 0 failures, green three times consecutively.** Two processes in `warden_aldis`'s own fight at his own placed body. **Half-owed still:** the WALK to him (his arena's dialogue, the machine gate, the legendary chamber) is not covered, and §10's stat multiplier / attack cooldown reach nothing on this tree (finding F1) |
| **21** — disconnect and reconnect | **partial.** The smoke asserted the session-side restore only, and said so in its own header | **`smoke_net_reconnect_keeps_character` — 53 checks, 0 failures, green twice.** The party, satchel and player-scoped flag come back off `user://characters/<id>/character.json`, proved by blanking the process's own copy first, with a negative control. **Not half — done** |

Three deliberate breaks of production code confirmed the claims that passed on the
first try, each with the check count unchanged: HP × players (2 red), a world flag
paid per participant (2 red), and the character restore taken back out (4 red).
**Ten findings**, two of them production fixes row 21 could not exist without. §6
has every attempt, including all the reds — among them a real flake in row 8's own
shared-damage half, found on a third run and fixed at the cause rather than
re-run past (F10).

---

## 1. What shipped

| File | What |
|---|---|
| `tests/smoke_net_shared_boss.gd` | **new.** Row 8. Two real processes in `warden_aldis`'s own fight. |
| `tests/smoke_net_reconnect_keeps_character.gd` | **rewritten.** Row 21, re-pointed at `user://characters/<id>/character.json`. |
| `scripts/net/session.gd` | `_restore_character_here()` and `_adopt_character_id()` — the two production gaps row 21 needed (§4, F6 and F7). |
| `tools/net/peer_runner.gd` | probes `boss`, `character_restore`; steps `party_grant`, `save_character_here`, `wipe_character`; `place_creature` gains `exact`; `win_trainer_battle` gains `enemy_hp_ceiling` and `stop_when_creatures_left`; `strike` reports its local verdict; the verdict message gains a `data` passthrough. |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard` roster + count floor. |
| `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` | rows 8 and 21, and the two "Known-open" bullets. |

Godot 4.7-stable installed at `~/godot-bin/godot` (4.7.stable.official.5b4e0cb0f).
`--headless --path . --import` run twice before anything else; both passes exit 0
with zero `ERROR` lines.

---

## 2. Commands

```
~/godot-bin/godot --headless --path . --import          # twice, both exit 0
tools/net/run_net_smoke.sh boss_rewards_each_participant # baseline, unmodified tree
tools/net/run_net_smoke.sh shared_boss
tools/net/run_net_smoke.sh reconnect_keeps_character
~/godot-bin/godot --headless --path . --check-only --script <each edited .gd>

# CI registration, both halves
for f in tests/smoke_net_*.gd; do head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"; done | wc -l
python3 <extract every `run:` block from ci.yml> && bash -n each
```

### The count floor was REGENERATED, not incremented

`for f in ...; done | wc -l` returns **27** on this tree. The floor in
`ci.yml` was 26 and is now **27**; `tests/smoke_net_shared_boss.gd` was added to
the `for required in` roster (`reconnect_keeps_character` was already in it).

### Every `run:` block in `ci.yml` passes `bash -n`

**66 blocks extracted, 0 syntax errors.** The discovery block (ci.yml:1951) was
then *executed* standalone with a stub `GITHUB_OUTPUT`: exit 0, `found (27):`,
all 27 files listed including both of this lane's.

---

## 3. Findings

Ten. Two are **production fixes** row 21 could not exist without (F6, F7). Three
were fixed or excluded **in the harness**, because the defect was the harness's or
the measurement's rather than the game's (F2, F4, F9), and one more (F10) was fixed
at the cause after it produced a real flake. Four are recorded and **not fixed**, each with the reason at it (F1, F5, and F3/F8, which are not defects at
all but invalidate assumptions a later lane would otherwise make).

### F1 — §10's stat multiplier and attack cooldown reach NOTHING, in any trainer or boss battle. NOT FIXED.

The headline finding of this lane, and it is not row 8's own claim — row 8's
claim (never HP × players) holds. This is the other two thirds of §10 / D-MP12.

`encounter_director.gd::_scale_opponent_for_the_session()` is called from exactly
one place: `_send_out_next_creature()`, immediately after the creature is popped
off the trainer's queue and **before** `_start_fight()` opens or resumes the
encounter record. It reads its multiplier off the record, which is the right
source. But:

* for the **first** creature there is no record yet, so it returns on `_encounter`
  being empty;
* for **every creature after that**, `_resume_trainer_encounter()`'s own header
  states the condition: "`combat_manager.gd::_finish()` submits `disengage` at
  the end of EVERY round … by the time the next creature steps up, §9 has
  emptied the record's participant list and marked it `done`." An empty
  participant list means `_restamp_scaling()` has already written the row through
  `scaling_for(0)` — the identity — so the scaler reads 1.0/1.0 and returns on
  its own `is_equal_approx` guard. The re-seat that restores the row to 1.1/0.85
  runs inside `_start_fight()`, i.e. *after* the scaling call.

Measured on the Warden, at two participants, on two different creatures:

| creature | live attack | authored attack | live defence | authored defence | live cooldown | authored cooldown | record's stamped `stat_multiplier` |
|---|---|---|---|---|---|---|---|
| burrowback (1st) | 27.750 | 27.750 | 42.550 | 42.550 | 0.000 | 0.000 | 1.1 |
| galecrest (2nd) | 51.800 | 51.800 | 27.750 | 27.750 | 0.900 | 0.900 | 1.1 |

Nothing caught it because the only tests of §10 —
`tests/test_encounter_rewards.gd`'s scaling block — assert on
`ENCOUNTER_HOST.scaling_for()` (the table) and `host.scaling(id)` (the record).
**No test has ever asserted that the multiplier reaches a creature.**

Not fixed, deliberately: the call has to move to after the record is resumed, and
`_scale_opponent_for_the_session()` multiplies the instance's own
`attack`/`defence` **in place with no unscaled base kept** — so moving it without
also deciding where that base lives risks compounding the multiplier round over
round. That is lane 4.D's code and a real design decision (keep a base, or
re-derive from the species curve at each re-stamp), not a line this row may
quietly change. `smoke_net_shared_boss.gd` therefore **prints** these numbers and
asserts **no direction** on them: asserting equality would bless the defect, and
asserting inequality would go red the day it is fixed.

### F2 — `place_on_ground` puts a creature metres above the floor inside the Warden Arena. Worked around in the harness, NOT fixed in the world.

`_step_place_creature` used `place_on_ground()`, which asks the world for a
height (D09). Inside the stronghold that height is the *terrain* under the
building, not the arena floor: both creatures were placed at y 4.30 and 6.17 with
the boss standing at y −1.76, i.e. 6–8 m in the air, and every swing missed.

Worked around with a new `exact: true` argument that uses the literal
coordinates — correct for this caller, whose Y comes off the encounter record
(the boss's own height, host truth). OFF by default, so no existing caller
changes. Whether `place_on_ground` *should* answer the floor inside a building is
a world question outside this lane.

### F3 — the Warden's opening creature authors no `attack_cooldown`. Not a defect; recorded because it shapes the smoke.

`burrowback`'s `combat` block in `band5_stronghold_approach/trainers.json` names
`telegraph`, `recovery`, `power`, `chase_speed` and `reposition_distance` but not
`attack_cooldown`, so its override reads 0.0 and the scaler falls back to
`combat.json`'s `enemy_trainer` baseline. Any cooldown measurement taken on the
opener compares 0.0 to 0.0 and says nothing. The galecrest (2nd) authors 0.9,
which is why the smoke reads scaling there.

### F4 — a HOST striker's §5 refusal is unreadable through the refusal probe. Fixed in the harness.

`submit_encounter_intent()` commits synchronously on the host and returns the
verdict; only a **client's** answer arrives later through
`note_encounter_refusal()`, which is what the `encounter`/`boss` probes' `refusal`
field reads. A smoke whose striker was the host therefore saw `code: ''` while
the refusal had in fact been issued — a false red that looks exactly like a
missing feature. `_step_strike` now reports `ok`/`pending`/`code`/`reason`, and
the verdict message carries a `data` passthrough so they survive the coordinator.
Row 8's friendly-fire arm then went further and made the **client** the striker,
so the refusal has to travel back over the wire as a sentence (7.A's F7 half).

### F5 — contract §7's `state_hash` can never agree once two peers hold different PLAYER-scoped flags. NOT FIXED.

`HASHED_KEYS` includes `progression`, and `save_game.gd` writes that key as the
world's flags **merged with the local player's own** —
`tools/net/peer_runner.gd`'s own `world_snapshot` comment says it: "two peers
holding identical worlds legitimately differ there, and a smoke diffing it would
report a divergence that is not one."

7.A's reconnect smoke could ask for hash equality because its joiner held nothing
personal. This version gives the client a player-scoped flag **on purpose** —
that is the row — and measured `state hashes never agreed across peers within 600
frames` while the two peers' `Game.world_snapshot()` were identical key for key.
The background desync detector did **not** fire (exit 1, not 2), so it is a false
red in an explicit assertion rather than a harness fault; it is the same defect
either way.

Not fixed: `HASHED_KEYS` is contract §7 and every net smoke's desync detector
reads it. Splitting `progression` into its world and player halves for the hash
is a contract change with a blast radius across nine smokes, not a line for this
row. Row 21 instead asserts the thing that IS true and IS the point — both peers'
whole `world_snapshot()` agree key for key, `smoke_net_late_join_modified_world`'s
own assertion. `smoke_net_behind_character_joins_ahead_world`, the other smoke
built on divergent player flags, asks for no hash equality either.

### F6 — `character_save.gd::apply()` had no caller. FIXED (`session.gd::_restore_character_here`).

Lane 1.C wrote `apply()` as "the entry point for the multiplayer paths that have
a character id and no slot at all" and nothing ever called it. Every peer **wrote**
`user://characters/<id>/character.json` on the way out and nothing read one back,
so a rejoiner arrived as whatever its process still held in memory and a peer
whose process had restarted arrived as a blank trainer. `join()` now applies the
file before it builds its hello, so a restored character's own realm and display
name are what the peer announces. Never fatal: no id, no save system or no file
all return false, and joining as a fresh trainer is the correct outcome for a
character that has never been saved. The host does not come through here — it
loads a slot through `title_screen.gd` before it ever calls `host()`, and applying
a character over the top of that would discard the party the player just loaded.

### F7 — `join()` never told `PlayerState` which character it was joining as. FIXED (`session.gd::_adopt_character_id`).

`join(ip, port, {"character_id": X})` put `X` in `_pending_hello` and nowhere
else. The registry row, the world and every other peer knew this peer as `X`
while its own `PlayerState.character_id` stayed empty, so `_local_character_id()`
**minted** a `peer-<pid>-<usec>` id on the way out and `_save_character_here()`
wrote the character file under *that* — a file the next join by the announced id
could never find. The write and the read were addressing two different names for
one trainer. Measured before the fix: `autosave_here() left no character file
for ''`.

Only ever a stamp, never a clear, so `join()` with no summary keeps minting
exactly as it did.

### F8 — `deploy_creature` does not put anything in the party. Not a defect; recorded because it invalidates an assumption.

`encounter_director.gd::adopt_starter()` spawns the ally **body** and sets
`_ally`; it never touches `Game.party` (the opening adds the chosen creature
separately, through `party_seam.gd`). So a peer that has "deployed its own
creature" still reports a party of **zero**, and a headless peer's satchel is
**empty** — there is no starting satchel to lean on either. Row 21 therefore
grants its party through `party_seam.gd::add()` (the opening's own door, and the
place the five-creature cap is enforced) and its satchel through the existing
`storage_grant` arm.

### F9 — the boss hits the victim during a friendly-fire measurement. Excluded, not tuned around.

Row 8's friendly-fire arm asserts §5's two halves: the refusal was issued **and**
the teammate took nothing. The second is measured inside a live boss fight, and
the victim's creature is a legal target for the boss — which struck it for
**14.587 hp** inside a 30-frame settle on one run (126.287 → 111.700), turning a
green assertion red for a reason that has nothing to do with friendly fire.

Retrying until it happened to pass would be the wrong fix; so would widening the
tolerance to swallow a boss hit. The confound is **excluded** instead, using the
host's own tally: `encounter_host.gd::note_struck()` counts every participant
`pick_struck` chooses, and `host_pick_struck_participant`'s own header states that
on this path a pick IS a hit. The arm re-stages and re-swings until it gets a
window in which that tally did not move for the victim's peer, and then asserts
over that window; if it never finds one, a named assertion says so rather than
reporting the boss's damage as the friendly swing's. The refused swing is
harmless to repeat, so nothing is weakened by the retry.
### F10 — which ambient creature a joiner is bound to is a lottery, and it decided whether a swing could reach. Fixed in the harness.

`encounter_director.gd::join_encounter()` binds the joiner's manager to
`nearest_live_wild()` — whichever ambient creature happened to be closest to the
joining player — and its own combat manager then keeps pulling its creature back
to that body. Wild bodies are not replicated (the acceptance file's first
known-open), so how far that stand-in is from where the host holds the real
opponent is decided by the seeded spawn table.

**Measured: the same code, three runs.** Two landed a blow in 1–3 swings; the
third could not land one in 14 (`202.7 → 202.7`), because that run's nearest wild
was further away. That is a flake, and re-running past it would be turning
0-for-1 into green.

Fixed at the cause rather than the symptom, in two parts:

* a new `place_stand_in` arm moves the JOINER's local stand-in onto where the host
  says the opponent is, so the joiner's local view agrees with the host's. It
  changes no outcome — protocol §2 resolves every strike against host positions,
  which is what makes the drift cosmetic in the first place — and it is what wild
  replication will do for free when it lands. The arm **refuses on the host**,
  where that body is the authoritative one, rather than quietly letting a smoke
  teleport the creature everyone is fighting;
* the swing loop no longer aims from where a creature was ASKED to stand. It reads
  where the **host** holds it (`deployed_creatures` on peer 0 for the joiner, the
  `encounter` probe for the host's own) and submits only once that is within
  `SWING_REACH_M` of the boss. An attempt spent waiting for the host's view to
  catch up is counted as a re-place, not as a wasted swing, and both numbers plus
  the last measured gap are reported in the assertion.


---

## 4. Row 8 — `tests/smoke_net_shared_boss.gd`

**The fight proved: `warden_aldis`.** Rank `warden`, the only entry in
`trainers.json`'s `boss_ranks`, five creatures at levels 18/18/19/19/20, so the
record is stamped `kind: "boss"` by `encounter_director.gd:2941`. It is driven
through `begin_trainer_battle()` — the same call `stronghold_climax.gd` makes and
`smoke_boss.gd` drives — and `_trainer_body_named("warden_aldis")` **finds his
placed body**, so peer 0 is teleported to his post and the fight runs inside the
stronghold (measured: the opponent record's position at z ≈ 7665–7668, peer 1
teleported to (16.85, −1.76, 7668.02)). No fallback target was needed; the
Cloudreach finale and the captains were not used.

**What is NOT proved, and it is named in the acceptance row too:** the WALK. The
Warden Arena's dialogue, the machine gate behind him and the legendary chamber are
`smoke_boss.gd`'s solo ground; no net smoke enters them.

### The five assertions, and why none is row 7's

Row 7 (`smoke_net_boss_rewards_each_participant`) owns the per-participant
payout. This file asserts **no coin, no potion, no item receipt and no XP** —
nothing that row is evidence for. What it asserts instead:

1. **ONE record, not two fights.** Peer 0 challenges; peer 1 joins that
   `encounter_id` (§6). The host's record holds 2 participants and is still the
   id the challenge minted, before and after a round change (a round swaps the
   opponent, never the record). Peer 1's `bound_id` is that id while its own
   `trainer_battle_active` is FALSE, its `trainer_battle_id` is empty and its
   `trainer_creatures_left` is 0 — it is in the Warden's fight without running
   one. Two peers each running their own Warden battle would satisfy "both fought
   the boss" and is the failure this is against.
2. **The boss's HP is host truth.** Both peers place their creature beside where
   the host holds the boss and submit a real `strike_intent`; the same number
   falls; both peers read it equal to the thousandth. Measured: 212.1 → 203.0 by
   peer 0, → 194.4 by peer 1, host and guest agreeing at every step.
3. **Never HP × players** (§10 / D-MP12), at both moments it could fire:
   * when the second player **arrives** — the record's scaling row moves to the
     two-player one on that same commit, and the creature already on the field
     keeps its authored `hp_max` (222.200, not 244.420);
   * when the next creature is **sent out** with two participants already in the
     fight — `max_hp` on the instance AND `hp_max` on the record are both the
     authored 212.100, not 233.310.
   The multiplier is read by the smoke **straight out of
   `data/config/multiplayer.json`**, not through `encounter_host.gd::scaling_for()`,
   so a code/config divergence fails here instead of agreeing with itself. The
   configured row is asserted to name **only** `stat_multiplier` and
   `attack_cooldown_multiplier`, so a new `hp_multiplier` key fails on the data
   alone. And `configured_stat > 1.0` is asserted **first**, because at 1.0 every
   comparison is authored-against-itself and would pass a build that scaled
   nothing.
4. **The world fact happens once.** All three of the Warden's flags are
   world-scoped in `data/progression/flag_scopes.json`: `defeated_warden` plus
   `realm_key_cloudreach` and `realm_heart_meadows_earned` from his
   `reward.flags`. All three land on **both** peers, neither peer is offered a
   second Warden fight, and **no peer carries a
   `reward:trainer:warden_aldis:flag:<flag>:<peer>` receipt** — 0 of 2, twice.
   That is the discriminating half: a flag paid the way coins are would leave one
   receipt per participant, which is exactly what row 7 asserts *exists* for
   coins.
5. **Friendly fire between the two pilots is refused,** in the boss fight and not
   only a wild one: `friendly_target` with a non-empty sentence that travelled
   back to the client that swung, the teammate's creature untouched and the boss
   untouched, over a window the boss itself did not act in (see F9).

The `enemy_hp_ceiling` allowance used to finish the remaining creatures is
`smoke_boss.gd`'s own, by its own name and reason ("the opponent's HP is pulled
low so a level-1 starter can finish a level-20 ace inside a CI budget: this test
is about WIRING, not balance"). It touches `hp` only, never `max_hp`, `attack` or
`defence`, and every scaling read happens before it is applied. Measured cost:
the whole team of five goes down in **856–898 frames / 7–8 swings**.

## 5. Row 21 — `tests/smoke_net_reconnect_keeps_character.gd`

The old version's own header said it: everything that survived the reconnect
survived "by not having gone away, not by being restored". Two things make this
version assert the file.

**The production fix (F6, F7).** `join()` now stamps the joined `character_id`
onto `PlayerState` and applies `user://characters/<id>/character.json` if there is
one, before it builds its hello — so a restored character's own realm and display
name are what the peer announces.

**The falsifiability step.** Between the write and the rejoin, the peer's
in-memory character is blanked with the game's own loader
(`PlayerState.load_data({})`, which clears the party, the satchel, the player
flags, the pose and the maps and returns satiety to 100 — the state a freshly
booted process holds), **leaving the file alone**. The smoke asserts, in the same
step, that the process now holds nothing AND that the file still holds
everything: *the file is now the only copy on this machine*. Then it rejoins.

Measured across the reconnect:

| | before the drop | after the blanking | after the rejoin | the file |
|---|---|---|---|---|
| party | `["bramblebun@3"]` | `[]` | `["bramblebun@3"]` | `["bramblebun@3"]` |
| satchel | `{orb_basic: 2, potion_small: 3}` | `{}` | `{orb_basic: 2, potion_small: 3}` | same |
| `player_slept_at_home` | held | gone | held | held |
| satiety | 99.9258 | 100.0 | 99.9258 | 99.9258 |

Plus 7.A's own assertions, kept: one registry row for that character under a
**new** ENet peer id, the host mapping the id to that new peer, the peer not
receiving the host's world change while it was gone and receiving it on the
rejoin, and — replacing the hash check, see F5 — both peers' whole
`Game.world_snapshot()` identical key for key.

**Negative control.** The same drop and blanking, then a rejoin as
`reconnect-smoke-never-saved`, an id with no file: the peer comes back with no
party, no satchel and no flag. So "the state returned" is not something the
drop/blank/rejoin sequence produces on its own.

The player-scoped flag is **waited for**, not read on the next line: a client's
`grant_player_flag` answers `{"ok": false, "pending": true}` — the host being
ASKED, not a refusal — and one run read the store before the grant arrived. That
was a race in the smoke, not a defect in the grant.

---

## 6. Every assertion was seen red first

Two ways, and both are reported: the reds that happened **on their own** while the
smokes were being written (those are findings F1–F4, F7–F9 above, each measured),
and three **deliberate breaks** of production code for the claims that passed
first time. The check count is reported on every run, and a break that made a run
execute FEWER checks would be aborting the function rather than failing it.

### How the count is taken

`net_harness.gd::finish()` **re-prints every failure** after the run, so a raw
`grep -c '^PASS:\|^FAIL:'` over-counts a failing run by exactly the number of
distinct failures. Every number below is `lines − unique failures`, i.e. the real
number of `check()` calls executed. Getting this wrong is how a break that aborted
a function could be mistaken for one that failed it.

### The three breaks

| break | what was broken | result |
|---|---|---|
| **B1** | `_send_out_next_creature()` multiplies `max_hp` by the participant-count `stat_multiplier` — HP × players, in the place a future edit would make it | **80 checks, 2 failures against that revision's green 80** — exactly the two HP assertions, at the value the assertion's own message predicted: `record 233.310, authored 212.100` and `live 233.310; … folded into hp would give 233.310`. Run twice: 79-vs-79 on an earlier revision, then 80-vs-80 |
| **B2** | `encounter_rewards.gd::grants_for()` stops skipping world-scoped reward flags, so they are paid per participant the way coins are | **80 checks, 2 failures against that revision's green 80** — exactly the two world-fact assertions: `found 2 of 2: {"1": true, "142837648": true}` |
| **B3** | `_restore_character_here()` taken back out of `join()` — the state of the tree before this lane. The file is still written; nothing reads it | **53 checks, 4 failures** against green's **53**, the count identical, and 53 is also the final green — the party, the satchel, the player flag and the whole-view comparison all red, with the failure text showing the file still holding `["bramblebun@3"]`, `{orb_basic: 2, potion_small: 3}` and the flag while the process held none of it. Run twice, against an earlier revision of the smoke (52 vs that revision's green 52) and against the final one |

B1 turned the **send-out** HP assertion red and not the **arrival** one, because
for the first creature there is no record yet and the break's multiplier resolved
to 1.0 there — which is finding F1 showing through the break. The arrival
assertion is the same claim at a different moment and is reported as covered by
B1's sibling rather than independently broken.

Each break is compared against the green of **the revision it was run on**, which
is the comparison that means anything: the counts are 79/79 and 80/80 for row 8's
breaks and 52/52 then 53/53 for row 21's, and the smoke gained one check after
those runs when F10 was fixed (the final green is 81). A break's value is that it
turned specific assertions red without changing how many ran; re-running all three
against the final revision would not add to that, and the two that were re-run did
not change their verdict.

Every break was applied and reverted by a script (`break1.py` / `break2.py` /
`break3.py`, `apply` / `revert`), each verified to compile before use, and
`git status` was checked clean of them afterwards.

### Every attempt, including the reds and what each one meant

Baseline first, on the **unmodified** tree, to prove the harness works on this box
before trusting anything: `smoke_net_boss_rewards_each_participant` — **38 checks,
0 failures, exit 0, first attempt.** (The acceptance file's cell for row 7 says
"30 checks"; 38 is what this box measured today. Reported as measured.)

| run | checks | failures | what it meant |
|---|---|---|---|
| row 8 #1 | 79 | 5 | **findings, not noise.** §10's attack/defence never applied (F1); the opening burrowback authors no cooldown (F3); peer 1 could not land a blow and the two creatures settled 7.36 m apart — both the ground query inside the arena (F2) |
| row 8 #2 | 83 | 6 | `exact` placement not yet in; the friendly pair settled 10.33 m apart and the refusal read as absent — the failure that looks like the feature working |
| row 8 #3 | 80 | 5 | `exact` fixed the strikes (peer 1 landed a blow in 1 swing). Remaining: F1, and a host striker's refusal unreadable through the probe (F4) |
| row 8 #4 | 79 | 1 | F4 fixed by making the client the striker; the one red was the `pending` field being dropped by the coordinator, which is why the verdict message gained `data` |
| row 8 #5 | 79 | 1 | the boss struck the victim for 14.587 hp inside the measurement window (F9) |
| row 8 #6 | 80 | 1 | after the F9 fix and two greens, a THIRD run could not land peer 1's blow in 14 swings (`202.7 -> 202.7`) — finding F10, a real flake from which ambient wild the joiner was bound to, fixed at the cause |
| **row 8 final** | **81** | **0** | green **three times consecutively**, 81 checks every time, exit 0. The friendly-fire staging needed 4, 1 and 1 attempts |
| row 21 #1 | 49 | 8 | **findings.** `join()` never stamped the character id, so `autosave_here()` wrote nothing for `''` (F7); `deploy_creature` leaves the party empty and a headless peer's satchel is empty (F8) |
| row 21 #2 | 51 | 2 | party/satchel/flag all restored off the file and the negative control clean; the reds were the `progression` state-hash false divergence (F5) |
| row 21 #3 | 52 | 1 | F5 replaced with the whole-world diff; the red was reading the player flag before the host's `pending` grant landed — a race in the smoke |
| **row 21 final** | **53** | **0** | green after adding the `wait_flag`; **green twice**, 53 checks both times, exit 0 |

No run's failure was cleared by re-running it. Every red above was cleared by a
change to the smoke, the harness or production code, and each is accounted for.

---

## 7. Harness additions, and why each is production-faithful

| addition | what it does | why it is not a shortcut |
|---|---|---|
| step `place_stand_in` | moves a JOINER's local stand-in onto where the host holds the opponent | protocol §2 resolves every strike against host positions, so this changes no outcome — it makes the joiner's local view agree with the host's, which is what wild replication will do for free. Refuses **on the host**, where that body is the authoritative one |
| probe `boss` | the host record, the creature on the field, the same team entry rebuilt **unscaled**, the stamped scaling row, the host's `struck_counts` tally, and the last refusal | the "authored" side is re-derived through the production `trainer_npc.gd::creature_for()`, which is fully deterministic (`from_species` rolls no level, no IV, no trait), so it is the same authored source the fight read — a species retune moves both sides together instead of turning the smoke into a false red, while hp against attack/defence still cannot move together |
| probe `character_restore` | what the process holds in memory and what the character file holds, side by side, never merged | the whole point of row 21 is which of the two a party came from; merging them is what made the old smoke unfalsifiable. The satchel is the WHOLE satchel through `gate_f_probe.gd::inventory_snapshot`, not a list of named items, so the comparison is total |
| step `party_grant` | puts a creature in the party through `party_seam.gd::add()` | that file's own header calls itself "the one place the opening sequence touches the party", so this is the production door and not a poke at `autoload/party.gd`. The five-creature cap is `party.add()`'s and it is the thing being called, so a sixth is refused here exactly as everywhere else — and the refusal is reported |
| step `save_character_here` | `Game.autosave_here()` | D100's own routing, which on a client is exactly `session.gd::_save_character_here()` — the call a real disconnect makes. A step that called `save_character()` itself would test the harness's idea of how a character is written |
| step `wipe_character` | `PlayerState.load_data({})` | the game's own loader, so what is left is exactly the blank character a freshly booted process holds. `character_id` is preserved, because the id is how the rejoin finds the file |
| `place_creature`'s `exact` | uses the literal coordinates instead of `place_on_ground()` | the caller's Y comes off the encounter record — the opponent's own height, host truth. OFF by default; see F2 |
| `win_trainer_battle`'s `enemy_hp_ceiling` | `smoke_boss.gd`'s wiring-not-balance allowance | same name, same reason, `hp` only and never `max_hp`. OFF by default (0.0), so row 7's run is byte-for-byte the fight it was |
| `win_trainer_battle`'s `stop_when_creatures_left` | stops with N of their creatures still queued | checked BEFORE the ceiling, so an early stop hands the caller a creature at full health. −1 (the default) fights to the end |
| `strike`'s local verdict + the verdict message's `data` | `ok` / `pending` / `code` / `reason` survive the coordinator | see F4. `pending` is carried through verbatim, because a client's `{"ok": false, "pending": true}` is the host being asked and not the host saying no. `{}` when a step names no `data`, so every existing step is unchanged on the wire |

`Game.is_multi_peer()` is what the new code asks; `multiplayer.is_server()` is not
called anywhere in this lane. `int(null)` / `bool(null)` are avoided by every new
probe returning a shaped default (`{}`, `Vector3.INF`, `-1`) rather than `null`,
with the sentinel documented at each one.

## 8. What is still owed, and what this lane did not touch

**Owed on row 8:**

* the WALK to the Warden — his arena's dialogue, the machine gate and the
  legendary chamber remain solo-only ground;
* §10's stat multiplier and attack cooldown reach nothing (F1). Row 8's own claim
  is unaffected; §10 as a whole is not satisfied by this tree.

**Owed on row 21:** nothing this lane can see. The row reads the file, the file is
proved to be the source, and the negative control holds. The
`reconnect_window_s`-is-not-a-timer finding is 7.A's and is carried forward
unchanged in both the smoke's header and the acceptance file.

**Not touched, per the lane brief:** `Game.enter_realm()`, `session.gd`'s realm
paths and everything under the realm shell. `session.gd`'s diff is `join()`'s
character adoption/restore plus two new private functions; `_teardown()`,
`leave()`, `_save_character_here()` and every realm call are unchanged.

**For whoever owns `docs/CURRENT_STATE.md`:** F1 is a game defect, not a harness
one — D-MP12's difficulty scaling is inert in every trainer and boss battle — and
belongs in that file's ranked list. This lane deliberately did not edit it: the
brief scoped this lane's doc edits to the two acceptance rows and their
"Known-open" bullets, and CURRENT_STATE is another lane's ledger this wave. It is
recorded in both places this lane does own.

**Not fixed, deliberately, with the reason at each:** F1 (§10's multiplier — lane
4.D's code, needs an unscaled base decided), F2 (`place_on_ground` inside a
building — a world question), F5 (`progression` in `HASHED_KEYS` — a contract §7
change reaching nine smokes), F3 and F8 (not defects; recorded because they
invalidate assumptions a later lane would otherwise make).

**Shard cost.** Measured on this box from the run id to the SUMMARY.md write:
`shared_boss` **~113 s**, `reconnect_keeps_character` **~82 s** — about
**3.3 minutes** added to `verify-multiplayer-shard`. Its `timeout-minutes: 65` was
already an estimate rather than a measurement of the shard (its own comment says
so, because the job had never run a net smoke until the discovery fix landed), so
the timeout is left alone; the first real green run is still what should correct
it, in either direction.

**Sanity on the rest of the shard:** the baseline run of
`smoke_net_boss_rewards_each_participant` on the unmodified tree is the only other
net smoke this lane exercised. The `enemy_hp_ceiling` and
`stop_when_creatures_left` defaults keep it, and every other caller of the changed
arms, on exactly the path it had; the `data` key is additive on the wire; `exact`
is off by default. `session.gd::join()` is the one production path that behaves
differently, and it only differs when a character file exists for the id being
joined — which is never true on a first join, and no existing net smoke joins
twice in one process.
