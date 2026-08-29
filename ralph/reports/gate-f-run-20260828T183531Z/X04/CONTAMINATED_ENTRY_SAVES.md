# X04's entry saves are all fainted-party saves — its combat assertions are not evidence about combat

**Added 2026-08-30, after the fact, once `ralph/reports/FINDING-T2-STRANDING-2026-08-30.md`
(`origin/ralph/T2-STRANDING@08506512`) established the real exposure boundary.**

This segment was run on the coordinator's instruction that its entry saves
(`S04-exit`, `S06-exit`, `S09-exit`) predated, or were otherwise clear of,
the South Bridge stranding. **That instruction was wrong, corrected twice
over, and this segment's evidence is compromised as a result.**

T2-STRANDING's finding, checking exit-save contents directly rather than
inferring from segment structure, established: `S03-exit.json` onward
(every exit save from S03 through S09) carries a party of one creature
(Moss) with `hp: 0.0` — **permanently fainted**, because S03's own catch
loop fainted the player's only creature on a fair roll (RIG-18's already-
recorded miss), and nothing in the run ever healed it (the tutorial's three
creature beds were built but never assigned the fainted creature before
S03's sleep step — a step-script gap, not a broken game system: a real
player has an always-available recovery path here that this run's rig
script never took).

`encounter_director.gd::summon_active_creature()` correctly refuses to
deploy a fainted creature, so `creature_recall` (the RIG-11/RIG-13 fix
pressed after every load, including X04's own three `seed_save` points)
silently no-ops on all three of X04's entries. **All three of X04's entry
saves — `S04-exit`, `S06-exit`, and `S09-exit` — carry this fainted party.**
There is no clean entry point into X04 anywhere in this run.

**What this means for this directory's own results (`INVENTORY.json`:
104 PASS / 12 FAIL / 8 DELEGATED, `combat_start` count 0):** the 12 FAILs
this segment recorded at `input_context=world (wanted combat)` (X04-021,
X04-034, X04-042, X04-053, X04-114, and others) are the **same shape as
every South Bridge stranding FAIL in S05 through S10** — a fight that could
never start because no usable creature could be summoned — not new evidence
about combat, camera, switching, or faint-recovery. **None of X04's
thirteen CB test cases (intentional loss, faint mid-fight, switching under
pressure, camera stress, arena-edge stress, size/range spread, lighting
variants) produced real combat evidence.**

Separately and independently, RIG-19 (see `GATE_F_RUN_3_RIG_FINDINGS.md`)
found that X04's own `move_to` steps also carry no `budget_frames` and
undershoot every one of its three combat sites by 1.1-6.3 km regardless of
party state. **Both defects point the same direction — zero combat_start
in this segment — for two independent reasons.** Fixing only one would not
have produced combat evidence either.

**This directory's telemetry is not deleted or rewritten.** It is a real
record of what the harness did against these entry saves, preserved per
protocol. It should be read as: confirmation that a fainted-only party
correctly cannot fight (a real, if narrow, positive result about
`can_challenge()`'s and `summon_active_creature()`'s own correctness), and
as the shape T2-STRANDING's finding predicted before it was run — not as
evidence about the chapter's combat systems themselves.

**X04 is worth re-running once healthy exit saves exist** (after T2-STRANDING's
S03 creature-bed fix lands and a fresh S03-S09 chain produces them), seeded
from the new saves, and ideally after RIG-19's budget-sizing gap is also
addressed so a re-run's own travel does not independently undershoot.
