# Gate 3 chapter chain — outcome

**Run:** `ralph/reports/gate-f-run-g3-20260904T001916Z`, logic lane, headless.
**Candidate:** `claude/gate-3-coordinator-cjgwca` (main at `3c73aab5` plus docs).
**Ended:** 2026-09-04T01:05Z, at S04. Not still running.

| Segment | P | F | SKIP | exit save | verdict |
|---|---|---|---|---|---|
| S01 | 13 | 0 | 0 | — (start of chain) | PASS |
| S02 | 77 | 5 | 3 | written | FAIL — all five are one defect |
| S03 | 475 | 38 | 47 | **written** | the milestone; see below |
| S04 | 50 | 21 | 0 | **not written** | FAIL — chain halted here |

## Why it stopped

`run_chain.sh` halted itself, correctly: *"S04 wrote no exit save — the chain
cannot continue past it. Stopping here rather than running S04+1 against stale
state."* Every later segment seeds from the previous segment's exit save, so a
chain that continued would have replayed S03's state and quietly reported
findings about a player who was never there. That is precisely the failure mode
that made Gate F run 3 unreadable, and the harness refusing to do it is the
right behaviour.

S04 wrote no exit save because the save step was among its 21 failures — *"slot
4's content is byte-identical to what `seed_save` wrote at the start of this
segment — the Save tab was never used"*.

## What this run established, and what it cannot say

**S03 passed 475/38 and wrote `S03-exit.json`.** That is the result worth
keeping. Gate F run 3 died at exactly this point: its S03 catch loop fainted the
only creature, no step-script assigned it to a bed, and five consecutive
downstream segments then spent themselves walking into a correctly-locked South
Bridge gate. `archive/reports/GATE_F_RUN_3_FINDINGS.md` calls that stranding the
dominant fact of the run. **This chain got past it with a party that can fight.**

**S02's five failures are one defect, not five.** The tutorial catch's retry path
re-enters `combat_aim` but never emits a second `catch_throw` — three retries,
three re-aims, zero throws, across two runs. `opening.json`'s
`max_catch_failures` counts LANDED throws, so the promise its own comment quotes
from `docs/specs/OPENING_SEQUENCE.md` ("the tutorial catch cannot fail twice") is
unreachable, and a first throw that legitimately fails at high HP dead-ends a
fresh save with a party of one. Logged GAME-11/RIG-26; the `G3-OPENING-FIX` lane
has since root-caused it.

**S04's 21 failures are not quotable and should not be actioned.** They cluster
on `input_context=narrative_modal (wanted combat)` and `combat_running=false` —
blind press counts fired at a narrative modal that holds input. Gate 2's 2.8
lane had already rewritten `S04.json` to replace exactly those with
`advance_dialogue_until_closed` (nine uses) and `fight_until_resolved`, but that
rewrite is on `ralph/G3-LAND-0904` and **not on the SHA this chain ran**. The
numbers describe an instrument that has since been fixed.

**Nothing about how the game looks.** Logic lane only; no frame was rendered.
The capture debt is outstanding, not discharged.

## What unblocks the rest of the chapter

S06–S10e still have no evidence. The chain cannot reach them until a run
produces a healthy S04 exit save, which needs 2.8's rewritten segments — so the
re-run belongs on `ralph/G3-LAND-0904` or later, not on this candidate. The
`G3-HARNESS` lane owns that re-run along with the Pond walker (2.9) and the S08
post-faint gap; this chain is blocked behind it by design rather than by
accident.
