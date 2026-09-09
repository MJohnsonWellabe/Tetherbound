# Real Meadows manager and earned catch-loop integration — proposed brief

2026-09-09. Design only, awaiting orchestrator review before implementation or
Godot execution. This is one synthetic encounter fixture in one real Meadows
world, not another fresh campaign, a chapter replay or earned campaign credit.

## Scope and fixture boundary

Create `tools/probe_aim_real_manager.gd` only, plus an ignored guarded runner at
`.artifacts/aim-real-manager-20260909/run.ps1`. Do not modify production scripts,
the earned driver or the already-proven cancellation helper for this experiment.
Use the actual `scenes/world/meadows_playground.tscn`, including its real
CombatManager, EncounterDirector, SequenceDirector, local rig and PlaygroundHUD.
Set `current_scene` to that world so HUD ownership queries use the actual scene.

Before world boot, reset Game against a unique synthetic save root in an isolated
APPDATA/LOCALAPPDATA profile. Add exactly one Terrapup at the configured starter
level (currently three), and fifteen basic orbs once. No other items or flags
are seeded. The sequence may derive opening history from that initial party;
record those resulting flags explicitly as fixture-derived, never earned.

Wait for actual world shell/population and local scene dependencies, bounded by
90 seconds. Establish the smoke_catching initial human placement once at
`(48, ground_height_at(48,-58)+1, -58)` with zero initial velocity. If an ally
body is not already present, call the director's existing
`summon_active_creature()` once during fixture setup; this deploys the same
party instance rather than granting a second starter. Wait for terrain and
deployment before the measurement boundary. Resolve the authored practice wild
through `EncounterDirector.wild_creature()`. Do not move the wild or ally, force
their level/HP, disable their AI, change camera transforms, or repair anything.

At `fixture_complete`, record initial species/levels/HP, party IDs/count, complete
orb count, tool selection, world flags, human/wild/ally poses and native rates.
Keep normal time_scale=1, 60 Hz physics and max_fps=60; no accelerated combat.
All movement, engagement, aim opening and throw/cancel input after this boundary
must use mapped physical controller events. No direct manager engage/leave/tick,
ThrowAim release/tick or action-state injection is permitted.

## One ordered encounter

1. Prepare a fresh-opening driver instance with actual world dependencies and
   use its ordinary `_walk_to_and_engage_wild(wild, 2600)` path. Fail if it binds
   another target, times out or loses a creature. Never retry another encounter.
2. Use that driver's `_open_throw_aim()`, right-stick `_aim_at_wild()` and strict
   `_final_throw_verdict_ready()`. If a clear eligible shot is unavailable within
   those existing bounds, fail rather than repositioning the fixture.
3. Attach a **test-only manual cancellation observer**, after ThrowAim at equal
   physics priority. It reads the first positive native windup and records the
   actual committed point and preview. It sends one physical mapped menu_cancel
   press + flush on that first windup, and releases it after native IDLE. This
   deliberate user cancellation is independent of the invalid-commit predicate;
   assert the observed commit was valid, otherwise the valid-windup case fails.
   It must not force the assist point, preview, state, camera or a body pose.
4. Invoke the unmodified driver's `_tap_action(THROW_ACTION)` in full: three
   physics waits before physical release and five after. The observer therefore
   runs while the exact eight-tick driver call is pending. Capture commit/cancel
   frame IDs, physical action states, orb count, launch receipt, manager state,
   encounter identity, creature identity/HP and equipped tool at commit, cancel,
   tap return and three subsequent HUD idle polls. Require cancellation on the
   next physics tick, no release/spend, same active encounter and creatures,
   aim closed, and unchanged tool selection. Do not interpret natural damage
   as failure unless it ends the fight or faints a participant. Neither flee nor
   recall may be injected. Stop/free the observer and release its held input.
5. Without resetting anything, create a **new** fresh-opening driver instance
   and invoke its real `catch_existing(tree, world, Game, player, rig, wild)`.
   A separate instance avoids double-registering that method's capture counters
   on the preparation driver. This executes natural piloted weakening, the
   integrated `_catch_with_real_throws()` loop, strict dispatch checks, the shared
   cancellation helper and native catch resolution. No overridden loop, forced
   cancellation, pinned HP, inventory refill, revival, respawn wait or second
   engagement is allowed. The unchanged 40-launch / refusal-above-eight and
   inherited steering/observation bounds remain in force.
6. Require its successful result, actual `caught` outcome, exactly one party
   addition matching the engaged creature, at least one native orb release and
   strike, and corresponding inventory spending. Record all misses, refusals,
   naturally occurring helper cancellations and native catch result signals.
   A natural stale commit is not required; if none occurs, say so explicitly.

