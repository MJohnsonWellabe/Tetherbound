# Gate F leg S03 — what was real, what dissolved, and what is still open

**Lane:** `ralph/GATE-F-LEG-S03`. **Date:** 2026-08-31.
**Base:** `453107fb` (`main`), the same candidate `ralph/reports/gate-f-full`
measured. **Mandate:** drive and FIX segment S03, the village tutorial ladder.

This lane was told to verify each diagnosed defect before fixing it. Two were
real and are fixed. One dissolved on inspection and took most of a third with
it. One is an owner decision the audit was right to refuse, and this lane
refuses it too, for a reason the audit did not have. One is a hard blocker
owned by another lane and is why the real run has not happened yet.

---

## 1. The headline: S03's own step script was measuring a game that no longer ships

`FIRST-HOUR-FUN-REBUILD` changed three shipped numbers. None of them reached
`tools/gate_f/segments/S03.json`, and the audit read the stale script as
evidence about the game.

| | S03.json asked for | the game actually ships |
|---|---|---|
| team size | 3 (`party_size min: 3`) | **5** — `tournament.json` `entry.min_party_size` |
| the "home" | camp + floor + wall + door + roof | **one Camp** — `progression.json` `home.required_pieces` |
| creature beds | **three** (`creature_bed_built_3`) | **one** — `objectives.json` `tournament_build_creature_beds` |

**`min_party_size` was already 5 on `453107fb` itself** — verified with
`git show 453107fb:data/config/tournament.json`. `DEFECTS.md`'s GAME-F3 says
"*`tournament.json` requires `min_party_size: 3`*"; that statement is wrong
about its own candidate. The shipped config has said five since `71cb20d14`,
and `objectives.json` says it in words: *"Build your full team of five for the
village tournament."*

`objectives.json` is equally explicit about the other two: `tournament_build_home`
is *"Make camp for your team"* with *"no wall, roof or door requirement"*, and
`tournament_build_creature_beds` calls one bed *"the mandatory care lesson and
tournament proof"*, with `tests/test_quest_log.gd` asserting the rung *"must
not require one bed per tournament entrant"*.

---

## 2. GAME-F5 — **dissolved**, and it was a rig bug, not an economy shortfall

GAME-F5 measured the village's gathering budget against what S03.json builds.
Against what the game requires, the arithmetic inverts.

| | wood | stone | fiber |
|---|---:|---:|---:|
| available — twenty village nodes, one pass | 28 | 9 | 32 |
| **needed** — what S03.json built (camp+floor+wall+door+roof + 3 beds) | 45 | 17 | 34 |
| **needed** — what the game asks for (camp ×1 + creature_bed ×1) | **18** | **8** | **18** |
| margin against the real bill | **+10** | **+1** | **+14** |

Costs read from `data/items/buildables.json` through the same
`home_progress.gd::materials_threshold()` the game itself uses. One sweep of the
twenty authored nodes pays for the opening's build rung with room to spare, and
GAME-F5's "2 wood and 2 fiber short on the *minimum*" was measured against a
three-bed minimum the game stopped asking for.

**What is real, and is new:** the stone margin is **one node wide**. The village
authors only three stone nodes (9 stone) against a bill of 8 — and one of those
three was GAME-F1's stray. See §3: the two defects are the same defect.

GAME-F5's open question — *eleven `gather` events across eighteen reached
nodes* — is **not** answered here and is still worth a lane. It is now a
question about instrument reliability rather than about the economy, because
the economy clears.

---

## 3. GAME-F1 — **real, fixed**, and it was load-bearing on the economy

`(44,−24)` and `(52,−30)` stood 2.30 m and 3.54 m outside
`village_boundary.json`'s outline (measured point-in-polygon, not by eye). The
fence is a hard `StaticBody3D`.

Moved inward to `(40.5,−28.0)` and `(47.0,−34.5)` — 4.3 m and 7.1 m, each at
least 3 m clear of the line, 4 m from every other node, and still outside the
practice cluster's 15 m disc. Item, amount, label, model and order unchanged, so
the gathering budget is untouched.

