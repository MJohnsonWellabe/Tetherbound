# No-windup source diagnosis and proposed next experiment

2026-09-09. Source-only review after the retained first real-manager failure.
No additional Godot run, shared-helper edit or world mutation was performed.

## Established behavior and missing evidence

`throw_aim.gd:341` sets a 0.15-second entry guard. Its physics callback subtracts
delta before `_tick_aiming`; while guard remains positive, line 311 returns
before checking a launch edge. Holding the button beyond guard expiry does not
launch: line 318 requires a new just-pressed edge. The tiny proof fixture set
the guard to zero as disclosed, so it did not cover this native entry interval.

The inherited `_open_throw_aim()` calls `_tap_action(THROW_ACTION)`, which waits
three physics signals with the pad held and five after release. It returns as
soon as `is_aiming()` is true; it does not require guard expiry. The right-stick
convergence gate checks geometry and physical trajectory, with one post-camera
and post-physics refresh. Those checks are not a nine-tick minimum. Thus source
permits a still-guarded strict geometric verdict, but does not prove it happened.

In the retained run the final manual `_tap_action` returned at physics 266;
its eight physics waits put its invocation at physics 258. No timestamp records
the moment aim opened, the dispatch guard, or the action edge consumed by
ThrowAim. The native target became geometrically ineligible by tap return, but
that alone cannot explain **no commit**: production permits unassisted commits.
Consequently the guard is one plausible cause; lost/batched physical edges
remain another. The receipt does not distinguish them. Do not turn this into a
confirmed entry-guard defect without the missing callback evidence.

## Ordinary driver's existing retry and uncovered risk

The earned catch loop already tolerates an ignored launch. After its existing
360-frame outcome observation, unchanged stock and no strike increment the
shared refusal counter, decrement the attempted launch, run the existing bounded
approach, and continue. It fails above eight refusals. The manual phase failed
earlier by design and therefore did not exercise this retry path.

However, the next iteration always calls inherited `_open_throw_aim()`, whose
first action is another physical throw press **before** checking whether aim
was already open. After an ignored launch leaves aim open, that press can itself
commit/release before strict readiness and before `_watch_throw_commit()` is
mounted. This is a concrete source reachability gap, not a claim that the failed
world run spent an orb. Confirmed cancellation is different: it reaches IDLE,
so the subsequent aim-open press really opens aim again.

## Smallest proposed lawful changes, pending review

1. Make the **earned driver's** aim-open operation idempotent: if the actual
   manager is already aiming, return true without input; otherwise delegate to
   the existing bounded implementation. This removes the unintended launch in
   the ordinary ignored-press retry. It adds no retry or waiting budget and does
   not change production behavior or the inherited legacy fixture driver.
2. If observation confirms the entry-guard cause, strengthen earned convergence
   readiness with `float(throw.get("_guard")) <= 0.0`, inside its existing time
   deadline. Add the same fail-closed requirement to the final synchronous
   verdict. Never assign the guard or sleep an extra fixed interval. Preserve
   active aim, current eligibility, nonempty preview and clear trajectory.
   This proposal is conditional; no source patch has been made from a guess.
3. Do not shorten the non-cancellation 360-frame wait based merely on absence of
   a sampled commit. Proving that the physical press/release was consumed would
   be needed to distinguish an ignored edge from a still-buffered edge. Existing
   refusal accounting remains the limit until that evidence exists.

## Next bounded observation proposal

Before another real world, use the retained tiny native fixture to compare its
existing direct physical dispatch with the unmodified driver's complete
`_tap_action(THROW_ACTION)`. This specifically adds the eight-tick call absent
from the first tiny proofs. Record before and after each real ThrowAim physics
callback: physics/process IDs, delta, `_guard`, `_windup`, state, committed point,
pressed/just-pressed and preview. Record native `_input` event deliveries and
the driver's dispatch/return using instrumentation only. No manual production
callback invocation. Keep the existing geometry and one initial orb grant.

