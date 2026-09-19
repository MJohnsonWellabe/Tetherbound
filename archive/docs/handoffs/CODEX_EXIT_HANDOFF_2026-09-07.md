# Codex exit handoff — HUD compass and map objective work

Date: 2026-09-07 (America/Chicago)

## Resume point

- Worktree: `D:\CodexWork\Tetherbound-codex-handoff-0906`
- Branch: `ralph/hud-map-compass-0906`
- HEAD: `096a724aa4de127b830f0b6133740ab46375073b`
- Godot: `D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe`
- No commit or PR has been created for this branch.
- The worktree is intentionally left dirty. Do not discard the feature files listed below.

Read `AGENTS.md`, `CLAUDE.md`, `docs/00_START_HERE.md`, and
`docs/HANDOFF_COORDINATION_2026-09-06-CODEX.md` before changing anything.

## Requested outcome

Task 8 removes the runtime minimap, replaces it with a horizontal compass and
objective/destination bearing, makes the full map open at a useful local view,
automatically highlights the next locational objective, adds a "Set objective
as destination" action, and closes with rendered before/after evidence plus a
blind visual review. The final branch still needs validation, commit, PR, CI,
and merge.

Task 7 is already complete separately: PR #75 was merged at
`c5e4d14d101275de2f96b3918ae6ddcd19dafd35`, with all CI checks green.

## Feature work currently in the worktree

- `scripts/ui/compass_bar.gd` (new): horizontal heading tape, cardinal and
  intercardinal ticks, objective/destination bearing marker, off-screen edge
  chevron, distance, and testable heading/wrap helpers. East/west convention is
  `fposmod(180 - rad_to_deg(yaw), 360)`.
- `scripts/ui/playground_hud.gd`: mounts the compass instead of the minimap;
  day/time moved top-left, objective card remains top-right.
- `scripts/ui/hud_presentation_policy.gd`: presentation mode key changed from
  `minimap` to `compass`.
- `scripts/world/cloudreach_world_runtime.gd`: removed direct minimap setup;
  compass reads `Game.map`.
- `scripts/world/quest_log.gd`: objective rows carry `id` and `destination`;
  explicit destination is preserved, Cloudreach falls back to `region_id`, and
  `tracked_destination()` exposes the current destination.
- `data/progression/objectives.json`: explicit map destinations for fixed
  Meadows objectives. Portable camp/build/feed objectives intentionally have
  no fixed destination.
- `autoload/game_state.gd`: default `map_last_zoom` is 8.0; progression changes
  synchronize the tracked objective marker; destination IDs resolve through
  MapState geometry.
- `scripts/ui/tab_map.gd`: opens at 8x around the player, retains whole-realm
  zoom-out, adds the destination button, prevents focused buttons from also
  cycling realms through `ui_accept`, keys the fog cache by MapState, and
  reuses the existing map controls on reopen.
- `tests/test_compass_bar.gd` (new), `tests/test_quest_log.gd`, and
  `tests/smoke_gate_a_map_cycle.gd` cover the new behavior. The live smoke now
  asserts that repeated map opens reuse the same canvas instance.
- Capture tooling changed in `tools/_capture_map_ui_0905.gd` and
  `tools/capture_hud_lightweight_0904.gd`; new lightweight reopen harness is
  `tools/capture_map_reopen_lightweight.gd`.

## Verified evidence so far

- `tests/test_compass_bar.gd`: 4 tests, 12 assertions, green.
- `tests/test_quest_log.gd`: 44 tests, 816 assertions, green.
- `tests/test_map_zoom_persistence.gd`: 3 tests, 9 assertions, green.
- Focused `--only=test_map`: 8 files, 83 tests, 482 assertions, green. It emits
  pre-existing source-parser Script Errors from `test_map_legibility`, but the
  runner reports zero failures.
- One earlier full live `tests/smoke_gate_a_map_cycle.gd` run passed movement,
  compass heading, initial local map view, objective button/marker, zoom, pan,
  clamping, and pause/recovery. It predates the latest same-canvas assertion,
  so the latest smoke file must be rerun.
- Final clean HUD compass render:
  `shots/codex-compass-final/hud_full.png`.
- Lightweight repeated-open harness produced three byte-identical images in
  `shots/map-reopen-lightweight/` with SHA-256
  `453DE084510D8C9B594C4575DCE970F894942C5EE3787182DB0BCB2C3FCCF2A0`.

Known unrelated renderer output: South Bridge's
`assets/environment/team_tether/hall/banner_cloth.gdshader` redefines `E` at
line 114; terrain texture mipmap warnings also recur. Both predate and are out
of scope for this HUD/map task.

## Current blocker: full-world repeated-open corruption

The real Meadows capture still corrupts the second map open. The first frame is
clean, while the repeated frame loses the terrain/fog rendering and fragments
several unrelated glyphs. This is real in the saved PNGs, not just the image
viewer:

- Clean first open:
  `shots/codex-map-settle-proof-0907c/map_day1.png`
  SHA-256 `003C781448D943095C19DAA0F5480DBB55C2AA1E3B586AC18EF52DD10B566389`
- Corrupted reopen:
  `shots/codex-map-settle-proof-0907c/map_day1_repeat.png`
  SHA-256 `39C77666A556D0B7A544025B86CB27CB1221FB2519BFDA95F15AF402B3301D7B`

Two attempted mitigations did not solve the full-world case:

1. Reuse the existing map control tree instead of destroying/recreating it on
   each `game_menu.open()`.
2. Preserve texture caches across structural builds.