**The half the audit did not name:** `(52,−30)` is a **stone** node, one of the
village's only three. With it unreachable, reachable stone was **6 against a
bill of 8** — the opening's build rung was unaffordable, and no number anywhere
was wrong. GAME-F1 and GAME-F5 were the same defect seen from two ends.

**Recurrence guard.** `tests/test_village_boundary.gd` gains two tests. They read
the live `harvest.json` rather than copying coordinates (a copy would keep
checking the old spot after a node moved) and keep the human decision in the
COUNT — adding or removing a village node fails until a person confirms it,
which is the review `MUST_BE_INSIDE`'s own comment exists to protect.

---

## 4. GAME-F2 — **real, fixed**, and verified in a live world

`spawns.json`'s practice cluster carried no `level`. `encounter_director.gd:438`
reads `spawn.get("level", 0)` and treats absent as "roll it", so the chapter's
teaching fight was rolling band1's `wild_band` `[2,6]` against a level-3 starter.

Restored `"level": 2` and the `_why_game_11` rationale byte-identical to
`b02f6e8f`, and re-mirrored into `tests/fixtures/band_split_baseline/spawns.json`.

**The mirror is not what makes it stick.** That fixture was reverted alongside
the live file last time, so the two agreed on the unpinned value and
`test_band_content.gd` stayed green. A baseline that moves with the thing it
baselines cannot catch a regression in it. `tests/test_practice_fight_level.gd`
now holds the number itself, finds the cluster by its authored centre rather
than by array index, and cross-checks it against the award-curve prose in
`progression.json` that states the same number independently.

**Measured in a booted world** (`tools/gate_f/diag/probe_game_f1_f2_in_world.gd`,
fresh world, no save loaded, no level-up — so GAME-F4 cannot contaminate it):

```
bramblebun L2 at (33.7, -39.8)  max_hp=93.7
bramblebun L2 at (22.3, -42.2)  max_hp=106.2
bramblebun L2 at (41.3, -48.2)  max_hp=106.2
```

93.7 max HP is exactly what run 7 measured with the pin in place, against the
124.2 this run measured without it.

---

## 5. GAME-F3 — **not a game defect on this evidence**, and the audit's second pass is factually wrong

Two corrections, then a refusal.

**(a) The 59,165 scatter props are not competing.** GAME-F3's second pass says
*"`Strip meadow grass` is the ground... it is the meadow, and 59,165 harvestable
props"*. It is not. `vegetation.gd::_spawn_harvest_point` hard-codes the scatter's
label as **`"Chop"`** (and `"Pick up"` for the felled pile). `"Strip meadow
grass"` is an **authored** `harvest.json` label, on seven authored fiber nodes.
Attempt 9 lost the button to the authored fiber node at `(34,−46)`, not to the
meadow. The defect is twenty authored nodes wide, not 59,165.

**(b) Seven of the ten failures were GAME-F2, not prompt contention.** The
second pass's own table: 1 attempt engaged, 2 lost to harvest prompts, and
**7 were refused with `"Ripplet is out of the fight."`** — the starter fainted,
because it entered S03 at 38% health, because the level pin was missing. Fixing
GAME-F2 removes 70% of GAME-F3's cascade.

**Why no priority change was made.** Four of the twenty authored village nodes
sit *inside* the practice cluster's 15 m disc, and they are there **on purpose** —
`harvest.json`'s own `_why_gate_b_three_beds` put them *"on the practice-path
loop the first day already walks."* So every candidate fix trades one failure
for its mirror image on the same ground: give engage a priority edge and a
player standing at a node with a bramblebun a metre away can no longer gather,
in the exact meadow where the chapter teaches gathering. `prompt_arbiter.gd`'s
nearest-wins is deliberate, `encounter_director.gd`'s priority 0 is deliberate
and its comment records what happened (GAME-0) the last time it was not, and a
player who steps toward the creature gets the creature. **This is the owner
judgement the audit said it was**, and CLAUDE.md forbids inventing it. Recorded,
not chosen.