Use actual physical aim entry in a separate tiny case by starting the fixture
unarmed/IDLE as setup and invoking its real `try_begin_aim` through a native
controller-reading wrapper, if that wrapper is reviewed. Do not simulate guard
expiry with assignment after measurement starts. The actual manager remains
covered only by the real-world phase, not that synthetic wrapper.

A simpler first discriminator needs no wrapper change: retain the disclosed
zero-guard fixture and run the exact eight-tick tap, with per-callback receipts.
If it fails, stop and diagnose the event-delivery path; do not add a guard fix.
If it passes, it rules out an unconditional incompatibility of `_tap_action`
with the observer, but still does not prove the real-world guard hypothesis.
Each tiny invocation uses an isolated profile and 20-second watchdog, stop at
first failure. No full-world run is authorized by this source-only brief.

For a later separately authorized world observation, preserve the same initial
fixture and single encounter, add the missing read-only guard/input callback
receipts **before aim entry**, and enforce the reviewed readiness change only
if supported. The required end state remains real-manager physical cancellation
and the real `catch_existing` loop; a passing tiny discriminator is not that end
state and does not restart the campaign.

## Approved tiny implementation

The orchestrator approved the earned-only idempotent override and a 20-second
tiny discriminator. `tools/aim_eight_tick_probe.gd` reuses the retained native
fixture, tests that an already-aiming open returns without any physical events,
then uses a disclosed synthetic controller-reading manager wrapper to verify
the closed path delegates to the inherited eight-tick input call and native
`try_begin_aim`. That wrapper only reads the actual interact edge and invokes the
ordinary native entry method; it is not a real-manager replacement claim.
Finally the zero-guard fixture sends the complete inherited eight-tick throw,
with the actual shared observer mounted, and records native input deliveries
and pre/post native aim-tick guard/edge/windup receipts. No production guard is
mutated after case setup. One initial grant supplies four orbs for all cases.
Stop on the first failed case; do not run another world.

## Tiny result and reviewable change

First parse and first runtime both exited zero. Runtime took 2.849 seconds,
reported `PHASE_PROOF checks=5 failures=[]`, and produced no ERROR, SCRIPT ERROR
or WARNING entries. Logs: `.artifacts/aim-eight-tick-20260909/{parse,engine}.log`,
with an isolated profile in that directory.

The earned-only override is eight lines: return true without any input if the
real manager is already aiming; otherwise `await super._open_throw_aim()`.
Ten subsequent native physics callbacks after the already-aiming call saw no
pad events, no commit and no spend. The closed-case synthetic wrapper observed
one physical press/release pair, one native `try_begin_aim`, exactly eight driver
physics waits, and no commit/spend. That native entry still had guard 0.033333
after physics 43, immediately before the opening helper returned. This directly
confirms that opening-helper success does not imply guard expiry, but does not
establish the guard at the failed world dispatch.

The exact zero-guard throw call dispatched at physics 64; native input delivered
the press and ThrowAim saw `just_pressed=true` at physics 65, committed once,
and the shared observer recorded that commit. Release input arrived after
physics 67; the helper call returned at physics 72, exactly eight ticks after
dispatch. Native orb release followed at physics 76, spending exactly one orb
(four to three). This rules out an unconditional failure of the eight-tick tap
to reach ThrowAim. No stale commit occurred in this case; existing stale-cancel
proofs are separate evidence.

Next step remains a reviewed real-manager observation with before/after guard
and physical-edge receipts beginning before aim opens. The tiny result supports
observing natural guard expiry but does not justify labeling the first world
failure as guard-caused. No guard-readiness rule, fixed extra sleep, production
change, second world run or campaign replay was added. The full real catch loop
still has not been exercised by these synthetic proofs.

## Approved natural-guard causal follow-up

