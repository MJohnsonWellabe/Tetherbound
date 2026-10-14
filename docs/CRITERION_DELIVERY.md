# Criterion delivery first

Owner direction, 14 October 2026. Binding for every future Tetherbound lane; supersedes conflicting continuation or infrastructure work orders. The current eight-lane run is stopped. Resume only on a new owner instruction.

## Deliver the game and prove the criterion

1. Select one open criterion by ID. Read its existing acceptance conditions and choose the smallest player-visible change and the existing proof that can close it. State the expected result before editing. Source commits, green CI, component probes, reports, and new tools are not criterion closure.
2. Reuse the existing code, capture tools, launchers, saved checkpoints and evidence. Read the preserved lane handoffs and the infrastructure inventory below before proposing anything new. Do not rebuild or refactor infrastructure because it is inconvenient, unfamiliar or imperfect.
3. Do not build harnesses, supervisors, validators, generalized test frameworks, new staging systems or reporting machinery. Do not fix unrelated tests. An exception is allowed only when a reproduced failure prevents the specific selected criterion's required proof, no existing supported route can produce that proof, and the smallest bounded correction is necessary. Record the criterion, actual failure, existing alternatives checked, minimum correction and exact next proof in the existing work note. This is an evidence requirement, not a new owner approval process.
4. After that correction, immediately attempt the criterion's proof. Do not turn the exception into a tooling project or a sequence of replacement harnesses. After two failures on an approach, park it with its evidence or change the game-level approach. Never weaken, skip or delete tests, lower visual bars, raise time/resource caps, manufacture earned progress or waive warnings to claim success.
5. Every work block must implement player-visible behavior or execute the required criterion proof. A lane waiting for the single native writer must select genuinely independent criterion work or remain idle; it must not invent tooling to stay busy. Match active lanes to the machine's proof capacity.
6. Review progress after at most 60 minutes of active work without closure. Record what changed in the game, actual proof attempted, result and the next bounded action. If progress is only infrastructure, reports or repeated review, stop that approach and take another eligible criterion. This checkpoint is not permission to abandon genuinely progressing game work or to start an hourly reporting project.
7. Report separately: criteria closed, game changes not yet accepted, failed/unrun proofs, and necessary infrastructure work. State zero closures plainly. Count a criterion only when its required proof and landing rules pass. Do not substitute commit/push/test counts for delivered criteria.
8. Use independent reviews and code-blind judging where required, but do not repeatedly review unchanged artifacts or spawn agents merely to produce more review packets. Use bounded cheaper agents for mechanical work where permitted. Preserve the established one-native-writer rule.

## Preserve and reuse

- Coordinator branch: `tb/ev-coordinator`. All eight lane branches landed on main in PR #687 (14 Oct 2026) and their GitHub branches were then deleted; every recorded head SHA stays reachable from main. New focused lanes use new `tb/` branches cut from main. Archiving conversations does not delete local checkouts.
- Existing lane evidence/handoffs: `ralph/reports/EVIDENCE/HANDOFF-*.md`, `ralph/reports/EVIDENCE/F38-F41/`, and the owning feature evidence directories. Exact end-of-run branch heads and reusable artifact locations are indexed in `ralph/reports/EVIDENCE/takeover-native/preservation-index.md`.
- Existing committed native proof and reusable runner sources: `ralph/reports/EVIDENCE/takeover-native/`. Portable raw JSON bundles contain original files with hashes; recover and verify those files rather than rebuilding them. A prepared or failed packet is not a working/approved runner.
- Local original artifacts remain in `D:/tetherbound/.artifacts/`; native preservation backups remain in `D:/CodexTemp/`. Keep unique saves, assets and evidence. Do not delete these on restart merely because the conversations are archived.
- Existing tools include `tools/earned_saves/`, fixed camera sets in `tools/visual_judge/camera_sets/`, and the branch-specific frozen packages named in the inventory. Read the specific packet's scope and known failures; do not assume source pins or native-stage identity are current.
- Before archiving: commit and push source/WIP and essential reusable scripts/receipts; label untested work and leave failed visual candidates OFF. Verify remote HEAD matches local, preserve local-only artifacts explicitly, stop owned native processes safely, and pause continuation automations. Do not buy storage, publish secrets, or commit generated import caches.

## Restart

Read this policy and the preservation index first. Start with a criterion that can be implemented and proved using the preserved machinery. Do not automatically resume the old queues, every parked diagnostic, or eight sessions. The owner will decide when to restart; the worker decides the smallest effective execution within that new instruction.