**Fixed in the rig instead**, which is where the failure actually was: the catch
ladder approached to `within: 4.5`, from which a node at half a metre wins every
tie. Now `2.0` — RIG-F5's own recommended floor, above the 1.8 that failed a
`close_3d` check on a creature 0.22 m up a slope.

---

## 6. A new finding: rung 11 can never be the tracked objective

Not in `DEFECTS.md`. `home_progress.gd::home_built()` requires **every**
`required_pieces` entry, and that dict is `{camp: 1, creature_bed: 1}` — so
`home_built` cannot be set until the creature bed stands. `quest_log.gd` tracks
"the first unset flag in file order". Therefore:

- the player places the Camp and **nothing advances**;
- the tracked line still reads *"Make camp for your team"*, whose `how` text
  says *"Place a Camp"* — which they just did, with no cue that a bed is also
  required;
- placing the bed sets `home_built` **and** `creature_bed_built` in the same
  frame, and the chain jumps straight to `tournament_sleep`.

`tournament_build_creature_beds` is never the tracked line. **SHIP candidate,
not fixed** — the two clean fixes (drop `creature_bed` from `required_pieces`,
or rewrite the rung-10 `how` text) are both design calls, and dropping it also
lowers the gathering threshold below what the next rung needs.

S03's `S03-174` used to assert `objective_is tournament_build_creature_beds`.
It now asserts `tournament_sleep`, because the old assertion asserts a state the
shipped config cannot produce.

---

## 7. RIG-F1 / F2 / F3 and the rest of the rig

- **RIG-F1** — already fixed on `ralph/GATE-F-FULL` (`wait_until`). Nothing owed.
- **RIG-F2** — the aim-toggle parity. Needs a press-until-predicate action the
  vocabulary does not have. Not written here: it is an instrument feature, and
  this lane changing the step vocabulary mid-run is what RIG-F5 warns against.
- **RIG-F3** — S02's floors. Needs three or four S02 runs to re-derive; this lane
  ran none, so it adds no third data point. **S03's own two floors (`S03-261`
  distance ≥ 600 m, `S03-262` route rows ≥ 2000) are now in the same position**
  and are flagged in the file rather than retuned: they were derived against a
  ladder that is now 82 steps shorter.
- **S03C** regenerated from the updated S03 with the project's own
  `derive_capture_lane.py`; all seven owed `GF-` ids preserved. The other twelve
  `*C.json` files were **already** out of date on `main` before this lane
  touched anything and were left alone — they belong to other legs.

---

## 8. What the real run found — S02 and S03 driven end to end

`ralph/reports/gate-f-leg-s03/` is this lane's own run directory (its own
`RUN_METADATA.json` declares a logic lane honestly, so CD-8b's pre-flight stops
falling through to the stale 2026-08-27 candidate record that claims xvfb).
S01 and S02 were re-run from scratch rather than seeded from
`gate-f-full/S02/saves/S02-exit.json`, because that save is a *product* of
GAME-F2: Moss at 45.15 of 117.6 (38%) and a level-5 caught bramblebun. An
earned S03-exit needs an earned entry.

### The pin works, measured on the played path

S02's first fight, this lane, with the pin restored:

| | audit (unpinned) | this lane (pinned) |
|---|---|---|
| opponent | level 5, 124.2 max HP | **level 2, 106.2 max HP** |
| starter after the fight | 45.2 of 117.6 (38%) | **61.9 of 117.6 (53%)** |
| the catch | — | **landed, party 1 → 2** |

The earned `S02-exit` carries Moss (ripplet L3, 61.9/117.6) and a **level-2**
bramblebun, both with `base_hp` correctly persisted — FOUNDATION's GAME-F4 fix
working on the played path, not just in its unit test.

### Four rig defects the run found, all fixed

1. **S02's save block could not write a handoff save.** `game_menu` (Start) is
   also `backpack_drop`, so opening the shell can raise a "Drop it?"
   confirmation — *timing-dependent*, because `tab_backpack.gd`'s
   `_ignore_drop_until_release` guard sometimes holds. `S02-63b` dismissed it
   with an unconditional B; when the guard held there was nothing to dismiss and
   B closed the **shell**, so five tab presses went to the world and no save was
   written. Replaced with `open_menu {tab: map}`, which presses that tab's own
   shortcut instead of Start — the pattern S03-265 already used, which is why
   S03's save block never had this failure.
