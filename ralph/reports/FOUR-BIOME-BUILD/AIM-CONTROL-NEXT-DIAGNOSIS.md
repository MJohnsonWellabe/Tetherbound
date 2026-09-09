# Aim control next diagnosis — 2026-09-09

## Decision

**Do not integrate or tune `aim_commit_guard_probe.gd` at `3194ceafa`.** Its
one-degree conjunction is unnecessary for the perpendicular-distance inequality,
and the reported failure is acquisition liveness, not insufficient geometric
margin. Removing that conjunction is mathematically legitimate **only with a
proved displacement bound**; the existing proposed target bound is not one for
the real wild creature. A controller timing correction has a concrete source
cause and merits one finite native proof, described below. Neither that correction
nor a safe dispatch guard is claimed implemented or proven here.

The strongest new distinction is **production callback order**. The ordinary
solo Meadows target moves *after* ThrowAim, whereas the focused and guard probes
place their target *before* ThrowAim. The reverse-order probe remains a valid
adversarial sufficient cause. It is not the actual tutorial's callback sequence.
Do not infer one target movement before each production commit from that fixture.

This diagnosis changed only this report. No campaign, world boot, focused probe,
production callback, render, save, inventory or progression operation was run.
The executable's read-only `--version` returned
`4.7.stable.official.5b4e0cb0f`. Source was inspected at branch head `4e653e9b3`;
concurrent independent lane changes are outside this report's ownership.

## What failed, and what did not

The existing reports preserve different verdicts that must stay distinct:

- Wave8's first dispatch passed the driver's strict current/preview check, then
  production rejected assist at `1.191 / 1.133 m` with clear LOS. Its unassisted
  orb physically struck. The second ordinary throw retained assist; the earned
  catch completed at +102.09 seconds and the driver walked toward the Gate Key.
  The operator then stopped it under the repeated-class rule. This was neither
  a failed catch nor a terminal harness failure. The continuous campaign remains
  incomplete, and there is no authorization for a fourth attempt.
- The stale dispatch violates the **driver expectation** that readiness predicts
  the later production verdict. It does not establish that gameplay's strict
  off-body rejection is wrong. Catch success does not erase the stale dispatch;
  stale dispatch does not make a physically earned catch fictitious.
- The guard's moving case never dispatched. At its unchanged four-second deadline,
  strict production readiness and `0.4643 < 1.36 m` held, but one-degree centering
  did not. That is a new driver gate's liveness failure, not an off-body commit,
  insufficient margin, failed production catch, or proof that the target is
  impossible to aim at with normal controls.

Evidence: `AIM-COMMIT-RACE-HANDOFF.md`, `AIM-COMMIT-FOCUSED-DIAGNOSIS.md`, and
`AIM-COMMIT-GUARD-PROOF.md` in this directory. No new runtime result supersedes them.

## Native order, including buffered input

