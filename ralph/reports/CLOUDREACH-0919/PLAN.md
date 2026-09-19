# Cloudreach visual production plan — 2026-09-19

Status: submitted for review; substantive implementation and costly work held until PLAN-APPROVED.md appears.

## Scope and source

Branch: ralph/cloudreach-visual-production-0919. Isolated worktree: D:\tetherbound\cloudreach-0919. Base: origin/main c05c724740b1111b693fb87da72b182934a5232d, including owner directive #128. Existing Meadows worktrees and their local changes are preserved.

Authority: AGENTS.md, CLAUDE.md, docs/00_START_HERE.md, docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md, and docs/CODEX_GOAL_2026-09-19_CLOUDREACH_VISUAL_PRODUCTION.md. The older full-game handoff supplies defect history only within this goal's scope.

Only Cloudreach visual/environment production: terrain wear coverage, cloud banks, cliff strata, grass roles, and independently evidenced named-location visual grades. No new gameplay, encounters, quests, progression, content, creature generations, or Meshy spend. Stormwood and Water remain paused. Preserve CloudSea safety height/recovery, collision, walkable crowns, region bounds, and existing gameplay behavior. If visual work requires gameplay-affecting changes, record the scope issue here and hold that slice for review.

## Work sequence

1. Reconcile current main and committed Cloudreach evidence, including later PR #121–125 work. Build a twelve-location evidence crosswalk with source revision, production capture, independent verdict, and unresolved provenance. Do not assume the old 0 PASS / 10 POLISH / 2 FAIL count is current. An evidence inventory alone does not promote any row.
2. Trace current terrain overlay generation, shaders, route joins/fades, cloud visuals and their safety boundary, cliff strata cadence, and grass generation/config consumers. Identify Cloudreach-only edit seams and affected tests. Read relevant visual contracts and failed-round history before selecting a candidate. Shared visual code must use an explicit Cloudreach scope and preserve other biome output.
3. After approval, implement and verify bounded slices, starting with true wear coverage masks and continuous joined route ribbons with endpoint fades. Keep the underlying crown visible through uncovered regions; change presentation rather than terrain collision.
4. Build approximately 80–120 deterministic multi-lobe cloud banks with height tiers, shaded bases and night-aware exposure, preserving the safety-owned CloudSea contract.
5. Break cliff-strata repetition with low-frequency spatial variation. Add only a few visual-only authored silhouettes if production evidence shows variation is insufficient; retain crowns and bounds.
6. Replace the exhausted grass tuning strategy with low/medium/sparse-tall roles and width proportional to height. No repeated tip/arc/count tuning loop. Validate the role distribution at ordinary route distance, including day/night and landmark paving intersections.
7. Capture affected production routes and named destinations, verify shipping-build geometry parity, and request independent code-blind review. Promote only rows supported by those receipts; stop after two non-progressing rounds and record the actual unresolved mechanism.

The listed approaches are the goal's requirements, not an advance commitment to an unreviewed architecture. Exact file ownership and implementation briefs follow source investigation and approval. Use bounded implementation agents under the repository tier policy and independent judges with no code/change context.

## Render and machine coordination

Before every screenshot capture or Godot import/export/render operation, read D:\tetherbound\RENDER_LOCK.json. Missing/null permits acquisition as cloudreach with UTC timestamp; verify ownership before launch. Meadows has priority. If Meadows holds it, continue source investigation or cache-read-only tests instead. Recheck throughout long capture runs and before subsequent captures. Release to held_by:null immediately in cleanup, including crash/abort. Never release another session's ownership or kill its process. Reclaim only after the directive's two-hour/no-new-output abandonment evidence is established and logged. Separate worktrees do not waive this machine-wide lock. No capture or import is part of the preapproval investigation.

## Verification and delivery

Choose focused behavior tests from the actual affected code: coverage/joins/fades, deterministic banks, unchanged safety/collision contracts, strata bounds, grass role geometry and unaffected biome consumers. Use already-imported cache-only tests concurrently when safe; cold import and world-heavy validation require machine/resource coordination. Run required world smoke for world changes and inspect distinct ERROR lines, not only SCRIPT ERROR. Run production day/night route evidence with ordinary player/camera context and real shipping geometry; label diagnostic frames honestly. Keep raw payload local and commit verdicts and permitted contact sheets only.

Exact-stage scoped commits; no incidental .import/.uid churn. Push this plan before implementation, open a draft PR, and inspect actual CI jobs without interpreting docs-only skips as game validation. Ship implementation through reviewed PR/CI and verify landing if authorized by the established workflow. No ledger promotion before production capture plus independent review.

Finish the work window with RESULTS.md containing commit/build identities, affected files, commands and results, production frame paths, reviewed-frame/played-path findings, independent verdicts, ledger deltas, and limitations. A pending approval checkpoint will explicitly claim no visual completion.

## While approval is pending

Continue read-only source/evidence reconciliation, history checks, test selection and shipping/capture parity investigation. Check this worktree and fetched lane/main refs for ralph/reports/CLOUDREACH-0919/PLAN-APPROVED.md. Do not create the approval file, treat elapsed time as approval, spend generation credits, promote grades, or begin substantive implementation.