2. **RIG-F2, fixed properly.** `interact` toggles the catch aim, so the fixed
   "aim = interact ×2, throw = ×1" pattern lands on the wrong parity: **one
   `catch_throw` out of four throw blocks**, and the starter stands still
   through 4×6 s of waits taking free damage. That, not balance, is what fainted
   Moss. The audit could not fix it because the vocabulary had no
   press-until-predicate action; this lane wrote it. `press_until` reuses
   `_step_assert`'s own check vocabulary, PASSes on **zero** presses when the
   state already holds, is priced at full budget like a walk, and takes a
   `skip_if` so a retry block after a successful catch reads SKIP, not FAIL
   (CD-4's rule). Result: two real throws, catch landed, starter survived.
3. **S03's catch ladder killed what it was trying to catch.** `combat_quick`
   ×20 into a 106 HP level-2 opponent is ~200 damage. Four fights staged, zero
   throws, every aim step reporting `input_context=world` — because the fight
   was already over. Replaced with S02's measured opener (charged + 3 quick,
   which lands the target at 63% and catches on the second throw).
4. **The knife equip selected an empty hotbar slot.** The hotbar is 1-indexed
   (`['', 'axe', 'pickaxe', '', 'knife']`), so the knife bound by four
   `backpack_assign` presses lands in slot **5**; the step read `hotbar_4`. Every
   fiber node was worked with no tool. **This is almost certainly GAME-F5's
   unanswered question** — *"seven nodes were walked to, had the right tool
   equipped… and produced no gather event… one run cannot tell which"* — and the
   answer is none of its three candidates: the tool was bound, the wrong slot was
   selected.

### An instrument defect worth more than any of them

