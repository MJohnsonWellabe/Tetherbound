# Real-world map cycle — functional pass, visual verdict pending

Root ran `tools/capture_gate_a_map_presentation.gd` against the fully built
Meadows world with Compatibility/OpenGL3 on the NVIDIA RTX3050. The disclosed
fixture isolates its save before reset and supplies free-play/map reveal for
presentation; it is not fresh-save campaign proof.

Actual controller input opens Map, closes it, opens it a second time and closes
again. Each menu state is asserted, and the second open requires its real clipped
canvas. All three1920x1080 viewport PNGs were written successfully; process
session17299 exits0 and both Godot processes are gone. The full native log has
zero `ERROR:` or `SCRIPT ERROR` lines. Terrain mipmap/deprecation warnings remain.

Log: `%TEMP%/root-map-world-reopen-20260908.log`.
Uncommitted evidence payloads:

- `map-world-reopen-20260908/clean_full_map_first_open.png`
- `map-world-reopen-20260908/clean_hud_minimap_after_close.png`
- `map-world-reopen-20260908/clean_full_map_second_open.png`

Root did not view or judge these frames. This establishes the real-world menu
cycle and capture delivery, not visual correctness, legibility or absence of
corrupt pixels. The fresh code-blind verdict remains outstanding under the
existing agent-tree limit, alongside the earlier isolated UI captures. Do not
replace that verdict with the writer's opinion or declare the visual bug closed.
