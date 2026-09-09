# Owner directive — root-cause the shared visual defects, and correct the single-lane framing

Recorded from the owner conversation, 2026-09-09, relayed through the orchestrator
session (Claude Code) because direct remote control into this session was
unavailable at the time. This supersedes the **lane structure** of
`OWNER_DIRECTIVE_2026-09-09_CONTINUOUS_VISUAL_LANE.md` — not its intent.

## What that directive got right, and what it caused

"Keep a lane focused on visual review and fixes always" was the right call —
visual work should never go dormant. But "a critic reviewing the current
candidate counts as the visual lane while the fixer waits for that verdict"
describes exactly one lane, cycling one fixer against one reused critic. That
framing is the direct cause of a pattern visible across all five
`VISUAL-WAVE*-IMAGE-REVIEW-0909.md` reports so far: every one discloses
"reused reviewer, not a fresh task," and the reviews stayed narrow — Cloudreach
has had zero visual review, Water has had none beyond creature-road-visibility.
Never let the lane go dormant, but stop running it as one serial cycle.

## What's actually wrong, so it isn't rediscovered

The same defect language recurs across everything reviewed so far: noisy or
competing surface color, weak facial contrast, no value hierarchy, blotchy
ground material. That shows up on the creature roster, on Torrentoad
specifically, on both reviewed Meadows landmarks, and on Stormwood's ground.
That is one shared cause, not five unrelated ones. Every fix landed so far
(Arlo's jacket color, Torrentoad's pose timing, Stormwood's daylight lighting)
treated one instance instead of the shared system underneath it.

## The real parallelism model — use what the hardware actually allows

**Judging and code-level root-cause work are not render-bound.** Nothing stops
many fresh, blind judge subagents running at once against already-captured
frames, or many subagents investigating/editing shared material, shader and
lighting files concurrently. Use that freely, starting now.

**Screenshot capture is render-bound.** One Godot process per machine is this
project's own established ceiling (`AGENT_WORKFLOW.md` §3, PR #83's own
reasoning). Before relying on parallel capture across biomes: test whether a
second git worktree (its own `.godot/` import cache) actually sustains a
second concurrent render on this hardware without degrading either, and report
that result. If it can't, capture sequentially but completely — full
catalogue, day and night, one biome at a time — rather than the ad hoc renders
that have been happening.

**The shared-system fix stays ONE lane, never split per biome.** Splitting it
would recreate the exact instance-by-instance pattern above, with the added
risk of several sessions independently patching the same shared material file
and conflicting with each other.

## Work, in priority order

1. **Free win, minutes not a project.** Two separate waves flagged a blank
   rectangular panel beside the Meadows waterfront doorway as reading like
   unfinished/missing scenery. Find it, give it real material or remove it.
   Do this first.
2. **Root-cause the shared creature material/shader template** driving the
   facial-contrast and surface-noise problem repeated across the roster and
   Torrentoad. Fix the value-hierarchy/facial-contrast rule once at the shared
   level, then re-run the judge against every creature already reviewed to
   confirm it moved all of them, not just one.
3. **Root-cause the shared terrain/ground material** behind "blotchy" and
   "repeated decorative clusters that feel assembled," seen on both Meadows
   landmarks and Stormwood's ground. Fix once, re-verify against all three.
4. **Root-cause the night exposure/fill floor.** Every night frame reviewed so
   far (Meadows canonical night, Stormwood Crown night) loses the trainer's
   legs and most terrain to black. Fix the exposure/fill curve once, re-verify
   against both.
5. **Torrentoad, round 3 of its 3-round cap.** Both rounds so far found the
   same two defects: unclear eyes/face, and front digits clipping into the
   floor in the low pose. A third round of pose-timing polish without
   addressing either repeats the two-no-yield pattern this project already
   has a rule against. Round 3 must address the face/eye markings and the
   floor-contact clipping specifically, or register the subject in
   `docs/SECOND_PASS_BACKLOG.md` with all three verdicts and stop.
6. **Arlo's identity — decide explicitly.** The accent-color fix landed and
   was judged twice; both times the verdict was "doesn't address identity."
   Either scope a genuine identity pass (costume/accessory — no new humanoid
   mesh without owner reference art, per `CLAUDE.md`) or explicitly register
   "generic identity, accepted for now" in `docs/SECOND_PASS_BACKLOG.md`.
   Don't keep re-reviewing the same color accent expecting a different verdict.
7. **Cloudreach: full survey, never yet done.** Every destination in its slice
   of `data/config/debug_teleport_spots.json`, day and night, judged fresh.
8. **Water: composition/landmarks, not just creature-road-visibility.** Same
   full-catalogue treatment for Water's actual environment.

## Judge protocol, unchanged and non-negotiable

Fresh judge instance per subject/location. Never reused across waves. Never
told what changed or which round this is. Full `.claude/skills/visual-judge`
rubric every time, not a narrow two-crop comparison. No numeric scores.

## Evidence loop

After each fix in items 2–4, re-run the judge against every previously
reviewed subject that showed that defect class, not just the one it was found
on. A fix that only improves the location it was tested on is not a
root-cause fix; log it as local and keep looking.

## Unchanged

The Stage C6 full-audit directive
(`OWNER_DIRECTIVE_2026-09-08_STAGE_C6_FULL_VISUAL_AUDIT.md`) and existing art,
scale, evidence and resource rules remain applicable. The separate
earned-content lane continues unaffected; serialize only on files both lanes
touch, or on the render lock itself. This instruction does not turn a narrow
fix into whole-biome or shipping-art acceptance.
