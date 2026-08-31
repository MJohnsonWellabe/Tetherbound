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

## 8. What is NOT done, and why

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

## 9. Verification actually run

- `tests/test_practice_fight_level.gd` + `tests/test_village_boundary.gd` — green.
- **Both defects reintroduced locally and both new tests failed on them**, with
  the messages naming the coordinates and the missing pin.
- `tests/test_gate_f_rig.gd` — 49 tests, 240 assertions, green against the
  rewritten `S03.json`.
- `tools/gate_f/diag/probe_game_f1_f2_in_world.gd` — a booted Meadows, no save
  loaded: three practice bramblebuns at L2, and both moved nodes standing inside
  the fence.
- Full unit suite — see the branch's final commit.