The next authorized tiny probe is `tools/aim_natural_guard_probe.gd`. In one
closed-case fixture it opens through the proven physical controller path,
immediately sends the inherited eight-tick throw while the naturally remaining
entry guard is positive, and records the real launch edge at ThrowAim's native
callback. It then observes natural guard expiry during those same eight ticks,
uses ordinary bounded steering, and sends a fresh edge with the shared helper.
One initial orb grant; no guard/state mutation after the closed-case setup.
20-second watchdog, isolated profile, parse first, stop at first failure.
Only a causal guarded-edge rejection result authorizes strengthening earned
readiness with guard<=0; that change must remain inside existing deadlines and
retain all geometry/active-aim conditions. The old world's cause stays unknown.

## Causal tiny result and authorized readiness correction

First causal parse/runtime succeeded: seven checks, 2.459 seconds, no engine
errors or warnings. Natural opening returned with guard 0.0333333 at physics 22;
the fresh interact edge at physics 23 was ignored while the guard was still
strictly positive, with no commit/spend. The default numeric rendering rounded
that tiny positive residual to `0.0`; the assertion compared the actual float.
The following validation added both `guard_positive` and 20-decimal guard text
to eliminate that reporting ambiguity. Native countdown eventually reached
exact zero; a new edge committed at physics 38 and released one orb at 49.

This confirms native guard rejection **in the tiny fixture**. It does not assign
that cause retrospectively to the uninstrumented first world run. With that
causal evidence, the conditionally authorized correction was implemented:
earned `_aim_readiness_ready()` returns false while guard>0 inside its existing
convergence deadline, and `_final_throw_verdict_ready()` fails closed with an
explicit guard message if that condition somehow reaches dispatch. All prior
active-aim/eligibility/preview/trajectory checks remain. No extra wait, timeout,
launch/refusal allowance, production guard write or production behavior change.

The subsequent first validation of the changed readiness passed eight checks
in 2.514 seconds, no engine errors or warnings. It directly asserted earned
convergence rejects the naturally positive guard; expired-guard ordinary
steering and final dispatch passed, followed by a real fresh-edge commit and
one-orb release. The trace at physics 22 shows `just_pressed=true`,
`guard_positive=true`, and guard `0.00000000000000002082`: production correctly
ignored this edge under its existing strict comparison. A later tick clamped
the countdown to zero without intervention. This is why the driver uses the
same strict guard comparison instead of an approximate-zero threshold.

Artifacts: `.artifacts/aim-natural-guard-20260909/{parse,engine}.log` for the
causal proof and `.artifacts/aim-natural-guard-readiness-20260909/{parse,engine}.log`
for validation using `-- --verify-readiness`, each with isolated profiles. Both
runtimes terminated within their 20-second watchdogs. No world was launched.

## Proposed final real-manager proof, pending review

Authorize one additional synthetic **encounter integration proof**, using the
same original real-manager brief, initial Terrapup/fifteen orbs, single human
placement, normal 60 Hz, same authored practice creature and unchanged 590/600s,
90%/400-process guards. This is not a second attempt at the unchanged hypothesis:
the driver now has independently proven idempotent opening and stricter native
readiness. It remains no campaign or chapter replay and earns no campaign credit.

Before physical aim entry, mount read-only sibling observers immediately before
and after the real ThrowAim node, at the same physics priority. Record frame IDs,
native guard with positive boolean/precise text, state, windup, committed point,
preview, and physical pressed/just-pressed/released edges. Add an `_input`
receipt node for delivered mapped events. These nodes must not tick or mutate
the real manager/ThrowAim, intercept events, change process priorities of game
nodes, or move actors/camera. Bound detailed sampling to the manual input phase
and actual catch throw intervals; retain terminal receipts before cleanup.

Then execute the original two phases without changes: exact eight-tick manual
valid-windup cancellation and three subsequent HUD idle polls; followed in the
same encounter by a fresh driver's real `catch_existing` loop, no health or
inventory repair. Require every original manager/identity/stock/catch assertion.
If no natural invalid commit happens, report composition rather than claiming
full-world invalid-commit cancellation. Stop at the first failed phase and
retain it. Use a new artifact basename so the first failure cannot be overwritten.

No new real-manager probe implementation or world launch is authorized until
the orchestrator reviews this proposal and grants the world lease.
