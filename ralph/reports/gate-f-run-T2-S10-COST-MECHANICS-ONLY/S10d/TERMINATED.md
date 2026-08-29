# S10d (second attempt) — manually terminated, not a harness failure

This attempt was killed (`kill -TERM`, exit 143) after ~25 minutes with the
player oscillating a few metres from its spawn point during its first
`move_to` step, without ever tripping the cost gate, derailing, or
harness-erroring. No `INVENTORY.json`/`INCOMPLETE.md` exists for this
attempt because the process did not exit through its own normal close path.

See `ralph/reports/handover-T2-S10-COST-2026-08-30.md`'s "S10d — second
attempt" section for the full account and why this is read as a
`stick_navigator.gd` geometry snag at this specific stranded/synthetic
save's spawn position, not a defect in `S10d.json` or the split.
