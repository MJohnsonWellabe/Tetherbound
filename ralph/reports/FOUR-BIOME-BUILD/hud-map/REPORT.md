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

## Clean viewport evidence

The first OS-composited capture round was rejected because another desktop window
obscured roughly two thirds of every frame. Those files are superseded and are not
evidence.

A new continuous full Meadows process ran with the shipped Compatibility/OpenGL 3
renderer at 1920×1080. The capture-only harness drove the physical joypad bindings for
Map and Back: first open → viewport capture → close → gameplay HUD/minimap viewport
capture → second open → viewport capture → close. It also rejected the second open
unless the production map tab rebuilt a valid clipped canvas. The game viewport is the
pixel source, so an unrelated foreground desktop window cannot enter the PNG. The
process exited 0 with no `SCRIPT ERROR` or `ERROR` line.

Command:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/capture_gate_a_map_presentation.gd
```

Local capture payloads for the independent code-blind judge (not committed):

- `captures/clean_full_map_first_open.png` — 1920×1055, SHA-256
  `1463E0B00D6C1668302E3AE06FE795D07261FCCE33557D8ABC9268B7F0A5FCC8`
- `captures/clean_hud_minimap_after_close.png` — 1920×1055, SHA-256
  `6CF7AE75F923F165CB81B908056456031A2A0598EF158E40000912FFD043460A`
- `captures/clean_full_map_second_open.png` — 1920×1055, SHA-256
  `68D098FF0852C24DA67F8C2600B1EC49DC1302AA7071D0D17B7655D6A211DB3A`

Capture-integrity inspection found all three unobstructed, full-frame and populated;
the gameplay frame visibly contains the restored HUD minimap and the second-open frame
is not blank or corrupt. This is not an artistic verdict. The coordinator will send
the files to an independent code-blind judge.

After capture, the real-input regression was rerun:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/smoke_gate_a_map_cycle.gd
```

It exited 0 and reported the production Meadows map opened, closed, opened a second
time, closed cleanly, and returned world movement ownership.

## Independent code-blind verdict

The replacement frames passed capture integrity and the rollback contract: the HUD
minimap is visible and readable without covering the centre of play; both full-map
opens are populated and visually consistent; the second open is neither blank nor
corrupt. This completes prompt 77's explicit fallback exit (restore the minimap and
preserve the compass branch) rather than claiming the abandoned compass experiment
was repaired.

The judge did **not** pass the full map as finished interface art. It found three
repair-pass defects in both opens: `DISCOVERED REGIONS` overlaps `GRANDPA'S VILLAGE`
and northern lettering clips at the panel edge; the geography is a narrow strip
dominated by oversized labels; and large marker backplates crowd the northern
settlements and relay/crossing cluster. These are recorded as open product defects,
not misreported as second-open corruption or capture failure.
