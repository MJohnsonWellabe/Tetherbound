# HUD-MAP lane report — minimap restoration

Date: 2026-09-07 (America/Chicago)
Branch: `codex/hud-map-proof-0907`
Base: `7ab4a12647a377a400c43335b64aff8b03ca6d43` (PR #79 merge)

## Verdict

Restore the proven runtime minimap and roll back the HUD compass/map overhaul from
`21a6def9ebe9272998c1eb76c59a70ba3bce66e0`.

The authoritative exit handoff already records more than the two no-yield attempts
allowed by prompt 77: control-tree reuse, texture-cache preservation, a 120-frame
settle, in-place fog texture updates, and a two-frame refresh did not repair the real
Meadows second-open corruption. The lane therefore followed the contract's required
fallback instead of making another speculative renderer-lifetime change.

The compass work remains preserved at
`origin/ralph/hud-map-compass-0906` (`21a6def9ebe9272998c1eb76c59a70ba3bce66e0`)
for a later attempt. `docs/CODEX_EXIT_HANDOFF_2026-09-07.md` is retained as the
historical diagnosis.

## Scope

The coordinator explicitly widened this lane's ownership only enough to reverse the
companion wiring from `21a6def9e`: `autoload/game_state.gd`,
`scripts/ui/hud_presentation_policy.gd`, and
`scripts/world/cloudreach_world_runtime.gd`, in addition to the HUD/map/quest/test
files named by prompt 77. No unrelated edits were made in those files.

The restored real-input smoke adds one regression beyond the pre-compass version: it
opens the real Meadows map, closes it, opens it a second time, verifies the rebuilt
canvas is clipped and bound to the active Meadows `MapState`, closes it, and proves
world movement recovers.

## Automated evidence

- `tests/run_tests.gd -- --only=test_map`: 83 tests, 482 assertions, 0 failed.
  The known source-parser diagnostic lines from `test_map_legibility.gd` remain, as
  documented in the historical handoff; the runner verdict is green.
- `--only=test_minimap`: 5 tests, 8 assertions, 0 failed.
- `--only=test_quest_log`: 43 tests, 828 assertions, 0 failed.
- `--only=test_realm_map_persistence`: 7 tests, 171 assertions, 0 failed.
- `--only=test_hud_presentation_lifecycle`: 3 tests, 25 assertions, 0 failed.
- `--only=test_alpha_pins`: 24 tests, 154 assertions, 0 failed.
- `--only=test_cloudreach_atmosphere`: 3 tests, 29 assertions, 0 failed.
- `tests/smoke_gate_a_map_cycle.gd`: green in the real Meadows scene with physical
  joypad events, including repeated map open/close and post-menu movement recovery.
- `--check-only`: green for every changed surviving GDScript.

The first focused test invocation in this fresh worktree was not counted: it ran
before a Godot class/import cache existed, so `UITokens`, the menu base class, and
vendored textures could not resolve. After bootstrapping the ignored cache from the
same PR #79 tree, the identical command produced the green result above.

## OS-composited evidence

One continuous full Meadows process ran with the Compatibility/OpenGL 3 renderer at
1280×800. The capture probe drove the physical joypad bindings for Map and Back, not
direct menu calls: first open → capture → close → second open → capture → discovery
revision → capture → close → restored minimap capture. `DisplayServer.screen_get_image()`
captured OS-composited pixels and the process exited 0.

Command:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/_probe_map_visible_window.gd
```

Local capture payloads for the independent code-blind judge (not committed):

- `captures/restored_map_initial_os_20260907_1349.png` — SHA-256
  `FA6F32398F0479D87BDB5093AFB4F68A33297BD88EA0BB19BDDA80139736729F`
- `captures/restored_map_reopened_os_20260907_1349.png` — SHA-256
  `BECDA643BB4D7C49BFC48EF8C87905C0AC77F56B07EE8DFB427D39E3CBA4557D`
- `captures/restored_map_surveyed_os_20260907_1349.png` — SHA-256
  `66D698069B073B88731C84D5295EE754CC977A07D0E61F67F230E3B692584EFA`
- `captures/restored_minimap_hud_os_20260907_1349.png` — SHA-256
  `F295190F7474A61B8DCE2F701083AE28AB819EE2F600ED0AC927587280198AE7`

This lane intentionally did not inspect or judge its own frames. The coordinator was
notified that the files are ready for an independent code-blind verdict.
