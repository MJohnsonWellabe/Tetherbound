# Aim cancellation before spending — isolated proof brief

Authorized 2026-09-09 after three failed scheduling experiments. This is a new
native cancellation experiment, not a fourth campaign attempt. No existing
driver or production script changes are authorized. First runtime passed all
19 checks; no retry was run.

The strict active-aim, current eligibility, nonempty preview and unblocked
trajectory checks remain at physical pad dispatch. The new invariant explicitly
allows an invalid commit but requires its cancellation before orb release or
inventory spending. It does not prove an interval with no invalid pose or commit.
Production free-aim throws remain legal.

Godot stamps physical input edges for the next physics tick. An observer placed
immediately after ThrowAim can therefore detect the first positive windup and
read its actual committed point, then parse and flush a mapped menu_cancel pad
event. ThrowAim checks cancel before decrementing windup on the next tick. No
direct _leave_aim, _release or _tick call is permitted.

Reuse the retained production camera/player/wild/ThrowAim native fixture. Its
Combat wrapper is synthetic, not a campaign encounter. Seed a small orb stock
once before observation; never refill. Initial follow residual and blocked hand
arc are disclosed artificial conditions established before each measurement.
No owner profile, campaign progress, HP repair or pose repair during measurement.

Cases, stopping at the first failure:

1. Retain eligible-dispatch/ineligible-commit negative control, teardown before spend.
2. Same stale commit, actual mapped cancellation next physics tick, zero release
   and zero spend; record committed point, windup, stock, frame IDs and cancel edge.
3. Eligible stationary commit reaches the actual production release and spends
   exactly one orb.
4. Physical hand-arc blocker refuses dispatch with no input, commit or spend.
5. Repeat cancellation at a different idle/physics ratio and verify callback counts.

Use an approximately 20-second watchdog, installed Godot 4.7 headless only,
isolated APPDATA/LOCALAPPDATA and retained logs under a new .artifacts basename.
Parse check first, then one run. A failure requires source diagnosis and a new
explicitly reviewed hypothesis before another run. A passing synthetic proof
does not authorize fresh-campaign replay or driver integration.

The pad B menu_cancel binding is not combat_run or creature_recall. Verify those
flee actions stay unpressed. The synthetic Combat wrapper cannot establish full
HUD/manager behavior; retain that limitation rather than claiming a real fight
was proven not to flee. B also maps hotbar_1, so full-scene integration needs its
existing aim-input ownership checked separately.

## Result and exact boundaries

Parse-only check exited 0. The first runtime exited 0 after approximately 4.284
seconds (tool wall time), within the 20-second in-scene watchdog. It reported
`PHASE_PROOF checks=19 failures=[]`. Engine log scan found zero `ERROR:`,
`SCRIPT ERROR`, `WARNING:` or `FAIL:` entries. Subsequent process census found
no remaining Godot process. All five cases ran; none was skipped after failure.

| Case | Actual receipt |
| --- | --- |
| Legacy stale commit | Physics 24, process 15, unassisted; stock 4, no release; teardown at commit |
| Stale commit canceled | Commit physics 45; cancel consumed 46; stock 4 throughout, IDLE, no release |
| Eligible release | Commit physics 67; production last_launch contains orb_basic; stock 4 to 3 |
| Physical blocker | Preview names HandArcBlocker; no dispatched input or commit; stock 3 |
| Multiple physics per idle | Commit 152 and cancel 153 both process 98; stock 3, no release |

At cancellation the real `menu_cancel` just-pressed receipt was true, and the
test asserted neither `combat_run` nor `creature_recall` was pressed. The
observer is a sibling immediately following ThrowAim with equal physics
priority; it detects positive windup after the production callback, reads the
committed point plus refreshed report, and sends physical pad input. It never
calls a production tick, release or leave method. A single initial grant of four
synthetic basic orbs supplied all cases. No stock restoration occurred.

The reused fixture directly establishes initial AIMING state, zero entry guard,
engaged target and aim-camera profile; it is explicitly synthetic. The 1.2-second
per-case observation bound waits for lifecycle receipts and does not extend the
unchanged four-second steering acquisition or 0.18-second production windup.
The final case sets max_fps to 15 with normal 60 Hz physics before setup and
observes two real physics ticks between idle updates; no fake delta/tick is used.

Artifacts: `.artifacts/aim-cancel-windup-20260909/parse.log` and `engine.log`.
Both invocations set APPDATA and LOCALAPPDATA to that artifact directory's
`profile` subdirectory, then invoked:

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path C:/Projects/Tetherbound --script res://tools/aim_cancel_windup_probe.gd --check-only --log-file C:/Projects/Tetherbound/.artifacts/aim-cancel-windup-20260909/parse.log
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path C:/Projects/Tetherbound --script res://tools/aim_cancel_windup_probe.gd --log-file C:/Projects/Tetherbound/.artifacts/aim-cancel-windup-20260909/engine.log
```

Verified probe SHA256:
`99E426DBFDD31C5FD9891980F751E0CC9D8EF208FB97970E78E2BDD68BDCCAC4`.

## Interpretation and remaining blocker

The failed scheduling strategy tried to exclude intervening pose callbacks.
The engine itself explains why an in-physics flush cannot do that: physical
press parsing stamps the next physics frame, and just-pressed tests that stamp.
The main loop flushes before advancing the physics frame. See official installed
commit [input.cpp](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/input/input.cpp#L958)
and [main.cpp](https://github.com/godotengine/godot/blob/5b4e0cb0f/main/main.cpp#L4605).
The cancellation proof uses that next-tick behavior instead of trying to bypass it.

This proves cancellation before spending for the observed invalid commits. It
does not prove continuous eligibility, a no-invalid-pose interval, arbitrary
future target movement, catch success, or full-world input ownership. It does
not justify refusing ordinary unassisted throws in production.

The remaining integration blocker is concrete: `project.godot` maps B to both
menu_cancel and hotbar_1. `playground_hud.gd:3900` excludes hotbar input while
aiming, but after cancellation that condition becomes false. A following idle
poll might still see the same physical press. The present fixture contains no
HUD or real encounter manager and cannot exclude hotbar activation or prove
the complete fight stays active. No driver integration or fresh-campaign retry
is authorized by this result; full input ownership needs a separate bounded proof.
