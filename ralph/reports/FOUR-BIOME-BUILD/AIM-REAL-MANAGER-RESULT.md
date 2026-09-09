# Real manager cancellation and actual catch-loop proof

The separately reviewed changed-source run passed on its first attempt. It
establishes manual physical cancellation in the actual Meadows manager/HUD
and the real `fresh_opening_segment.catch_existing` path in the same synthetic
encounter. It is not a fresh campaign, chapter completion or campaign credit.
The earlier no-windup failure remains preserved and is not reclassified.

## What ran

The original fixture and bounds were retained: one configured-level Terrapup,
fifteen initial basic orbs, real Meadows world/manager/HUD, one disclosed initial
human placement, then ordinary physical controller movement/engagement/aiming.
No health/stock restoration, state/guard injection, target movement or camera
repair occurred after setup. The earned driver now includes the independently
tested idempotent aim-open behavior and guard-expiry readiness condition.

New read-only nodes bracketed the real ThrowAim physics callback and recorded
guard precision/positivity, state, windup, actual committed point, preview and
physical action edges. A separate node recorded delivered pad events. Neither
observer invoked game callbacks or altered gameplay node priorities. Detailed
sampling began before aim opened. The single manual-cancel observer remained
the disclosed test action, separate from the invalid-commit helper.

Parse passed first attempt. The one world runtime ran from 10:54:50.107 to
10:56:18.331 UTC (88.224 seconds), under the original 590-second internal and
600-second external limits. The external guard did not stop it. Its 33 resource
samples peaked at 57.57% system commit, 245 processes and 2,213,638,144 owned
private bytes. The native Godot tree was confirmed absent before releasing the
world lease to the visual lane.

## Actual receipts

| Observation | Native evidence |
| --- | --- |
| Manual eligible commit | Physics 266, process 100; guard zero, valid committed point `(42.23198,-0.314785,-49.60905)`, stock 15 |
| Manual physical cancellation | Physics 267, same process 100; aim IDLE, same active fight/creature identities, stock 15 |
| Complete inherited throw tap returns | Physics 272; aim closed, fight active, stock 15, tool unchanged |
| Three subsequent HUD idle waits | Physics 277; same fight active, aim closed, no tool activation or spend |
| Real earned-loop natural weakening | Bramblebun reduced by real attacks to 26.395 HP; Terrapup remained alive, ending at 84.937 HP |
| Native orb release | Physics 692, stock 15→14 |
| Physical target strike | Physics 716, placement offset 0.208 |
| Native capture resolution | Physics 1023, `catch_resolved:true:3` |
| Real `catch_existing` return | Physics 1121; failures empty, outcome `caught`, fight ended, party 1→2 with engaged species, stock 14 |

The terminal native verdict is
`REAL_MANAGER_RESULT passed=true phase=actual_catch_existing reason=catch_existing failures=[]`.
There was exactly one observed orb release and strike, zero misses, zero natural
invalid commits and zero shared-helper cancellation receipts in the catch phase.
Thus this is composition evidence: prior tiny proofs establish invalid-commit
detection/cancellation; this world proves a deliberate valid-commit cancellation
has correct manager/HUD ownership and that the real catch loop succeeds. It does
**not** claim that a naturally invalid commit was cancelled in a full world.

The runtime engine log has zero ERROR or SCRIPT ERROR entries and thirteen
known terrain interpolation/mipmap warnings. The wrapper again returned null
for native ExitCode while its PowerShell process exited zero; neither value is
used as the native success claim. The explicit terminal verdict and retained
manager/inventory/party/capture receipts prove the result.

## Retained artifacts and boundaries

`.artifacts/aim-real-manager-guarded-20260909/` contains parse/engine/console/stderr
logs, telemetry.jsonl, resources.csv, result.json, isolated profiles and runner.
The previous failed run remains under `.artifacts/aim-real-manager-20260909/`.
No second changed-source world run was performed.

SHA256 of runtime sources:

- `tools/probe_aim_real_manager.gd`: `12E5E677661B943612EEE823954721773A6D67323E9A97126063F751447458AF`
- `tests/helpers/fresh_opening_segment.gd`: `2751FCB20295FB1E8ABFE83B3B0CC3539B9CA9907D97122383F670D7A2E2F06C`

This closes the bounded synthetic integration proof only. CI/review/landing,
continuous earned campaign coverage, visual acceptance and shipping gates
remain owned by the overarching goal. No campaign was restarted here.
