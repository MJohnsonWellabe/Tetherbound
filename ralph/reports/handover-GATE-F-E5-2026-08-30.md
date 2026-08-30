# Handover — GATE-F-E5, 2026-08-30

**Branch:** `ralph/GATE-F-E5`, off `origin/main` at `24fc81cb`.
**Scope:** reconcile Gate F §E.5 and its segment transcription with the three
opening rungs OP-0830-4 added.

---

## The one thing to read if you read nothing else

**`ralph/T5-OPENING` has NOT landed on `main`.** The task that routed this lane
said it "landed"; it has not. `origin/ralph/T5-OPENING` exists at `ed1eca93`,
`origin/main` is `24fc81cb`, and `main`'s `data/progression/objectives.json`
still has **24** entries beginning at `opening_first_catch`.

That inverts the failure rather than removing it. Before this branch, the three
assertions passed on `main` and would fail the moment T5-OPENING landed. After
this branch, they pass once T5-OPENING lands and **fail on `main` until it
does** — `opening_hear_grandpa` is not an id `main` knows, so
`_objective_flag_id()` resolves it to `""` and the comparison cannot match.

**So: land `ralph/T5-OPENING` before or together with this branch. Never this
one alone.** The two are verified compatible — see the evidence section; the
E5 patch applies to the T5-OPENING tree with no conflict.

---

## 1. The T5-OPENING measurement, re-counted rather than trusted

Its handover's claim was checked line by line against `main`, not assumed.

