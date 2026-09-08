# Detached dialogue camera lookup

CI 34216463559 unit shard 4 (job 102029764692) reports green while
`test_dialogue_portraits.gd` emits native `data.tree` null errors and script
errors at `dialogue_panel.gd::_conversation_camera`. The portrait assertions
still execute, unlike the previous missing-map-constant aborts.

Root reproduced locally: 13 tests / 2697 assertions / 0 failed, but repeated
native and script errors. The method unconditionally called `get_tree()` on
a detached panel. Its existing contract explicitly allows having no camera.

The production lookup now returns null before calling `get_tree()` if the
panel is not inside the tree. Attached panels retain their original group
lookup; no camera position, blend, UI style or portrait rule changed.

After repair the identical portrait suite passes 13 tests / 2697 assertions
with no native or script errors. Logs:
`%TEMP%/root-dialogue-portrait-baseline-20260908.log` and
`%TEMP%/root-dialogue-portrait-guarded-20260908.log`.
This local repair is after the active CI head and needs a future CI verdict.
The unchanged conversation-camera regression suite also passes 24 tests /
104 assertions with a clean native log (`root-dialogue-camera-regression-20260908.log`).
