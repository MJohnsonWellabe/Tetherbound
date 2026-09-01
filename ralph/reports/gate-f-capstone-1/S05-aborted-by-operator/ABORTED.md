# S05 was aborted by the operator, mid-segment

Not a segment result. This directory holds a partial `events.jsonl` and
`route.csv` for a segment that was **killed while running**, and it must not be
read as evidence about S05.

## Why

By the time S05 started, the chain's own state had made it uninformative. S04's
exit carries a party of **1 fainted creature**, no `tournament_entered`, no
`tournament_won`, and a guided ladder still parked on main-chain rung 4
(`opening_first_catch`). S05's span is "leave village -> pond -> South Bridge
fight -> cross", and the South Bridge fight is a gated crossing that
`can_challenge()` refuses outright for a fainted-only party — the same refusal
S03 already measured ten times over.

Running S05 through S10e from that state would have spent hours of container
time re-measuring one already-recorded fact (CAP-1's cascade) instead of
answering the question that decides the whole run: **is CAP-1 deterministic?**

This is an operator decision, recorded here rather than taken silently — the
2026-08-27 run's own lesson is that a legitimate operator choice becomes a
defect the moment nothing in the record says it was made.

## What replaced it

1. A bounded reproduction of S02's tutorial-catch failure (protocol section J,
   repro budget 3), in a **separate run directory** so this run's save lineage
   is never touched.
2. A recovery probe for the question CAP-4 leaves open: the trainer says
   "a bed will do it" — does it?

## Restart

S05 was never completed and has no exit save. If the chain is resumed after a
fix, S05 restarts from `S04-exit` exactly as `run_chain.sh` would have run it;
this directory is superseded and is kept, not deleted (protocol section A).
