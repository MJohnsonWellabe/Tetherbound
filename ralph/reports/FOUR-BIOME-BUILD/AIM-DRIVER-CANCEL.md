# Earned driver cancellation integration brief

Authorized 2026-09-09 after the separate 19-check windup and 8-check actual-HUD
proofs. Integrate a shared post-ThrowAim observer into the earned catch driver;
no production behavior changes and no fresh campaign or full-world retry.

The strict synchronous dispatch verdict stays unchanged. The observer reads the
first actual positive windup, committed assist point and physical preview, then
sends only mapped physical menu_cancel press/release events when that commit is
invalid. It never invokes a production tick, leave or release method. Confirmed
cancellation exits the existing observation loop immediately and shares the
existing refusal counter (failure after more than eight), with no orb repair,
pose repair, widened eligibility or extra launch budget.

Adapt the retained tiny native proof to create the same observer through the
driver's factory. Preserve the stale negative control, valid one-orb release,
blocked no-input case, 15 FPS / 60 physics case and actual HUD ownership case.
Parse first, then one run of each with isolated profiles and 20-second watchdogs;
stop on first failure and diagnose before another attempt. The synthetic manager
still cannot prove complete encounter behavior or earned campaign success.

## First-attempt results

Both parse checks exited zero. The adapted windup proof exited zero in 5.405
seconds, all 19 checks passed. Its five cases observed legacy stale commit at
physics 28 without spending; shared-helper stale cancellation at 49→50 without
spending; eligible production release spending one orb (4→3); blocked dispatch
with no input/commit/spend; and 15 FPS cancellation at 143→144 within process 95.
No ERROR, SCRIPT ERROR, WARNING or FAIL entries occurred in that engine log.

The inherited actual-HUD proof exited zero in 3.265 seconds, all eight checks
passed. Its ordinary B positive control equipped an axe, then the shared helper
cancelled a stale commit at physics 49→50 with stock four throughout. Three
subsequent HUD idle polls left the tool unequipped and aim closed. The sole
warning was the retained positive-control `HUD has no player; readout will stay
empty`; no ERROR, SCRIPT ERROR or FAIL entries occurred. Both native processes
were terminal before handing the full-world lease back to the orchestrator.

The proof now creates the observer through the same earned-driver
`_watch_throw_commit()` factory, which sets the native sibling order, physics
priority and mapped physical event callable. Its instrumentation only observes
the helper's cancellation receipt; it no longer implements cancellation itself.
The legacy negative control deliberately omits the helper. The HUD subclass
inherits this shared-helper path without copying it.

The earned loop retains strict `_final_throw_verdict_ready`, 40 launches, its
existing 360-frame outcome bound and the existing refusal count (fails above
eight). A confirmed cancellation breaks the observation loop immediately,
checks unchanged orb stock, decrements the attempted launch and increments that
same refusal count before another ordinary aiming attempt. It does not run the
ordinary 900-frame approach used for a non-cancellation refusal. The helper
releases B when cancellation is observed, on explicit stop and on tree exit.
Its node is stopped and queued for deletion before any result branch returns.

Artifacts: `.artifacts/aim-driver-cancel-20260909/{parse,engine}.log` and
`.artifacts/aim-driver-cancel-hud-20260909/{parse,engine}.log`; each uses its own
isolated profile subdirectory and the installed Godot 4.7 headless binary. No
production file, owner profile, full-world scene or fresh campaign was changed
or run. This establishes the shared observer path and HUD ownership in the
retained synthetic fixture; complete encounter-manager and earned-loop end-to-end
behavior still require separately authorized bounded evidence.
