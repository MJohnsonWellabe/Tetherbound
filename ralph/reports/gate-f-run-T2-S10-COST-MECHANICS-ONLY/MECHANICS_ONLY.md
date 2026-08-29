# MECHANICS-ONLY validation run -- NOT game evidence

This run directory was created by ralph/T2-S10-COST solely to validate the
RIG mechanics of the S10 split (S10a/S10b/S10c/S10d/S10e): does each
sub-segment's step-script run to completion, does seed_save/save_out chain
correctly from one sub-segment's exit to the next, and does the cost-gate
math land where the handover report predicted.

It is seeded from the STRANDED `ralph/reports/gate-f-run-20260828T183531Z/S09/saves/S09-exit.json`,
which belongs to a run whose S09 lane never produced a healthy chain for
independent reasons (see ralph/reports/FINDING-T2-STRANDING-2026-08-30.md,
a concurrent lane's own finding). Re-using that save here makes NO claim
about the game, the chapter, pacing, difficulty or economy -- it is used
ONLY to exercise the harness's own save/load/cost-gate machinery.

Do not cite anything in this directory as Gate F evidence. See
ralph/reports/handover-T2-S10-COST-2026-08-30.md for what this run
validated and what still needs a real, healthy S09-exit to evidence.