The last experiment increased `tab_map.gd::SETTLE_FRAMES` from 6 to 120 while
reusing cached textures. The capture completed successfully but the second PNG
was still corrupt. This 120-frame change is therefore unproven overhead and
should probably be reverted to 6 unless the next investigation finds a reason
to retain it.

### Investigation update after this document was first written

Work briefly resumed after the initial exit. `SETTLE_FRAMES` is back at 6.
The latest authoritative findings are:

- A fresh live controller smoke passed with the new same-canvas assertion:
  `Gate A map/cycle: OK -- real pad cycling, heading compass, objective
  destination, full-map zoom/pan, recovery.`
- A fresh focused suite passed: 138 tests, 1,481 assertions, 0 failures,
  covering compass, quest log, all `test_map*` files, and
  `test_realm_map_persistence.gd`.
- Every changed/new GDScript listed in this document passed `--check-only`.
- The first blind review was not valid evidence because the image viewer had
  served stale same-basename files; however, later uniquely named and
  OS-composited captures independently confirmed the reopen corruption.
- Windows.Graphics.Capture could not inspect the Godot OpenGL window on this
  host (`SetIsBorderRequired failed: No such interface supported`).
- `DisplayServer.screen_get_image()` was added to a temporary probe and proved
  the corruption is visible in OS-composited window pixels, not only in
  `ViewportTexture.get_image()` readback. In one sequence the initial map was
  clean, the reopened map lost texture/glyph regions, and the surveyed map
  recovered after the MapState revision changed.
- `scripts/ui/tab_map.gd::_fog_texture()` now updates the existing
  `ImageTexture` RID in place when dimensions/state match. This is a sensible
  resource-lifetime improvement, but did not by itself fix the reopen frame.
- A deferred reopen fog refresh was added. A 2-frame delay did not fix the
  corruption. The worktree currently has the experimental delay set to **30
  frames**, but its verification run crashed during unrelated Meadows
  vegetation construction before reaching the UI. Treat 30 as an unverified
  experiment, not a finished fix.

Latest OS-composited artifacts are under:

- `shots/final-os-evidence-20260907/`
- `shots/final-os-evidence-20260907-pass2/`

The pass-2 uniquely named reopened frame is visibly corrupt. The temporary
probe is `tools/_probe_map_visible_window.gd`; it captures initial, reopened,
surveyed, and compass frames using OS-composited pixels. It is diagnostic
tooling and should not be committed without deciding that it belongs in the
repo.

The most promising next test is to finish the 30-frame deferred-refresh run.
If it repairs the reopened OS capture, minimize the delay and keep the map body
hidden until that refresh completes so players never see a broken intermediate
frame. If it does not, compare the clean surveyed transition against reopen:
the key difference is a genuine MapState revision/legend/fog update occurring
after the menu has already been visible for about two seconds.

Useful observation: corruption affects shell/tab/button/control glyphs outside
the custom map canvas as well as the map textures. That points beyond a simple
`MapCanvas.queue_redraw()` omission. The lightweight harness is stable, so the
failure requires the loaded Meadows renderer/resource pressure or the full
capture sequence. Investigate GPU texture/font atlas lifetime or the capture
harness's repeated `ViewportTexture.get_image()`/hide/show interaction before
adding more redraw delay.

Reproduction command (about two minutes on this machine):

```powershell
& 'D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/_capture_map_ui_0905.gd -- --out=res://shots/<fresh-unique-dir>
```

Compare `map_day1.png` and `map_day1_repeat.png` from the same run.

## Required remaining work, in order

1. Resolve or revert the current experimental 30-frame deferred fog refresh,
   fix the full-world repeated-open corruption, and rerun both viewport and
   OS-composited reproduction until
   both first and repeated frames are clean.
2. Copy final evidence to a brand-new directory with unique basenames (the app
   image viewer has shown stale same-name images). Suggested names:
   `compass_final_0907.png`, `map_local_initial_0907.png`,
   `map_local_reopened_0907.png`, and `map_surveyed_0907.png`.
3. Run a fresh blind visual judge using `.claude/skills/visual-judge/SKILL.md`
   and only those unique final files. Prior judge attempts were invalidated by
   stale/corrupted same-basename image rendering. Iterate until pass or
   pass-with-minor with no release blocker.
4. Rerun the latest full live smoke:

   ```powershell
   & 'D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --script tests/smoke_gate_a_map_cycle.gd
   ```

5. Run final `--check-only` checks for every changed/new GDScript, rerun the
   compass, quest-log, map, and zoom suites, and run relevant multiplayer map
   state/persistence evidence. Consult the handoff coordination document for
   the exact required multiplayer gate rather than substituting an unrelated
   Stormwood smoke.
6. Clean only generated noise, then inspect the exact diff. Many tracked
   `.import` files were rewritten by local Godot import/path normalization and
   are not intended feature changes. The untracked Terrain3D `~dll` is also
   generated. Several untracked `.uid` files belong to recently merged
   Stormwood work; verify each against current HEAD before deleting or adding
   it. Preserve all feature files listed above.
7. Commit the scoped diff, push `ralph/hud-map-compass-0906`, open the PR, wait
   for every required CI job (including all multiplayer shards and solo
   regression), fix any failures, and merge only when fully green.

## Working-tree caution

`git status --short` currently includes dozens of modified asset `.import`
files, the feature sources/tests above, one generated Terrain3D `~dll`, and
multiple untracked `.uid` files. Do not use a broad reset/clean command. Resolve
each class deliberately so unrelated/user work is not lost.
