# Focused aim commit diagnosis — 2026-09-09

## Verdict

**A real driver check-to-commit race is reproduced without the campaign world.**
The helper's released-look readiness returns after a physics callback, then parses
the physical X event. Camera follow can run before the throw's next physics input
poll. The production commit correctly rejects the now off-body ray. A second native
case falsifies the proposed timer-only repair: dispatching after camera process still
allows target physics movement before the throw commits.

No production aim/camera defect is established, no production file was edited, and
no helper repair or campaign completion is claimed. The next bounded task is a
**driver centering/motion guard proof**, not another campaign. There was no fourth
fresh campaign in this lane.

## Starting evidence, read directly

`AIM-COMMIT-RACE-HANDOFF.md` and `.artifacts/wave8-memory-watched-fresh.log`
were read before the previous probes. The latter's lines 107–109 show current and
cached preview eligibility true at physical input, then production commit false:

| Boundary | Reticle offset / unchanged radius | Verdict |
|---|---:|---|
| Driver input | 1.083119 / 1.132625 | current eligible, target first hit, LOS true |
| Cached physics preview at input | 1.087712 / 1.132625 | eligible, physical path clear |
| Actual production commit | 1.191 / 1.133 | `reticle_outside_body`, target first hit, LOS true |

The first unassisted orb physically struck at offset 0.158. The second ordinary
throw committed eligible at 0.622 / 1.133 and retained assist. The live catch
completed at +102.09 seconds, exploration resumed with two creatures, and the
driver began walking toward the Gate Key. The verified process was then stopped
by the external operator under the owner stop rule. **This is operator-stopped
evidence of an earlier stale dispatch, not a terminal harness failure or a failed
catch.** The continuous campaign remains incomplete.

The player position and forward vector are unchanged across the first readiness
receipts, while lens position advances. The log does not record the commit-time
lens, rig pivot, arm hit length, or target centre. It therefore cannot uniquely
apportion that final 0.108 m offset increase between target motion and camera follow.
Do not upgrade the native sufficient-cause result into that missing measurement.

## Actual callback and cache sequence

- `tests/helpers/gate_a_opening_drive.gd::_aim_camera_at` accepts angular error
  within the existing one-degree window **or** `_shot_is_eligible()`. Thus a ray
  close to the outer production boundary can end steering well outside one degree.
- `_released_aim_is_ready` releases the right stick, awaits a zero-second
  **process** timer, then a zero-second **physics** timer, then reads readiness.
  These timers are post-node callbacks. Its last return is post-physics.
- `fresh_opening_segment.gd::_final_throw_verdict_ready` synchronously checks
  active aim, current production eligibility, nonempty cached preview, and clear
  trajectory. `_tap_action` then calls `Input.parse_input_event` with the real
  configured joypad button. No await separates this predicate and parse call.
- `camera_rig.gd::_process` applies look and follows the player. Released look
  stops angular input; it does not stop positional smoothing. `_physics_process`
  handles conversation framing only when conversation framing is active.
- `throw_aim.gd::_tick_aiming` updates the physical preview and cached
  `_aim_report`, then polls `Input.is_action_just_pressed`, then calls the real
  `_commit_launch_assist`. The commit recomputes geometry; it does not trust the
  driver's earlier cached verdict.
- `creature_body.gd::_physics_process` actually moves through `move_and_slide`.
  The world target may therefore move in physics before the throw polls input.

Native receipts also show `pressed=false` immediately after `parse_input_event`
and `pressed=true/just_pressed=true` on the following physics pass. Parsing the
event is not synchronous production commitment in this configuration. Merely
flushing input after the old post-physics check would not make a subsequent
production physics callback occur before camera process.

## Small native regression

Owned probe: `tools/aim_commit_focused_probe.gd`. It creates one small Node3D world,
a stationary CharacterBody thrower, one sphere-shaped CharacterBody target, the
real SpringArm camera script, and the real throw script. Instrumentation subclasses
call `super()` and record boundaries. Input uses the actual opening helper's pad
binding. No manual production callback stepping, world boot, Terrain3D, render,
stock override, inventory grant/write, HP change, save or progress fixture occurs.

