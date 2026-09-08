# Map UI capture — 2026-09-08

Two production menu opens and closes rendered successfully in the Compatibility
renderer on the local NVIDIA GPU. The unique engine log is
`%TEMP%/root-map-ui-render-20260908.log`; process exit 0, no native errors.

Frames (uncommitted) are in `map-legibility-capture-20260908/`:
`map_ui_open_1.png` and `map_ui_open_2.png`.

This is deliberately UI-only evidence. `tools/capture_map_ui_isolated.gd`
mounts the real game menu and uses its production map drawing, fed a real
Meadows terrain bitmap from CI run 34213024669, artifact 10051081200, host
Livewire fixture's `cache/map_meadows.png`. It reveals the map as a disclosed
presentation fixture and isolates the saver before reset. It does not instantiate
Terrain3D or a world HUD, and opens the menu through its API rather than input.

Consequently this proves that this UI capture path renders twice, not that a
fresh-save player can navigate the map, that the HUD minimap is sound, or that
the full-world second-open corruption cannot recur. The existing full-world
capture remains pending. The map's unit contract separately passes 29 tests /
95 assertions; see `MAP-LEGIBILITY-CONTRACT.md`.

Code-blind visual verdict is pending. Two attempts to allocate a fresh
zero-context critic were rejected by the active agent-tree thread limit, even
after the Meadows agent completed. An existing informed agent is not being
relabelled as blind to bypass this requirement. No visual quality pass is claimed by the
implementer. This small UI-only render ran beside the existing headless Meadows
test, without a second terrain world or concurrent cache writer.
