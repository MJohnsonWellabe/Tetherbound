# Same-physics aim dispatch investigation — 2026-09-09

## Bounded brief before runtime

The retained fresh-campaign failure occurred between a helper's current verdict
and production ThrowAim's later physics callback. This new isolated experiment
tests a different dispatch phase, not another convergence or movement margin.

`tools/aim_same_physics_dispatch_probe.gd` reuses the existing native production
camera, trainer, wild and ThrowAim fixture. Synthetic initial camera-follow
residual conditions are set before measurement. A legacy pre-node
process dispatch must demonstrate stale eligibility. A sibling observer immediately
before ThrowAim's physics callback then reads the unchanged active-aim/current
eligibility/clear-preview gates and sends the existing physical joypad event.
It must either refuse without input or retain eligibility through actual commit,
with no intervening camera/player/target pose callback. A stationary acceptance
case and blocked physical-preview refusal are separate checks.

The probe neither changes production scripts nor loads campaign state. It does
not change body radius, catch rules, time budgets, or the existing fresh opening
helper. Every case tears down after commit before orb release/spending. A 20-second
watchdog bounds the experiment; no new fresh campaign is authorized by a pass.
Initial runtime result is pending. Owner profiles will remain isolated under
`.artifacts/aim-same-physics-20260909/`.

First attempt parsed but failed its negative-control prerequisite: the camera
had already followed before the legacy sample, so current eligibility was false
and no input was sent. It did not test a stale commit. The corrected setup uses
the existing native steering acquisition and introduces only the disclosed
trainer follow residual at the pre-node process sample, without relocating the
target or waiting through another camera update before sampling.

The second attempt reproduced the legacy stale commit and the new phase refused
that residual without dispatch. Its stationary case committed successfully but
failed the stricter callback-order assertion: `parse_input_event` remained buffered,
with `pressed=false` immediately after parsing, then committed one physics frame
later after camera and target updates. Therefore phase placement alone is not a
fix. The next strategy drains the ordinary Input event queue immediately after
the physical pad event in the observer callback. It preserves the legacy control,
eligibility/preview gates and the no-intervening-pose assertion.

## Result: ordering proof failed; no driver change

The third attempt also failed the unchanged ordering assertion. Draining buffered
events made `pressed=true` immediately, but `just_pressed` was still false at
physics frame 66. Production ThrowAim committed at frame 67 / process frame 58,
after the target and camera advanced. Its current offset changed from 0.164249
to 0.176831 metres against the unchanged 1.132625-metre radius. This stationary
shot happened to retain assist; it does not prove atomic verdict/dispatch timing.

Both attempts 2 and 3 proved the legacy negative control: current eligibility
was true when the physical event was parsed and false at production commit after
camera follow. The proposed phase refused that residual before sending input.
Each then stopped at the stationary ordering failure, with 7 checks and 1 failure.
The blocked-preview case was not reached. No fourth attempt was run; no existing
driver or production code was changed. The new probe is retained as failed
diagnostic evidence, not a passing test or a permission to retry the campaign.

Exact invocations used the installed Godot 4.7 console binary, `--headless
--path C:/Projects/Tetherbound --script res://tools/aim_same_physics_dispatch_probe.gd`,
and fresh named logs `engine.log`, `engine2.log`, `engine3.log` under the artifact
root. APPDATA and LOCALAPPDATA pointed only to its isolated `profile` directory.
The first parse-only check passed; all three runtimes exited 1 through their
explicit failed assertion. Engine3 contains no `ERROR:`, `SCRIPT ERROR` or
`WARNING:`. No full-world or campaign scene was loaded by this experiment.

The next strategy must account for the observed next-physics-tick `just_pressed`
edge as well as queue delivery. Moving the same observer or adding another flush
is not supported by these results. A post-camera idle dispatch is a distinct
hypothesis only if its complete callback interval is proved at different
process/physics ratios; no such proof or fix exists here.