The isolated initial follow destination is fixture setup, before readiness; no
camera transform is written. The moving control uses native `move_and_slide`.
Each fixture is destroyed immediately after commit, before the stock-spending
release windup. This proves commit behavior, not orb flight or catch completion.

This deliberately calls the existing released-readiness subroutine and dispatch
boundary, not the entire steering/approach loop. It isolates the remaining interval
that `tools/aim_readiness_regression.gd` did not cover.

| Case, fixed native 60 Hz | Driver boundary | Actual result |
|---|---|---|
| Existing post-physics dispatch, unsettled follow | current/preview eligible at 0.832 / 1.360, clear trajectory | one camera process, offset 1.492, unassisted commit |
| Stationary control | current/preview eligible at 0 / 1.360 | assisted commit |
| Additional post-process check, same unsettled follow | current now false at 1.492; preview still old/eligible | refuses before pad press |
| Additional post-process check, smaller follow residual | current eligible at 0.746 / 1.360 | assisted commit |
| Additional post-process check, target moving at 2.4 m/s | current/preview eligible at 1.340 / 1.360 | target moves 0.040 m in next physics, commit off-body at 1.380 |

Assertions verify the following, rather than inferring them from an overall pass:

- Follow-only failing interval: exactly one native camera process after parse,
  target unchanged, forward unchanged, local camera transform and spring hit
  length unchanged, current and preview initially eligible, LOS still clear at
  the actual off-body commit.
- Target-only failing interval: no camera process after parse, lens unchanged,
  forward and arm unchanged, native target displacement exceeds 0.039 m, same
  initial current/preview and final clear-LOS off-body verdict class.
- Stationary and safe-follow positive controls physically commit with assist.

With forward fixed, spring extension alone translates the lens along that same
ray and cannot change perpendicular reticle offset. The fixture further excludes
it by directly asserting unchanged local camera and hit length. Spring occlusion
could still affect LOS in another case; neither failing interval here loses LOS.

## Commands, results and preserved failed fixture attempts

Use the installed console executable:
`C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`.
Set a new isolated APPDATA directory for each invocation. The final contract run was:

```powershell
$env:APPDATA='C:\Projects\Tetherbound\.artifacts\aim-commit-focused-profile-05'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script tools/aim_commit_focused_probe.gd -- --require-assisted-commit
```

Final receipt `.artifacts/aim-commit-focused-05-contract-red.log`: **24 checks,
22 pass, exactly 2 expected contract failures; exit 1.** Those failures are
`legacy: ready physical press MUST retain actual production assist` and
`post-process target motion: ready physical press MUST retain actual production
assist`. No `ERROR:` or `SCRIPT ERROR` appears. This is intentionally a red
regression against existing behavior; it is not a passing helper fix.

Without `--require-assisted-commit`, the probe tests the diagnostic expectations
(including reproduction of the two defects) rather than claiming they are fixed.
Do not put that mode in an acceptance chain as proof the driver is repaired.

Earlier local receipts remain in `.artifacts/`; telemetry payloads are not committed:

1. `aim-commit-focused-01.log`: first fixture warmed six physics ticks but reached
   its first camera process with the startup delta. Follow jumped 3.51 m before
   readiness; the required initially-ready condition failed. This was **not** a
   reproduction of the requested remaining interval. Added idle warmup, without
   changing production/helper behavior. The early negative-assist assertion could
   pass with zero commits; it was corrected to require an actual commit as well.
2. `aim-commit-focused-02.log`: eight diagnostic checks passed. First clean native
   follow-only reproduction: 0.832 to 1.492, stationary control assisted,
   post-process check refused. Real variable frame timing, max FPS 60.
3. `aim-commit-focused-03.log`: adding the native moving target revealed two fixture
   assumptions. Variable process delta gave the follow case only 1.186 m at commit,
   correctly retaining assist; teleporting the target's initial condition after
   physics warmup left its raycast shape stale and invalidated initial LOS. Both
   failed prerequisites are retained, not counted as regression passes. Initial
   target placement was moved before physics-space warmup; fixed-FPS engine
   scheduling now makes the single-step diagnostic deterministic. No manual tick
   or changed tolerance was substituted.