The composition being tested is precise: prior tiny fixtures establish invalid
commit detection, the deterministic manual phase establishes physical cancel
ownership in the real manager/HUD across the actual eight-tick tap, and the final
phase establishes the unmodified earned catch loop in this synthetic encounter.
No single phase substitutes for another. A happy catch without a natural stale
commit cannot claim full-world invalid-commit cancellation was observed.

## Execution and stop rules

Parse-only first with the installed Godot 4.7 headless binary. Then exactly one
world run after the orchestrator confirms the exclusive world lease. Use a
590-second in-scene real-time watchdog and the retained Varga wrapper pattern:
600-second external cap, stop above 90% system commit or 400 processes, sample
every two seconds, and terminate only the wrapper-owned Godot process tree.
Record terminal JSON plus engine/console/stderr/resource and event receipts.
There is no retry after failure; retain the earliest failed phase and source
diagnosis for a separately reviewed next action.

Proposed commands after implementation and approval (not executed):

```powershell
$aimRunRoot = 'C:/Projects/Tetherbound/.artifacts/aim-real-manager-20260909'
$env:APPDATA = "$aimRunRoot/parse-profile"
$env:LOCALAPPDATA = "$aimRunRoot/parse-profile"
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path C:/Projects/Tetherbound --script res://tools/probe_aim_real_manager.gd --check-only --log-file "$aimRunRoot/parse.log"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$aimRunRoot/run.ps1"
```

The runner must create new parse/runtime profile directories, set runtime output
paths, verify no preexisting Godot process, start hidden, and refuse reuse of an
existing runtime artifact directory. Do not run the unmodified smoke_catching:
its repeated HP pinning, revival and orb refill are specifically excluded here.

## First execution — failed before manual cancellation; no retry

The orchestrator approved implementation and one run. Initial parse failed on
`manual_ok` inference; explicit `bool` corrected that source-only defect. Both
logs are retained as `parse.log` and `parse2.log`; second parse exited zero.

The single world run ran 10:42:40.572–10:44:01.055 UTC (80.48 seconds), completed
the real world boot and ordinary practice-wild engagement, and stopped at the
first manual-case assertion. `REAL_MANAGER_RESULT passed=false` is the terminal
native verdict. The wrapper reported null native ExitCode and itself exited
zero, so its exit status is not a pass. No resource stop occurred: 32 samples,
peak 56.86% system commit, 248 processes and 2,197,331,968 owned private bytes.
The Godot process tree was verified absent and the lease returned immediately.

The fixture started with one creature and fifteen orbs. Natural engagement
selected `Wild_bramblebun_0_1`. Strict dispatch had current eligibility true,
offset 0.715754 versus radius 1.132625, and clear physical trajectory. However,
the actual eight-tick `interact` tap produced **no positive windup and no commit**:
the observer never dispatched manual cancel. At tap return (physics 266) and
after three subsequent idle waits (physics 270), aim was still active, windup
zero, committed point INF, last_launch empty, stock fifteen and both creatures
alive in the same fight. The target had moved and the later preview was outside
the reticle. The probe correctly failed the manual-cancel contract and did not
call `catch_existing`. Neither full-scene cancellation nor full-loop success is
proved by this run. No mutation or retry followed it.

The engine runtime log contains zero ERROR/SCRIPT ERROR entries and thirteen
warnings from known terrain interpolation/mipmap startup paths. The failure is
a semantic assertion, not a script exception. One initial parse error remains
explicitly separate from that runtime error count.

Source diagnosis establishes that the action name was correct: inherited
`THROW_ACTION` is `interact` (`gate_a_opening_drive.gd:49`), and ThrowAim reads it
at line 319. A concrete remaining hypothesis is the native 0.15-second entry
guard (`throw_aim.gd:341`), which silently ignores the launch edge while positive
(line 311). The prior tiny fixtures disclosed setting that guard to zero. This
run did not sample the guard or the exact per-tick pressed/just-pressed edge, so
it does **not** establish guard timing as the cause. A next diagnostic would
need those read-only receipts and a separately reviewed hypothesis; no guard
mutation, widened readiness or blind repeat is authorized by this result.

Artifacts live under `.artifacts/aim-real-manager-20260909/`: source-used runtime
profile, engine/console/stderr, telemetry.jsonl, resources.csv, result.json and
runner. Probe SHA256 at execution:
`1BED2D0539E2321A2C50F561C4CE2E9DA18FB44A40F4007D877A9B395FDDFC9F`.
