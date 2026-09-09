# Aim controller phase proof — stopped on command attribution

## Verdict

**The one permitted command-associated post-process proposal fails. Stop; do
not integrate it into the opening helper.** The first executable 60 Hz run
isolated the existing pre-node mismatch, then passed degree liveness and strict
commit prediction in the first two production-order cases. The nonzero-follow
case exposed a mismatched command observation immediately after a refused
released-look check: command 13 requested a nonzero stick
`(0.862905, -0.057844)`, while its paired observation saw effective stick
`(0, 0)` and zero camera turn.

That is the named command-attribution stop condition. The proposal would treat
that result as a stationary/deadzone response and double its deflection, exactly
the class the handoff required it to exclude. No alternate-ratio run, blocked
case, adversarial target-before-throw case, helper edit, campaign, or further
tuning followed.

The trace also prevents calling the first positive control physically
stationary: it seeded zero target velocity, but the real engaged wild AI remained
live and advanced longitudinally during acquisition. Production order still
gave the expected zero wild movement callbacks from dispatch to commit. The
broader stationary-control prerequisite is therefore not established by that
case, independently of the later attribution failure.

## Isolated proposal

Owned probe: `tools/aim_controller_phase_probe.gd`. It constructs a tiny native
world with a physical floor and these production scripts, using instrumentation
subclasses that call `super()`:

1. real `camera_rig.gd` SpringArm and Camera3D;
2. real `player_controller.gd` trainer body;
3. real `throw_aim.gd`, as a child of a CombatManager-shaped node;
4. real `wild_creature.gd` / `creature_body.gd`, populated as Bramblebun with
   combat AI, slowdown, collision and native movement active.

The production-order fixture adds CameraRig, Player, CombatManager/ThrowAim,
then the wild body. The separately named adversarial fixtures retain the old
target-before-throw order; they are defined in the probe but were not reached
after the stop condition. Fixture transforms are set only before acquisition.
There are no camera transform writes, frozen bodies, manual callback calls,
stock/HP/item/progression changes, world boot, save operation, or release/spend.
Successful fixtures are queued for teardown after the native commit callback and
before ThrowAim's release windup completes.

The one candidate change exists only in the probe's helper subclass. A command
gets an integer ID and records its requested vector, then awaits the next
`process_frame` and one zero-second process timer before recording the effective
stick and camera turn. The observed turn updates the inherited calibration only
for that command. The original one-degree per-axis diagnostic, four-second
deadline, square-root response update, live-deadzone floor, active aim, current
production eligibility, nonempty physical preview, and unblocked trajectory
checks remain unchanged in value and strength.

## Phase mismatch prerequisite

The preliminary trace delivered raw right-stick command `(0.35, 0)`, resumed at
the next pre-node process signal, and requested `(0.75, 0)` there. At that helper
sample the effective InputMap stick was still `(0.1875, 0)`, the transformed
value of the preceding command. The camera then turned after that sample.

All three prerequisite assertions passed:

- the camera frame received the preceding delivered command;
- the helper's newly requested command differed from the effective stick;
- a real post-camera turn occurred after the mismatched helper sample.

This isolates the diagnosed old sampling defect with buffered input and native
camera processing. It does not prove the replacement phase association.

## 60 Hz result and separate verdicts

The first executable run stopped at 20 checks with exactly one runtime assertion
failure. Godot reported `4.7.stable.official.5b4e0cb0f`.

| Case reached | Degree liveness | Command attribution | Strict commit prediction | Native dispatch-to-commit callbacks |
|---|---|---|---|---|
| Production zero-seeded, AI-live control | pass, post-settle error `0.8111°` inside 4 s | pass, 7 commands / 7 observations | pass, assisted; offset `0.160864 -> 0.164016 m`, LOS clear | wild 0, trainer 1, idle 1 |
| Production moving edge, initial `x=1.30 m`, velocity `2.4 m/s` | pass, post-settle error `0.7692°` inside 4 s | pass, 3 / 3 | pass, assisted; offset `0.158743 -> 0.159205 m`, LOS clear | wild 0, trainer 1, idle 1 |
| Production nonzero follow residual | pass, final post-settle error `0.8617°` inside 4 s | **fail**, command 13 observed zero effective stick and zero turn | dispatch gates passed; no press issued after attribution failed, so commit prediction is unproved | not entered |
| Blocked hand trajectory | not run after stop | not run | not run | not run |
| Adversarial moving edge, target before ThrowAim | not run after stop | not run | not run | not run |
| Adversarial follow, target before ThrowAim | not run after stop | not run | not run | not run |

Degree liveness therefore passed in every reached acquisition, including the
old nonzero-follow liveness counterexample. Command attribution failed. Strict
ready-to-commit prediction passed only for the two production-order commits that
were reached; it remains unproved for follow, blockage, adversarial order, and a
truly stationary wild control. A phase proof requires all three dimensions, so
the overall result is failure.

The production-order commits separately confirm the diagnosis's schedule
condition: from post-physics dispatch to ThrowAim's next poll, the real wild body
had zero movement callbacks, while the trainer had one physics callback and the
rig had one idle callback. That observed zero is specific to this node order and
does not establish a universal creature-motion bound.

## Preserved failure

In the nonzero-follow trace, command 12 had a valid association: requested
`(0.881945, -0.093188)`, effective `(0.853816, -0.090216)`, turn `1.0268°`.
Release then survived a camera/physics settle with strict production readiness
but returned at `1.3914°`, so steering correctly resumed inside the same
deadline. The immediately requested command 13 was recorded in the same process
and physics counts as that post-settle boundary, with effective zero and zero
turn. Command 14 later delivered and brought the case to `0.8617°`, but that does
not erase command 13 or make its calibration attribution valid.

Per the finite handoff, this was not repaired with another wait, a delivery
retry, gain change, deadline increase, input flush, or callback placement hook.
The proposal remains a failed isolated artifact. The named current cause is
driver phase/command attribution; safe dispatch and the speculative future
motion bound remain unresolved.

## Command and stopping point

The decision-bearing invocation used a fresh APPDATA profile:

```powershell
$env:APPDATA='C:\Projects\Tetherbound\.artifacts\aim-controller-phase-profile-02'
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/aim_controller_phase_probe.gd
```

Receipt: `.artifacts/aim-controller-phase-02.log`, exit 1, 20 checks, one named
failure, no script/runtime error. Profile 01 was a parse-only development attempt;
two local type annotations corrected that before the first executable proposal
run. Telemetry remains uncommitted. The different process/physics ratio was not
run because the 60 Hz command-attribution stop condition fired first.

No aim issue is closed and no campaign retry or helper ownership is authorized by
this result.