**All twenty gather presses PASSED while ten of them did nothing.** `press`
asserts the input was *injected*, not that anything received it — precisely the
T2-GATEF-RUN6/RIG-26 shape already fixed once for engage (*"a press into an
unengaged world PASSed and the visible failure surfaced several steps later"*).
A gather step needs an inventory-delta assertion or it cannot report its own
failure. Recorded, not fixed: it is a vocabulary change, and this lane has
already added one primitive mid-run.

### The structural finding: there is no recovery before the team rung

This is the one that is **not** a tunable number, and it is stated as an open
question rather than fixed, per CLAUDE.md.

The chapter's objective order is: build a team of **five** → train to level
**6** → gather → build camp → build bed → sleep → feed. The **only** creature
healing in the game is `home_recovery.gd`, i.e. the creature bed — which is
built at rung 11, *after* the team rung. Verified against the earned save:
the opening satchel holds **12 basic orbs and nothing else** — no Revive
draughts (correcting DEFECTS.md's GAME-F2, which says losing "costs one of the
two Revive draughts the opening satchel grants"); Tam gives a knife and a
torch; Mira gives an axe, a pickaxe and 30 coins and sells no healing.

So a party that arrives from S02 at ~53% health must catch three more creatures
and train five to level 6 with no way to heal. In this lane's runs Moss fainted
during the catch ladder every time, after which `encounter_director` correctly
refused every later engage with "Ripplet is out of the fight." and the ladder
cascaded — 9 of the 27 failures in one run are that single refusal repeated.

**No S03-exit produced by this lane is tournament-ready.** That is not a rig
failure and not a balance number: it is the chapter asking for a trained team of
five before it has taught, or provided, any way to recover one. Closing it is a
design decision — move the camp/bed rung ahead of the team rung, grant a healing
item in the opening, or add out-of-combat regeneration — and this lane will not
invent it. **PROGRESSION-F7 named the tournament gate as the chapter's
progression boundary; this is the mechanism behind it.**


### What the final run reached

`ralph/reports/gate-f-leg-s03/S03` — **318 PASS / 26 FAIL / 9 SKIP**, with an
earned `S03-exit.json`. Three rungs that have never passed in any Gate F run
now pass:

```
home_materials_gathered   SET      (24 wood / 12 stone / 28 fiber collected)
home_built                SET      placed_buildings: ['camp', 'creature_bed']
creature_bed_built        SET
```

Twenty of twenty nodes now yield (was ten), and the camp is affordable and
armed. The gathering half of the village ladder works end to end.

**Sixteen of the twenty-six remaining failures are one cause.** The team never
reaches five, so `quest_log` keeps `tournament_team_ready` as the tracked line
and every rung after it (`S03-41`, `-106`, `-174`, `-206`, `-229`) asserts an
objective the chain cannot reach; nine more are the single "Ripplet is out of
the fight." refusal repeated across catch attempts 2–10. That is §8's structural
finding, not ten separate defects.

The rest: `S03-205b/c` (a fainted party cannot be put to bed, so the sleep rung
cannot run), `S03-239/-315/-317/-260` (the Satchel feed flow — `menu_cancel`
left the shell open and focus would not move; a real rig defect this lane did
not reach), and `S03-261/-262`, the two stale floors, now re-derived below.

### The floors, re-derived — RIG-F3's ask, finally answerable

RIG-F3 asked for *"three or four S03 runs… and a floor set below the observed
minimum with the run ids written into the step's expected. Two samples is not a
floor."* Four runs, all in this lane's run directory:

| run | distance | route rows |
|---|---:|---:|
| `S03-superseded-1` | 476.3 m | 1358 |
| `S03-superseded-2` | 598.3 m | 1404 |
| `S03-superseded-4` | 470.6 m | 1327 |
| `S03` | 472.9 m | 1350 |

`S03-superseded-2` is an outlier and is labelled as one: it carried the
duplicate tool-select steps this lane added and then removed. The three
comparable runs cluster at 470.6–476.3 m and 1327–1358 rows. Floors moved
600 m → **420 m** and 2000 → **1200 rows**, below the observed minimum with
headroom rather than pinned to it.

## 9. What is NOT done, and why


**The real S03 run has not happened.** It depends on `GAME-F4` (every creature
loaded from a save loses its base stats; the first level-up after that collapses
it to `max_hp 1.18`). S03 boots by loading `S02-exit` and then has to train five
creatures to level 6 — dozens of level-ups through exactly the broken path. Any
`S03-exit` produced today would carry collapsed creatures and would be worse than
no save at all, because eight downstream lanes are waiting to verify against it.

`ralph/GATE-F-FOUNDATION` owns that fix and **did not exist on `origin` at any
point during this lane** (polled repeatedly through 00:22 UTC; `GATE-F-LEG-S05`,
`S07` and `S10CDE` all appeared in that window, FOUNDATION did not). Everything
in this report is work that did not require booting from a save, which is what
the lane brief asked for in that case.

**When FOUNDATION lands:** rebase this branch onto it, then drive S03 from a real
`S02-exit`. Two things to expect that this lane could not settle:

1. **Five creatures at level 6 is a much larger ask than three.** The ladder has
   ten catch attempts against a three-bramblebun cluster on a 45 s respawn, and
   one Bryn fight for training. Whether the village ladder contains enough
   content to reach `min_level: 6` across five creatures is an open progression
   question — PROGRESSION-F7 measured the gate refusing a team of two, and it
   will refuse a team of five under-levelled just as correctly.
2. **`tests/helpers/gate_a_material_route.gd`'s `TARGET_STOCK` is `{wood 69,
   stone 42, fiber 34}`** — the old house+3-beds+camp bill, stale in the same way
   S03.json was. It is another lane's smoke-test helper and was not touched.

---

## 10. Verification actually run

- `tests/test_practice_fight_level.gd` + `tests/test_village_boundary.gd` — green.
- **Both defects reintroduced locally and both new tests failed on them**, with
  the messages naming the coordinates and the missing pin.
- `tests/test_gate_f_rig.gd` — 49 tests, 240 assertions, green against the
  rewritten `S03.json`.
- `tools/gate_f/diag/probe_game_f1_f2_in_world.gd` — a booted Meadows, no save
  loaded: three practice bramblebuns at L2, and both moved nodes standing inside
  the fence.
- Full unit suite — see the branch's final commit.
