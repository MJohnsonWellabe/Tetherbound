# Earned aim shipping review — 2026-09-09

Verdict: approved for an isolated main-based PR and its required CI. No correctness
blocker found in the reviewed aim change. This is not a landing, campaign, visual,
or chapter-acceptance verdict. The final isolated PR head still needs executed code
jobs and the orchestrator's landing verification.

Reviewed against `origin/main` at `4830bf402`. Read the hard rules, routing,
orchestration contract, relevant workflow/architecture material, source diff,
native ThrowAim lifecycle, inherited pad input implementation, retained probes,
and the three aim implementation/result reports. No Godot process was started,
branch switched, or implementation file edited for this review.

## Code findings

- Earned convergence and final dispatch retain active-aim, current eligibility,
  nonempty preview, and physical trajectory checks. Both now reject a strictly
  positive native entry guard. This matches production's strict comparison,
  including the measured tiny positive floating-point residual; it does not add
  a sleep, change the guard, or enlarge the inherited convergence deadline.
- Already-open aim returns without an input edge. Closed aim still delegates to
  the inherited bounded physical opening. This removes the source path where a
  refusal retry could launch before the final verdict and observer installation.
- The shared observer is mounted immediately after ThrowAim with the same
  physics priority. It reads the first positive windup, committed point, and
  native preview. Invalid commits send the mapped physical `menu_cancel` press,
  then release it after native IDLE is observed. It calls no game tick, leave,
  release, health, inventory, or pose mutation method.
- Native ThrowAim handles cancellation before decrementing the windup and
  before `_release()` spends stock. The observer's next-tick cancellation is
  therefore consistent with production ordering. The retained 15 FPS case also
  demonstrates cancellation across two physics callbacks in one process frame.
- Cancellation checks unchanged stock and shares the existing refusal counter
  (failure above eight); it removes the cancelled attempt from the 40-launch
  counter. The 360-frame outcome and 900-frame post-strike bounds are unchanged.
  Ordinary ignored-press refusal handling remains intact. No orb repair occurs.
- Every result branch after observer creation follows `stop()` and
  `queue_free()`. The helper releases any held cancel on normal completion,
  explicit stop, and tree exit. This review does not claim every hypothetical
  external interruption was runtime-tested.

The relevant production ThrowAim, Meadows CombatManager, HUD, input map,
inherited opening driver, and common phase-probe source have no diff from the
reviewed main. The common phase probe and stick navigator already exist there.
Pending Stormwood/net, water, visual, and unrelated workflow work must stay out
of this isolated aim PR.

## Evidence checked directly

Retained tiny logs show 19 windup checks, eight actual-HUD checks, five exact
eight-tick/idempotence checks, and eight natural-guard/readiness checks, all with
empty failure lists. The windup receipts include stale commit without the helper,
shared-helper cancellation at 49→50 with stock four, eligible release spending
one orb, blocked dispatch with no commit/spend, and 143→144 cancellation within
process frame 95. The actual HUD receipt remains tool-empty and stock-four after
its later idle polls; its separate B positive control establishes that ordinary
HUD polling really can equip the tool.

Read the actual `.artifacts/aim-real-manager-guarded-20260909/telemetry.jsonl`,
engine log, wrapper result, and resource sample file. The telemetry confirms:

| Receipt | Verified state |
| --- | --- |
| Manual commit, physics 266/process 100 | Valid committed point, guard zero, stock 15 |
| Manual cancel, physics 267/process 100 | Aim closed, fight and both creature identities retained, stock 15 |
| Tap return 272 and post-HUD receipt 277 | Aim closed, fight retained, tool empty, stock 15 |
| Native release 692 / strike 716 | One release, one strike, stock 14, no miss |
| Capture resolution 1023 | `catch_resolved:true:3` |
| Actual catch return and terminal 1121 | Outcome caught, fight ended, party two, stock 14, failures empty |

The catch windup samples have a finite committed point, eligible preview and
clear trajectory. There is no observed natural invalid commit or shared-helper
cancellation in this world catch phase. Its manual cancellation deliberately
cancelled a valid commit. Therefore the supported conclusion is composition:
tiny invalid-commit cancellation plus actual manager/HUD ownership plus actual
`catch_existing` success in one synthetic encounter. It does not establish
full-world natural-invalid-commit cancellation or continuous earned campaign
completion, and does not authorize a fourth fresh campaign.

The engine log contains the explicit successful terminal verdict, zero ERROR or
SCRIPT ERROR entries, and thirteen terrain/interpolation warnings. The wrapper
retains a null native exit code; it is not presented as an exit-zero receipt.
Its timestamps give 88.224 seconds. The 33 resource rows peak at 57.57% commit,
245 processes, and 2,213,638,144 owned private bytes. Runtime source hashes for
the real-manager probe and earned driver match the published report exactly.
The older failed world result remains separate and its cause remains unknown.

## CI review

`.artifacts/aim-pr-ci/ci.yml` differs from main by exactly the four-line earned-aim
step after setup in `verify-regions-shard`. It preserves main's existing tests.
`tools/ci/verify-earned-aim.sh` uses separate XDG profiles, one attempt per case,
30-second external bounds, full logs, both pipeline statuses, error scanning,
and exact complete-check summary matching. A printed success cannot hide a
preceding native error. Its four selected cases require 19, eight, five and eight
checks respectively; no world/campaign replay is added to CI.

The review recommendation to add the existing five-check
`tools/aim_eight_tick_probe.gd` to this same runner has been applied and inspected.
The natural-guard subclass
overrides `_run()`, so running it does not execute the parent probe's explicit
already-aiming/no-input idempotence assertion. The retained local proof is valid;
the fourth CI case now keeps that behavior under future regression coverage.
Require the first actual isolated-head CI result before landing.
