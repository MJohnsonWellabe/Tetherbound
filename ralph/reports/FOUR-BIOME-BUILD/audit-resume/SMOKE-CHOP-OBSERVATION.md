# Smoke chop durable-impact observation repair

**Date:** 2026-09-09 02:30 UTC  
**Scope:** Test-only repair of `smoke_playground::_a_swing_plays_the_chop_and_lands_on_its_impact_frame`; no production, performance, save, campaign, or world changes.

## Cause and correction

The playground smoke previously judged impact time from the first process-frame poll that observed tool durability had fallen. The failing run had already recorded the real production callback inside the unchanged timing window (`0.460 / 0.625 = 0.736`), while its later durability observation was delayed. `ToolHold._resolve_swing()` emits `swing_connected` after calling `gather()` without checking whether gather succeeded, so the signal timestamp alone is also insufficient evidence.

The smoke now arms a `ChopImpactReceipt` for the required tool identity. In the synchronous `swing_connected` callback it resolves the current slot again with `Inventory.find_slot(required_tool)` and records the wall-clock receipt only if that tool's durability has already decreased. The existing process-frame durability poll remains in the diagnostic as `durability_observed_seconds`, but no longer replaces the event time. The impact-time animation name and position are captured by a wrapper in that same callback. The original acceptance interval is unchanged: `impact_fraction - 0.08` through `impact_fraction + 0.20`, or `0.52..0.80` for the authored `0.60` impact.

## Native regression

`tests/test_smoke_chop_observation.gd` is a deterministic test fixture rather than a full-smoke substitute. It invokes the real `ToolHold._resolve_swing()` path against a bounded harvest node and real `Inventory.damage_tool()`, then exercises the shared receipt callback from the actual `ToolHold.swing_connected` signal.

Final focused result:

```text
only test_smoke_chop_observation.gd: 1 of 321 test files
3 tests, 10 assertions, 0 failed
```

The cases prove:

- moving the axe from slot 0 to slot 5 after arming still records the real durability change by identity;
- advancing the observer clock from 460 ms to 526 ms cannot rewrite the 460 ms durable receipt;
- the production signal with no durability decrease remains a missing/rejected receipt;
- real durable receipts at `0.300 / 0.625 = 0.48` and `0.510 / 0.625 = 0.816` fail the unchanged early and late bounds.

## Full playground smoke

Exactly one isolated full-world attempt was launched with separate `APPDATA` and `LOCALAPPDATA` under:

`C:/Projects/Tetherbound/.artifacts/smoke-chop-observation-20260909T022842Z`

The watcher verified console launcher PID 46032 and real renderer descendant PID 14732 with command line:

```text
Godot_v4.7-stable_win64.exe --headless --path C:\Projects\Tetherbound --script tests/smoke_playground.gd
```

It exited 0 with `smoke: OK`. Neither guard fired: peak committed memory was 60.83% and peak system process count was 258. The render lease was released immediately on process exit.

The repaired diagnostic was:

```json
{"clip":"chop","clip_position":0.314085,"durability_at_signal":39,"durability_before":40,"durability_changed_wall_seconds":0.401,"durability_observed_seconds":0.441,"durability_slot":4,"required_tool":"knife","signal_node":"@Node3D@64004","signal_seen":true,"signal_wall_seconds":0.401,"swing_seconds_elapsed":0.378358}
```

The durable wall-clock receipt was `0.401 / 0.625 = 0.6416`, inside the unchanged `0.52..0.80` band. The later poll lagged by 40 ms and remained diagnostic only. The output retained the previously known `ERROR: Parameter "material" is null.` plus existing deprecation and missing-mipmap warnings; this test-only change does not suppress or claim to repair them.