Godot 4.7 flushes agile input before each physics iteration, increments the physics
frame, executes that iteration, then flushes again before idle processing. Several
idle passes can precede the next physics iteration; a busy frame can execute several
physics iterations before idle. These are phase order facts, not a fixed 1:1 clock.
[Engine main loop, lines 4605–4686](https://github.com/godotengine/godot/blob/4.7-stable/main/main.cpp#L4605).

SceneTree emits `process_frame` before node `_process`; its process timers run
after node processing. Likewise, `physics_frame` precedes physics callbacks and
physics timers follow them. Equal physics priorities use scene-tree order.
[SceneTree](https://github.com/godotengine/godot/blob/4.7-stable/scene/main/scene_tree.cpp#L596),
[node comparator](https://github.com/godotengine/godot/blob/4.7-stable/scene/main/node.h#L177).

`Input.parse_input_event` can enqueue instead of applying the event. When the
engine actually applies a newly pressed action, it stamps
`pressed_physics_frame = current_physics_frame + 1`; physics `just_pressed` tests
that stamp. Thus even explicitly flushing a press from a helper physics callback
before ThrowAim does **not** make that callback's current-tick poll see a new press.
Do not propose an allegedly atomic same-tick callback/flush workaround.
[Input implementation, lines 958–964 and 1410–1468](https://github.com/godotengine/godot/blob/4.7-stable/core/input/input.cpp#L958).

The inspected ordinary solo world has this relative tree order, all relevant
script physics priorities unchanged from zero:

1. `CameraRig`: native SpringArm internal physics plus the camera script (the
   latter does no physics framing while an ordinary catch is active).
2. `Player`, inheriting `player_controller.gd` through `local_rig.tscn`.
3. `CombatManager`, then its child `ThrowAim`, created in manager `_ready()`.
4. `EncounterDirector` and later dynamically appended ordinary wild/follower
   bodies. The cluster spawn uses `get_parent().add_child(wild)`; normal
   `spawn_wild` also defaults to that parent.

Source: `scenes/world/meadows_playground.tscn:71–119`,
`scripts/combat/combat_manager.gd:277–283`,
`scripts/combat/encounter_director.gd:660–662,958–970`, and
`scenes/player/local_rig.tscn`. No relevant reprioritization/reparenting was found
in the inspected camera, manager, director or creature scripts. This is a
source-derived ordinary-solo order, not a new runtime trace of wave8. An explicitly
parented encounter, network proxy or other scene must establish its own order.

Consequently, from the existing **post-physics** readiness check to the next
ordinary-solo ThrowAim poll, the normal wild script has zero intervening movement
callbacks, assuming aim stays active and input is delivered for that next poll.
The trainer does get a physics callback before the poll, but the rig is top-level
and follows in idle, so that next trainer displacement is not immediately applied
to the lens before the poll. The rig can still consume its existing follow
residual in any intervening idle callbacks. This explains why a stationary-player
requirement is stronger than necessary for the camera-residual argument in this
particular order. It does not prove a moving hand's physical arc remains clear.

SpringArm runs in internal physics and places children along its +Z axis while
preserving their basis. With the current unrotated child camera and released rig
heading, spring movement is parallel to the camera ray: it cannot change
perpendicular offset, but can change the ray origin and therefore LOS/frontness.
[SpringArm implementation](https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/physics/spring_arm_3d.cpp#L126).

## A real controller phase defect, separate from the guard

`gate_a_opening_drive.gd:782–831` sends right-stick events and awaits
`process_frame`. At that signal, the engine has already done its pre-idle input
flush but the camera has not processed. The helper reads the previous camera
orientation and sends another command, which remains buffered during this camera
callback. The camera therefore applies the preceding delivered command, not the
one just sent at the signal.

`_calibrated_deflection()` at lines 893–916 stores the most recently commanded
deflection and assumes the measured turn belongs to it. During the signal-driven
loop these can be one command apart. On an initial no-turn sample it doubles the
deflection; after a release refusal `_aim_has_history` is cleared and that
uncalibrated branch is revisited. Releasing at the same pre-node signal also leaves
the previously delivered nonzero stick active for that camera process; the queued
zero does not retroactively cancel its turn. The existing process/physics settle
correctly observes the result, but does not prevent this extra turn.

That source mechanism is consistent with the failed report's tiny pre-release
offset followed by a larger post-settle offset. It is **not yet runtime isolation
of how much** of each offset change was stale angular input versus target/follow
motion. Do not claim a fixed proportional gain, minimum deflection, longer wait or
one-degree retuning repairs it.

A justified candidate correction is to pair each command with its actual
post-camera observation: replace the steering loop's pre-node frame-signal sampling
with one post-process observation per commanded update, maintaining a record of
the deflection whose delivery/turn was observed. This changes sampling phase,
not the timer deadline or the number of allowed acquisition attempts. It must
also avoid calibrating a stationary/released interval as a commanded turn.

## Which margin is sound, under which assumptions

For fixed unit heading `f`, let `P = I - f*fᵀ`, target center `T`, lens `C`, and
unchanged production radius `R`. The triangle inequality gives

```
|P(T_commit - C_commit)|
  <= |P(T_now - C_now)| + |P(delta_T)| + |P(delta_C)|.
```

No one-degree conjunct appears or is needed. Requiring active aim, the unchanged
current eligible verdict, nonempty clear physical preview, and a **valid** bound
within `R` permits legally off-center shots without relaxing production's body or
LOS assertions. A refused candidate still has to issue steering within the same
deadline; retaining the old eligibility shortcut with a stricter callback alone
would allow a release/check loop that never corrects aim.

The entire projected follow residual is valid for any number of positive-lag
exponential follow steps toward one fixed destination. In the verified ordinary
solo order above, the followed trainer's last post-physics position is fixed
through those intervening idle steps; its next physics motion precedes commit but
no following idle step. Pending look, recenter/mouse input, camera retargeting,
conversation framing, a different tree order or delayed input delivery invalidate
that argument and must not silently be treated as zero. A changed heading requires
a rotation term; the fixed-heading bound does not cover it.

For **a target that really does move before commit**, the preserved guard's
`_target_motion_bound()` is not a production displacement bound:

- `wild_creature.gd::_tick_combat()` calls `_unstick()` before body integration.
  `_unstick()` at lines 235–260 can directly move the target **0.35 m** after the
  140-frame stuck threshold. This is a concrete omitted displacement path, not
  speculation about an external platform. It is not scaled by `delta` and is not
  in `velocity`, `_acceleration`, `_gravity`, `_impulse` or `_jump_speed`.
- The body uses friction when no movement is requested, resets grounded vertical
  velocity to -2, and adds damped impulses. The bound only budgets acceleration
  and gravity as changes; projected previous total velocity does not independently
  bound changes to its horizontal/vertical components. New player-hit knockback
  (`combat_manager.gd:1270`) is distinct from the enemy's own configured lunge
  (`:1898`); both cannot be assumed exhausted by one enemy-lunge allowance.
- `creature_body.gd:1639–1643` runs native slide then arena `hold_inside`, which
  can change global position directly. Even inside the arena, projected lateral
  displacement cannot generally be bounded by projected incoming velocity when
  a collision/boundary redirects forward movement sideways.
- The real body has `floor_snap_length=0.4`; native motion includes floor snap,
  collision recovery and platform travel. Empty environment modifiers exclude
  only that repository modifier mechanism, not those native motions.
  [CharacterBody motion](https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/physics/character_body_3d.cpp#L40).
- `dt=1/physics_ticks_per_second` also assumes ordinary effective time scale;
  callback count and actual step duration must be observed or justified.

The trainer is not a stationary CharacterBody fixture either: aiming enables its
locomotion (`throw_aim.gd:355`), and releasing the left stick permits friction,
gravity, environmental movement, slide, step-up and entombment recovery
(`player_controller.gd:272–292,746–788`). Its movement matters to hand trajectory
even when the narrow camera argument excludes a later idle follow.

Finally, perpendicular containment proves **only body-window containment**. It
does not prove frontness, target lifetime/visibility, camera-to-target LOS or the
hand's physical arc at the future poll. A large enough body margin cannot repair
an occlusion assertion. All those production gates and commit assertions remain
strict; none can be declared covered by this scalar inequality.

## Finite Sol handoff: prove the phase correction before selecting a guard

The justified next implementation is a **new isolated controller-phase proof**,
not a transfer or retuning of `3194ceafa`. Root assigns Sol one new probe/report;
existing helper, failed probe and production sources remain untouched until a
separate successful-proof review. This brief grants no campaign invocation.

1. Construct a small native scene with the ordinary-solo relative order above,
   actual trainer controller, actual wild creature script/body and native
   SpringArm/ThrowAim. Use a small physical floor and normal catching profile.
   Keep movement, AI and physics live. Fixture initial transforms are allowed only
   before the measured interval; no camera transform writes, freezes, HP/item or
   progression injection, stock override, or manual production callback stepping.
   Instrumentation may call `super()` and observe. Tear down at commit before
   release/spend, as the prior focused proof did.
2. First use trace assertions to isolate the existing command/observation mismatch:
   requested and effective stick, helper sample, rig before/after, target and
   trainer before/after, physics/process counts. Then implement **one** change:
   command-associated post-process sampling. Keep response curve, one-degree
   diagnostic, original four-second moving-case deadline, and strict commit/LOS
   assertions fixed. The degree gate is a diagnostic for the old liveness
   counterexample, not a newly required production acceptance rule.
3. Keep the original moving-edge/follow fixtures as adversarial controls, including
   target-before-throw. Add the production-order case as a separately named case;
   never reorder the old failing case and call it fixed. In production order,
   trace the expected zero target movements from post-physics dispatch to commit;
   in the adversarial order, trace the movement that actually occurs. Exercise
   stationary, moving and nonzero follow residual; a real blocked hand trajectory
   must refuse without a press/commit/spend.
4. One first-pass run at 60 Hz and one different process/physics ratio are the
   finite falsification set. Record actual callback counts, not just requested
   FPS. The first missing prerequisite, continuing four-second liveness failure,
   mismatched command attribution or ready-to-off-body/LOS failure ends this
   proposal. Preserve the failure and hand back; no extra waits, retries, gain
   tuning, enlarged deadline or campaign permitted.
5. Only if the phase proof succeeds, root may select a driver eligibility-plus-
   margin implementation scoped to the **observed production order**. Zero target
   motion is a schedule-conditioned result, not a universal creature bound. The
   pending-input/fixed-heading assumptions and future LOS/arc limitations above
   must be resolved explicitly before claiming safe dispatch. The old generic
   motion bound must not be copied as `certain=true`. Existing focused strict-red
   controls and `aim_readiness_regression.gd` remain required evidence for any
   eventual helper change; passing the controller proof alone does not close aim.

If the native production-order fixture cannot establish those prerequisites
without special callback placement, freezing or production changes, the handoff
is **unproved delivery/geometry interval**, not another margin experiment. The
named current cause is driver phase/command attribution plus a speculative future
motion bound; a universal helper guarantee and a gameplay defect remain unproved.

## Validation and stopping point

Validation here was source inspection, executable version identification and
`git diff --check` on this report. No runtime test result is claimed. Engine links
are the official 4.7-stable source; no master-branch behavior is used as evidence.
Stop after the normal report-only commit. Root owns implementation assignment,
integration decisions and the continuous-campaign stop rule.
