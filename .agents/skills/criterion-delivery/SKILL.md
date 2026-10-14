---
name: criterion-delivery
description: Load before starting, resuming or planning any Tetherbound lane, work order or criterion (F##/CARD/X rows), and whenever an hour has passed without a criterion closing. Keeps work on building and proving acceptance criteria instead of harnesses, tooling, diagnostics or evidence plumbing. Binding policy is docs/CRITERION_DELIVERY.md (owner, 14 Oct 2026).
---

# Criterion delivery first

Binding policy: `docs/CRITERION_DELIVERY.md`. Read it in full before any work. This skill is the checklist, not a replacement. The policy wins wherever the two differ.

Why it exists: on 13–14 Oct eight lanes pushed about 280 commits in 12 hours and closed zero criteria (board stuck at 233/271 for 18 hours). The work was capture tools, profilers, supervisors, provenance packets and repeated reviews. The owner stopped every lane.

## Before you start

1. Name **one** open criterion by ID from the board (`ralph/reports/COORDINATOR/dashboard/criteria.json`). Write the expected player-visible result and the existing proof that closes it.
2. Read `ralph/reports/EVIDENCE/takeover-native/preservation-index.md` and your lane's `HANDOFF-*.md`. Reuse what exists; never rebuild it.

## While working: every commit must be one of these

- A change to what the player sees or does for that criterion.
- The run of that criterion's required proof.
- The **smallest** correction to a **reproduced** blocker of that proof, when no existing route works, recorded in the work note (criterion, failure, alternatives checked, the correction, the next proof). Then attempt the proof immediately.

Not allowed: new harnesses, supervisors, validators, staging systems, profilers, report formats, refactors of working tools, fixes to unrelated tests, or reviews of unchanged artifacts.

## The 60-minute check

After at most 60 minutes of active work without a closure, write down: what changed in the game, which proof you attempted, the result, and the next action. If the hour produced only infrastructure, reports or reviews, stop that approach and take another criterion. Two failures on one approach: park it with its evidence, or change the game-level approach.

## Reporting

Report separately: criteria closed, game changes not yet accepted, failed/unrun proofs, and necessary infrastructure work. Say "zero criteria closed" plainly when true. Commits, pushes and green CI are not closures.

Never weaken, skip or delete a test, lower a visual bar or waive a warning to claim a closure.