| claim | verdict |
|---|---|
| 48 `objective_is` assertions across the segment scripts | **confirmed** — 48 exactly (a 49th `grep` hit is prose in `X05.json`'s `_gap`, not an assertion) |
| exactly three assert `opening_first_catch` at a fresh-save opening | **confirmed** — `S01-12`, `S02-11`, `S02C-11`, and no others |
| the other 45 assert a rung at or after `open_road_gate` | **confirmed** — every remaining asserted id resolves to chain index ≥ 2 (old numbering) |
| the chain becomes 27 entries from `opening_hear_grandpa` | **confirmed** on the T5-OPENING tree: 27 entries, rung 1 `opening_hear_grandpa`, label "Go down and hear Grandpa out." |
| "across all 26 segment scripts" | **off by one, immaterial** — there are 47 segment files and **25** of them carry an `objective_is`. Corrected here for the record; it changes nothing about the three steps. |

`opening_first_catch` is not deleted. It moves from rung 1 to **rung 4 of 27**,
keeping its own flag `opening:beat:road`.

## 2. The ladder, and what changed

Recorded in `ralph/GATE_F_MASTER_PROTOCOL.md` §E.5 as a full 27-row table, with
the reason attached to it. §E.5 previously read *"24 main-chain objectives from
`opening_first_catch`"*; it now reads 27 from `opening_hear_grandpa`. §L.5's
row ("all 24 main-chain objectives traversed") moved with it.

The three new rungs are **guidance, not gameplay** — each binds to a flag
`sequence_director.gd` already wrote:

| # | id | flag | label |
|---|---|---|---|
| 1 | `opening_hear_grandpa` | `opening:beat:choose` | Go down and hear Grandpa out. |
| 2 | `opening_take_starter` | `opening:beat:return_starter` | Choose your first creature and give it a name. |
| 3 | `opening_show_grandpa` | `opening:beat:walk_out` | Show Grandpa your creature before you head out. |
| 4 | `opening_first_catch` | `opening:beat:road` | Catch your first wild creature. |

Why they exist, in one line: from the first frame of a new game — in bed,
upstairs, behind a door that stays shut until `opening:beat:walk_out` — the
tracked line read *"Catch your first wild creature."*, an action three rungs
away, and nothing named the second Grandpa conversation that releases the door.
That is the owner's OP-0830-4, "trapped in Grandpa's house".

## 3. What this branch changed

**Protocol first, then the transcription** — in that order, in separate commits.

- `ralph/GATE_F_MASTER_PROTOCOL.md` — §E.5's count and first rung; the 27-row
  ladder table; why it changed; §L.5's traversal row.
- **The three assertions**, retargeted to `opening_hear_grandpa`:
  `S01-12`, `S02-11`, `S02C-11`. **Not weakened, not deleted.** Each still
  asserts *the chain's first rung by id* rather than being relaxed to "any
  rung" — catching a silent reordering of the opening is the entire reason
  they exist, and it is what they just did. Each `expected` string now records
  that it was retargeted, from what, and why.
- **92 `N/24` ordinals → `(N+3)/27`** across 23 segment files. Not bumped
  blind: every one was machine-checked against the objective id **or** the
  progression flag named on its own line before rewriting (70 named an id, 22
  named a flag; all 92 agreed with the old numbering, so a uniform +3 is
  correct). Two prose counts moved with them ("the last of the 24",
  "24-objective main chain").
- **Two §E.5 navigation records in `S02` retargeted**, which the routing brief
  did not name and which encoded the old ladder as firmly as the assertions:
  - `S02-12` (at the wake beat) was filed against `opening_first_catch`,
    "Catch your first wild creature." — it is now rung 1
    `opening_hear_grandpa`. Its observation is unchanged and now *agrees* with
    the rung it sits under; it previously had to reason the route from the bed
    prompt precisely because the objective named something unreachable.
  - `S02-29` was `"objective 1/24 continued"`. It sits after the starter
    choice and the second Grandpa conversation, so it is now rung 4's own
    record: `4/27 opening_first_catch`.
- `tools/gate_f/operator_harness.gd` — **doc comment only.** It quoted the
  stale §E.5 sentence. `_objective_flag_id()` itself needed no change and got
  none; a note now records why, so the next person does not go looking.

## 4. Nothing else hard-codes the old first rung — checked, not assumed

- **`operator_harness.gd::_objective_flag_id()`** builds its id→flag map by
  reading `objectives.json` at call time. It absorbed a reordered chain without
  being touched, which is what it was written for. Only its prose was stale.
- **No test hard-codes an objective id.** `test_gateb_objective_chain.gd` and
  `test_quest_log.gd` walk the chain from the data; `test_gate_f_rig.gd` reads
  `S01.json`/`S01C.json` but only for the lane-split contract (`evidence_lane`,
  `owes`, `record_hz`), never for an objective. `test_gate_f_instrumentation.gd`
  counts step-script files, not rungs.
- **No fixture and no count.** `tools/gate_f/run_inventory.py` and
  `run_segment.sh` never mention an objective id.
- **`ralph/GATE_F_MASTER_PROTOCOL.md` was the only doc** carrying the count;
  `ralph/GATE_F_PROTOCOL.md` and `docs/ralph-prompts/` do not.

## 5. Evidence

`main` cannot run these assertions to a pass, because the rung does not exist
there yet — so they were run where the ladder does exist. A scratch worktree of
`origin/ralph/T5-OPENING` took this branch's patch:

| | |
|---|---|
| this branch's diff onto the T5-OPENING tree | **applies clean**, 27 files, no conflict — the two lanes do not collide |
| chain read on that tree | 27 entries; rung 1 `opening_hear_grandpa` → `opening:beat:choose`; `opening_first_catch` at rung 4 → `opening:beat:road` |
| fresh-save tracked entry vs. the retargeted assertion | `opening_hear_grandpa` == asserted id → **the three steps PASS** |
| `test_gate_f_rig.gd` + `test_gate_f_instrumentation.gd` + `test_gateb_objective_chain.gd` + `test_quest_log.gd` | **106 tests, 37,041 assertions, 0 failed** |
| `tests/smoke_gate_f_probe.gd` | **OK** — "every accessor agreed with the live game it reads" |
| `tests/smoke_opening.gd` | **OK** — "talked, chose, named, and the creature is in the party" |
| capture-lane drift on that tree | unchanged from its own baseline |

On this branch's own tree (`main` + these changes), the same four unit files are
**105 tests, 37,129 assertions, 0 failed** and `smoke_gate_f_probe.gd` is **OK**
— the three retargeted steps are segment scripts, not unit tests, so nothing
here regressed. (106 vs 105: T5-OPENING adds one test of its own.)

**A negative result worth recording.** Swapping *only* T5-OPENING's
`objectives.json` onto `main` — data without that lane's code — fails
`test_quest_log.gd::test_every_objective_waits_on_a_flag_something_actually_sets`
on all three new rungs ("no trainer sets it and it is not a known world flag").
T5-OPENING's own commit `e4192af3` teaches those tests the new flags. This is
the second, independent proof that the two branches must land together: the
data alone does not stand up.

## 6. Not run, and why

`tools/gate_f/run_segment.sh S01` was attempted and **refused before doing any
work**: the freeze record at `ralph/reports/gate-f-candidate/RUN_METADATA.json`
declares `display_server=X11 under xvfb-run`, and logic mode passes
`--headless`, so the harness's capture pre-flight calls the contradiction and
stops. That gate is behaving exactly as designed (it is the CD-1 defence
against runs that report PASS without having happened) and it was not defeated
to get evidence. Re-running `xvfb-run` around it does not help — `--headless`
wins. Whoever re-baselines the run owns clearing that record.

## 7. Findings for whoever picks this up

1. **`ralph/T5-OPENING` is unlanded** and `ralph/START_HERE.md` does not mention
   it. `ralph/OWNER_PLAYTEST_2026-08-30.md` routes OP-0830-1/2/4 to it. It is
   the fix for an owner-reported softlock and it is sitting on a branch.
2. **Eight capture lanes are stale on `main`** against
   `derive_capture_lane.py`: `S03C`, `S04C`, `S05C`, `S06C`, `S07C`, `S08C`,
   `S09C`, `X04C`. The generator would add a `deploy the active creature after
   load` step (RIG-13) to each, and `S03C` is 121 steps behind its source.
   `--check` returns 1 on `main` today. **This lane deliberately did not fix
   it**: regenerating changes what those segments *do*, which is Gate F's call,
   not a transcription correction's. The drift set is byte-identical before and
   after this branch — verified both ways.
3. **`derive_capture_lane.py` has no argument parsing.** `main()` is
   `check = "--check" in argv`, so **any** other argument — `--help` included —
   silently runs it in **write mode** and rewrites all 17 capture lanes. That
   happened once in this lane and was caught and reverted; it would be easy for
   it to happen to someone else and land. A three-line argparse guard, or an
   explicit `--write`, would close it.
4. **Rungs 2 and 3 have no §E.5 navigation record.** Recorded in-place as
   `_gap_e5_opening_rungs` in `S02.json` rather than dropped. None was
   invented: a navigation record is a played observation ("what was legible on
   screen", "time-to-route-decision", "reasoned from frame X") and this lane
   corrected a transcription, it did not play the segment. Both are in-house
   modal beats, so the likely finding is "no navigation decision exists at this
   rung" — a prediction, not a record. Owed on the next S02 run.
5. **Three `.uid` sidecars are missing on `main`**, surfaced by a Godot import:
   `scripts/world/river_nest_clear.gd.uid`, `tools/_capture_guardian_den.gd.uid`,
   `tools/_probe_guardian_isolation.gd.uid`. Left untracked here — out of scope
   — but the repo tracks `.uid` files and has fixed exactly this before
   (`791f17df`).

## 8. Untouched, per scope

`data/progression/objectives.json` (this lane changed no game data — the ladder
belongs to T5-OPENING), `_objective_flag_id()`'s body, every `objective_is`
assertion at or after `open_road_gate`, the eight already-drifted capture lanes,
and every segment step's `action`/`args` other than the three retargeted ids.
No assertion was weakened and no step was deleted.
