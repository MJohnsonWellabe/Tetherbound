# Fresh through-rest instrumented attempt — 2026-09-09

This was one fresh-save `--through-rest` attempt on clean-main `d3cdb57ca38acc2691c014663419389037b5209c` with read-only stage/walk receipts. It was stopped at its first terminal failure and was not retried. It is neither a through-rest pass nor continuous-campaign acceptance evidence.

The unique profile and raw outputs are under `.artifacts/opening-prefix-d3cdb57-0909/rest-instrumented/`:

- `console.log`: SHA-256 `0527081DB1101CE05CD5675D3861D54902CF1E661797B156892E98655ADC3517`
- `stderr.log`: SHA-256 `4A3969336C7D19C6555E0AE7D8767D5342393E5F6E2A9B6A5071B3D2A1543E42`
- `result.json`: SHA-256 `7C9DEA03C66E108459A3870CB7769451D371E9B48482158FA673A8F0699BA0FA`
- `resources.csv`: SHA-256 `EFA7327146A27C98B2A2CA5C0EB998F9DA6A7FA173664BB0CA6D01B0FDA0B26F`

The wrapper ran for 234.68 seconds and exited 1 with no guard stop. The fresh result reported 227.895 seconds, `reached="village"`, and `Live catch failed: ["live tutorial fight ended without capture: lost"]`. Peak system commit was 60.9%, peak process count 252, and peak owned private memory 2,297,974,784 bytes. Terminal Godot census was zero.

The run passed title, wake, starter, the opening catch, key and road gate, then failed during the later earned-team catch of `Wild_bramblebun_0_3`. It never entered MATERIALS, CAMP or REST, so the new receipts did not address the previous quiet tail or assignment three.

The final emitted line said aim convergence stopped 4.08 degrees off after eight seconds, but the detailed receipts constrain the cause differently. Across the final interval, `launch_assist_diagnostics()` repeatedly reported the correct wild as first hit, line of sight true, `eligible=true`, and reticle offsets inside the body radius. `aim_report()` was `{}` throughout. Production `throw_aim.gd::aim_report()` returns empty outside `State.AIMING`; the fresh helper's strict readiness correctly requires a nonempty, unblocked trajectory preview before commit.

The call context explains the mismatch. After a physical miss, the throw returns to IDLE. `fresh_opening_segment.gd` then calls inherited `_wander_for_a_new_angle()`, which walks to a new angle and unconditionally waits on `_aim_camera_at()` for eight seconds. With ThrowAim IDLE, no preview can exist, so that wait cannot succeed; its result is ignored, the enemy continues attacking, and only the next catch-loop iteration physically opens aim again. The landed aim fix remains correct: it validates live reticle geometry and preview before commit. This demonstrates an avoidable harness lifecycle delay before that strict guard. Eliminating it does not yet prove a successful fresh fight or campaign.

The bounded correction preserves the wander movement but performs its trailing re-aim only when the production combat manager reports aim is still active. When IDLE, it returns immediately so the next loop performs `_open_throw_aim()` and then applies the unchanged strict preview/commit checks. No production source, combat rule, catch odds, timer or acceptance guard changes.

`tools/probe_gate_a_aim_wander.gd` exercises the actual `_wander_for_a_new_angle()` coroutine with a derived driver that stubs only body movement and `_aim_camera_at()` to count calls. Both cases use the same ten-frame settle and inherited `is_aiming()` query, supplied by an explicit combat-state test double. Against the original unconditional call, `baseline-original-2.log` failed the IDLE case (`movement_calls=1`, `aim_calls=1`, expected zero) while passing AIMING. With the guard, `fixed.log` passed both: movement remained one call in each state, IDLE made zero aim calls, and AIMING made one. The first probe attempt, `baseline-original.log`, is retained too; it failed setup because its player double was `Node3D` rather than the helper's typed `CharacterBody3D`, and was not presented as behavior evidence.

Probe artifacts under `.artifacts/opening-prefix-d3cdb57-0909/aim-wander-probe/`:

- `baseline-original.log`: SHA-256 `61FF285DF9CD9EE0F5BC7C798F0D9683C65EAB5342A18F3B67A41444BA6D3C94`
- `baseline-original-2.log`: SHA-256 `FEAD7E2EA5959BE217D4ED9F7B67A0B8E35219B7C0C08F7BED49B7EAE5D4D167`
- `fixed.log`: SHA-256 `1276D53A4D3103E5041455277084CF149DCE19BD6564F6EB18BC0E1041A5B1B3`
- discarded policy-mirror test: SHA-256 `CACFA0F546E5F521A71E9130B20F68518F5C375612F868AACC4154E83B9C2491`