4. `aim-commit-focused-04.log`: all 12 diagnostic checks passed for the five cases
   after those fixture corrections. This was followed by adding explicit interval
   invariants and the strict red-contract mode; receipt 05 is that final source.

These are tiny diagnostic development attempts, not fresh campaign retries. They
show why a merely capped real-time fixture is not a deterministic regression for
crossing a particular boundary on one particular step.

## Bounded Sol brief: centering and motion guard, proof before integration

Branch: shared `codex/four-biome-audit-resume-0908`; do not switch, reset, amend or
push. First own a new `tools/aim_commit_guard_*` probe and a separate short report.
Root may subsequently grant the narrowly required helper ownership. Do not edit
`scripts/player/camera_rig.gd`, `scripts/combat/throw_aim.gd`, creature movement,
catching data, save/inventory/progression, camera-audit tools or existing assertions.

Player-path outcome: when the fresh driver declares its throw ready and issues one
ordinary X press, the actual production commit retains the eligible/clear verdict.
Driver centering precision is permitted to be tighter than production eligibility;
production's radius is a legal gameplay tolerance, not proof a moving ray will
remain legal at the later input poll. A refused candidate must resume steering
within the **same existing deadline**, not restart the budget or add a throw retry.

Work in this order, bounded to one implementation proposal and one falsification:

1. Preserve this native legacy red case and moving-target timing-only negative
   control unchanged. Preserve the safe-follow and stationary positive controls.
2. Prototype a driver-only readiness/centering predicate. Start with the existing
   one-degree precision instead of accepting `_shot_is_eligible` as sufficient
   convergence. Express any additional safety budget in metres of actual reticle
   geometry and motion; do not select a magic body fraction just to green a sample.
   If a candidate fails the stronger predicate, the loop must actually steer:
   keeping the old `or _shot_is_eligible()` candidate branch while only tightening
   its readiness callback can repeat release/check forever with no stick correction.
3. Use the geometric bound for a fixed released heading, with perpendicular
   projection P: `offset_at_commit <= offset_now + |P(target_delta)| +
   |P(camera_delta)|`. A follow residual projected from current rig pivot toward
   its real destination can bound camera translation; one prior observed drift is
   only an estimate, not a bound. Target velocity alone omits acceleration and the
   input scheduling interval. Explicitly state what the proposed guard bounds,
   what it only estimates, and what uncertainty causes it to keep steering.
4. Test the full proposed steering-to-dispatch path against the real rig and real
   input in both failing initial conditions, then a moving centered positive
   control and the real blocked-trajectory/no-spend control. Add one different
   process/physics ratio: a post-process timer is not proof that another idle
   callback cannot occur before the next physics tick. Keep the production commit
   and physical-preview assertions strict. Check the native phase trace, not just
   the driver's returned bool.
5. Only after that proof, and root ownership approval, make the smallest coherent
   helper edit. Existing gates remain active aim, current production eligibility,
   nonempty physics preview, clear physical trajectory, unchanged time budgets,
   ordinary pad input. Run the focused proof and
   `tools/aim_readiness_regression.gd` (including its existing legacy and blocked
   controls). Any full-world/campaign invocation requires a new root decision;
   this brief grants none.

Stop if the first proposal still produces ready-to-off-body commitment or can only
be made to pass by arbitrary waits, retries, a widened radius, test weakening,
physics/target freezing, camera teleport, fixture progress, or a production test
hook. Report the counterexample and hand back. Do not micro-tune the same axis.

**Precisely unresolved:** the production log lacks the final transform receipts
needed to divide its one offset increase between follow and target movement, and
no proposed driver guard has yet proved a sufficient motion margin through actual
buffered input delivery and production callbacks. The two native sufficient causes
and the failure of a timer-only repair are now established; a safe helper fix is
not. Other lanes can proceed while this bounded proof is evaluated.

## Scope and commit

Only this report and `tools/aim_commit_focused_probe.gd` belong to this lane.
No production functionality changed. No rendered evidence, full suite or campaign
was run or claimed. Normal commit on the assigned shared branch; parent handoff
provides the resulting SHA. Existing other-lane work is left untouched.
