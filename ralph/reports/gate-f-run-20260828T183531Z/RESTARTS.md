# RESTARTS — gate-f-run-20260828T183531Z

Section A's blocker rule: "only the affected segment restarts, from its entry
save. Pre-fix and post-fix evidence are never combined: the run directory gains
a RESTARTS.md naming segment, old SHA, new SHA, and reason, and the superseded
segment directory is renamed `<segment>-superseded-<n>`, never deleted."

| segment | old rig SHA | new rig SHA | reason |
|---|---|---|---|
| S03 | `0bd8781` | `435fbb8da3b085cbf4fc5c3710a2a969371c2ec0` | BLOCKED by the CD-7 cost gate at step 9 of 274, 91 s in. The gate priced the segment at 0.351 s/frame because its in-play recheck divided the 42.8 s the Load press spent building the Meadows by the 122 physics frames that had ticked, then projected that across 119,472 remaining frames — 11.6 h predicted for a segment that costs about half an hour. Fixed outside the run as CD-7c. |
| S04 | `0bd8781` | `435fbb8da3b085cbf4fc5c3710a2a969371c2ec0` | Not a segment failure. S04 was 100 s into its run when the operator stopped the driver to fix CD-7c; its process was killed mid-step. The partial directory is preserved rather than deleted, but it is **not evidence of anything** and no verdict in it may be read. |
| S05 | `fe39fbf` | `be4e986` | Not a segment failure, and the same shape as S04-superseded-1. S05 was 45 s of play time into its run (17 events, 90 route rows, still finishing the load-in at the village) when the operator session that launched it was reclaimed; its Godot process died with it, mid-step. No `INVENTORY.json`, no notes and no verdict were ever written. The partial directory is preserved rather than deleted, but it is **not evidence of anything** and nothing in it may be read as a result. Re-run from the same entry save, `S04-exit`. The two rig SHAs differ only by report commits: `tools/gate_f/` is unchanged between them (`git diff fe39fbf be4e986 -- tools/gate_f/` is empty by construction — no rig commit lands after CD-7c). |

## What is NOT superseded

S01 and S02 ran to completion against `0bd8781` and are **kept**. CD-7c changes
when the cost gate refuses a segment and nothing else — it cannot alter a step
verdict in a segment that was never refused. Neither of them was: S01's
INVENTORY records no block, and S02's records none either. Their evidence
stands at the old rig SHA and this file is where a reader finds out that two
rig SHAs are present in one run directory.

The candidate SHA — the GAME — is unchanged at `main@26f0db4` for every segment
in this run. Only the rig moved.

## The superseded evidence is the finding

`S03-superseded-1/` is not a failed attempt to be ignored. It is the primary
evidence for CD-7c: `INVENTORY.json` there carries the two re-prices, the
0.351 s/frame measurement, and the refusal text, and `BLOCKER.md` carries the
gate's own words. The fix commit cites those numbers.
