# Independent review: F33 Harness maximum HP (926cfa59, e367f0b9)

**Verdict:** APPROVE-WITH-NITS. The reviewer was an independent agent; it did not edit anything.

**Confirmed correct:**
- All three party-HP damage paths divide once:
  - the solo strike;
  - a session hit with no durable record;
  - a durable session hit, staged on the host.
- A guest never divides a second time on the durable path.
- The host's own creature gets the right s on both paths.
- The upper bound 1.702 is correct.
- No raised value reaches a save, a durable row or an escrow marker.
- `begin()` clears the per-fight s.

## Findings and fixes

| # | Severity | Finding | Fix |
|---|---|---|---|
| 1 | Medium | With gear off, a guest-announced `hp_scale` could pass through `_geared_card`, with no bound | f4bf2759 discards it before the early return. `_host_hp_scale` is also clamped to `combat_manager._max_hp_scale()` |
| 2 | Medium | Flat potion heals in a fight heal more than a true raise would, and the message disagrees with the bar | New `combat_manager.scaled_heal(creature, shown_amount)`: stored HP gains amount / s and the call returns shown HP. Used by the hotbar potion (`playground_hud`) and backpack targeting (`tab_backpack`). Unit-tested: 50 shown = 50 / s stored |
| 3 | Low | Some test assertions were true by construction | (a) The smoke now takes the rolled damage from the guest's production `hit_landed` and asserts stored loss = rolled / host s (5.87 = 7.42 / 1.264). (b) The guest drops its local Harness right after joining, so the bar reads 134.40 before the host's hit and 169.88 after it; only the host's s explains that. (c) The durable staging amount goes through `_ordinary_hit_amount`, which is unit-tested (100 / s). (d) A unit test asserts a rolled 100 drops the shown bar by exactly 100 |
| 4 | Low | `_adopt_host_hp_scale` did not check the struck creature | The participant payload now carries `creature_uid`; a different id is not adopted (unit-tested) |
| 5 | Low | The combat HUD level line might crowd the panel | Captured in engine (`f33/harness-hud/`, Stormglass +3, s = 1.702): "Lv 3 · HP 229/229" and "HP 36/229" fit on one line, nothing overlaps |
| 6 | Nit | `_max_hp_scale` read the config on every hit | The value is cached in a static, and the bonus is clamped to [0, 1] |
| 7 | Nit | A doc comment in `playground_hud` sat above the wrong function | Moved back to `_combat_is_running` |

## Checks after the fixes

- **Unit tests:** `test_creature_gear` 8/303, `test_harness_max_hp` pass, `test_water_tidal_guard_combat` pass, `test_move_commit_runtime` 10/72, `test_hud_widgets` 41/274, `test_combat_hud_handheld_floors` 5/38.
- **Smokes:** `smoke_combat` OK, `smoke_party_revive_snapshot` 25/25.
- **Two-peer `smoke_net_harness_max_hp`:** ALL CHECKS PASSED (`f33/harness-hp-2peer/checks.txt`).
