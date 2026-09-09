# Aim commit guard proof — stopped on target-centering counterexample

## Verdict

**The one permitted proposal fails. Stop; do not integrate it.** In the exact
moving-target initial condition from the focused diagnosis, the target starts at
`x=1.30 m` with current/preview production eligibility inside the unchanged
`1.36 m` reticle radius, then moves laterally through native `move_and_slide` at
`2.4 m/s`. The guarded full steering path does not achieve its new conjunctive
one-degree gate within the single unchanged 4.0-second probe deadline. No pad
press or production commit follows.

This is a centering-liveness failure, not rejection by the proposed metre margin.
At the failed helper return, the strict production gates still report ready,
`offset_now=0.4416 m`, `target_bound=0.0227 m`, and
`bound_total=0.4643 m < radius=1.36 m`; `safe=false` solely because
`centred=false`. The proposal can keep the ray comfortably inside the legal body
window while failing to satisfy the tighter one-degree convergence gate.

No helper or production file was edited. No full world, campaign, render, stock
override, save/progression fixture, camera teleport, retry, added wait, deadline
reset, widened radius, frozen target, manual production callback, or weakened
commit assertion was used. `tests/helpers/gate_a_opening_drive.gd` remains outside
this lane pending a new root decision.

## The single proposal

The prototype lives only in `tools/aim_commit_guard_probe.gd`, as a subclass of the
fresh opening helper. It removes eligibility as a convergence substitute: an
eligible candidate outside the existing per-axis one-degree window is sent back
through the existing right-stick steering loop and the same original deadline.
Rejected candidates issue real stick correction rather than looping through
release/readiness with the old `or _shot_is_eligible()` branch.

For fixed released camera heading, it proposes the sufficient geometry condition

```
offset_at_commit <= offset_now + |P(target_delta)| + |P(camera_delta)|
```

where `P` is projection perpendicular to the released heading. Dispatch is allowed
only when this upper bound fits inside the production-reported reticle radius, in
addition to active aim, current production eligibility, a nonempty physical
preview, clear physical trajectory, and the existing one-degree window.

The camera term is the entire perpendicular residual from the current real rig
pivot to the real follow destination computed from the followed node, height,
shoulder offset and yaw. This is a bound across any number of monotone exponential
follow callbacks toward that fixed destination; a previously observed one-frame
drift is not used as the bound. Spring extension along the fixed heading has zero
perpendicular projection.

The target term budgets one input-to-poll physics step from the live projected
velocity plus a full semi-implicit acceleration/gravity step, current impulse, one
possible combat-config lunge, and pending jump. The probe fails closed when these
motion inputs are unavailable or an environmental velocity modifier is registered.
This is deliberately more than a current-velocity estimate: it includes acceleration
and the buffered-input scheduling interval.

## Falsification and steering trace

The single falsification used the target-only sufficient-cause setup after physics
space warmup: camera/pivot settled, target at `(1.30, 1.00, -8.00)`, then native
lateral velocity `2.4 m/s`. The initial reticle is `1.30 / 1.36 m`, so this preserves
the focused case's initially eligible edge prerequisite. The guard sends nonzero
right-stick commands after rejecting that eligibility-only candidate.

The released-look checks then oscillate around the moving target. Representative
receipts from the one run show the pre-release sample becoming close, followed by
the existing process/physics settle returning outside one degree:

| Target x | Pre-release offset | Post-settle target x | Post-settle offset | Post-settle result |
|---:|---:|---:|---:|---|
| 1.94 | 0.139 m | 1.98 | 0.219 m | not centered |
| 2.02 | 0.181 m | 2.06 | 0.314 m | not centered |
| 2.14 | 0.065 m | 2.18 | 0.485 m | not centered |
| 2.26 | 0.051 m | 2.30 | 0.549 m | not centered |
| 2.38 | 0.166 m | 2.42 | 0.257 m | not centered |
| 2.66 | 0.104 m | 2.70 | 0.324 m | not centered |

The deadline receipt remains production-ready and within the metre margin, as the
verdict records, but it is not within one degree. This distinguishes inability to
hold the tighter centering gate through released-look callbacks from rejection by
the motion bound. Per the focused brief's stop rule, the axis was not micro-tuned
and the planned 4:1 idle/physics extension was not executed.

## Preserved controls

The unchanged `tools/aim_commit_focused_probe.gd --require-assisted-commit` contract
was rerun first-principles with a unique APPDATA profile. It retained exactly its
two expected red assertions and no others (24 checks, 22 pass, exit 1):

- legacy follow-only: initially ready real pad dispatch reaches one native camera
  process and the production commit becomes clear-LOS off-body;
- post-process target-only: initially ready real pad dispatch reaches one native
  target physics movement and the production commit becomes clear-LOS off-body;
- stationary and safe-follow positive controls retain assist;
- timer-only post-process candidate refuses before press.

The guard probe's 60 Hz run reached these results before stopping (45 checks, 4
failures, exit 1):

| Case | Result |
|---|---|
| Legacy unsettled follow | assisted production commit; dispatch bound `0.4316 m`, actual `0.0974 m`; rejected eligible candidate issued nonzero steering |
| Moving edge | **failed to become ready in the unchanged deadline**; no press or commit |
| Stationary | assisted production commit; bound and actual `0 m` |
| Safe follow | assisted production commit; dispatch bound `0.5493 m`, actual `0.1649 m` |
| Moving centered (`0.35 m/s`) | assisted production commit; dispatch bound and actual `0.0117 m` |
| Physical hand-trajectory blocker | full single deadline expires; production preview names `GuardBlocker`; no pad dispatch, commit or windup/spend path |

Every successful dispatched case recorded exactly one native target physics callback
between physical event parsing and the production commit. That establishes the
one-input-to-poll-step assumption only for the tested 60 Hz schedule. It is not proof
for a different process/physics ratio; the 4:1 falsification was deliberately left
unrun after the earlier stop condition fired.

## Limits that prevent integration

This is a small fixture result, not a universal motion bound. The camera term assumes
the rig's followed actor does not acquire additional perpendicular displacement before
commit. That holds in the fixture (stationary player; idle follow before the next
physics commit), but has not been established for the earned-world trainer. The target
term assumes the inspected creature motion fields plus one combat lunge exhaust the
ways the target can move during the next physics step; active environmental modifiers
cause fail-closed behavior, but moving platforms or another unmodelled displacement
source have not been proved absent in the earned path.

The production log still lacks the final rig/target transforms needed to apportion its
offset increase, and this proof did not establish the different-ratio scheduling or
followed-actor assumptions. More immediately, the proposal fails the named moving
case before dispatch. A fresh strategy decision is required; tightening or retuning
this same centering axis would violate the bounded brief.

## Commands

All invocations used the installed Godot 4.7 console executable and a unique APPDATA.

```powershell
$env:APPDATA='C:\Projects\Tetherbound\.artifacts\aim-commit-focused-preservation-profile-01'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script tools/aim_commit_focused_probe.gd -- --require-assisted-commit

$env:APPDATA='C:\Projects\Tetherbound\.artifacts\aim-commit-guard-profile-04'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/aim_commit_guard_probe.gd -- --physics-fps=60
```

Earlier probe executions are development receipts, not additional proposals:
profiles 01–02 corrected parse/type errors; profile 03 exposed an invalid fixture
prerequisite (motion began during warmup and the full catching shoulder profile did
not preserve the focused initially-eligible geometry). Profile 04 is the corrected,
decision-bearing run. No telemetry payload is committed.
