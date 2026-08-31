# Run-level BLOCKER — refused at pre-flight, zero steps executed

**This directory contains no player-path evidence.** S01 and S02 both refused
before step 1; `CHAIN_LOG.tsv` records `P=0 F=0 SKIP=0` for both, and
`run_chain.sh` then stopped the chain because S02 wrote no exit save. It is
preserved, not deleted, because the refusal is itself the record of a
precondition that had not been discharged.

## What refused, verbatim

```
gate-f harness ERROR: capture pre-flight BLOCKER: the freeze record contradicts
this process: the freeze record at
/home/user/tetherbound/ralph/reports/gate-f-candidate/RUN_METADATA.json says
display_server=X11 under xvfb-run; this process has none
```

## Why it is correct that it refused

`_freeze_display_claim()` consults two records, nearest first: this run's own
`RUN_METADATA.json` (§A.2, written at freeze) and the candidate freeze record.
**This run had no `RUN_METADATA.json`**, so the check fell through to the
candidate record — and that record is stale in three independent ways:

| field | candidate record says | this run |
|---|---|---|
| `candidate_sha` | `f082bdf6` (2026-08-27) | `679f990c` |
| `run_dir` | `gate-f-run-20260827T025303Z` | this one |
| `segments_planned.journey` | `S01…S10` — predates the 2026-08-30 S10a–e split | `S01…S10e` |
| `lanes` block | absent | required: journey lanes are `logic` (headless) |

With no `lanes` block, §H.1 makes the record's flat
`"display_server": "X11 under xvfb-run"` bind **every** lane. Every journey
segment declares `evidence_lane: "logic"` and so runs headless by design, which
contradicts the flat claim. CD-8b makes that a hard refusal, correctly and
deliberately not waivable by `--gatef-allow-no-capture`.

**The gate did its job.** Nothing here is a game defect and nothing here is a
harness defect. The missing artefact is the §A.2 freeze record for this
candidate, which §A assigns to the coordinator before S01.

## Disposition

Superseded by a fresh run directory carrying a real §A.2 record for candidate
`679f990c`, with the per-lane block §H.1 requires. The stale candidate record
at `ralph/reports/gate-f-candidate/RUN_METADATA.json` was **not touched** —
amending a freeze record so a segment will start is the specific sin CD-8b
exists to prevent, and writing a new run's own missing record is not that.
