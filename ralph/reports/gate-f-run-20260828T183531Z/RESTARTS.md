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
| S05 | `be4e986` | `4e23c92` | RIG-9. The re-run at `be4e986` completed all 76 steps cleanly — 60 PASS, 7 FAIL, 9 DELEGATED, no derail, no harness error — and was then written out **INCOMPLETE** for 46 continuous frames "planned and not written", on a lane that had undertaken to take none. `record_hz` is zeroed for a logic lane at segment load, but `record_start` re-armed the recorder from its own args, so the two windows S05 declares spent themselves asking a headless process for frames. That is the outcome §H.1 forbids in its own words. The windows are now DELEGATED to `S05C` on the same terms as a prescribed §G frame. The fix cannot alter a step verdict — no step reads the recorder — but it changes what `INVENTORY.json` says about the segment, so the segment is re-run rather than have its own inventory corrected by hand. `S05-superseded-2/` is that clean-but-misfiled attempt and its 76 verdicts are readable; what may not be read from it is its `complete: false`. |

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
