# Routed finding — `smoke_progression_feedback` is red on `main`, and CI never ran it

**Found by:** lane 1.B (Stage B Wave 1), 2026-09-06, while establishing attribution for its own
smoke sequence. **Not the state seam's:** three identical failures on the lane branch and one
identical failure on a clean worktree of the untouched base `6b71c024`, byte-identical output.

**Tier:** Sonnet. **Size:** S–M. Read `ralph/briefs/MP-W1/COMMON.md` first.

**The defect, as diagnosed.** `scripts/ui/party_strip.gd::_poll_feed()` advances its cursor over
the progression feed **before** checking the `progression_feedback_enabled` guard. Events pushed
while combat has the strip disabled are consumed and dropped, so the XP and bond feedback the
player is supposed to see after a fight never arrives. Verify that reading before changing
anything; the lane diagnosed it but did not fix it, and a diagnosis is a hypothesis until a test
sees it red.

**Why it went unnoticed:** `tests/smoke_progression_feedback.gd` is in **no CI shard**. It is one
of the ~104 smokes CI never runs (`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §9).

**Done when:** the cursor advances only for events the strip actually presents; the smoke passes
on first attempt; the fix is seen red first; and the smoke is added to whichever CI shard fits
(the gate-evidence shard is the natural home, and it is already near its 40-minute ceiling — say
so in the report if it does not fit, and propose where it goes).

**Fails if** the smoke is weakened, or the guard is removed rather than reordered — the strip is
deliberately silent during a fight (W13-PROGRESSION-FEED, D76).
