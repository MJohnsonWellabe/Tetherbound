# Gate F Phase B — reviewer output

Independent Playtest Director / Product Reviewer pass over the Gate F run
`ralph/reports/gate-f-run-20260827T025303Z/`, candidate
`f082bdf6265760ca9835e1065361fbbf87475d69`.

Read in this order:

| # | file | what it is |
|---|---|---|
| 1 | `ADJUDICATION.md` | §14 blind analysis: game defect vs. harness artifact, the §14 judgment questions, root-cause clustering, and the read of X07's 79 frames |
| 2 | `PROVISIONAL_BACKLOG.md` + `.sha256` | §16.2 — what Gate F found **before** the historical register was opened. Frozen and hashed at commit `092c229` |
| 3 | `RECONCILIATION.md` | §16.3 — all 162 player-facing historical items in one category each; §16.5 capture rate |
| 4 | `COVERAGE_DEFECTS.md` | §16.4 — CD-1…CD-7, the seven causes behind 138 misses, folded into the permanent protocol template |
| 5 | `FINAL_BACKLOG.md` | §15/§16.6 — 13 items in full format, history merged |
| 6 | `SUMMARIES.md` | the six §15 summaries |
| — | `PHASE_B_LOG.md` | check-in log; records exactly when quarantine was broken |

## The three things to take away

1. **Three of the four loudest findings in the run are not defects.** "Input
   ownership never handed back", "no fight ever stages" and the 23-minute
   `SwapPanel` hold are all harness artifacts, refuted by the run's own data.
   The South Bridge really never opens — because its gate fight was never won,
   which is a gate working correctly.

2. **One real game defect dominates: ~50 seconds of frozen screen on New Game**,
   reproduced in 6 of 8 segments at 49–51 s with the renderer switched off.

3. **Gate F does not pass, and its capture rate is 8.0%.** Roughly a quarter of
   the protocol executed; 9,231 planned frames captured zero; five of eight
   study segments never ran. Per §16.5 the historical backlog **remains
   operationally authoritative** — this backlog is additive, not a replacement.

Fix the instrument (Tier 0), re-freeze, re-run. Tier 1's four real game defects
can proceed in parallel.
